import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ScanCouponPage extends StatefulWidget {
  const ScanCouponPage({super.key});

  @override
  State<ScanCouponPage> createState() => _ScanCouponPageState();
}

class _ScanCouponPageState extends State<ScanCouponPage> {
  final _kodeCtrl = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _orderResult;
  String? _errorMessage;

  @override
  void dispose() {
    _kodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cariPesanan() async {
    final kode = _kodeCtrl.text.trim();
    if (kode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _orderResult = null;
      _errorMessage = null;
    });

    try {
      final data = await Supabase.instance.client
          .from('pemesanan')
          .select('''
            id_pesanan, status_pesanan, jumlah_pesan, total_harga, kode_qr,
            makanan:id_makanan(nama_makanan),
            account:id_pelanggan(nama_account)
          ''')
          .eq('kode_qr', kode)
          .maybeSingle();

      if (data == null) {
        setState(() => _errorMessage = 'Kode QR tidak ditemukan atau tidak valid.');
      } else {
        setState(() => _orderResult = data);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _konfirmasiPengambilan() async {
    if (_orderResult == null) return;
    final id = _orderResult!['id_pesanan'];

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('pemesanan')
          .update({'status_pesanan': 'Selesai'})
          .eq('id_pesanan', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan #$id berhasil dikonfirmasi sebagai SELESAI!',
                style: GoogleFonts.outfit()),
            backgroundColor: AppColors.primary,
          ),
        );
        setState(() {
          _orderResult = null;
          _kodeCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal konfirmasi: $e'), backgroundColor: Colors.red),
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
          // Header
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              height: MediaQuery.of(context).padding.top + 140,
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
                    'Scan & Validasi Kupon',
                    style: GoogleFonts.outfit(
                        fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(
                    'Masukkan kode QR dari pembeli untuk konfirmasi',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 150),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // QR Placeholder area
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'Kamera scan segera hadir',
                          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Manual input
                  Text(
                    'Atau masukkan kode secara manual:',
                    style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _kodeCtrl,
                          style: GoogleFonts.outfit(fontSize: 14, letterSpacing: 1),
                          decoration: InputDecoration(
                            hintText: 'Masukkan kode kupon...',
                            hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
                            prefixIcon: const Icon(Icons.key_outlined, color: AppColors.primary),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.divider)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.divider)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _cariPesanan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.search),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_errorMessage!, style: GoogleFonts.outfit(color: Colors.red))),
                        ],
                      ),
                    ),

                  // Result card
                  if (_orderResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Detail Pesanan',
                                  style: GoogleFonts.outfit(
                                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  _orderResult!['status_pesanan'] ?? '',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _infoRow('Pembeli', (_orderResult!['account']?['nama_account'] ?? '-')),
                          _infoRow('Makanan', (_orderResult!['makanan']?['nama_makanan'] ?? '-')),
                          _infoRow('Jumlah', '${_orderResult!['jumlah_pesan']} porsi'),
                          _infoRow('Total', 'Rp${_orderResult!['total_harga']}'),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _konfirmasiPengambilan,
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(
                                'Konfirmasi Pesanan Diambil',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
