<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\OrderHistory;
use App\Models\OrderItemHistory;
use Illuminate\Support\Facades\DB;

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
            try {
                $historyOrder = OrderHistory::create([
                    'restaurant_id' => $order->restaurant_id,
                    'table_number' => $order->table_number,
                    'completed_at' => now(),
                ]);

                foreach ($order->orderItems as $item) {
                    OrderItemHistory::create([
                        'order_history_id' => $historyOrder->id,
                        'item_id' => $item->item_id,
                        'quantity' => $item->quantity,
                        'special_note' => $item->special_note,
                    ]);
                }

                $order->delete();
                return response()->json(['message' => 'Order completed and archived']);
            } catch (\Exception $e) {
                return response()->json(['error' => 'Failed to archive order: ' . $e->getMessage()], 500);
            }
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

    public function history()
    {
        $user = Auth::user();
        
        if (!$user->restaurant) {
            return response()->json(['data' => []]);
        }

        return DB::table('order_history')
            ->where('restaurant_id', $user->restaurant->id)
            ->orderBy('created_at', 'desc')
            ->get();
    }

    // Web route methods
    public function webTableNumber($id)
    {
        $restaurant = \App\Models\Restaurant::findOrFail($id);
        return view('table-number', ['restaurant' => $restaurant]);
    }

    public function webSubmitOrder(Request $request, $id)
    {
        $validated = $request->validate([
            'table_number' => 'required|integer',
            'items' => 'required|array',
            'items.*.item_id' => 'required|exists:items,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.special_note' => 'nullable|string',
        ]);

        $restaurant = \App\Models\Restaurant::findOrFail($id);

        try {
            $order = Order::create([
                'restaurant_id' => $restaurant->id,
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

            return redirect()->route('web.order-confirmation', [
                'id' => $id,
                'table_number' => $validated['table_number'],
                'items' => $validated['items'],
            ]);
        } catch (\Exception $e) {
            return back()->withErrors(['error' => 'Failed to submit order: ' . $e->getMessage()]);
        }
    }

    public function webOrderConfirmation(Request $request, $id)
    {
        $tableNumber = $request->query('table_number');
        $items = $request->query('items');

        if (!$tableNumber || !$items) {
            return redirect()->route('web.menu-preview', ['id' => $id])->withErrors(['error' => 'Invalid order data']);
        }

        return view('order-confirmation', [
            'restaurant' => \App\Models\Restaurant::findOrFail($id),
            'table_number' => $tableNumber,
            'items' => $items,
        ]);
    }
}