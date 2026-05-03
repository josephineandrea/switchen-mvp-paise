import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/constants/app_colors.dart';

class AdminApprovalMitraPage extends StatefulWidget {
  const AdminApprovalMitraPage({super.key});

  @override
  State<AdminApprovalMitraPage> createState() => _AdminApprovalMitraPageState();
}

class _AdminApprovalMitraPageState extends State<AdminApprovalMitraPage> {
  List<Map<String, dynamic>> _list = [];
  bool _isLoading = true;
  String _filter = 'pending'; // pending | disetujui | ditolak

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('permintaan_mitra')
          .select('*, account:id_pelanggan(nama_account, email, no_hp)')
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
      await Supabase.instance.client.from('permintaan_mitra').update({
        'status': status,
        if (catatan != null) 'catatan_admin': catatan,
      }).eq('id_permintaan', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              status == 'disetujui' ? '✅ Toko berhasil disetujui!' : '❌ Permintaan ditolak.',
              style: GoogleFonts.outfit()),
          backgroundColor: status == 'disetujui' ? AppColors.primary : Colors.red,
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

  void _showTolakDialog(int id) {
    final catatanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Alasan Penolakan', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: catatanCtrl,
          maxLines: 3,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(
            hintText: 'Tulis alasan penolakan...',
            hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, 'ditolak', catatan: catatanCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Tolak', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
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
                  Text('Permintaan Mitra',
                      style: GoogleFonts.outfit(
                          fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Review dan setujui pendaftaran toko baru',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.75))),
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
                            Icon(Icons.storefront_outlined, size: 56, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text('Tidak ada permintaan',
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
                            final acc = item['account'] ?? {};
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
                                          color: const Color(0xFF1E3A5F).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.storefront,
                                            color: Color(0xFF1E3A5F), size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['nama_dapur'] ?? '-',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary)),
                                            Text(acc['email'] ?? '-',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _InfoRow(Icons.phone, 'Telepon', item['telp_dapur'] ?? '-'),
                                  _InfoRow(Icons.location_on, 'Alamat', item['alamat_dapur'] ?? '-'),
                                  _InfoRow(Icons.person, 'Pemilik', acc['nama_account'] ?? '-'),
                                  if (item['catatan_admin'] != null &&
                                      item['catatan_admin'].toString().isNotEmpty)
                                    _InfoRow(Icons.note, 'Catatan Admin', item['catatan_admin']),
                                  if (_filter == 'pending') ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showTolakDialog(item['id_permintaan']),
                                            icon: const Icon(Icons.close, size: 16),
                                            label: Text('Tolak', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(item['id_permintaan'], 'disetujui'),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: Text('Setujui', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1E3A5F),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                      ],
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
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
          border: Border.all(
              color: selected ? const Color(0xFF1E3A5F) : AppColors.divider),
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
