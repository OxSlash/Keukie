<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ProfilController extends Controller
{
    public function update(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'name' => 'required|string|max:225',
            'email' => 'required|string|email|unique:users,email' . $user->id,
        ]);

        $emailBerubah = $request->email !== $user->email;
        $user->name = $request->name;
        $user->email = $request->email;

        if ($emailBerubah) {
            $user->email_verified_at = null;
        }

        $user->save();

        if ($emailBerubah) {
            $user->sendEmailVerificationNotification();
        }

        return response()->json([
            'message' => $emailBerubah
                ? 'Profil berhasil diperbarui, silahkan verifikasi email baru anda'
                : 'Profil berhasil diperbarui',
            'user' => $user,
        ], 200);
    }

    public function updatePassword(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Password lama salah',
            ], 401);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'message' => 'Password berhasil diubah',
        ], 200);
    }
}