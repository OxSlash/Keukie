import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaksi_service.dart';
import 'transaksi_form_screen.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final TransaksiService _service = TransaksiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _transaksi = [];
  bool _loading = true;
  String? _error;

  String? _filterJenis;
  String? _filterMetode;
  DateTime? _filterDari;
  DateTime? _filterSampai;

  static const bgColor = Color(0xFF0a0a0a);
  static const surfaceColor = Color(0xFF111111);
  static const surfaceLight = Color(0xFF1a1a1a);
  static const accentColor = Color(0xFF00ffcc);
  static const accentDark = Color(0xFF00b388);
  static const textPrimary = Color(0xFFffffff);
  static const textSecondary = Color(0xFFaaaaaa);

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _apiDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaksi() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.getTransaksi(
      jenis: _filterJenis,
      metode: _filterMetode,
      dari: _filterDari != null ? _apiDateFormat.format(_filterDari!) : null,
      sampai: _filterSampai != null
          ? _apiDateFormat.format(_filterSampai!)
          : null,
      cari: _searchController.text.trim(),
    );

    setState(() {
      _loading = false;
      if (result['statusCode'] == 200) {
        _transaksi = result['data'];
      } else {
        _error = result['message'] ?? 'Gagal memuat transaksi';
      }
    });
  }

  Future<void> _pickDate({required bool isDari}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: accentColor,
            surface: surfaceColor,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isDari) {
          _filterDari = picked;
        } else {
          _filterSampai = picked;
        }
      });
      _loadTransaksi();
    }
  }

  void _clearFilters() {
    setState(() {
      _filterJenis = null;
      _filterMetode = null;
      _filterDari = null;
      _filterSampai = null;
      _searchController.clear();
    });
    _loadTransaksi();
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text(
          'Hapus Transaksi',
          style: TextStyle(color: textPrimary),
        ),
        content: const Text(
          'Yakin ingin menghapus transaksi ini?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _service.destroy(id);
      if (result['statusCode'] == 200) {
        _loadTransaksi();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menghapus transaksi'),
          ),
        );
      }
    }
  }

  Future<void> _openForm({Map<String, dynamic>? transaksi}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransaksiFormScreen(transaksi: transaksi),
      ),
    );

    if (result == true) {
      _loadTransaksi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: const Text('Transaksi', style: TextStyle(color: textPrimary)),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: textPrimary),
            onSubmitted: (_) => _loadTransaksi(),
            decoration: InputDecoration(
              hintText: 'Cari catatan transaksi...',
              hintStyle: const TextStyle(color: textSecondary),
              filled: true,
              fillColor: bgColor,
              prefixIcon: const Icon(Icons.search, color: textSecondary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: accentColor),
                onPressed: _loadTransaksi,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Semua Jenis', _filterJenis == null, () {
                  setState(() => _filterJenis = null);
                  _loadTransaksi();
                }),
                _filterChip('Pemasukan', _filterJenis == 'pemasukan', () {
                  setState(() => _filterJenis = 'pemasukan');
                  _loadTransaksi();
                }),
                _filterChip('Pengeluaran', _filterJenis == 'pengeluaran', () {
                  setState(() => _filterJenis = 'pengeluaran');
                  _loadTransaksi();
                }),
                const SizedBox(width: 8),
                _filterChip('Semua Metode', _filterMetode == null, () {
                  setState(() => _filterMetode = null);
                  _loadTransaksi();
                }),
                _filterChip('Tunai', _filterMetode == 'tunai', () {
                  setState(() => _filterMetode = 'tunai');
                  _loadTransaksi();
                }),
                _filterChip('Digital', _filterMetode == 'digital', () {
                  setState(() => _filterMetode = 'digital');
                  _loadTransaksi();
                }),
                const SizedBox(width: 8),
                ActionChip(
                  backgroundColor: surfaceLight,
                  label: Text(
                    _filterDari == null
                        ? 'Dari Tanggal'
                        : _dateFormat.format(_filterDari!),
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  onPressed: () => _pickDate(isDari: true),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  backgroundColor: surfaceLight,
                  label: Text(
                    _filterSampai == null
                        ? 'Sampai Tanggal'
                        : _dateFormat.format(_filterSampai!),
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  onPressed: () => _pickDate(isDari: false),
                ),
                const SizedBox(width: 6),
                if (_filterJenis != null ||
                    _filterMetode != null ||
                    _filterDari != null ||
                    _filterSampai != null ||
                    _searchController.text.isNotEmpty)
                  ActionChip(
                    backgroundColor: Colors.redAccent.withOpacity(0.15),
                    label: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                    onPressed: _clearFilters,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        selectedColor: accentColor,
        backgroundColor: surfaceLight,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      );
    }

    if (_transaksi.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada transaksi',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransaksi,
      color: accentColor,
      backgroundColor: surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _transaksi.length,
        itemBuilder: (context, index) {
          final item = _transaksi[index];
          final isPemasukan = item['jenis'] == 'pemasukan';
          final nominal = double.tryParse(item['nominal'].toString()) ?? 0;
          final tanggal = DateTime.tryParse(item['tanggal']) ?? DateTime.now();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentDark.withOpacity(0.2)),
            ),
            child: ListTile(
              onTap: () => _openForm(transaksi: item),
              leading: CircleAvatar(
                backgroundColor: isPemasukan
                    ? accentColor.withOpacity(0.15)
                    : Colors.redAccent.withOpacity(0.15),
                child: Icon(
                  isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isPemasukan ? accentColor : Colors.redAccent,
                  size: 18,
                ),
              ),
              title: Text(
                _currency.format(nominal),
                style: TextStyle(
                  color: isPemasukan ? accentColor : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${item['metode'] == 'tunai' ? 'Tunai' : 'Digital'} • ${_dateFormat.format(tanggal)}'
                '${item['catatan'] != null && item['catatan'].toString().isNotEmpty ? '\n${item['catatan']}' : ''}',
                style: const TextStyle(color: textSecondary, fontSize: 12),
              ),
              isThreeLine:
                  item['catatan'] != null &&
                  item['catatan'].toString().isNotEmpty,
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(item['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}