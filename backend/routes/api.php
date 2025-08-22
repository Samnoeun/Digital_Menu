<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
// use App\Http\Controllers\Api\ReportController
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ItemController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\OrderItemController;
use App\Http\Controllers\Api\TableController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\RestaurantController;
use App\Http\Controllers\Api\OrderHistoryController;
use App\Models\OrderHistory;

// 🔓 Public Routes (No authentication needed)
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'forgot']);
Route::post('/reset-password', [AuthController::class, 'reset']);
// New public route for menu preview
Route::get('/restaurants/{id}/menu-preview', [RestaurantController::class, 'menuPreview']);

// Public routes for menu preview and order items
Route::get('/restaurants/{restaurant}/preview', [RestaurantController::class, 'preview']); // Public menu preview
Route::get('/order-items', [OrderItemController::class, 'index']); // View all order items
Route::post('/order-items', [OrderItemController::class, 'store']); // Create order item


// 🔐 Protected Routes (Require authentication via Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', function (Request $request) {
        return $request->user();
    });

    // Restaurant routes
    Route::apiResource('restaurants', RestaurantController::class)->except(['show']);
    Route::get('/restaurants/user/{id}', [RestaurantController::class, 'getByUserId']);

    // Category routes
    Route::apiResource('categories', CategoryController::class);
    
    // Item routes
    Route::apiResource('items', ItemController::class);
    
    // Table routes
    Route::apiResource('tables', TableController::class);
    
    // Order routes
    Route::apiResource('orders', OrderController::class);
    Route::put('/orders/{order}/status', [OrderController::class, 'updateStatus']);
    
    // Order item routes (remaining methods still protected)
    Route::apiResource('order-items', OrderItemController::class)->except(['index', 'store']);
    
    // User routes
    Route::apiResource('users', UserController::class);
    // Route::get('/reports/sales-summary', [ReportController::class, 'salesSummary']);
    //     // Order history routes
    // routes/api.php
    Route::get('/order-history', [OrderHistoryController::class, 'index']);

    
});