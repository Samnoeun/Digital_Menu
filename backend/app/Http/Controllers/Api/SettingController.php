<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Setting\StoreSettingRequest as SettingStoreSettingRequest;
use App\Http\Requests\Setting\UpdateSettingRequest as SettingUpdateSettingRequest;
use App\Http\Requests\StoreSettingRequest;
use App\Http\Requests\UpdateSettingRequest;
use App\Http\Resources\SettingResource;
use App\Models\Setting;

class SettingController extends Controller
{
    public function index()
    {
        return SettingResource::collection(Setting::all());
    }

    public function store(SettingStoreSettingRequest $request)
    {
        $setting = Setting::create($request->validated());
        return new SettingResource($setting);
    }

    public function show(string $id)
    {
        $setting = Setting::findOrFail($id);
        return new SettingResource($setting);
    }

    public function update(SettingUpdateSettingRequest $request, string $id)
    {
        $setting = Setting::findOrFail($id);
        $setting->update($request->validated());
        return new SettingResource($setting);
    }

    public function destroy(string $id)
    {
        $setting = Setting::findOrFail($id);
        $setting->delete();

        return response()->json(['message' => 'Setting deleted successfully.']);
    }
}
