<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class TableResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray($request)
    {
        return [
            'id'           => $this->id,
            'table_number' => $this->table_number,
            'qr_code_url'  => $this->qr_code_url,
           
        ];
    }
}
