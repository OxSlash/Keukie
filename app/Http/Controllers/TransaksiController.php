<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class TransaksiController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'jenis' => 'required|in:pemasukan,pengeluaran',
            'nominal' => 'required|numeric|min:1|max:9999999999999',
            'metode' => 'required|in:tunai,digital',
            'tanggal' => 'required|date',
            'catatan' => 'nullable|string|max:100',
        ]);

        $transaksi = $request->user()->transaksi()->create([
            'jenis' => $request->jenis,
            'nominal' => $request->nominal,
            'metode' => $request->metode,
            'tanggal' => $request->tanggal,
            'catatan' => $request->catatan,
        ]);

        return response()->json([
            'message' => 'Transaksi berhasil ditambahkan',
            'transaksi' => $transaksi,
        ], 201);
    }

    public function index(Request $request)
    {
        $query = $request->user()->transaksi()->orderBy('tanggal', 'desc')->orderBy('id', 'desc');

        if ($request->filled('jenis')) {
            $query->where('jenis', $request->jenis);
        }

        if ($request->filled('metode')) {
            $query->where('metode', $request->metode);
        }

        if ($request->filled('dari')) {
            $query->where('tanggal', '>=', $request->dari);
        }

        if ($request->filled('sampai')) {
            $query->where('tanggal', '<=', $request->sampai);
        }

        if ($request->filled('cari')) {
            $query->where('catatan', 'like', '%' . $request->cari . '%');
        }

        $transaksi = $query->get();

        return response()->json($transaksi, 200);
    }

    public function show(Request $request, int $id)
    {
        $transaksi = $request->user()->transaksi()->find($id);

        if (!$transaksi) {
            return response()->json([
                'message' => 'Transaksi tidak ditemukan',
            ], 404);
        }

        return response()->json($transaksi, 200);
    }

    public function update(Request $request, int $id)
    {
        $transaksi = $request->user()->transaksi()->find($id);

        if (!$transaksi) {
            return response()->json([
                'message' => 'Transakasi tidak ditemukan',
            ], 404);
        }

        $request->validate([
            'jenis' => 'sometimes|in:pemasukan,pengeluaran',
            'nominal' => 'sometimes|numeric|min:1|max:9999999999999',
            'metode' => 'sometimes|in:tunai,digital',
            'tanggal' => 'sometimes|date',
            'catatan' => 'nullable|string|max:100',
        ]);

        $transaksi->update($request->only(['jenis', 'nominal', 'metode', 'tanggal', 'catatan']));

        return response()->json([
            'message' => 'Transaksi berhasil diperbarui',
            'transaksi' => $transaksi,
        ], 200);
    }

    public function destroy(Request $request, int $id)
    {
        $transaksi = $request->user()->transaksi()->find($id);

        if (!$transaksi) {
            return response()->json([
                'message' => 'Transaksi tidak ditemukan',
            ], 404);
        }

        $transaksi->delete();

        return response()->json([
            'message' => 'Transaksi berhasil dihapus',
        ], 200);
    }
}