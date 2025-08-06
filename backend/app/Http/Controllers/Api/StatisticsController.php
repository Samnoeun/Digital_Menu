<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class StatisticsController extends Controller
{
   public function getStatistics(Request $request)
{
    $user = $request->user();
    $period = $request->input('period', 'today');
    
    $query = OrderStatistic::with('item')
        ->where('restaurant_id', $user->restaurant->id);

    // Date filtering
    switch ($period) {
        case 'today': 
            $query->whereDate('stat_date', now()->toDateString());
            break;
        case 'this_week':
            $query->whereBetween('stat_date', [
                now()->startOfWeek(), 
                now()->endOfWeek()
            ]);
            break;
        case 'this_month':
            $query->whereBetween('stat_date', [
                now()->startOfMonth(),
                now()->endOfMonth()
            ]);
            break;
    }

    $stats = $query->get();

    return response()->json([
        'total_orders' => $stats->sum('order_count'),
        'top_items' => $stats->groupBy('item_id')
            ->map(function($group) {
                return [
                    'item_id' => $group->first()->item_id,
                    'count' => $group->sum('quantity_sold')
                ];
            })
            ->sortByDesc('count')
            ->take(5)
            ->values()
    ]);
}
}
