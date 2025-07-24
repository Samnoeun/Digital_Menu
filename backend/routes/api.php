<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ItemController;
use App\Http\Controllers\Api\TableController;
use App\Http\Controllers\Api\SettingController;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::apiResource('categories', CategoryController::class);
Route::apiResource('items', ItemController::class);
Route::apiResource('tables', TableController::class);
Route::apiResource('settings', SettingController::class);
