<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateRestaurantRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'restaurant_name' => 'sometimes|string|max:255',
            'address' => 'sometimes|string|max:255',
            'profile' => 'sometimes|image|max:2048',
        ];
    }
}
