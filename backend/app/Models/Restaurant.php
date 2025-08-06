<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Restaurant extends Model
{
    use HasFactory;

    protected $fillable = ['restaurant_name', 'address', 'profile', 'user_id']; // ✅ Add user_id

    // Relationship with User
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    // Relationship with Categories
    public function categories()
    {
        return $this->hasMany(Category::class);
    }
}
