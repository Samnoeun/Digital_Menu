<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Item;
use App\Http\Requests\StoreItemRequest;
use App\Http\Requests\Item\UpdateItemRequest;
use App\Http\Resources\ItemResource;
use Illuminate\Support\Facades\Log;


class ItemController extends Controller
{
    public function index()
    {
        return ItemResource::collection(Item::with('category')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'image' => 'nullable|image|mimes:jpg,jpeg,png|max:2048', // ✅ Changed here
            'description' => 'nullable|string',
            'price' => 'required|numeric',
        ]);

        if ($request->hasFile('image')) { // ✅ Changed here
            $imagePath = $request->file('image')->store('items', 'public');
            $validated['image_path'] = $imagePath; // ✅ Store into DB
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
            'image_path' => 'nullable|image|max:2048',
        ]);

        $data = $request->only(['name', 'description', 'price', 'category_id']);

        // if ($request->hasFile('image')) {
        //     \Log::info('Image uploaded:', [
        //         'original_name' => $request->file('image')->getClientOriginalName(),
        //         'size' => $request->file('image')->getSize(),
        //     ]);
        //     $path = $request->file('image')->store('items', 'public');
        //     $data['image_path'] = $path;
        // } else {
        //     \Log::warning('No image file found in request.');
        // }
        if ($request->hasFile('image')) {
            Log::info('Image uploaded:', [ // ✅ no backslash needed
                'original_name' => $request->file('image')->getClientOriginalName(),
                'size' => $request->file('image')->getSize(),
            ]);
            $path = $request->file('image')->store('items', 'public');
            $data['image_path'] = $path;
        } else {
            Log::warning('No image file found in request.');
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
