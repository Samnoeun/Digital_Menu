<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class StatisticsController extends Controller
{
    public function getStatistics(Request $request)
    {
        $user = Auth::user();
        
        if (!$user->restaurant) {
            return response()->json(['data' => []]);
        }

        $period = $request->input('period', 'today');
        $restaurantId = $user->restaurant->id;

        $query = OrderStatistic::with('item')
            ->where('restaurant_id', $restaurantId);

        switch ($period) {
            case 'today':
                $query->whereDate('stat_date', Carbon::today());
                break;
            case 'this_week':
                $query->whereBetween('stat_date', [
                    Carbon::now()->startOfWeek(),
                    Carbon::now()->endOfWeek()
                ]);
                break;
            case 'this_month':
                $query->whereBetween('stat_date', [
                    Carbon::now()->startOfMonth(),
                    Carbon::now()->endOfMonth()
                ]);
                break;
            case 'custom':
                if ($request->has('date')) {
                    $query->whereDate('stat_date', $request->date);
                }
                break;
        }

        $stats = $query->get();

        $totalOrders = $stats->sum('order_count');
        
        $topItems = $stats->groupBy('item_id')
            ->map(function ($group) {
                return [
                    'item_id' => $group->first()->item_id,
                    'name' => $group->first()->item->name,
                    'count' => $group->sum('quantity_sold')
                ];
            })
            ->sortByDesc('count')
            ->take(5)
            ->values();

        return response()->json([
            'total_orders' => $totalOrders,
            'top_items' => $topItems
        ]);
    }
}
