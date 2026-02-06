<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PartitionController;

Route::get('/partitions', [PartitionController::class, 'index']);
Route::post('/partitions/{id}/favorite', [PartitionController::class, 'updateFavorite']);

