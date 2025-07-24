<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    use HasFactory;
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    protected $fillable = [
        'user_id',
        'restaurant_name',
        'logo',
        'address',
        'currency',
        'language',
        'dark_mode',
        'color',
    ];
    protected $hidden = [
        'created_at',
        'updated_at',
    ];

}
