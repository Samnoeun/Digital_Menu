<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ItemResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
public function toArray($request)
{
    return [
        'id' => $this->id,
        'name' => $this->name,
        'description' => $this->description,
        'price' => $this->price,
        'category_id' => $this->category_id,
        'image_path' => $this->image_path, // Keep original
        'image_url' => $this->image_path ? 
            url("api/images/{$this->image_path}") : null, // New API endpoint
        'category' => new CategoryResource($this->whenLoaded('category')),
        'created_at' => $this->created_at,
        'updated_at' => $this->updated_at,
    ];
}
}
