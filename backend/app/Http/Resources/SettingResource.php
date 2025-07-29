<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class SettingResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'restaurant_id' => $this->restaurant_id,
            'logo' => $this->logo,
            'dark_mode' => $this->dark_mode,
            'created_at' => $this->created_at,
        ];
    }
}
