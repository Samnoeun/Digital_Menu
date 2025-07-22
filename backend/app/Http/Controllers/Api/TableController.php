<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Table\StoreTableRequest;
use App\Http\Requests\Table\UpdateTableRequest;
use Illuminate\Http\Request;
use App\Models\Table;
use App\Http\Resources\TableResource;

class TableController extends Controller
{
    // GET /api/tables
    public function index()
    {
        // Return a resource collection using TableResource
        return TableResource::collection(Table::all());
    }

    // POST /api/tables
    public function store(StoreTableRequest $request)
    {
        $validated = $request->validated();
        $table = Table::create($validated);
        // Return the newly created resource with a 201 status
        return (new TableResource($table))->response()->setStatusCode(201);
    }

    // GET /api/tables/{id}
    public function show(string $id)
    {
        $table = Table::findOrFail($id);
        return new TableResource($table);
    }

    // PUT/PATCH /api/tables/{id}
    public function update(UpdateTableRequest $request, string $id)
    {
        $table = Table::findOrFail($id);
        $validated = $request->validated();
        $table->update($validated);
        return new TableResource($table);
    }

    // DELETE /api/tables/{id}
    public function destroy(string $id)
    {
        $table = Table::findOrFail($id);
        $table->delete();
        return response()->json(['message' => 'Table deleted successfully.']);
    }
}
