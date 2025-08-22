<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Restaurant;
use App\Http\Requests\StoreRestaurantRequest;
use App\Http\Requests\UpdateRestaurantRequest;
use App\Http\Resources\RestaurantResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class RestaurantController extends Controller
{
    // List all restaurants
    public function index()
    {
        return RestaurantResource::collection(Restaurant::all());
    }

    // Create a restaurant
    public function store(Request $request)
    {
        $request->validate([
            'restaurant_name' => 'required|string|max:255',
            'address' => 'required|string',
            'profile' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        $data = $request->only(['restaurant_name', 'address']);
        $data['user_id'] = auth()->id();

        if ($request->hasFile('profile')) {
            $file = $request->file('profile');
            $filename = time() . '.' . $file->getClientOriginalExtension();
            $file->storeAs('public/profiles', $filename);
            $data['profile'] = $filename;
        }

        $restaurant = Restaurant::create($data);

        return response()->json(['message' => 'Restaurant created', 'data' => $restaurant], 201);
    }

    // Get restaurant by user ID
    public function getByUserId($id)
    {
        $restaurant = Restaurant::where('user_id', $id)->first();

        if (!$restaurant) {
            return response()->json(['message' => 'Restaurant not found'], 404);
        }

        return response()->json(['restaurant' => $restaurant]);
    }

    // Show a single restaurant
    public function show($id)
    {
        $restaurant = Restaurant::findOrFail($id);
        return new RestaurantResource($restaurant);
    }

    // Update restaurant
    public function update(Request $request, Restaurant $restaurant)
    {
        $validated = $request->validate([
            'restaurant_name' => 'required|string|max:255',
            'address' => 'required|string',
        ]);

        if ($request->hasFile('profile')) {
            if ($restaurant->profile) {
                Storage::delete('public/profiles/' . $restaurant->profile);
            }

            $file = $request->file('profile');
            $filename = time() . '.' . $file->getClientOriginalExtension();
            $file->storeAs('public/profiles', $filename);
            $validated['profile'] = $filename;
        }

        $restaurant->update($validated);

        return response()->json([
            'message' => 'Restaurant updated successfully',
            'data' => $restaurant
        ]);
    }

    // Delete restaurant
    public function destroy($id)
    {
        $restaurant = Restaurant::findOrFail($id);
        $restaurant->delete();

        return response()->json(['message' => 'Deleted successfully']);
    }

    // Public API: preview menu (JSON)
    public function menuPreview($id)
    {
        $restaurant = Restaurant::with(['categories.items'])->findOrFail($id);

        return response()->json([
            'status' => 'success',
            'data' => [
                'restaurant' => [
                    'id' => $restaurant->id,
                    'restaurant_name' => $restaurant->restaurant_name,
                    'profile' => $restaurant->profile
                        ? url('storage/profiles/' . $restaurant->profile)
                        : null,
                    'address' => $restaurant->address,
                    'categories' => $restaurant->categories->map(function ($category) {
                        return [
                            'id' => $category->id,
                            'name' => $category->name,
                            'items' => $category->items->map(function ($item) {
                                return [
                                    'id' => $item->id,
                                    'name' => $item->name,
                                    'description' => $item->description,
                                    'price' => $item->price,
                                    'image' => $item->image ? url($item->image) : null,
                                ];
                            })
                        ];
                    })
                ]
            ]
        ], 200);
    }

    // Web view for menu preview (Blade)
    public function webMenuPreview($id)
    {
        $restaurant = Restaurant::with(['categories.items'])->findOrFail($id);

        return view('menu-preview', [
            'restaurant' => $restaurant,
            'categories' => $restaurant->categories,
            'items' => $restaurant->categories->flatMap(fn($cat) => $cat->items)
        ]);
    }
}
