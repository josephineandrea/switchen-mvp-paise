import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class PartnerOnboardingPage extends StatefulWidget {
  const PartnerOnboardingPage({super.key});

  @override
  State<PartnerOnboardingPage> createState() => _PartnerOnboardingPageState();
}

class _PartnerOnboardingPageState extends State<PartnerOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;

      // Cari id_pelanggan dari tabel account berdasarkan email
      final accountData = await client
          .from('account')
          .select('id_pelanggan')
          .eq('email', authState.user.email)
          .maybeSingle();

      if (accountData == null) {
        throw Exception('Akun tidak ditemukan di database.');
      }

      final idPelanggan = accountData['id_pelanggan'];

      // Cek apakah sudah pernah mengajukan permintaan
      final existing = await client
          .from('permintaan_mitra')
          .select('id_permintaan, status')
          .eq('id_pelanggan', idPelanggan)
          .maybeSingle();

      if (existing != null) {
        final status = existing['status'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'pending'
                    ? 'Permintaanmu sedang menunggu review admin.'
                    : status == 'disetujui'
                        ? 'Tokomu sudah aktif!'
                        : 'Permintaan sebelumnya ditolak. Hubungi admin.',
                style: GoogleFonts.outfit(),
              ),
              backgroundColor: status == 'disetujui' ? AppColors.primary : Colors.orange,
            ),
          );
        }
        return;
      }

      // Simpan ke tabel permintaan_mitra (menunggu persetujuan admin)
      await client.from('permintaan_mitra').insert({
        'id_pelanggan': idPelanggan,
        'nama_dapur': _nameCtrl.text.trim(),
        'telp_dapur': _phoneCtrl.text.trim(),
        'alamat_dapur': _addressCtrl.text.trim(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Permintaan terkirim! Admin akan meninjau tokomu segera.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go(AppRoutes.partnerDashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Green Header
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              height: MediaQuery.of(context).padding.top + 160,
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daftarkan Mitra F&B',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Isi form berikut untuk bergabung bersama Switchen',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form Content
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 170),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront, color: AppColors.primary, size: 36),
                    ),
                    const SizedBox(height: 28),

                    _buildField(
                      controller: _nameCtrl,
                      label: 'Nama Restoran / Toko',
                      hint: 'Contoh: Warung Sehat Bu Sari',
                      icon: Icons.storefront_outlined,
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Nomor Telepon Toko',
                      hint: '08xxxxxxxxxx',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.length < 9 ? 'Nomor tidak valid' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      controller: _addressCtrl,
                      label: 'Alamat Lengkap Toko',
                      hint: 'Jl. Contoh No. 1, Kelurahan, Kota',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
                    ),
                    const SizedBox(height: 32),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Data tokomu akan ditinjau oleh tim Switchen sebelum diaktifkan.',
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF795548)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Daftarkan Toko Saya',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
