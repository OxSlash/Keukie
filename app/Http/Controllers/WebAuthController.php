<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Laravel\Socialite\Facades\Socialite;

class WebAuthController extends Controller
{
    public function googleRedirect(Request $request)
    {
        $challenge = (string) $request->query('challenge');

        if (!preg_match('/^[A-Za-z0-9_-]{43}$/', $challenge)) {
            return $this->errorPage('Permintaan login tidak valid.');
        }

        $request->session()->put('auth_challenge', $challenge);

        /** @var \Laravel\Socialite\Two\GoogleProvider */
        $driver=Socialite::driver('google');
        
        return $driver->with(['prompt'=>'select_account'])->redirect();
    }

    public function googleCallback(Request $request)
    {
        $challenge = $request->session()->pull('auth_challenge');

        if (!$challenge) {
            return $this->errorPage('Sesi login berakhir, silakan ulangi dari aplikasi.');
        }

        try {
            $googleUser = Socialite::driver('google')->user();
        } catch (\Throwable $e) {
            return $this->errorPage('Login Google gagal, silakan coba lagi.');
        }

        $email = $googleUser->getEmail();
        $verified = filter_var($googleUser->user['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);

        if (!$email || !$verified) {
            return $this->errorPage('Email Google belum terverifikasi.');
        }

        $user = User::where('google_id', $googleUser->getId())->first()
            ?? User::where('email', $email)->first();

        if ($user) {
            if (!$user->hasVerifiedEmail()) {
                $user->forceFill([
                    'password' => Str::random(40),
                    'password_diatur' => false,
                ])->save();
                $user->tokens()->delete();
            }

            if (!$user->google_id) {
                $user->google_id = $googleUser->getId();
                $user->save();
            }
        } else {
            $user = User::create([
                'name' => $googleUser->getName() ?: Str::before($email, '@'),
                'email' => $email,
                'google_id' => $googleUser->getId(),
                'password' => Str::random(40),
                'password_diatur' => false,
            ]);
        }

        if (!$user->hasVerifiedEmail()) {
            $user->markEmailAsVerified();
        }

        return $this->finishLogin($user, $challenge);
    }

    public function exchange(Request $request)
    {
        $data = $request->validate([
            'code' => 'required|string',
            'verifier' => 'required|string|min:43|max:128',
        ]);

        $payload = Cache::pull('auth_code:' . $data['code']);

        if (!$payload) {
            return response()->json(['message' => 'Kode login tidak valid atau kedaluwarsa'], 401);
        }

        $expected = rtrim(strtr(base64_encode(hash('sha256', $data['verifier'], true)), '+/', '-_'), '=');

        if (!hash_equals($payload['challenge'], $expected)) {
            return response()->json(['message' => 'Verifikasi login gagal'], 401);
        }

        $user = User::findOrFail($payload['user_id']);

        return response()->json([
            'message' => 'Login berhasil',
            'token' => $user->createToken('keukie')->plainTextToken,
        ], 200);
    }

    private function finishLogin(User $user, string $challenge)
    {
        $code = Str::random(48);

        Cache::put('auth_code:' . $code, [
            'user_id' => $user->id,
            'challenge' => $challenge,
        ], now()->addMinutes(2));

        $deepLink = config('services.keukie.deeplink') . '?code=' . $code;

        return $this->page(
            'Berhasil masuk',
            'Membuka aplikasi Keukie...',
            '<a class="btn" href="' . e($deepLink) . '">Buka Keukie</a>',
            $deepLink
        );
    }

    private function errorPage(string $message)
    {
        return $this->page('Gagal masuk', $message);
    }

    private function page(string $title, string $message, string $body = '', ?string $redirect = null)
    {
        $script = $redirect
            ? '<script>window.location.href=' . json_encode($redirect) . ';</script>'
            : '';

        $html = '<!doctype html><html lang="id"><head><meta charset="utf-8">'
            . '<meta name="viewport" content="width=device-width,initial-scale=1">'
            . '<title>' . e($title) . '</title><style>'
            . 'body{background:#0a0a0a;color:#fff;font-family:sans-serif;display:flex;min-height:100vh;align-items:center;justify-content:center;margin:0}'
            . '.card{background:#111;border:1px solid #00b38855;border-radius:16px;padding:32px;max-width:380px;text-align:center}'
            . 'h1{color:#00ffcc;font-size:22px}p{color:#aaa}'
            . 'button,.btn{display:inline-block;background:#00ffcc;color:#000;border:0;border-radius:10px;padding:12px 20px;font-weight:700;text-decoration:none;cursor:pointer;font-size:15px}'
            . '</style></head><body><div class="card"><h1>' . e($title) . '</h1><p>' . e($message) . '</p>'
            . $body . '</div>' . $script . '</body></html>';

        return response($html);
    }
}