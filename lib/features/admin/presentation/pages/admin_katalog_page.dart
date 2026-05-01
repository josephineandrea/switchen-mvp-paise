import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/constants/app_colors.dart';

class AdminKatalogPage extends StatefulWidget {
  const AdminKatalogPage({super.key});

  @override
  State<AdminKatalogPage> createState() => _AdminKatalogPageState();
}

class _AdminKatalogPageState extends State<AdminKatalogPage> {
  List<Map<String, dynamic>> _makananList = [];
  List<Map<String, dynamic>> _dapurList = [];
  List<Map<String, dynamic>> _kategoriList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final makanan = await client
          .from('makanan')
          .select('*, dapur:id_dapur(nama_dapur), kategori:id_kategori(nama_kategori)')
          .order('created_at', ascending: false);
      final dapur = await client.from('dapur').select('id_dapur, nama_dapur').order('nama_dapur');
      final kategori = await client.from('kategori').select().order('nama_kategori');

      setState(() {
        _makananList = List<Map<String, dynamic>>.from(makanan);
        _dapurList = List<Map<String, dynamic>>.from(dapur);
        _kategoriList = List<Map<String, dynamic>>.from(kategori);
      });
    } catch (e) {
      debugPrint('[AdminKatalog] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _makananList;
    return _makananList.where((m) {
      final nama = (m['nama_makanan'] ?? '').toLowerCase();
      final toko = (m['dapur']?['nama_dapur'] ?? '').toLowerCase();
      return nama.contains(_searchQuery.toLowerCase()) ||
          toko.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['nama_makanan'] ?? '');
    final descCtrl = TextEditingController(text: existing?['deskripsi'] ?? '');
    final hargaAsliCtrl = TextEditingController(text: '${existing?['harga_asli'] ?? ''}');
    final hargaDiskonCtrl = TextEditingController(text: '${existing?['harga_diskon'] ?? ''}');
    int? selectedDapurId = existing?['id_dapur'];
    int? selectedKategoriId = existing?['id_kategori'];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text(existing == null ? 'Tambah Menu ke Katalog' : 'Edit Menu',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Data ini bisa diedit mitra untuk harga & stok harian',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                // Pilih Toko
                _FormLabel('Toko / Mitra'),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedDapurId,
                  hint: Text('Pilih toko mitra', style: GoogleFonts.outfit(color: AppColors.textHint)),
                  style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
                  items: _dapurList.map((d) => DropdownMenuItem<int>(
                    value: d['id_dapur'] as int,
                    child: Text(d['nama_dapur'] ?? '-'),
                  )).toList(),
                  onChanged: (v) => setModalState(() => selectedDapurId = v),
                  decoration: _inputDeco(),
                ),
                const SizedBox(height: 12),

                // Nama Makanan
                _FormLabel('Nama Makanan'),
                const SizedBox(height: 6),
                TextField(controller: nameCtrl, style: GoogleFonts.outfit(),
                    decoration: _inputDeco(hint: 'Contoh: Nasi Goreng Spesial')),
                const SizedBox(height: 12),

                // Deskripsi
                _FormLabel('Deskripsi'),
                const SizedBox(height: 6),
                TextField(controller: descCtrl, maxLines: 3, style: GoogleFonts.outfit(),
                    decoration: _inputDeco(hint: 'Bahan, rasa, kondisi makanan...')),
                const SizedBox(height: 12),

                // Kategori
                _FormLabel('Kategori'),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedKategoriId,
                  hint: Text('Pilih kategori', style: GoogleFonts.outfit(color: AppColors.textHint)),
                  style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
                  items: _kategoriList.map((k) => DropdownMenuItem<int>(
                    value: k['id_kategori'] as int,
                    child: Text(k['nama_kategori'] ?? '-'),
                  )).toList(),
                  onChanged: (v) => setModalState(() => selectedKategoriId = v),
                  decoration: _inputDeco(),
                ),
                const SizedBox(height: 12),

                // Harga
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _FormLabel('Harga Normal (Rp)'),
                    const SizedBox(height: 6),
                    TextField(controller: hargaAsliCtrl, keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(), decoration: _inputDeco(hint: '50000')),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _FormLabel('Harga Surplus (Rp)'),
                    const SizedBox(height: 6),
                    TextField(controller: hargaDiskonCtrl, keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(), decoration: _inputDeco(hint: '20000')),
                  ])),
                ]),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.isEmpty || selectedDapurId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Nama makanan & toko wajib diisi')));
                              return;
                            }
                            setModalState(() => isSaving = true);
                            try {
                              final payload = {
                                'nama_makanan': nameCtrl.text.trim(),
                                'deskripsi': descCtrl.text.trim(),
                                'harga_asli': int.tryParse(hargaAsliCtrl.text) ?? 0,
                                'harga_diskon': int.tryParse(hargaDiskonCtrl.text) ?? 0,
                                'stok': 0,
                                'id_dapur': selectedDapurId,
                                'id_kategori': selectedKategoriId,
                                'expired_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                                'waktu_ambil': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
                              };
                              if (existing == null) {
                                await Supabase.instance.client.from('makanan').insert(payload);
                              } else {
                                await Supabase.instance.client
                                    .from('makanan')
                                    .update(payload)
                                    .eq('id_makanan', existing['id_makanan']);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                    existing == null ? '✅ Menu berhasil ditambahkan!' : '✅ Menu diperbarui!',
                                    style: GoogleFonts.outfit(),
                                  ),
                                  backgroundColor: AppColors.primary,
                                ));
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C1D95),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(existing == null ? 'Simpan ke Katalog' : 'Simpan Perubahan',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Menu?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Menu ini akan dihapus dari katalog.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Supabase.instance.client.from('makanan').delete().eq('id_makanan', id);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Hapus', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFF4C1D95),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Tambah Menu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
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
                  colors: [Color(0xFF2D1B69), Color(0xFF4C1D95), Color(0xFF6D28D9)],
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
                  Text('Katalog Menu',
                      style: GoogleFonts.outfit(
                          fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('${_makananList.length} item terdaftar — admin yang menginput',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: Colors.white.withOpacity(0.75))),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari nama makanan atau toko...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4C1D95)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 56, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text('Belum ada menu',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Text('Tap tombol + untuk menambahkan',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFF4C1D95),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final m = filtered[i];
                            final diskon = m['harga_asli'] > 0
                                ? (((m['harga_asli'] - m['harga_diskon']) / m['harga_asli']) * 100).round()
                                : 0;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8, offset: const Offset(0, 3))
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4C1D95).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.fastfood, color: Color(0xFF4C1D95), size: 24),
                                ),
                                title: Text(m['nama_makanan'] ?? '-',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m['dapur']?['nama_dapur'] ?? '-',
                                        style: GoogleFonts.outfit(
                                            fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Text('Rp${m['harga_diskon']}',
                                          style: GoogleFonts.outfit(
                                              fontSize: 13, fontWeight: FontWeight.w700,
                                              color: AppColors.primary)),
                                      const SizedBox(width: 6),
                                      Text('Rp${m['harga_asli']}',
                                          style: GoogleFonts.outfit(
                                              fontSize: 11, color: AppColors.textHint,
                                              decoration: TextDecoration.lineThrough)),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('-$diskon%',
                                            style: GoogleFonts.outfit(
                                                fontSize: 10, fontWeight: FontWeight.w700,
                                                color: Colors.red)),
                                      ),
                                    ]),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showFormDialog(existing: m);
                                    if (v == 'delete') _confirmDelete(m['id_makanan']);
                                  },
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'edit',
                                        child: Row(children: [
                                          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4C1D95)),
                                          const SizedBox(width: 8),
                                          Text('Edit', style: GoogleFonts.outfit()),
                                        ])),
                                    PopupMenuItem(value: 'delete',
                                        child: Row(children: [
                                          const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          const SizedBox(width: 8),
                                          Text('Hapus', style: GoogleFonts.outfit(color: Colors.red)),
                                        ])),
                                  ],
                                ),
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

  Widget _FormLabel(String text) => Text(text,
      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4C1D95), width: 1.5)),
      );
}
