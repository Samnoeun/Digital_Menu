<?php

namespace App\Http\Requests\Setting;

use Illuminate\Foundation\Http\FormRequest;

class UpdateSettingRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return  true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'restaurant_name' => 'sometimes|required|string',
            'logo' => 'nullable|image|max:2048',
            'address' => 'sometimes|required|string',
            'currency' => 'sometimes|required|string',
            'language' => 'sometimes|required|string',
            'dark_mode' => 'boolean',
        ];
    }
}
