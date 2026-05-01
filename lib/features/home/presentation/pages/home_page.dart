import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _selectedCategoryId = 0;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  
  // Pagination State
  int _currentPage = 1;
  final int _itemsPerPage = 15;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.from('kategori').select();
      final fetchedCategories = List<Map<String, dynamic>>.from(response);
      
      // Filter out 'Minuman' as requested
      fetchedCategories.removeWhere((cat) => cat['nama_kategori'].toString().toLowerCase() == 'minuman');

      setState(() {
        _categories = [
          {'id_kategori': 0, 'nama_kategori': 'Semua'},
          ...fetchedCategories,
        ];
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProductsFromSupabase() async {
    final supabase = Supabase.instance.client;
    var query = supabase
        .from('makanan')
        .select('*, dapur(nama_dapur, jarak_dummy)')
        .gt('stok', 0);
        
    if (_selectedCategoryId != 0) {
      query = query.eq('id_kategori', _selectedCategoryId);
    }
    
    // Pagination logic
    final from = (_currentPage - 1) * _itemsPerPage;
    final to = from + _itemsPerPage - 1;
    final response = await query.range(from, to);
    
    final data = List<Map<String, dynamic>>.from(response);
    
    // Check if we reached the last page
    _isLastPage = data.length < _itemsPerPage;
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Pengguna';
    String userEmail = 'Memuat email...';
    
    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
      userEmail = authState.user.email;
    }
    
    final firstName = userName.split(' ').first;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is AuthInitial) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Column(
              children: [
                // ── Header Background ─────────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Container(
                  height: MediaQuery.of(context).padding.top + 200, 
                  width: double.infinity,
                  color: AppColors.primary,
                  child: Stack(
                    children: [
                      // Gambar Perempuan (Otomatis terpotong rapi di dalam batas hijau)
                      Positioned(
                        bottom: -10, // Pas di bawah
                        right: 20, 
                        child: SizedBox(
                          height: 150, // Sengaja dibuat besar agar pas dan terpotong
                          child: SvgPicture.asset('assets/images/hero_illustration.svg'),
                        ),
                      ),
                      
                      // Teks Header
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 24,
                        left: 20,
                        right: 140, // Kasih jarak supaya teks tidak menabrak gambar perempuan
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      userEmail,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selamat Pagi,\n$firstName!',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ayo Ubah Surplus Menjadi Nilai Plus',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 100px gap removed because background height now controls where this starts
                      const SizedBox(height: 20),

                      // Category chips
                      _buildCategoryChips(),
                      const SizedBox(height: 24),

                      // Section title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pilihan Untukmu',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary, // Dark green
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.storeList),
                              child: Text(
                                'Lihat Semua',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Product cards via FutureBuilder
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchProductsFromSupabase(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Belum ada produk dari database.'),
                            ));
                          }

                          final products = snapshot.data!;
                          
                          final mappedProducts = products.map((p) {
                            final dapur = p['dapur'] as Map<String, dynamic>?;
                            final jarak = dapur != null && dapur['jarak_dummy'] != null 
                                ? '${dapur['jarak_dummy']} km' 
                                : '0.5 km';
                            return {
                              'id': p['id_makanan']?.toString() ?? '',
                              'name': p['nama_makanan'] ?? 'Tanpa Nama',
                              'store': dapur?['nama_dapur'] ?? 'Dapur Tidak Diketahui',
                              'distance': jarak,
                              'price': (p['harga_diskon'] as num?)?.toInt() ?? 0,
                              'originalPrice': (p['harga_asli'] as num?)?.toInt() ?? 0,
                              'image': p['img_url'] ?? 'https://via.placeholder.com/150',
                              'category': 'Semua', 
                            };
                          }).toList();

                          return Column(
                            children: [
                              ...mappedProducts.map((product) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: _ProductCard(product: product),
                              )),
                              
                              // Pagination Controls
                              if (mappedProducts.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        color: _currentPage > 1 ? AppColors.primary : AppColors.textHint,
                                        onPressed: _currentPage > 1 
                                            ? () => setState(() => _currentPage--) 
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Halaman $_currentPage',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        color: !_isLastPage ? AppColors.primary : AppColors.textHint,
                                        onPressed: !_isLastPage 
                                            ? () => setState(() => _currentPage++) 
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    return const SizedBox(); // Handled in Stack
  }

  Widget _buildCategoryChips() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
          )
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final catId = category['id_kategori'] as int;
          final catName = category['nama_kategori'] as String;
          final selected = _selectedCategoryId == catId;
          
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategoryId = catId;
              _currentPage = 1; // Reset pagination when category changes
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.surfaceVariant,
                ),
                boxShadow: selected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  catName,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Pesanan',
                selected: _currentIndex == 1,
                onTap: () {
                  setState(() => _currentIndex = 1);
                  context.push(AppRoutes.orderHistory);
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                selected: _currentIndex == 2,
                onTap: () {
                  context.push(AppRoutes.profile);
                },
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

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary, // Dark green
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Text(
                        product['store'],
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFFFF6B6B)), // Red pin
                      const SizedBox(width: 6),
                      Text(
                        product['distance'],
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp${_formatPrice(product['price'])}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'Rp${_formatPrice(product['originalPrice'])}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Right Side (Image + Button)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product['image'],
                    width: 120, // Diperbesar menyesuaikan lebar tombol
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 80,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.fastfood, color: AppColors.textHint),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 120, // Lebar tombol Pesan disamakan dengan gambar
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      AppRoutes.storeDetail.replaceFirst(':storeId', product['id'] ?? 'demo'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B), // Red/Pink button
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: Text(
                      'Pesan',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
