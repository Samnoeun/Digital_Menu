<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ItemController;
<<<<<<< HEAD
use App\Http\Controllers\Api\TableController;
=======

// 🔓 Public Authentication Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'forgot']);
Route::post('/reset-password', [AuthController::class, 'reset']);
>>>>>>> 49d90a14523b0308b549747f4946b738fcf6241b

// 🔐 Protected Routes (need Bearer token)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', function (Request $request) {
        return $request->user();
    });

    // API Resources protected by token (optional: move these outside if you want them public)
    Route::apiResource('categories', CategoryController::class);
    Route::apiResource('items', ItemController::class);
});
<<<<<<< HEAD

Route::apiResource('categories', CategoryController::class);
Route::apiResource('items', ItemController::class);
Route::apiResource('tables', TableController::class);
=======
>>>>>>> 49d90a14523b0308b549747f4946b738fcf6241b
