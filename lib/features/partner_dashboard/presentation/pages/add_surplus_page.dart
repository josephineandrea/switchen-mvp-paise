import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class AddSurplusPage extends StatefulWidget {
  const AddSurplusPage({super.key});

  @override
  State<AddSurplusPage> createState() => _AddSurplusPageState();
}

class _AddSurplusPageState extends State<AddSurplusPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  
  int? _selectedKategoriId;
  List<Map<String, dynamic>> _kategoriList = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('kategori').select();
      setState(() => _kategoriList = List<Map<String, dynamic>>.from(data));
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori makanan'), backgroundColor: Colors.orange),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;

      // Cari id_dapur milik partner yang login
      final dapurData = await client
          .from('dapur')
          .select('id_dapur')
          .eq('id_pelanggan', int.parse(authState.user.id))
          .maybeSingle();

      if (dapurData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Toko belum terdaftar. Daftar dulu ya!',
                style: GoogleFonts.outfit(),
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Daftar',
                onPressed: () => context.push(AppRoutes.partnerOnboarding),
              ),
            ),
          );
        }
        return;
      }

      final now = DateTime.now();
      await client.from('makanan').insert({
        'nama_makanan': _nameCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'harga_asli': int.parse(_priceCtrl.text.replaceAll('.', '')),
        'harga_diskon': int.parse(_discountCtrl.text.replaceAll('.', '')),
        'stok': int.parse(_stockCtrl.text),
        'id_dapur': dapurData['id_dapur'],
        'id_kategori': _selectedKategoriId,
        'expired_at': now.add(const Duration(hours: 6)).toIso8601String(),
        'waktu_ambil': now.add(const Duration(hours: 1)).toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Makanan surplus berhasil ditambahkan!', style: GoogleFonts.outfit()),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                    'Tambah Stok Surplus',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Masukkan makanan yang siap dijual hari ini',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 150),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                            controller: _nameCtrl,
                            label: 'Nama Makanan',
                            hint: 'Contoh: Nasi Goreng Spesial',
                            icon: Icons.fastfood_outlined,
                            validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildField(
                            controller: _descCtrl,
                            label: 'Deskripsi',
                            hint: 'Jelaskan bahan dan kondisi makanan...',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Kategori Dropdown
                          Text('Kategori',
                              style: GoogleFonts.outfit(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedKategoriId,
                            hint: Text('Pilih kategori', style: GoogleFonts.outfit(color: AppColors.textHint)),
                            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
                            items: _kategoriList.map((k) {
                              return DropdownMenuItem<int>(
                                value: k['id_kategori'] as int,
                                child: Text(k['nama_kategori'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedKategoriId = v),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  controller: _priceCtrl,
                                  label: 'Harga Asli (Rp)',
                                  hint: '50000',
                                  icon: Icons.price_change_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  controller: _discountCtrl,
                                  label: 'Harga Diskon (Rp)',
                                  hint: '20000',
                                  icon: Icons.sell_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildField(
                            controller: _stockCtrl,
                            label: 'Jumlah Stok',
                            hint: '10',
                            icon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _submit,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.add_circle_outline),
                              label: Text(
                                _isSaving ? 'Menyimpan...' : 'Tambahkan Makanan',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
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
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}
