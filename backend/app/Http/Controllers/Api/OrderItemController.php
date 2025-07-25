<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\OrderItem\StoreOrderItemRequest;
use App\Http\Requests\OrderItem\UpdateOrderItemRequest;
use App\Models\OrderItem;
use Illuminate\Http\Request;

class OrderItemController extends Controller
{
    public function index()
    {
        $orderItems = OrderItem::with(['order', 'item'])->get();
        return response()->json($orderItems);
    }

    public function store(StoreOrderItemRequest $request)
    {
        $orderItem = OrderItem::create($request->validated());
        return response()->json(['message' => 'Order item created', 'order_item' => $orderItem], 201);
    }

    public function show($id)
    {
        $orderItem = OrderItem::with(['order', 'item'])->findOrFail($id);
        return response()->json($orderItem);
    }

    public function update(UpdateOrderItemRequest $request, $id)
    {
        $orderItem = OrderItem::findOrFail($id);
        $orderItem->update($request->validated());
        return response()->json(['message' => 'Order item updated', 'order_item' => $orderItem]);
    }

    public function destroy($id)
    {
        $orderItem = OrderItem::findOrFail($id);
        $orderItem->delete();
        return response()->json(['message' => 'Order item deleted']);
    }
}
