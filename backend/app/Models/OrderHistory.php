<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderHistory extends Model
{
    protected $fillable = ['restaurant_id', 'table_number', 'completed_at'];

    public function orderItems()
    {
        return $this->hasMany(OrderItemHistory::class);
    }
}