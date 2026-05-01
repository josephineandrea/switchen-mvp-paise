import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/constants/app_colors.dart';

class AdminApprovalMenuPage extends StatefulWidget {
  const AdminApprovalMenuPage({super.key});

  @override
  State<AdminApprovalMenuPage> createState() => _AdminApprovalMenuPageState();
}

class _AdminApprovalMenuPageState extends State<AdminApprovalMenuPage> {
  List<Map<String, dynamic>> _list = [];
  bool _isLoading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('permintaan_makanan')
          .select('*, dapur:id_dapur(nama_dapur), kategori:id_kategori(nama_kategori)')
          .eq('status', _filter)
          .order('created_at', ascending: false);
      setState(() => _list = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('[Admin] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, String status, {String? catatan}) async {
    try {
      await Supabase.instance.client.from('permintaan_makanan').update({
        'status': status,
        if (catatan != null) 'catatan_admin': catatan,
      }).eq('id_permintaan', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              status == 'disetujui'
                  ? '✅ Menu disetujui & otomatis masuk ke katalog!'
                  : '❌ Permintaan menu ditolak.',
              style: GoogleFonts.outfit()),
          backgroundColor: status == 'disetujui' ? AppColors.primary : Colors.red,
          duration: const Duration(seconds: 3),
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReviewDialog(Map<String, dynamic> item) {
    final catatanCtrl = TextEditingController();
    final hargaAsliCtrl = TextEditingController(text: '${item['harga_asli']}');
    final hargaDiskonCtrl = TextEditingController(text: '${item['harga_diskon']}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('Review Menu: ${item['nama_makanan']}',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('dari ${item['dapur']?['nama_dapur'] ?? '-'}',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Text('Harga Normal (Rp)',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: hargaAsliCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Text('Harga Surplus (Rp)',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: hargaDiskonCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Text('Catatan (opsional)',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                hintText: 'Catatan untuk mitra...',
                hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateStatus(item['id_permintaan'], 'ditolak',
                          catatan: catatanCtrl.text.trim());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Tolak', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Update harga terlebih dahulu kalau ada perubahan
                      final hargaAsli = int.tryParse(hargaAsliCtrl.text) ?? item['harga_asli'];
                      final hargaDiskon = int.tryParse(hargaDiskonCtrl.text) ?? item['harga_diskon'];
                      await Supabase.instance.client.from('permintaan_makanan').update({
                        'harga_asli': hargaAsli,
                        'harga_diskon': hargaDiskon,
                      }).eq('id_permintaan', item['id_permintaan']);

                      if (context.mounted) Navigator.pop(context);
                      _updateStatus(item['id_permintaan'], 'disetujui',
                          catatan: catatanCtrl.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065F46),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Setujui', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          ClipRRect(
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('Permintaan Menu',
                      style: GoogleFonts.outfit(
                          fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Review harga & detail menu dari mitra',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: Colors.white.withOpacity(0.75))),
                ],
              ),
            ),
          ),

          // Filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                _FilterTab(label: 'Menunggu', value: 'pending', current: _filter, onTap: (v) {
                  setState(() => _filter = v);
                  _loadData();
                }),
                const SizedBox(width: 8),
                _FilterTab(label: 'Disetujui', value: 'disetujui', current: _filter, onTap: (v) {
                  setState(() => _filter = v);
                  _loadData();
                }),
                const SizedBox(width: 8),
                _FilterTab(label: 'Ditolak', value: 'ditolak', current: _filter, onTap: (v) {
                  setState(() => _filter = v);
                  _loadData();
                }),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A5F)))
                : _list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fastfood_outlined, size: 56, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text('Tidak ada permintaan menu',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFF1E3A5F),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final item = _list[i];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF065F46).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.fastfood,
                                            color: Color(0xFF065F46), size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['nama_makanan'] ?? '-',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary)),
                                            Text(
                                              'dari ${item['dapur']?['nama_dapur'] ?? '-'} · ${item['kategori']?['nama_kategori'] ?? '-'}',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _PriceChip(
                                          label: 'Harga Normal',
                                          value: 'Rp${item['harga_asli']}',
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 10),
                                      _PriceChip(
                                          label: 'Harga Surplus',
                                          value: 'Rp${item['harga_diskon']}',
                                          color: AppColors.primary),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['deskripsi'] ?? '-',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item['catatan_admin'] != null &&
                                      item['catatan_admin'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.note, size: 14, color: Colors.amber),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(item['catatan_admin'],
                                                style: GoogleFonts.outfit(
                                                    fontSize: 11, color: Colors.amber.shade900)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (_filter == 'pending') ...[
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showReviewDialog(item),
                                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                                        label: Text('Review & Putuskan',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF065F46),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 10, color: color.withOpacity(0.8))),
            Text(value,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;

  const _FilterTab({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E3A5F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF1E3A5F) : AppColors.divider),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
