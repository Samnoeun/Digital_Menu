<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateRestaurantRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'restaurant_name' => 'required|string|max:255',
            'address' => 'required|string',
            'profile' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ];
    }
}