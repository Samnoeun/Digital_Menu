<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\RestaurantController;
use App\Http\Controllers\Api\OrderController;

Route::get('/', function () {
    return view('welcome');
});

// Public route for web menu preview
Route::get('/restaurants/{id}/menu', [RestaurantController::class, 'webMenuPreview'])->name('web.menu');

// Cart page route
Route::get('/restaurants/{id}/cart', [OrderController::class, 'webCart'])->name('web.cart');

// Routes for table number input and order confirmation
Route::get('/restaurants/{id}/table-number', [OrderController::class, 'webTableNumber'])->name('web.table-number');
Route::post('/restaurants/{id}/submit-order', [OrderController::class, 'webSubmitOrder'])->name('web.submit-order');
Route::get('/restaurants/{id}/order-confirmation', [OrderController::class, 'webOrderConfirmation'])->name('web.order-confirmation');
Route::get('/restaurants/{id}/check-table', [OrderController::class, 'webCheckTable'])->name('web.check-table');
Route::get('/images/{type}/{filename}', [App\Http\Controllers\Api\ImageController::class, 'show'])->name('image.show');