import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
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
  final _estimasiStokCtrl = TextEditingController();

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
    _estimasiStokCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('kategori').select();
      setState(() => _kategoriList = List<Map<String, dynamic>>.from(data));
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih kategori makanan terlebih dahulu', style: GoogleFonts.outfit()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final hargaAsli = int.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0;
    final hargaDiskon = int.tryParse(_discountCtrl.text.replaceAll('.', '')) ?? 0;
    if (hargaDiskon >= hargaAsli) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harga surplus harus lebih kecil dari harga normal', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;

      final accountData = await client
          .from('account')
          .select('id_pelanggan')
          .eq('email', authState.user.email)
          .maybeSingle();
      if (accountData == null) throw Exception('Akun tidak ditemukan.');

      final dapurData = await client
          .from('dapur')
          .select('id_dapur')
          .eq('id_pelanggan', accountData['id_pelanggan'])
          .maybeSingle();

      if (dapurData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Toko belum aktif. Tunggu persetujuan admin.', style: GoogleFonts.outfit()),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Embed estimasi stok ke dalam deskripsi sebagai info ke admin
      final deskripsiLengkap =
          '${_descCtrl.text.trim()}\n\n[Estimasi stok harian: ${_estimasiStokCtrl.text.trim()} porsi]';

      await client.from('permintaan_makanan').insert({
        'id_dapur': dapurData['id_dapur'],
        'nama_makanan': _nameCtrl.text.trim(),
        'deskripsi': deskripsiLengkap,
        'harga_asli': hargaAsli,
        'harga_diskon': hargaDiskon,
        'id_kategori': _selectedKategoriId,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Permintaan menu terkirim! Admin akan meninjau menumu.', style: GoogleFonts.outfit()),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
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
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              height: MediaQuery.of(context).padding.top + 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
                  Text('Ajukan Menu Baru',
                      style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Menu direview admin sebelum tayang di aplikasi',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 150),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFD54F)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Menu yang kamu ajukan akan ditinjau admin sebelum ditampilkan ke pembeli.',
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF795548)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

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
                            label: 'Deskripsi Makanan',
                            hint: 'Jelaskan bahan, rasa, dan kondisi makanan...',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Kategori
                          Text('Kategori Makanan',
                              style: GoogleFonts.outfit(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedKategoriId,
                            hint: Text('Pilih kategori', style: GoogleFonts.outfit(color: AppColors.textHint)),
                            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
                            items: _kategoriList.isEmpty
                                ? [
                                    DropdownMenuItem<int>(
                                      value: -1,
                                      child: Text('Belum ada kategori',
                                          style: GoogleFonts.outfit(color: Colors.grey)),
                                    )
                                  ]
                                : _kategoriList.map((k) {
                                    return DropdownMenuItem<int>(
                                      value: k['id_kategori'] as int,
                                      child: Text(k['nama_kategori'] ?? '-'),
                                    );
                                  }).toList(),
                            onChanged: (v) => setState(() => _selectedKategoriId = v),
                            decoration: InputDecoration(
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
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  controller: _priceCtrl,
                                  label: 'Harga Normal (Rp)',
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
                                  label: 'Harga Surplus (Rp)',
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
                            controller: _estimasiStokCtrl,
                            label: 'Estimasi Stok Harian (porsi)',
                            hint: 'Contoh: 10',
                            icon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                            helperText: 'Info untuk admin. Stok aktual kamu atur sendiri setelah disetujui.',
                            validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _submit,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send_outlined),
                              label: Text(
                                _isSaving ? 'Mengirim...' : 'Kirim Permintaan Menu',
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
                          const SizedBox(height: 24),
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
    String? helperText,
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
            helperText: helperText,
            helperStyle: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
            helperMaxLines: 2,
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
