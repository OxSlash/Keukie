import 'package:flutter/material.dart';
import '../services/profil_service.dart';

class SettingProfilModal extends StatefulWidget {
  const SettingProfilModal({super.key});

  @override
  State<SettingProfilModal> createState() => _SettingProfilModalState();
}

class _SettingProfilModalState extends State<SettingProfilModal> {
  final ProfilService _profilService = ProfilService();
  int _selectedIndex = 0;
  final _profilFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _profilLoading = false;
  String? _profilError;
  String? _profilSuccess;
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordLoading = false;
  String? _passwordError;
  String? _passwordSuccess;
  static const bgColor = Color(0xFF0a0a0a);
  static const surfaceColor = Color(0xFF111111);
  static const surfaceLight = Color(0xFF1a1a1a);
  static const accentColor = Color(0xFF00ffcc);
  static const accentDark = Color(0xFF00b388);
  static const textPrimary = Color(0xFFffffff);
  static const textSecondary = Color(0xFFaaaaaa);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitProfil() async {
    if (!_profilFormKey.currentState!.validate()) return;

    setState(() {
      _profilLoading = true;
      _profilError = null;
      _profilSuccess = null;
    });

    final result = await _profilService.updateProfil(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    setState(() {
      _profilLoading = false;
      if (result['statusCode'] == 200) {
        _profilSuccess = result['message'];
      } else {
        _profilError = result['message'] ?? 'Gagal memperbarui profil';
      }
    });
  }

  Future<void> _submitPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _profilLoading = true;
      _profilError = null;
      _profilSuccess = null;
    });

    final result = await _profilService.updatePassword(
      currentPassword: _currentPasswordController.text,
      password: _newPasswordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    setState(() {
      _passwordLoading = false;
      if (result['statusCode'] == 200) {
        _passwordSuccess = result['message'];
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _passwordError = result['message'] ?? 'Gagal mengubah password';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),

      child: Container(
        width: 560,
        height: 420,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentDark.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 160,
      decoration: const BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
      ),

      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Pengaturan',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(height: 12),
          _buildSidebarItem('Prodil', 0, Icons.person_outline),
          _buildSidebarItem('Ganti Password', 1, Icons.lock_outline),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: textSecondary, size: 18),
              label: const Text(
                'Tutup',
                style: TextStyle(color: textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String label, int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: accentColor.withOpacity(0.4))
              : null,
        ),

        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? accentColor : textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _selectedIndex == 0 ? _buildProfilForm() : _buildPasswordForm(),
    );
  }

  Widget _buildProfilForm() {
    return Form(
      key: _profilFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
            _buildTextFailed(
              controller: _nameController,
              label: 'Nama',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
            ),

            const SizedBox(height: 14),
            _buildTextFailed(
              controller: _emailController,
              label: 'Email',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Email tidak valid';
                return null;
              },
            ),

            const SizedBox(height: 18),
            if (_profilError != null)
              Text(
                _profilError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            if (_profilSuccess != null)
              Text(
                _profilSuccess!,
                style: const TextStyle(color: accentColor, fontSize: 12),
              ),

            const SizedBox(height: 10),
            _buildSubmitButton(
              label: 'Simpan Perubahan',
              loading: _profilLoading,
              onPressed: _submitProfil,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _passwordFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ganti Password',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
            _buildTextFailed(
              controller: _newPasswordController,
              label: 'Password Baru',
              obscure: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if (v.length < 8) return 'Minimal 8 karakter';
                return null;
              },
            ),

            const SizedBox(height: 14),
            _buildTextFailed(
              controller: _confirmPasswordController,
              label: 'Konfirmasi Password Baru',
              obscure: true,
              validator: (v) {
                if (v != _newPasswordController.text)
                  return 'Konfirmasi tidak cocok';
                return null;
              },
            ),

            const SizedBox(height: 18),
            if (_passwordError != null)
              Text(
                _passwordError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            if (_passwordSuccess != null)
              Text(
                _passwordSuccess!,
                style: const TextStyle(color: accentColor, fontSize: 12),
              ),

            const SizedBox(height: 10),
            _buildSubmitButton(
              label: 'Ubah Password',
              loading: _passwordLoading,
              onPressed: _submitPassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFailed({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
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
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}