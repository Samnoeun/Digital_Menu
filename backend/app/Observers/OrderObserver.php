<?php

namespace App\Observers;

use App\Models\Order;

class OrderObserver
{
    // OrderObserver.php
public function created(Order $order)
{
    $this->updateStatistics($order, 'created');
}

public function updated(Order $order)
{
    if ($order->isDirty('status') && $order->status === 'completed') {
        $this->updateStatistics($order, 'completed');
    }
}

protected function updateStatistics(Order $order, $action)
{
    $date = now()->toDateString();
    
    foreach ($order->items as $item) {
        $stat = OrderStatistic::firstOrNew([
            'date' => $date,
            'item_id' => $item->item_id
        ]);
        
        if ($action === 'created') {
            $stat->count += $item->quantity;
            $stat->total_orders += 1;
        } elseif ($action === 'completed') {
            // Keep the count but don't increment total orders
        }
        
        $stat->save();
    }
}
}
