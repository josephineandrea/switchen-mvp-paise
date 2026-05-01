import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Butter Croissant',
      'store': 'Toko Roti Braga',
      'distance': '0.5 km',
      'price': 10000,
      'originalPrice': 25000,
      'image': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=300&q=80',
    },
    {
      'name': 'Nasi Kotak',
      'store': 'Warung Sari Rasa',
      'distance': '1.2 km',
      'price': 10000,
      'originalPrice': 25000,
      'image': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=300&q=80',
    },
    {
      'name': 'Salad Sayur',
      'store': 'Green Bowl Café',
      'distance': '0.8 km',
      'price': 12000,
      'originalPrice': 30000,
      'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&q=80',
    },
    {
      'name': 'Kue Lapis',
      'store': 'Kue Bu Siti',
      'distance': '2.1 km',
      'price': 8000,
      'originalPrice': 20000,
      'image': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semua Surplus Terdekat',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.accent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Lokasi Anda',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari makanan, bahan makanan, toko',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    hintStyle: GoogleFonts.outfit(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20, bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Surplus Hari Ini',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._products.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: _SurplusCard(product: p),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurplusCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _SurplusCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.storefront_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(product['store'],
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(product['distance'],
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product['image'],
                    width: 90,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90, height: 80,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.fastfood, color: AppColors.textHint),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rp${_fmt(product['price'])}',
                      style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.priceColor),
                    ),
                    Text(
                      'Rp${_fmt(product['originalPrice'])}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.originalPriceColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text('Pesan', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int price) => price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
