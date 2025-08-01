<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;
    protected $fillable = [
        'restaurant_id',
        'name',
    ];
    public function items()
    {
        return $this->hasMany(Item::class);
    }
    public function restaurant()
    {
        return $this->belongsTo(Restaurant::class);
    }
}
