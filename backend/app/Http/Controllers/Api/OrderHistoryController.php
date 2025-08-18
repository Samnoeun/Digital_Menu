<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\OrderHistory; // Add this import
use App\Models\OrderItemHistory; 
class OrderHistoryController extends Controller
{
    public function index(Request $request)
{
    $user = $request->user();

    if (!$user->restaurant) {
        return response()->json(['data' => []]);
    }

    $history = OrderHistory::with(['orderItems.item'])
        ->where('restaurant_id', $user->restaurant->id)
        ->orderBy('created_at', 'desc')
        ->get()
        ->map(function ($order) {
            return [
                'id' => $order->id,
                'table_number' => $order->table_number,
                'status' => 'completed',
                'created_at' => $order->created_at,
                'order_items' => $order->orderItems->map(function ($item) {
                    return [
                        'item_id' => $item->item_id,
                        'quantity' => $item->quantity,
                        'special_note' => $item->special_note,
                        'item' => $item->item // Include full item data if needed
                    ];
                })
            ];
        });

    return response()->json(['data' => $history]);
}
}