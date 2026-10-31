<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $totalPemasukan = $request->user()->transaksi()->where('jenis', 'pemasukan')->sum('nominal');

        $totalPengeluaran = $request->user()->transaksi()->where('jenis', 'pengeluaran')->sum('nominal');

        $saldoTunai = $request->user()->transaksi()->where('metode', 'tunai')->where('jenis', 'pemasukan')->sum('nominal') - $request->user()->transaksi()->where('metode', 'tunai')->where('jenis', 'pengeluaran')->sum('nominal');

        $saldoDigital = $request->user()->transaksi()->where('metode', 'digital')->where('jenis', 'pemasukan')->sum('nominal') - $request->user()->transaksi()->where('metode', 'digital')->where('jenis', 'pengeluaran')->sum('nominal');

        $totalSaldo = $totalPemasukan - $totalPengeluaran;

        $riwayatTerbaru = $request->user()->transaksi()->orderBy('tanggal', 'desc')->orderBy('id', 'desc')->limit(5)->get();

        return response()->json([
            'totalSaldo' => $totalSaldo,
            'saldoTunai' => $saldoTunai,
            'saldoDigital' => $saldoDigital,
            'totalPemasukan' => $totalPemasukan,
            'totalPengeluaran' => $totalPengeluaran,
            'riwayatTerbaru' => $riwayatTerbaru,
        ]);
    }
}