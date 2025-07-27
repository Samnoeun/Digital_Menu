<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SettingResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user' => new UserResource($this->whenLoaded('user')),
            'restaurant_name' => $this->restaurant_name,
            'logo' => $this->logo,
            'address' => $this->address,
            'currency' => $this->currency,
            'language' => $this->language,
            'dark_mode' => $this->dark_mode,
            'created_at' => $this->created_at->toDateTimeString(),
        ];
    }
}
