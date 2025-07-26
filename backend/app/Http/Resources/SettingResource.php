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
            'user_id' => $this->user_id,
            'restaurant_name' => $this->restaurant_name,
            'logo' => $this->logo,
            'address' => $this->address,
            'currency' => $this->currency,
            'language' => $this->language,
            'dark_mode' => (bool) $this->dark_mode,
           
        ];
    }
}
