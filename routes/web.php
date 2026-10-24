<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\WebAuthController;

Route::get('/', function () {
    return view('welcome');
});
Route::get('/auth/google/redirect', [WebAuthController::class, 'googleRedirect']);
Route::get('/auth/google/callback', [WebAuthController::class, 'googleCallback']);
Route::get('/auth/email/verify', [WebAuthController::class, 'emailLinkVerify'])->middleware('throttle:20,1');
Route::post('/auth/email/confirm', [WebAuthController::class, 'emailLinkConfirm'])->middleware('throttle:10,1');