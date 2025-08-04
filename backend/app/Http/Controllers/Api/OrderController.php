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
    public function store(Request $request){
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
        }

        return response()->json($order->load('orderItems.item'), 201);
    }

    public function updateStatus(Order $order, Request $request)
    {
        $this->authorizeOrderAccess($order);
        $request->validate([
            'status' => 'required|in:pending,preparing,ready,completed',
        ]);

        $order->update(['status' => $request->status]);

        if ($request->status === 'completed') {
            $order->delete();
            return response()->json(['message' => 'Order completed and deleted']);
        }

        return response()->json($order->load('orderItems.item'));
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