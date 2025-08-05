<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderStatistic extends Model
{
    use HasFactory;
     protected $fillable = [
        'restaurant_id',
        'stat_date',
        'item_id',
        'quantity_sold',
        'order_count'
    ];

    public function restaurant()
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }
}
