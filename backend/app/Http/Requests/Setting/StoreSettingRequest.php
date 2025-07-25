<?php

namespace App\Http\Requests\Setting;

use Illuminate\Foundation\Http\FormRequest;

class StoreSettingRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
       return [
            'user_id' => 'required|exists:users,id',
            'restaurant_name' => 'required|string|max:255',
            'logo' => 'nullable|string|max:255',
            'address' => 'required|string|max:255',
            'currency' => 'required|string|max:10',
            'language' => 'required|string|max:10',
            'dark_mode' => 'boolean',
        ];
    }
}
