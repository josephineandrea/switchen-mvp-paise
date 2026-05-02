import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math'; // 🟢 Wajib buat fungsi acak (shuffle)
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final _searchCtrl = TextEditingController();
  final int _currentIndex = 0;

  // 🟢 WADAH MASTER (Penyimpanan semua data, dipakai murni buat Search Bar)
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _allStores = [];

  // 🟢 WADAH HARIAN (Menyimpan 5 toko pilihan & makanannya)
  List<Map<String, dynamic>> _dailyProducts = [];
  List<Map<String, dynamic>> _dailyStores = [];

  // 🟢 WADAH TAMPILAN (Yang beneran digambar di layar saat ini)
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _stores = [];
  
  bool _isLoading = true;
  String _userAddress = 'Mencari lokasi...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    Position? currentPosition = await _determinePosition();
    
    double userLat = currentPosition?.latitude ?? -6.886656; 
    double userLng = currentPosition?.longitude ?? 107.580635;

    await _fetchData(userLat, userLng);
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _userAddress = 'GPS mati. Memakai lokasi default.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _userAddress = 'Izin ditolak. Memakai lokasi default.');
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _userAddress = 'Izin diblokir. Memakai lokasi default.');
      return null;
    } 

    if (mounted) setState(() => _userAddress = 'Lokasi akurat ditemukan');
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchData(double userLat, double userLng) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // 1. AMBIL ALAMAT USER
      Map<String, dynamic>? userData;
      if (user != null && user.email != null) {
        userData = await supabase.from('account').select('alamat').eq('email', user.email!).maybeSingle();
      } else {
        userData = await supabase.from('account').select('alamat').eq('id_pelanggan', 1).maybeSingle();
      }
      final fetchedAddress = userData?['alamat'] ?? 'Lokasi tidak ditemukan';

      // 2. AMBIL DATA DAPUR & MAKANAN
      final storeResponse = await supabase.from('dapur').select();
      final productResponse = await supabase
          .from('makanan')
          .select('*, dapur(nama_dapur, alamat_dapur, latitude, longitude)')
          .gt('stok', 0);

      if (mounted) {
        setState(() {
          _userAddress = fetchedAddress;
          
          int seedHarian = DateTime.now().day + DateTime.now().month + DateTime.now().year;

          // ─── 🟢 3. ISI WADAH MASTER ───
          _allStores = List<Map<String, dynamic>>.from(storeResponse).map((store) {
            double sLat = (store['latitude'] as num?)?.toDouble() ?? 0.0;
            double sLng = (store['longitude'] as num?)?.toDouble() ?? 0.0;
            double distance = Geolocator.distanceBetween(userLat, userLng, sLat, sLng) / 1000;
            
            var newStore = Map<String, dynamic>.from(store);
            newStore['raw_distance'] = distance;
            return newStore;
          }).toList();

          _allProducts = List<Map<String, dynamic>>.from(productResponse).map((p) {
            final dapur = p['dapur'] as Map<String, dynamic>?;
            
            double storeLat = (dapur?['latitude'] as num?)?.toDouble() ?? 0.0;
            double storeLng = (dapur?['longitude'] as num?)?.toDouble() ?? 0.0;
            double distanceInMeters = Geolocator.distanceBetween(userLat, userLng, storeLat, storeLng);
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
            };
          }).toList();

          // ─── 🟢 4. BIKIN TAMPILAN HARIAN YANG SINKRON ───
          
          // Pilih 5 Toko Harian
          List<Map<String, dynamic>> sortedStores = List.from(_allStores);
          sortedStores.sort((a, b) => (a['raw_distance'] as double).compareTo(b['raw_distance'] as double));
          List<Map<String, dynamic>> kandidatToko = sortedStores.take(15).toList(); // Ambil 15 terdekat
          kandidatToko.shuffle(Random(seedHarian)); // Diacak harian
          _dailyStores = kandidatToko.take(5).toList(); // Pastikan cuma 5 yang tampil
          
          // Simpan daftar nama 5 toko itu buat sinkronisasi
          List<String> namaTokoHarian = _dailyStores.map((s) => s['nama_dapur'].toString()).toList();

          // Pilih Produk yang CUMA BERASAL dari 5 toko di atas
          _dailyProducts = _allProducts.where((p) => namaTokoHarian.contains(p['store'])).toList();
          _dailyProducts.shuffle(Random(seedHarian)); // Acak posisi makanannya
          _dailyProducts = _dailyProducts.take(15).toList(); // Maksimal nampilin 15 makanan biar ga kepanjangan

          // ─── 🟢 5. LEMPAR KE WADAH TAMPILAN ───
          _stores = List.from(_dailyStores);
          _products = List.from(_dailyProducts);

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetch store list: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterSearch(String query) {
    if (query.isEmpty) {
      // 🟢 Kalau search dihapus, balikin ke 5 toko & makanannya (sinkron)
      setState(() {
        _stores = List.from(_dailyStores);
        _products = List.from(_dailyProducts);
      });
      return;
    }

    final lowerQuery = query.toLowerCase();

    setState(() {
      // 🟢 Kalau user nyari, cari ke SELURUH Master Data (powerful)
      _products = _allProducts.where((product) {
        final productName = product['name'].toString().toLowerCase();
        final storeName = product['store'].toString().toLowerCase();
        return productName.contains(lowerQuery) || storeName.contains(lowerQuery);
      }).toList();

      _stores = _allStores.where((store) {
        final storeName = (store['nama_dapur'] ?? '').toString().toLowerCase();
        return storeName.contains(lowerQuery);
      }).toList();
    });
  }

  void _showProductDetail(BuildContext context, String foodId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: Supabase.instance.client
              .from('makanan')
              .select('*, dapur(nama_dapur, alamat_dapur)')
              .eq('id_makanan', foodId)
              .single(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            final product = snapshot.data!;
            final dapur = product['dapur'] as Map<String, dynamic>;
            final localProductData = _allProducts.firstWhere((p) => p['id'] == foodId, orElse: () => {});
            final distanceString = localProductData['distance'] ?? '- km';

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
                                child: Image.asset(
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
                                          Text(distanceString, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
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
                                  context.push(AppRoutes.orderDetail.replaceFirst(':orderId', foodId));
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 40,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
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
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFFF6B6B), size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _userAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => _filterSearch(value), 
                  decoration: InputDecoration(
                    hintText: 'Cari makanan, bahan makanan, toko',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    hintStyle: GoogleFonts.outfit(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              children: [
                if (_stores.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Toko Pilihanmu Hari Ini',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _stores.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final store = _stores[index];
                        return SizedBox(
                          width: 72, 
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B6B), 
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                store['nama_dapur'] ?? 'Toko',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Surplus Hari Ini',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                if (_products.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Belum ada surplus yang tersedia\natau makanan tidak ditemukan.', 
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: AppColors.textHint),
                    ),
                  ))
                else
                  ..._products.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: _SurplusCard(
                      product: p,
                      onTap: () => _showProductDetail(context, p['id']),
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
                onTap: () => context.go(AppRoutes.orderHistory),
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

class _SurplusCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap; 

  const _SurplusCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product['store'],
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFFFF6B6B)),
                        const SizedBox(width: 6),
                        Text(
                          product['distance'],
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/${product['image']}', 
                  width: 110,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110, height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp${_fmt(product['price'])}',
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
                      'Rp${_fmt(product['originalPrice'])}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 34,
                width: 90,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    'Pesan', 
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int price) => price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}