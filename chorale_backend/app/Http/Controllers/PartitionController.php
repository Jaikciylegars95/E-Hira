<?php

namespace App\Http\Controllers;

use App\Models\Partition;
use Illuminate\Http\Request;

class PartitionController extends Controller
{
    public function index()
    {
        return response()->json(Partition::all());
    }

    // ⭐ NOUVEAU : mise à jour favori
    public function updateFavorite(Request $request, $id)
    {
        $partition = Partition::findOrFail($id);
        $partition->is_favorite = $request->is_favorite;
        $partition->save();

        return response()->json(['success' => true]);
    }
}
