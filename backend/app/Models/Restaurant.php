<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;


class Restaurant extends Model
{
    use HasFactory;

    protected $fillable = ['restaurant_name', 'address', 'profile'];
}
