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

    public function rules(): array
    {
        return [
            'logo' => 'nullable|image|mimes:jpg,jpeg,png',
            'dark_mode' => 'nullable|boolean',
        ];
    }
}
