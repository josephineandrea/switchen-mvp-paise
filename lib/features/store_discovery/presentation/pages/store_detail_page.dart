import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. Tambahkan import ini
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

class StoreDetailPage extends StatefulWidget {
  final String storeId;
  const StoreDetailPage({super.key, required this.storeId});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  // 2. Fungsi untuk mengambil detail makanan berdasarkan ID
  Future<Map<String, dynamic>> _fetchProductDetail() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('makanan')
        .select('*, dapur(nama_dapur, alamat_dapur, jarak_dummy)')
        .eq('id_makanan', widget.storeId)
        .single();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProductDetail(),
        builder: (context, snapshot) {
          // 3. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          // 4. Error State
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Gagal memuat detail makanan'));
          }

          final product = snapshot.data!;
          final dapur = product['dapur'] as Map<String, dynamic>;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header teal + avatar
                    _buildHeader(context),

                    // Product hero image (Dinamis dari img_url)
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: Image.network(
                        product['img_url'] ?? '',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.fastfood, size: 60, color: AppColors.textHint),
                        ),
                      ),
                    ),

                    // Info section
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['nama_makanan'] ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                const Icon(Icons.storefront_outlined, size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  dapur['nama_dapur'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                                ),
                              ]),
                              Row(children: [
                                const Icon(Icons.location_on, size: 16, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  '${dapur['jarak_dummy'] ?? '0.5'} km',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Pickup time (Dinamis)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Waktu Ambil : ${product['waktu_ambil'] ?? '18:00 - 20:00 WIB'}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Deskripsi Makanan',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product['deskripsi_makanan'] ?? 'Tidak ada deskripsi.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Fixed Bottom Bar
              _buildBottomBar(context, product),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(height: 120, color: AppColors.primary),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                _buildUserAvatar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jane Doe', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            Text('janedoe506@gmail.com', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Map<String, dynamic> product) {
    final hargaDiskon = product['harga_diskon'] as int;
    final hargaAsli = product['harga_asli'] as int;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Harga', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Rp${_formatPrice(hargaDiskon)}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.priceColor)),
                    const SizedBox(width: 6),
                    Text('Rp${_formatPrice(hargaAsli)}', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.originalPriceColor, decoration: TextDecoration.lineThrough)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                // Melemparkan ID Makanan ke halaman rincian pesanan
                onPressed: () => context.push(AppRoutes.orderDetail.replaceFirst(':orderId', widget.storeId)),
                child: const Text('Pesan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}