<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use App\Http\Requests\Setting\StoreSettingRequest;
use App\Http\Requests\Setting\UpdateSettingRequest;
use App\Http\Resources\SettingResource;
use App\Models\Setting;
use Illuminate\Support\Facades\Log;



class SettingController extends Controller
{
    public function index()
    {
        return SettingResource::collection(Setting::with('user')->get());
    }

    public function store(StoreSettingRequest $request)
    {
        Log::info('Request data:', $request->all());

        $data = $request->validated();

        Log::info('Validated data:', $data);

        if (isset($data['dark_mode'])) {
            $data['dark_mode'] = filter_var($data['dark_mode'], FILTER_VALIDATE_BOOLEAN);
        }

        if ($request->hasFile('logo')) {
            $data['logo'] = $request->file('logo')->store('logos', 'public');
        }

        $setting = Setting::create($data);

        Log::info('Setting created:', $setting->toArray());

        return response()->json([
            'success' => true,
            'data' => new SettingResource($setting->load('user')),
            'message' => 'Setting created successfully',
        ], 201);
    }




    public function show(Setting $setting)
    {
        return new SettingResource($setting->load('user'));
    }

    public function update(UpdateSettingRequest $request, Setting $setting)
    {
        $data = $request->validated();

        // If a new logo file is uploaded
        if ($request->hasFile('logo')) {
            // Delete old logo if exists
            if ($setting->logo && Storage::exists('public/' . $setting->logo)) {
                Storage::delete('public/' . $setting->logo);
            }

            // Store new logo and update path in data
            $data['logo'] = $request->file('logo')->store('logos', 'public');
        }

        $setting->update($data);

        return new SettingResource($setting->fresh()->load('user'));
    }




    public function destroy(Setting $setting)
    {
        $setting->delete();
        return response()->json(['message' => 'Deleted successfully']);
    }
}
