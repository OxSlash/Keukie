import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'setting_profil_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();

  bool _isLoading = true;
  String? _errorMessage;

  double _totalSaldo = 0;
  double _saldoTunai = 0;
  double _saldoDigital = 0;
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  List<dynamic> _riwayatTerbaru = [];

  static const Color bgColor = Color(0xFF0A0A0A);
  static const Color cardColor = Color(0xFF111111);
  static const Color accentColor = Color(0xFF00FFCC);
  static const Color secondaryColor = Color(0xFF00B388);
  static const Color textSecondary = Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _dashboardService.getDashboard();

      if (result['statusCode'] == 200) {
        setState(() {
          _totalSaldo = double.tryParse(result['totalSaldo'].toString()) ?? 0;
          _saldoTunai = double.tryParse(result['saldoTunai'].toString()) ?? 0;
          _saldoDigital =
              double.tryParse(result['saldoDigital'].toString()) ?? 0;
          _totalPemasukan =
              double.tryParse(result['totalPemasukan'].toString()) ?? 0;
          _totalPengeluaran =
              double.tryParse(result['totalPengeluaran'].toString()) ?? 0;
          _riwayatTerbaru = result['riwayatTerbaru'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi Kesalahan';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openSettingProfil() {
    showDialog(
      context: context,
      builder: (context) => const SettingProfilModal(),
    );
  }

  String _formatRupiah(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: accentColor),
            onPressed: _loadDashboard,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: accentColor),
            color: cardColor,
            onSelected: (value) {
              if (value == 'setting_profil') {
                _openSettingProfil();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'setting_profil',
                child: Text(
                  'Setting Profil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSaldoCard(),
                  const SizedBox(height: 16),
                  _buildRingkasanRow(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Pemasukan vs Pengeluaran'),
                  const SizedBox(height: 12),
                  _buildBarChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Saldo Tunai vs Digital'),
                  const SizedBox(height: 12),
                  _buildPieChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Riwayat Terbaru'),
                  const SizedBox(height: 12),
                  _buildRiwayatList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSaldoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saldo',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _formatRupiah(_totalSaldo),
            style: const TextStyle(
              color: accentColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanRow() {
    return Row(
      children: [
        Expanded(child: _buildMiniCard('Tunai', _saldoTunai)),
        const SizedBox(width: 12),
        Expanded(child: _buildMiniCard('Digital', _saldoDigital)),
      ],
    );
  }

  Widget _buildMiniCard(String label, double value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: secondaryColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiah(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxY = [
      _totalPemasukan,
      _totalPengeluaran,
    ].reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxY == 0 ? 1.0 : maxY * 1.2;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: safeMaxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final label = value == 0 ? 'Pemasukan' : 'Pengeluaran';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: _totalPemasukan,
                  color: accentColor,
                  width: 40,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: _totalPengeluaran,
                  color: secondaryColor,
                  width: 40,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final total = _saldoTunai.abs() + _saldoDigital.abs();
    final tunaiPercent = total == 0 ? 0.0 : (_saldoTunai.abs() / total) * 100;
    final digitalPercent = total == 0
        ? 0.0
        : (_saldoDigital.abs() / total) * 100;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: tunaiPercent == 0 ? 1 : tunaiPercent,
                    color: accentColor,
                    title: '${tunaiPercent.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: digitalPercent == 0 ? 1 : digitalPercent,
                    color: secondaryColor,
                    title: '${digitalPercent.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(accentColor, 'Tunai'),
              const SizedBox(height: 8),
              _buildLegendItem(secondaryColor, 'Digital'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildRiwayatList() {
    if (_riwayatTerbaru.isEmpty) {
      return const Text(
        'Belum ada transaksi',
        style: TextStyle(color: textSecondary),
      );
    }

    return Column(
      children: _riwayatTerbaru.map((item) {
        final isPemasukan = item['jenis'] == 'pemasukan';
        final nominal = double.tryParse(item['nominal'].toString()) ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                color: isPemasukan ? accentColor : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['catatan'] ??
                          (isPemasukan ? 'Pemasukan' : 'Pengeluaran'),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      '${item['metode']}-${item['tanggal']}',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isPemasukan ? '+' : '-'} ${_formatRupiah(nominal)}',
                style: TextStyle(
                  color: isPemasukan ? accentColor : Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
