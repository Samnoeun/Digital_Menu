<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Item\StoreItemRequest;
use Illuminate\Http\Request;
use App\Models\Item;
use App\Http\Requests\Item\UpdateItemRequest;
use App\Http\Resources\ItemResource;
use App\Models\Category;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class ItemController extends Controller
{
    public function index()
    {
        $user = auth()->user();
        
        if (!$user->restaurant) {
            return response()->json(['data' => []]);
        }

        return ItemResource::collection(
            Item::whereHas('category', function ($query) use ($user) {
                $query->where('restaurant_id', $user->restaurant->id);
            })
            ->with('category')
            ->get()
        );
    }

    public function store(StoreItemRequest $request)
    {
        $user = auth()->user();

        if (!$user->restaurant) {
            return response()->json([
                'message' => 'Please create a restaurant first'
            ], 422);
        }

        // Verify the category belongs to the user's restaurant
        $category = Category::where('id', $request->category_id)
            ->where('restaurant_id', $user->restaurant->id)
            ->firstOrFail();

        $validated = $request->validated();
        
        try {
            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('items', 'public');
                $validated['image_path'] = $imagePath;
            }

            $item = Item::create($validated);
            
            return response()->json([
                'message' => 'Item created successfully',
                'data' => new ItemResource($item)
            ], 201);
            
        } catch (\Exception $e) {
            // Delete the uploaded image if item creation fails
            if (isset($imagePath)) {
                Storage::disk('public')->delete($imagePath);
            }
            
            Log::error('Item creation failed: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to create item'
            ], 500);
        }
    }

    public function show(Item $item)
    {
        $this->authorizeItemAccess($item);
        return new ItemResource($item->load('category'));
    }

    public function update(UpdateItemRequest $request, Item $item)
    {
        $this->authorizeItemAccess($item);

        $validated = $request->validated();
        $oldImagePath = $item->image_path;

        try {
            if ($request->hasFile('image')) {
                Log::info('Image uploaded:', [
                    'original_name' => $request->file('image')->getClientOriginalName(),
                    'size' => $request->file('image')->getSize(),
                ]);
                
                $path = $request->file('image')->store('items', 'public');
                $validated['image_path'] = $path;
                
                // Delete old image after successful upload
                if ($oldImagePath) {
                    Storage::disk('public')->delete($oldImagePath);
                }
            }

            $item->update($validated);
            
            return response()->json([
                'message' => 'Item updated successfully',
                'data' => new ItemResource($item)
            ]);
            
        } catch (\Exception $e) {
            // Delete the new uploaded image if update fails
            if (isset($path)) {
                Storage::disk('public')->delete($path);
            }
            
            Log::error('Item update failed: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to update item'
            ], 500);
        }
    }

    public function destroy(Item $item)
    {
        $this->authorizeItemAccess($item);
        
        try {
            $imagePath = $item->image_path;
            $item->delete();
            
            // Delete associated image
            if ($imagePath) {
                Storage::disk('public')->delete($imagePath);
            }
            
            return response()->noContent();
            
        } catch (\Exception $e) {
            Log::error('Item deletion failed: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to delete item'
            ], 500);
        }
    }

    /**
     * Authorize that the item belongs to the user's restaurant
     */
    protected function authorizeItemAccess(Item $item)
    {
        $user = auth()->user();
        
        if (!$user->restaurant || $item->category->restaurant_id !== $user->restaurant->id) {
            abort(403, 'Unauthorized action.');
        }
    }
}