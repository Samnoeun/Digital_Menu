<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Item;
use App\Http\Requests\StoreItemRequest;
use App\Http\Requests\UpdateItemRequest;
use App\Http\Resources\ItemResource;

class ItemController extends Controller
{
    public function index()
    {
        return ItemResource::collection(Item::with('category')->get());
    }

    // public function store(StoreItemRequest $request)
    // {
    //     $item = Item::create($request->validated());
    //     return new ItemResource($item->load('category'));
    // }
    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'image_path' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
            'description' => 'nullable|string',
            'price' => 'required|numeric',
        ]);

        if ($request->hasFile('image_path')) {
            $imagePath = $request->file('image_path')->store('items', 'public');
            $validated['image_path'] = $imagePath;
        }

        $item = Item::create($validated);

        return response()->json(['data' => $item], 201);
    }

    public function show(Item $item)
    {
        return new ItemResource($item->load('category'));
    }

    public function update(Request $request, $id)
    {
        $item = Item::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric',
            'category_id' => 'required|exists:categories,id',
            'image' => 'nullable|image|max:2048',
        ]);

        $data = $request->only(['name', 'description', 'price', 'category_id']);

        // handle image upload
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('items', 'public');
            $data['image_path'] = $path;
        }

        $item->update($data);

        return response()->json(['message' => 'Item updated successfully', 'data' => new ItemResource($item)]);
    }


    public function destroy(Item $item)
    {
        $item->delete();
        return response()->noContent();
    }
}
