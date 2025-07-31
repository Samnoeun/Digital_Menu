<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;



class SettingController extends Controller
{
    public function index()
    {
        return Setting::with('restaurant')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'restaurant_id' => 'required|exists:restaurants,id',
            'dark_mode' => 'required|boolean',
        ]);

        $setting = Setting::create($data);

        return response()->json(['data' => $setting], 201);
    }

    public function show(Setting $setting)
    {
        return $setting->load('restaurant');
    }

    public function update(Request $request, Setting $setting)
    {
        $data = $request->validate([
            'dark_mode' => 'sometimes|boolean',
        ]);

        $setting->update($data);

        return response()->json(['data' => $setting]);
    }

    public function destroy(Setting $setting)
    {
        $setting->delete();
        return response()->json(['message' => 'Deleted successfully']);
    }
}
