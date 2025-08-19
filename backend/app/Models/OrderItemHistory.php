<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItemHistory extends Model
{
    protected $fillable = ['order_history_id', 'item_id', 'quantity', 'special_note'];

    public function item()
    {
        return $this->belongsTo(Item::class);
    }
}