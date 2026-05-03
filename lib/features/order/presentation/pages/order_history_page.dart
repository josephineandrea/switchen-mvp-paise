import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final int _currentIndex = 1;

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    try {
      // 1. Ambil ID Angka dari tabel account berdasarkan email auth
      final accountData = await supabase
          .from('account')
          .select('id_pelanggan')
          .eq('email', user.email!)
          .maybeSingle();

      if (accountData == null) return [];

      final int idPelangganAngka = accountData['id_pelanggan'];

      // 2. Gunakan ID Angka tersebut untuk fetch pesanan
      final response = await supabase
          .from('pemesanan')
          .select('*, makanan(*, dapur(nama_dapur))')
          .eq('id_pelanggan', idPelangganAngka) 
          .order('tanggal_pesan', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetch data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Text(
              'Pesanan Saya',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allOrders = snapshot.data ?? [];
                
                if (allOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pesanan nih.',
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final activeOrders = allOrders.where((o) => o['status_pesanan'] != 'Selesai').toList();
                final historyOrders = allOrders.where((o) => o['status_pesanan'] == 'Selesai').toList();

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                      if (activeOrders.isNotEmpty) ...[
                        Text(
                          'Pesanan Aktif',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        ...activeOrders.map((order) => _OrderCard(order: order, isActive: true)),
                        const SizedBox(height: 32),
                      ],
                      
                      if (historyOrders.isNotEmpty) ...[
                        Text(
                          'Riwayat Pesanan',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        ...historyOrders.map((order) => _OrderCard(order: order, isActive: false)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                selected: _currentIndex == 0,
                onTap: () => context.go(AppRoutes.home),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Pesanan',
                selected: _currentIndex == 1,
                onTap: () {}, 
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                selected: _currentIndex == 2,
                onTap: () => context.go(AppRoutes.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? AppColors.primary : AppColors.textHint,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isActive;
  
  const _OrderCard({required this.order, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final makanan = order['makanan'] as Map<String, dynamic>?;
    final dapur = makanan?['dapur'] as Map<String, dynamic>?;
    
    final storeName = dapur?['nama_dapur'] ?? 'Toko Switchen';
    final productName = makanan?['nama_makanan'] ?? 'Produk';
    final orderId = 'PSN-${(order['id_pesanan'] ?? '0').toString().padLeft(6, '0')}';
    final String imageUrl = makanan?['img_url'] ?? '';

    String formattedTime = 'Baru saja';
    if (order['tanggal_pesan'] != null) {
      try {
        final date = DateTime.parse(order['tanggal_pesan']).toLocal();
        formattedTime = DateFormat('dd MMM, HH:mm').format(date);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(storeName, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              Text(formattedTime, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.startsWith('http') 
                  ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                  : Image.asset(
                      'assets/images/$imageUrl', 
                      width: 70, height: 70, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('ID: $orderId', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                    Text('Total: Rp${order['total_harga']}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),

              if (isActive)
                ElevatedButton(
                  onPressed: () => _showQrDialog(context, productName, orderId, order['kode_qr'] ?? orderId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(80, 32),
                  ),
                  child: const Text('QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Selesai', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70, height: 70, color: Colors.grey[100],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 30),
    );
  }

  void _showQrDialog(BuildContext context, String productName, String orderId, String qrData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kode QR Pesanan',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  productName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 24),
                Text(
                  'ID Pesanan: $orderId',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tunjukan QR ini ke kasir saat pengambilan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE5983A),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}