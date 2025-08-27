<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ImageController extends Controller
{
    public function show($type, $filename)
    {
        // Clear any output buffers to prevent corruption
        while (ob_get_level() > 0) {
            ob_end_clean();
        }
        
        // Validate the type to prevent directory traversal
        $allowedTypes = ['items', 'profiles'];
        if (!in_array($type, $allowedTypes)) {
            abort(404);
        }
        
        // Clean the filename
        $filename = basename($filename);
        
        // Build the storage path - use the same path structure as the working URL
        $storagePath = "{$type}/{$filename}";
        
        // Check if file exists in public storage
        if (!Storage::disk('public')->exists($storagePath)) {
            abort(404, 'Image not found');
        }
        
        // Get the full path to the file
        $filePath = Storage::disk('public')->path($storagePath);
        
        // Check if file exists on filesystem
        if (!file_exists($filePath)) {
            abort(404, 'File not found on filesystem');
        }
        
        // Get MIME type
        $mimeType = mime_content_type($filePath);
        
        // Return the file using Laravel's response()->file()
        return response()->file($filePath, [
            'Content-Type' => $mimeType,
            'Content-Length' => filesize($filePath),
            'Cache-Control' => 'public, max-age=31536000', // 1 year
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET',
        ]);
    }
}