import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/constants/app_colors.dart';

class PartnerEditProductPage extends StatefulWidget {
  final String productId;
  const PartnerEditProductPage({super.key, required this.productId});

  @override
  State<PartnerEditProductPage> createState() => _PartnerEditProductPageState();
}

class _PartnerEditProductPageState extends State<PartnerEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _hargaDiskonCtrl = TextEditingController();
  final _stokCtrl = TextEditingController();
  final _expiredCtrl = TextEditingController();

  Map<String, dynamic>? _makanan;
  bool _isLoading = true;
  bool _isSaving = false;
  int _hargaDiskonPreview = 0; // untuk real-time preview

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _hargaDiskonCtrl.dispose();
    _stokCtrl.dispose();
    _expiredCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await Supabase.instance.client
          .from('makanan')
          .select('*, kategori:id_kategori(nama_kategori), dapur:id_dapur(nama_dapur)')
          .eq('id_makanan', int.parse(widget.productId))
          .single();
      setState(() {
        _makanan = data;
        _hargaDiskonCtrl.text = '${data['harga_diskon']}';
        _hargaDiskonPreview = (data['harga_diskon'] as num?)?.toInt() ?? 0;
        _stokCtrl.text = '${data['stok']}';
        final exp = data['expired_at'] != null
            ? DateTime.parse(data['expired_at']).toLocal()
            : DateTime.now().add(const Duration(hours: 6));
        _expiredCtrl.text =
            '${exp.day.toString().padLeft(2, '0')}/${exp.month.toString().padLeft(2, '0')}/${exp.year} ${exp.hour.toString().padLeft(2, '0')}:${exp.minute.toString().padLeft(2, '0')}';
      });
      // Listener real-time preview
      _hargaDiskonCtrl.addListener(() {
        final val = int.tryParse(_hargaDiskonCtrl.text) ?? 0;
        if (mounted) setState(() => _hargaDiskonPreview = val);
      });
    } catch (e) {
      debugPrint('[EditProduct] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hargaAsli = _makanan?['harga_asli'] ?? 0;
    final hargaDiskon = int.tryParse(_hargaDiskonCtrl.text) ?? 0;
    if (hargaDiskon >= hargaAsli) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Harga surplus harus lebih kecil dari harga normal (Rp$hargaAsli)',
            style: GoogleFonts.outfit()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('makanan').update({
        'harga_diskon': hargaDiskon,
        'stok': int.tryParse(_stokCtrl.text) ?? 0,
        'expired_at': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
        'waktu_ambil': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      }).eq('id_makanan', int.parse(widget.productId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Produk berhasil diperbarui!', style: GoogleFonts.outfit()),
          backgroundColor: AppColors.primary,
        ));
        context.pop(true); // return true supaya dashboard refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Header
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                  child: Container(
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
                      left: 20, right: 20, bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text('Edit Produk',
                            style: GoogleFonts.outfit(
                                fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(_makanan?['nama_makanan'] ?? '-',
                            style: GoogleFonts.outfit(
                                fontSize: 14, color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info card (read-only dari admin)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8, offset: const Offset(0, 3))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text('Detail dari Admin (tidak bisa diubah)',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12, color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600)),
                                ]),
                                const SizedBox(height: 12),
                                _ReadOnlyRow('Nama Makanan', _makanan?['nama_makanan'] ?? '-'),
                                _ReadOnlyRow('Toko', _makanan?['dapur']?['nama_dapur'] ?? '-'),
                                _ReadOnlyRow('Kategori',
                                    _makanan?['kategori']?['nama_kategori'] ?? '-'),
                                _ReadOnlyRow(
                                    'Harga Normal', 'Rp${_makanan?['harga_asli'] ?? 0}'),
                                _ReadOnlyRow('Deskripsi',
                                    _makanan?['deskripsi'] ?? '-',
                                    multiline: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Banner info
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Kamu bisa mengatur harga surplus dan stok harian di bawah ini.',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: AppColors.primary),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 20),

                          // Editable fields — Harga Surplus
                          _buildLabel('Harga Surplus (Rp)'),
                          const SizedBox(height: 4),
                          // Batas atas yang jelas
                          Builder(builder: (ctx) {
                            final hargaAsli = (_makanan?['harga_asli'] as num?)?.toInt() ?? 0;
                            final isOverLimit = _hargaDiskonPreview >= hargaAsli && _hargaDiskonPreview > 0;
                            final persen = hargaAsli > 0 && _hargaDiskonPreview > 0
                                ? (((hargaAsli - _hargaDiskonPreview) / hargaAsli) * 100).round()
                                : 0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Preview card
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isOverLimit
                                        ? Colors.red.shade50
                                        : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isOverLimit
                                            ? Colors.red.shade300
                                            : AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Harga Normal',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 11, color: AppColors.textSecondary)),
                                          Text(
                                            'Rp${_formatNumber(hargaAsli)}',
                                            style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                                decoration: TextDecoration.lineThrough,
                                                decorationColor: AppColors.textHint),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.arrow_forward, size: 16, color: AppColors.textHint),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Harga Surplus',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  color: isOverLimit ? Colors.red : AppColors.primary)),
                                          Text(
                                            _hargaDiskonPreview > 0
                                                ? 'Rp${_formatNumber(_hargaDiskonPreview)}'
                                                : '-',
                                            style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: isOverLimit ? Colors.red : AppColors.primary),
                                          ),
                                        ],
                                      ),
                                      if (!isOverLimit && persen > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text('-$persen%',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.green.shade800)),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isOverLimit)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_rounded,
                                            size: 14, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Maks: Rp${_formatNumber(hargaAsli - 1)} (di bawah harga normal)',
                                          style: GoogleFonts.outfit(
                                              fontSize: 11, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                TextFormField(
                                  controller: _hargaDiskonCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.outfit(),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Wajib diisi';
                                    final val = int.tryParse(v) ?? 0;
                                    if (val <= 0) return 'Harga harus lebih dari 0';
                                    if (val >= hargaAsli) {
                                      return 'Harus lebih kecil dari harga normal (Rp${_formatNumber(hargaAsli)})';
                                    }
                                    return null;
                                  },
                                  decoration: _inputDeco(
                                    hint: 'Contoh: ${(hargaAsli * 0.5).round()}',
                                    helper: 'Batas maksimal: Rp${_formatNumber(hargaAsli - 1)}',
                                    isError: isOverLimit,
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 16),

                          _buildLabel('Stok Hari Ini (porsi)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _stokCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.outfit(),
                            validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                            decoration: _inputDeco(
                              hint: 'Contoh: 10',
                              helper: 'Stok akan otomatis reset tiap hari',
                            ),
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save_outlined),
                              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                                  style: GoogleFonts.outfit(
                                      fontSize: 16, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
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

  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  Widget _ReadOnlyRow(String label, String value, {bool multiline = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text('$label:',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: multiline ? 4 : 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  InputDecoration _inputDeco({String? hint, String? helper, bool isError = false}) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 14),
        helperText: helper,
        helperStyle: GoogleFonts.outfit(
            fontSize: 11,
            color: isError ? Colors.red : AppColors.textSecondary),
        helperMaxLines: 2,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: isError ? Colors.red : AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: isError ? Colors.red : AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: isError ? Colors.red : AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red)),
      );
}
