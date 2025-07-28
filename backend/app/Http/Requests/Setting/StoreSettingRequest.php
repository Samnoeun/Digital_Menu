<?php

namespace App\Http\Requests\Setting;

use App\Http\Resources\UserResource;
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
            'id' => $this->id,
            'user' => new UserResource($this->user),
            'restaurant_name' => $this->restaurant_name,
            'logo' => $this->logo ? url('storage/' . $this->logo) : null,
            'address' => $this->address,
            'currency' => $this->currency,
            'language' => $this->language,
            'dark_mode' => $this->dark_mode,
            'created_at' => $this->created_at,
        ];
    }
}
