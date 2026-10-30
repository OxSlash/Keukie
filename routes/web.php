<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\WebAuthController;

Route::get('/', function () {
    return view('welcome');
});
Route::get('/auth/google/redirect', [WebAuthController::class, 'googleRedirect']);
Route::get('/auth/google/callback', [WebAuthController::class, 'googleCallback']);