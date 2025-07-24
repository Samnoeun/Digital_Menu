<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
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

    // POST /api/settings
    public function store(StoreSettingRequest $request)
    {
        $data = $request->validated();
        $data['user_id'] = auth()->id(); // or manually set

        if ($request->hasFile('logo')) {
            $data['logo'] = $request->file('logo')->store('logos', 'public');
        }

        $setting = Setting::create($data);
        return new SettingResource($setting);
    }

    // GET /api/settings/{id}
    public function show(Setting $setting)
    {
        return new SettingResource($setting);
    }

    // PUT/PATCH /api/settings/{id}
    public function update(UpdateSettingRequest $request, Setting $setting)
    {
        $data = $request->validated();

        if ($request->hasFile('logo')) {
            $data['logo'] = $request->file('logo')->store('logos', 'public');
        }

        $setting->update($data);
        return new SettingResource($setting);
    }

    // DELETE /api/settings/{id}
    public function destroy(Setting $setting)
    {
        $setting->delete();
        return response()->json(['message' => 'Setting deleted successfully.']);
    }
}

