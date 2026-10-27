import 'dart:async';
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
  Timer? _debounce;
  int _requestId = 0;

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
  static const double maxContentWidth = 900;

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
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaksi({bool silent = false}) async {
    final requestId = ++_requestId;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final result = await _service.getTransaksi(
      jenis: _filterJenis,
      metode: _filterMetode,
      dari: _filterDari != null ? _apiDateFormat.format(_filterDari!) : null,
      sampai: _filterSampai != null
          ? _apiDateFormat.format(_filterSampai!)
          : null,
      cari: _searchController.text.trim(),
    );

    if (!mounted || requestId != _requestId) return;

    setState(() {
      _loading = false;
      if (result['statusCode'] == 200) {
        _error = null;
        _transaksi = result['data'];
      } else {
        _error = result['message'] ?? 'Gagal memuat transaksi';
      }
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadTransaksi(silent: true);
    });
  }

  Future<void> _pickDate({required bool isDari}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = isDari ? DateTime(2020) : (_filterDari ?? DateTime(2020));
    final lastDate = isDari ? (_filterSampai ?? today) : today;
    final current = isDari ? _filterDari : _filterSampai;

    var initialDate = DateUtils.dateOnly(DateTime.now());
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;

    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      helpText: isDari ? 'Dari tanggal' : 'Sampai tanggal',
      cancelText: 'Batal',
      errorFormatText: 'Format tanggal tidak valid',
      errorInvalidText: 'Tanggak diluar rentang (maksimal hari ini)',
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
  }

  void _clearFilters() {
    _debounce?.cancel();
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

  bool get _hasActiveFilter =>
      _filterJenis != null ||
      _filterMetode != null ||
      _filterDari != null ||
      _filterSampai != null ||
      _searchController.text.isNotEmpty;

  Widget _buildSearchAndFilters() {
    return Container(
      width: double.infinity,
      color: surfaceColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: textPrimary),
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari catatan transaksi...',
                    hintStyle: const TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: bgColor,
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, color: textSecondary),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _segmentedFilter(
                      title: 'Jenis',
                      selected: _filterJenis,
                      options: const [
                        ('Semua', null),
                        ('Pemasukan', 'Pemasukan'),
                        ('Pengeluaran', 'Pengeluaran'),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterJenis = value?.toLowerCase();
                        });
                        _loadTransaksi();
                      },
                    ),
                    _dateChip(
                      label: 'Dari tanggal',
                      value: _filterDari,
                      onTap: () => _pickDate(isDari: true),
                      onClear: () {
                        setState(() => _filterDari = null);
                        _loadTransaksi();
                      },
                    ),
                    _dateChip(
                      label: 'Sampai Tanggal',
                      value: _filterSampai,
                      onTap: () => _pickDate(isDari: false),
                      onClear: () {
                        setState(() => _filterSampai = null);
                        _loadTransaksi();
                      },
                    ),
                    if (_hasActiveFilter)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(
                          Icons.restart_alt,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        label: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmentedFilter({
    required String title,
    required String? selected,
    required List<(String, String?)> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentDark.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: const TextStyle(color: textSecondary, fontSize: 11),
            ),
          ),
          for (final option in options)
            _segment(
              option.$1,
              option.$2 == selected,
              () => onChanged(option.$2),
            ),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? accentColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final active = value != null;
    return Material(
      color: surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: active
              ? accentColor.withOpacity(0.6)
              : accentDark.withOpacity(0.25),
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: active ? accentColor : textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                active ? _dateFormat.format(value!) : label,
                style: TextStyle(
                  color: active ? textPrimary : textSecondary,
                  fontSize: 12,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onClear,
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
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

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > maxContentWidth ? (width - maxContentWidth) / 2 + 12 : 12;
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
        padding: EdgeInsets.symmetric(
          horizontal: _horizontalPadding(context),
          vertical: 12,
        ),

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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: accentColor,
                      size: 20,
                    ),
                    onPressed: () => _openForm(transaksi: item),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Hapus',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(item['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}