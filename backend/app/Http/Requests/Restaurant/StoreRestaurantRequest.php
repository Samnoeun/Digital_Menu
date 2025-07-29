<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreRestaurantRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'restaurant_name' => 'required|string|max:255',
            'address' => 'required|string|max:255',
            'profile' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
        ];
    }
}
