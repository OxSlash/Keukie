import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaksi_service.dart';
import '../utils/rupiah_input_formatter.dart';

class TransaksiFormScreen extends StatefulWidget {
  final Map<String, dynamic>? transaksi;

  const TransaksiFormScreen({super.key, this.transaksi});

  @override
  State<TransaksiFormScreen> createState() => _TransaksiFormScreenState();
}

class _TransaksiFormScreenState extends State<TransaksiFormScreen> {
  final TransaksiService _service = TransaksiService();
  final _formKey = GlobalKey<FormState>();

  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();

  String _jenis = 'pemasukan';
  String _metode = 'tunai';
  DateTime _tanggal = DateUtils.dateOnly((DateTime.now()));
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.transaksi != null;

  static const bgColor = Color(0xFF0a0a0a);
  static const surfaceColor = Color(0xFF111111);
  static const surfaceLight = Color(0xFF1a1a1a);
  static const accentColor = Color(0xFF00ffcc);
  static const accentDark = Color(0xFF00b388);
  static const textPrimary = Color(0xFFffffff);
  static const textSecondary = Color(0xFFaaaaaa);

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _apiDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.transaksi!;
      _jenis = t['jenis'];
      _metode = t['metode'];
      _nominalController.text = RupiahInputFormatter.fromNumber(
        double.tryParse(t['nominal'].toString()) ?? 0,
      );
      _catatanController.text = t['catatan'] ?? '';
      _tanggal = DateUtils.dateOnly(
        DateTime.tryParse(t['tanggal']) ?? DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal.isAfter(today) ? today : _tanggal,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      errorFormatText: 'Format tanggal tidak valid',
      errorInvalidText: 'Tanggal tidak boleh lewat hari ini',
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
      setState(() => _tanggal = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggal.isAfter(DateUtils.dateOnly(DateTime.now()))) {
      setState(() => _error = 'Tanggal tidak boleh lewat hari ini');
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final nominal = RupiahInputFormatter.parse(
      _nominalController.text,
    )!.toDouble();
    final tanggalStr = _apiDateFormat.format(_tanggal);

    final result = _isEdit
        ? await _service.update(
            widget.transaksi!['id'],
            jenis: _jenis,
            nominal: nominal,
            metode: _metode,
            tanggal: tanggalStr,
            catatan: _catatanController.text.trim(),
          )
        : await _service.store(
            jenis: _jenis,
            nominal: nominal,
            metode: _metode,
            tanggal: tanggalStr,
            catatan: _catatanController.text.trim(),
          );

    if (!mounted) return;

    setState(() => _loading = false);

    if (result['statusCode'] == 200 || result['statusCode'] == 201) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = result['message'] ?? 'Gagal menyimpan transaksi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text(
          _isEdit ? 'Edit Transaksi' : 'Tambah Transaksi',
          style: const TextStyle(color: textPrimary),
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Jenis',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _jenisButton(
                        'pemasukan',
                        'Pemasukan',
                        accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _jenisButton(
                        'pengeluaran',
                        'Pengeluaran',
                        Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  style: const TextStyle(color: textPrimary),
                  decoration: _inputDecoration('Nominal').copyWith(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(color: textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                    final parsed = RupiahInputFormatter.parse(v);
                    if (parsed == null || parsed <= 0)
                      return 'Nominal tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Metode',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _metodeButton('tunai', 'Tunai')),
                    const SizedBox(width: 10),
                    Expanded(child: _metodeButton('digital', 'Digital')),
                  ],
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: _inputDecoration('Tanggal'),
                    child: Text(
                      _dateFormat.format(_tanggal),
                      style: const TextStyle(color: textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _catatanController,
                  maxLength: 100,
                  minLines: 1,
                  maxLines: 3,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(color: textPrimary),
                  decoration: _inputDecoration('Catatan (opsional)'),
                ),
                const SizedBox(height: 10),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Simpan Perubahan' : 'Tambah Transaksi',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _jenisButton(String value, String label, Color color) {
    final selected = _jenis == value;
    return OutlinedButton(
      onPressed: () => setState(() => _jenis = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? color.withOpacity(0.15) : surfaceLight,
        side: BorderSide(color: selected ? color : accentDark.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(color: selected ? color : textSecondary),
      ),
    );
  }

  Widget _metodeButton(String value, String label) {
    final selected = _metode == value;
    return OutlinedButton(
      onPressed: () => setState(() => _metode = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? accentColor.withOpacity(0.15)
            : surfaceLight,
        side: BorderSide(
          color: selected ? accentColor : accentDark.withOpacity(0.2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(color: selected ? accentColor : textSecondary),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accentDark.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accentDark.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColor),
      ),
    );
  }
}
