<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\OrderHistory;
use Carbon\Carbon;

class ReportController extends Controller
{
    public function salesSummary(Request $request)
    {
        $user = $request->user();

        if (!$user->restaurant) {
            return response()->json(['data' => []]);
        }

        // Get filter type: today | this_month | custom
        $filter = $request->query('filter', 'today');

        if ($filter === 'today') {
            $startDate = Carbon::today();
            $endDate   = Carbon::today()->endOfDay();
        } elseif ($filter === 'this_month') {
            $startDate = Carbon::now()->startOfMonth();
            $endDate   = Carbon::now()->endOfMonth();
        } else { // custom
            $startDate = Carbon::parse($request->query('start_date', Carbon::today()));
            $endDate   = Carbon::parse($request->query('end_date', Carbon::today()->endOfDay()));
        }

        $orders = OrderHistory::with(['orderItems.item'])
            ->where('restaurant_id', $user->restaurant->id)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->get();

        // Group by item
        $summary = $orders->flatMap->orderItems
            ->groupBy('item_id')
            ->map(function ($items) {
                $item = $items->first()->item;
                return [
                    'item_id'       => $item->id,
                    'item_name'     => $item->name,
                    'category_name' => $item->category->name ?? null,
                    'total_sold'    => $items->sum('quantity'),
                ];
            })
            ->values();

        return response()->json([
            'start_date' => $startDate->toDateString(),
            'end_date'   => $endDate->toDateString(),
            'items'      => $summary,
        ]);
    }
}
