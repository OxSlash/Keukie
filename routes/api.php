<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\TransaksiController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProfilController;
use App\Http\Controllers\WebAuthController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:register');

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:login');

Route::post('/auth/exchange', [WebAuthController::class, 'exchange'])->middleware('throttle:10,1');

Route::get('/email/verify/{id}/{hash}', [AuthController::class, 'verifyEmail'])->middleware('signed','throttle:6,1')->name('verification.verify');

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::post('/email/resend', [AuthController::class, 'resendVerification'])->middleware('throttle:3,1');

    Route::get('/transaksi', [TransaksiController::class, 'index']);
    Route::post('/transaksi', [TransaksiController::class, 'store']);
    Route::get('/transaksi/{id}', [TransaksiController::class, 'show']);
    Route::put('/transaksi/{id}', [TransaksiController::class, 'update']);
    Route::delete('/transaksi/{id}', [TransaksiController::class, 'destroy']);

    Route::get('/dashboard', [DashboardController::class, 'index']);

    Route::put('/profil', [ProfilController::class, 'update']);
    Route::put('/profil/password', [ProfilController::class, 'updatePassword']);
});