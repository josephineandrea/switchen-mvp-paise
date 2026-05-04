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
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final makanan = await client
          .from('makanan')
          .select('*, dapur:id_dapur(nama_dapur, alamat_dapur), kategori:id_kategori(nama_kategori)')
          .order('created_at', ascending: false);
      final dapur = await client.from('dapur').select().order('nama_dapur');
      final kategori = await client.from('kategori').select().order('nama_kategori');

      if (mounted) {
        setState(() {
          _makananList = List<Map<String, dynamic>>.from(makanan);
          _dapurList = List<Map<String, dynamic>>.from(dapur);
          _kategoriList = List<Map<String, dynamic>>.from(kategori);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedTab == 0) {
      if (_searchQuery.isEmpty) return _makananList;
      return _makananList.where((m) {
        final nama = (m['nama_makanan'] ?? '').toLowerCase();
        final toko = (m['dapur']?['nama_dapur'] ?? '').toLowerCase();
        return nama.contains(_searchQuery.toLowerCase()) || toko.contains(_searchQuery.toLowerCase());
      }).toList();
    } else {
      if (_searchQuery.isEmpty) return _dapurList;
      return _dapurList.where((d) {
        final nama = (d['nama_dapur'] ?? '').toLowerCase();
        final alamat = (d['alamat_dapur'] ?? '').toLowerCase();
        return nama.contains(_searchQuery.toLowerCase()) || alamat.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['nama_makanan'] ?? '');
    final descCtrl = TextEditingController(text: existing?['deskripsi'] ?? '');
    final hargaAsliCtrl = TextEditingController(text: '${existing?['harga_asli'] ?? ''}');
    final hargaDiskonCtrl = TextEditingController(text: '${existing?['harga_diskon'] ?? ''}');
    final imgUrlCtrl = TextEditingController(text: existing?['img_url'] ?? '');
    int? selectedDapurId = existing?['id_dapur'];
    int? selectedKategoriId = existing?['id_kategori'];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text(existing == null ? 'Tambah Menu Baru' : 'Edit Menu',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                Text('Toko Mitra', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedDapurId,
                  hint: Text('Pilih toko', style: GoogleFonts.outfit(fontSize: 14)),
                  items: _dapurList
                      .map((d) => DropdownMenuItem<int>(
                            value: d['id_dapur'] as int,
                            child: Text(d['nama_dapur'] ?? '-'),
                          ))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedDapurId = v),
                  decoration: _inputDeco(),
                ),
                const SizedBox(height: 12),
                Text('Nama Makanan', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: nameCtrl, decoration: _inputDeco()),
                const SizedBox(height: 12),
                Text('Link Gambar (Aset)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: imgUrlCtrl, decoration: _inputDeco(hint: 'nama_file.jpg')),
                const SizedBox(height: 12),
                Text('Deskripsi', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: descCtrl, maxLines: 2, decoration: _inputDeco()),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Harga Normal', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: hargaAsliCtrl, keyboardType: TextInputType.number, decoration: _inputDeco()),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Harga Surplus', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: hargaDiskonCtrl, keyboardType: TextInputType.number, decoration: _inputDeco()),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              final payload = {
                                'nama_makanan': nameCtrl.text.trim(),
                                'deskripsi': descCtrl.text.trim(),
                                'harga_asli': int.tryParse(hargaAsliCtrl.text) ?? 0,
                                'harga_diskon': int.tryParse(hargaDiskonCtrl.text) ?? 0,
                                'img_url': imgUrlCtrl.text.trim(),
                                'id_dapur': selectedDapurId,
                                'id_kategori': selectedKategoriId ?? 1,
                                'stok': 0,
                                'expired_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                                'waktu_ambil': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
                              };
                              if (existing == null) {
                                await Supabase.instance.client.from('makanan').insert(payload);
                              } else {
                                await Supabase.instance.client.from('makanan').update(payload).eq('id_makanan', existing['id_makanan']);
                              }
                              Navigator.pop(ctx);
                              _loadData();
                            } catch (e) {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C1D95),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Simpan Menu', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showFormDialog(),
              backgroundColor: const Color(0xFF4C1D95),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Tambah Menu', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2D1B69), Color(0xFF4C1D95)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20)),
                const SizedBox(height: 12),
                Text('Katalog Switchen', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _TabBtn(label: 'Menu', isSelected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                      _TabBtn(label: 'Toko', isSelected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: _selectedTab == 0 ? 'Cari menu atau toko...' : 'Cari nama toko...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4C1D95)))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      return _selectedTab == 0
                          ? _MenuCrd(item: item, onEdit: () => _showFormDialog(existing: item))
                          : _TokoCrd(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF4C1D95) : Colors.white70)),
        ),
      ),
    );
  }
}

class _MenuCrd extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  const _MenuCrd({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/${item['img_url']}',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: Colors.grey[100],
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama_makanan'] ?? '-', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(item['dapur']?['nama_dapur'] ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Rp${item['harga_diskon']}', style: GoogleFonts.outfit(color: const Color(0xFF00615F), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4C1D95))),
        ],
      ),
    );
  }
}

class _TokoCrd extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TokoCrd({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFF4C1D95).withOpacity(0.1), child: const Icon(Icons.store, color: Color(0xFF4C1D95))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama_dapur'] ?? '-', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(item['alamat_dapur'] ?? '-',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}