<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OrderController extends Controller
{
     public function index()
    {
        $user = Auth::user();
        
        if (!$user->restaurant) {
            return response()->json(['data' => []]);
        }

        return Order::with(['orderItems.item'])
            ->where('restaurant_id', $user->restaurant->id)
            ->orderBy('created_at', 'desc')
            ->get();
    }
    public function store(Request $request)
{
    $user = Auth::user();
    
    if (!$user->restaurant) {
        return response()->json(['message' => 'Restaurant not found'], 422);
    }

    $validated = $request->validate([
        'table_number' => 'required|integer',
        'items' => 'required|array',
        'items.*.item_id' => 'required|exists:items,id',
        'items.*.quantity' => 'required|integer|min:1',
        'items.*.special_note' => 'nullable|string',
    ]);

    $order = Order::create([
        'restaurant_id' => $user->restaurant->id,
        'table_number' => $validated['table_number'],
        'status' => 'pending',
    ]);

    foreach ($validated['items'] as $item) {
        $order->orderItems()->create([
            'item_id' => $item['item_id'],
            'quantity' => $item['quantity'],
            'special_note' => $item['special_note'] ?? null,
        ]);

        // Update statistics
        $this->updateStatistics(
            $user->restaurant->id,
            $item['item_id'],
            $item['quantity'],
            now()->toDateString()
        );
    }

    return response()->json($order->load('orderItems.item'), 201);
}

public function updateStatus(Order $order, Request $request)
{
    $this->authorizeOrderAccess($order);
    $request->validate([
        'status' => 'required|in:pending,preparing,ready,completed',
    ]);

    // Update statistics first
    if ($request->status === 'completed') {
        foreach ($order->orderItems as $orderItem) {
            OrderStatistic::updateOrCreate(
                [
                    'restaurant_id' => $order->restaurant_id,
                    'stat_date' => $order->created_at->format('Y-m-d'),
                    'item_id' => $orderItem->item_id
                ],
                [
                    'quantity_sold' => DB::raw("quantity_sold + {$orderItem->quantity}"),
                    'order_count' => DB::raw("order_count + 1")
                ]
            );
        }
        
        // Soft delete the order
        $order->delete();
        
        return response()->json(['message' => 'Order completed and archived']);
    }

    $order->update(['status' => $request->status]);
    return response()->json($order->load('orderItems.item'));
}

protected function updateOrderStatistics(Order $order)
{
    $date = $order->created_at->toDateString();
    
    foreach ($order->orderItems as $orderItem) {
        OrderStatistic::updateOrCreate(
            [
                'restaurant_id' => $order->restaurant_id,
                'stat_date' => $date,
                'item_id' => $orderItem->item_id
            ],
            [
                'quantity_sold' => DB::raw("quantity_sold + {$orderItem->quantity}"),
                'order_count' => DB::raw("order_count + 1")
            ]
        );
    }
}

    public function destroy(Order $order)
    {
        $order->delete();
        return response()->json(['message' => 'Order deleted']);
    }
        protected function authorizeOrderAccess(Order $order)
    {
        $user = Auth::user();
        
        if (!$user->restaurant || $order->restaurant_id !== $user->restaurant->id) {
            abort(403, 'Unauthorized action.');
        }
    }
}