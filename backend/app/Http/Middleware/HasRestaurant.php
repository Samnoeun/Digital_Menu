<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Cookie\Middleware\HasRestaurant as Middleware;

class HasRestaurant
{
    public function handle($request, Closure $next)
    {
        if (!auth()->user()->restaurant) {
            return redirect()->route('restaurant.create')
                ->with('error', 'You need to create a restaurant first');
        }
        
        return $next($request);
    }
}