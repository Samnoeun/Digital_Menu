<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Restaurant extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', // THIS WAS MISSING
        'name', 
        'description', 
        'address',
        'contact_number', 
        'primary_color', 
        'secondary_color'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}