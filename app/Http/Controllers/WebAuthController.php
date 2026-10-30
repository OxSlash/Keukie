<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
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

        return Socialite::driver('google')->redirect();
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
            if(!$user->hasVerifiedEmail()){
                $user->forceFill(['password'=>Str::random(40)])->save();
                $user->token()->delete();
            }

            if(!$user->google_id){
                $user->google_id=$googleUser->getId();
                $user->save();
            }
        } else {
            $user = User::create([
                'name' => $googleUser->getName() ?: Str::before($email, '@'),
                'email' => $email,
                'google_id' => $googleUser->getId(),
                'password' => Str::random(40),
            ]);
        }

        if (!$user->hasVerifiedEmail()) {
            $user->markEmailAsVerified();
        }

        return $this->finishLogin($user, $challenge);
    }

    public function emailLinkRequest(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|string|email|max:255',
            'challenge' => ['required', 'regex:/^[A-Za-z0-9_-]{43}$/'],
        ]);

        $email = Str::lower($data['email']);
        $token = Str::random(64);

        DB::table('login_tokens')->where('email', $email)->delete();
        DB::table('login_tokens')->insert([
            'email' => $email,
            'token_hash' => hash('sha256', $token),
            'challenge' => $data['challenge'],
            'expires_at' => now()->addMinutes(15),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $url = rtrim(config('app.url'), '/') . '/auth/email/verify?token=' . $token;

        $html = '<p>Halo,</p>'
            . '<p>Klik tombol di bawah untuk masuk ke Keukie. Link berlaku 15 menit dan hanya bisa dipakai sekali.</p>'
            . '<p><a href="' . e($url) . '" style="background:#00ffcc;color:#000;padding:12px 20px;border-radius:8px;text-decoration:none;font-weight:bold">Masuk ke Keukie</a></p>'
            . '<p>Jika bukan Anda yang meminta, abaikan email ini.</p>';

        Mail::html($html, function ($message) use ($email) {
            $message->to($email)->subject('Link masuk Keukie');
        });

        return response()->json([
            'message' => 'Jika email valid, link masuk telah dikirim',
        ], 200);
    }

    public function emailLinkVerify(Request $request)
    {
        $token = (string) $request->query('token');

        if (!$this->findValidToken($token)) {
            return $this->errorPage('Link tidak valid atau sudah kedaluwarsa.');
        }

        $form = '<form method="POST" action="/auth/email/confirm">'
            . '<input type="hidden" name="_token" value="' . csrf_token() . '">'
            . '<input type="hidden" name="token" value="' . e($token) . '">'
            . '<button type="submit">Lanjutkan masuk</button></form>';

        return $this->page('Konfirmasi masuk', 'Klik tombol di bawah untuk masuk ke aplikasi Keukie.', $form);
    }

    public function emailLinkConfirm(Request $request)
    {
        $row = $this->findValidToken((string) $request->input('token'));

        if (!$row) {
            return $this->errorPage('Link tidak valid atau sudah kedaluwarsa.');
        }

        $used = DB::table('login_tokens')
            ->where('id', $row->id)
            ->whereNull('used_at')
            ->update(['used_at' => now()]);

        if (!$used) {
            return $this->errorPage('Link sudah dipakai.');
        }

        $user = User::where('email', $row->email)->first()
            ?? User::create([
                'name' => Str::before($row->email, '@'),
                'email' => $row->email,
                'password' => Str::random(40),
            ]);

        if (!$user->hasVerifiedEmail()) {
            $user->markEmailAsVerified();
        }

        return $this->finishLogin($user, $row->challenge);
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

    private function findValidToken(string $token)
    {
        if ($token === '') {
            return null;
        }

        return DB::table('login_tokens')
            ->where('token_hash', hash('sha256', $token))
            ->whereNull('used_at')
            ->where('expires_at', '>', now())
            ->first();
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