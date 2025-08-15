<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Category;
use App\Http\Requests\Category\StoreCategoryRequest;
use App\Http\Requests\Category\UpdateCategoryRequest;
use App\Http\Resources\CategoryResource;

class CategoryController extends Controller
{
    // List categories for the authenticated user's restaurant, latest first
    public function index()
    {
        $user = auth()->user();
        
        if (!$user || !$user->restaurant) {
            return response()->json([
                'data' => [],
                'message' => 'No restaurant found for this user'
            ]);
        }

        $categories = Category::where('restaurant_id', $user->restaurant->id)
            ->with('items')
            ->orderBy('created_at', 'desc') // latest first
            ->get();

        return CategoryResource::collection($categories);
    }

    // Create a new category
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255'
        ]);

        $user = auth()->user();
        
        if (!$user->restaurant) {
            return response()->json([
                'message' => 'User is not associated with a restaurant'
            ], 422);
        }

        $category = Category::create([
            'name' => $request->name,
            'restaurant_id' => $user->restaurant->id
        ]);

        return response()->json($category, 201);
    }

    // Show a single category
    public function show($id)
    {
        $category = Category::with('items')->findOrFail($id);
        return new CategoryResource($category);
    }

    // Update a category
    public function update(UpdateCategoryRequest $request, $id)
    {
        $category = Category::findOrFail($id);

        $category->update($request->validated());

        return response()->json(['message' => 'Category updated successfully', 'data' => $category]);
    }

    // Delete a category
    public function destroy(Category $category)
    {
        $category->delete();
        return response()->noContent();
    }
}
