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
            'restaurant_name' => 'required|string',
            'logo' => 'nullable|image|max:2048',
            'address' => 'required|string',
            'currency' => 'required|string',
            'language' => 'required|string',
            'dark_mode' => 'required', // Don't use boolean directly
        ];
    }
}
