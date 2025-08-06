<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes; 

class Order extends Model
{
    use SoftDeletes;
    use HasFactory;
    public function user()
    {
        return $this->belongsTo(User::class);
    }


    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }
    protected $fillable = ['table_number','restaurant_id', 'status'];

}
