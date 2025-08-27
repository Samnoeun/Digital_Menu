<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;

class ImageController extends Controller
{
    public function show($type, $filename)
    {
        // Validate the type to prevent directory traversal
        $allowedTypes = ['items', 'profiles'];
        if (!in_array($type, $allowedTypes)) {
            abort(404);
        }
        
        $path = "$type/$filename";
        
        // Check if file exists in storage
        if (!Storage::disk('public')->exists($path)) {
            // Also check if file exists in the old profiles directory
            if ($type === 'profiles' && Storage::disk('public')->exists("public/profiles/$filename")) {
                $path = "public/profiles/$filename";
            } else {
                abort(404);
            }
        }
        
        try {
            // Get the file and its MIME type
            $file = Storage::disk('public')->get($path);
            $mime = Storage::disk('public')->mimeType($path);
            
            // Return the image with proper headers
            return response($file, 200)
                ->header('Content-Type', $mime)
                ->header('Access-Control-Allow-Origin', '*')
                ->header('Access-Control-Allow-Methods', 'GET')
                ->header('Cache-Control', 'public, max-age=31536000');
                
        } catch (\Exception $e) {
            // Log the error and return 404
            \Log::error("Image loading failed: " . $e->getMessage());
            abort(404);
        }
    }
}