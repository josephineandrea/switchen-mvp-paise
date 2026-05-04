import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
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
  final int _currentIndex = 0;
  int _selectedCategoryId = 0;
  
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoadingProducts = true;
  
  double _userLat = -6.886656;
  double _userLng = 107.580635;

  String _userName = 'Memuat...';
  String _userEmail = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    Position? currentPosition = await _determinePosition();
    if (currentPosition != null) {
      _userLat = currentPosition.latitude;
      _userLng = currentPosition.longitude;
    }
    
    await _fetchUserData();
    await _fetchCategories();
    await _fetchAllProducts();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null; 

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    try {
      Map<String, dynamic>? userData;
      
      if (user != null && user.email != null) {
        userData = await supabase.from('account').select('nama_account, email').eq('email', user.email!).maybeSingle();
      } 
      
      if (userData == null) {
        userData = await supabase.from('account').select('nama_account, email').eq('id_pelanggan', 1).maybeSingle();
      }
      
      if (mounted && userData != null) {
        setState(() {
          _userName = userData?['nama_account'] ?? user;
          _userEmail = userData?['email'] ?? 'Email tidak ditemukan';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Pengguna';
          _userEmail = 'Email tidak ditemukan';
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.from('kategori').select();
      final fetchedCategories = List<Map<String, dynamic>>.from(response);
      
      fetchedCategories.removeWhere((cat) => cat['nama_kategori'].toString().toLowerCase() == 'minuman');

      if (mounted) {
        setState(() {
          _categories = [
            {'id_kategori': 0, 'nama_kategori': 'Semua'},
            ...fetchedCategories,
          ];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchAllProducts() async {
    final supabase = Supabase.instance.client;
    try {
      final storeResponse = await supabase.from('dapur').select();
      final productResponse = await supabase
          .from('makanan')
          .select('*, dapur(nama_dapur, alamat_dapur, latitude, longitude)')
          .gt('stok', 0);
          
      if (mounted) {
        setState(() {
          int seedHarian = DateTime.now().day + DateTime.now().month + DateTime.now().year;

          List<Map<String, dynamic>> processedStores = List<Map<String, dynamic>>.from(storeResponse).map((store) {
            double sLat = (store['latitude'] as num?)?.toDouble() ?? 0.0;
            double sLng = (store['longitude'] as num?)?.toDouble() ?? 0.0;
            double distance = Geolocator.distanceBetween(_userLat, _userLng, sLat, sLng) / 1000;
            
            var newStore = Map<String, dynamic>.from(store);
            newStore['raw_distance'] = distance;
            return newStore;
          }).toList();

          processedStores.sort((a, b) => (a['raw_distance'] as double).compareTo(b['raw_distance'] as double));
          List<Map<String, dynamic>> kandidatToko = processedStores.take(15).toList();
          kandidatToko.shuffle(Random(seedHarian));
          List<Map<String, dynamic>> dailyStores = kandidatToko.take(5).toList();
          
          List<String> namaTokoHarian = dailyStores.map((s) => s['nama_dapur'].toString()).toList();

          List<Map<String, dynamic>> mappedProducts = List<Map<String, dynamic>>.from(productResponse).map((p) {
            final dapur = p['dapur'] as Map<String, dynamic>?;
            
            double storeLat = (dapur?['latitude'] as num?)?.toDouble() ?? 0.0;
            double storeLng = (dapur?['longitude'] as num?)?.toDouble() ?? 0.0;
            double distanceInMeters = Geolocator.distanceBetween(_userLat, _userLng, storeLat, storeLng);
            double distanceInKm = distanceInMeters / 1000;

            return {
              'id': p['id_makanan'].toString(),
              'name': p['nama_makanan'] ?? 'Tanpa Nama',
              'store': dapur?['nama_dapur'] ?? 'Toko',
              'distance': '${distanceInKm.toStringAsFixed(1)} km',
              'raw_distance': distanceInKm,
              'price': (p['harga_diskon'] as num?)?.toInt() ?? 0,
              'originalPrice': (p['harga_asli'] as num?)?.toInt() ?? 0,
              'image': p['img_url'] ?? '',
              'category': p['id_kategori'] ?? 0,
            };
          }).toList();

          List<Map<String, dynamic>> dailyProducts = mappedProducts.where((p) => namaTokoHarian.contains(p['store'])).toList();
          dailyProducts.sort((a, b) => (a['raw_distance'] as double).compareTo(b['raw_distance'] as double));
          dailyProducts = dailyProducts.take(15).toList();
          dailyProducts.shuffle(Random(seedHarian));

          _allProducts = dailyProducts;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _showProductDetail(BuildContext context, Map<String, dynamic> localProduct) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: Supabase.instance.client
              .from('makanan')
              .select('*, dapur(nama_dapur, alamat_dapur)')
              .eq('id_makanan', localProduct['id'])
              .single(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            final product = snapshot.data!;
            final dapur = product['dapur'] as Map<String, dynamic>;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.zero, 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                               child: (product['img_url'] != null && product['img_url'].toString().startsWith('http'))
                                    ? Image.network(
                                        product['img_url'],
                                        height: 280,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 280,
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/${product['img_url']}',
                                        height: 280,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 280,
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                                          );
                                        },
                                      ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['nama_makanan'], 
                                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          const Icon(Icons.storefront, size: 18, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(dapur['nama_dapur'], style: GoogleFonts.outfit(color: Colors.grey)),
                                        ]),
                                        Row(children: [
                                          const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                                          const SizedBox(width: 4),
                                          Text(localProduct['distance'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                        ]),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: const Color(0xFFF4FBF7), borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text('Waktu Ambil : 14.00 - 18.00 WIB', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text('Deskripsi Makanan', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(product['deskripsi'] ?? 'Tidak ada deskripsi.', style: GoogleFonts.outfit(color: Colors.grey, height: 1.5)),
                                    const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
                        ),
                        child: Row(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Harga', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                                Row(
                                  children: [
                                    Text('Rp${product['harga_diskon']}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    const SizedBox(width: 8),
                                    Text('Rp${product['harga_asli']}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  context.pop(); 
                                  context.push(AppRoutes.orderDetail.replaceFirst(':orderId', localProduct['id']));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7E7E),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text('Pesan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40, 
                        height: 4, 
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9), 
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)
                          ]
                        )
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
    
    List<Map<String, dynamic>> displayedProducts = _allProducts;
    if (_selectedCategoryId != 0) {
      displayedProducts = displayedProducts.where((p) => p['category'] == _selectedCategoryId).toList();
    }
    displayedProducts = displayedProducts.take(5).toList();
    
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
                      Positioned(
                        bottom: -10, 
                        right: 50, 
                        child: SizedBox(
                          height: 150, 
                          child: SvgPicture.asset('assets/images/hero_illustration.svg'),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 24,
                        left: 20,
                        right: 140, 
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
                      const SizedBox(height: 20),
                      _buildCategoryChips(),
                      const SizedBox(height: 24),

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
                                color: AppColors.primary, 
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

                      if (_isLoadingProducts)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ))
                      else if (displayedProducts.isEmpty)
                        Center(child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('Belum ada produk di kategori ini.', style: GoogleFonts.outfit(color: Colors.grey)),
                        ))
                      else
                        Column(
                          children: displayedProducts.map((product) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: _ProductCard(
                              product: product,
                              onTap: () => _showProductDetail(context, product),
                            ),
                          )).toList(),
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
                onTap: () {}, 
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Pesanan',
                selected: _currentIndex == 1,
                onTap: () {
                  context.go(AppRoutes.orderHistory); 
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                selected: _currentIndex == 2,
                onTap: () {
                  context.go(AppRoutes.profile); 
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
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary, 
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
                          size: 14, color: Color(0xFFFF6B6B)), 
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (product['image'] != null && product['image'].toString().startsWith('http'))
                    ? Image.network(
                        product['image'],
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      )
                    : Image.asset(
                        'assets/images/${product['image']}', 
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, color: Colors.grey),
                          );
                        },
                      ),
              ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 120, 
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B), 
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