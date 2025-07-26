<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RestaurantController extends Controller
{
    public function show()
    {
        $restaurant = Auth::user()->restaurant;

        if (!$restaurant) {
            return response()->json([
                'message' => 'Restaurant not found'
            ], 404);
        }

        return response()->json($restaurant);
    }

    // Create new restaurant
    public function store(Request $request)
    {
        $user = Auth::user(); // Get authenticated user

        // Check if user already has a restaurant
        if ($user->restaurant) {
            return response()->json([
                'message' => 'User already has a restaurant'
            ], 400);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            // other validation rules
        ]);

        // This is the correct way to create through a hasOne relationship
        $restaurant = $user->restaurant()->create($validated);

        return response()->json($restaurant, 201);
    }

    // Update restaurant
    public function update(Request $request)
    {
        $restaurant = Auth::user()->restaurant;

        if (!$restaurant) {
            return response()->json([
                'message' => 'Restaurant not found'
            ], 404);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'address' => 'nullable|string',
            'contact_number' => 'nullable|string',
            'primary_color' => 'sometimes|string',
            'secondary_color' => 'sometimes|string'
        ]);

        $restaurant->update($validated);

        return response()->json($restaurant);
    }

    // Upload logo (separate endpoint for file upload)
    public function uploadLogo(Request $request)
    {
        $request->validate([
            'logo' => 'required|image|max:2048'
        ]);

        $path = $request->file('logo')->store('restaurant-logos');

        $restaurant = Auth::user()->restaurant;
        $restaurant->update(['logo' => $path]);

        return response()->json([
            'logo_url' => asset("storage/{$path}")
        ]);
    }
}
