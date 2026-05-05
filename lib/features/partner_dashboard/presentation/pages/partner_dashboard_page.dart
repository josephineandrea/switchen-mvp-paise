import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class PartnerDashboardPage extends StatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  int _currentIndex = 0;
  Map<String, dynamic>? _dapur;
  List<Map<String, dynamic>> _makananList = [];
  List<Map<String, dynamic>> _pesananHariIni = [];
  bool _isLoading = true;
  bool _hasStore = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final userEmail = authState.user.email;

      // Ambil id_pelanggan dari tabel account berdasarkan email
      final accountData = await client
          .from('account')
          .select('id_pelanggan')
          .eq('email', userEmail)
          .maybeSingle();

      if (accountData == null) {
        debugPrint('[Partner] Akun tidak ditemukan di tabel account: $userEmail');
        _hasStore = false;
        return; // finally tetap berjalan
      }

      final partnerId = accountData['id_pelanggan'];
      debugPrint('[Partner] partnerId: $partnerId');

      // Cek apakah sudah punya toko
      final dapurData = await client
          .from('dapur')
          .select()
          .eq('id_pelanggan', partnerId)
          .maybeSingle();

      debugPrint('[Partner] dapurData: $dapurData');

      if (dapurData != null) {
        _dapur = dapurData;
        _hasStore = true;
        final idDapur = dapurData['id_dapur'];

        // Load makanan
        final makanan = await client
            .from('makanan')
            .select()
            .eq('id_dapur', idDapur)
            .order('created_at', ascending: false);
        _makananList = List<Map<String, dynamic>>.from(makanan);
        debugPrint('[Partner] Makanan loaded: ${_makananList.length}');

        // Load pesanan hari ini
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
        final pesanan = await client
            .from('pemesanan')
            .select('''
              id_pesanan, status_pesanan, jumlah_pesan, total_harga, tanggal_pesan,
              makanan:id_makanan(nama_makanan, id_dapur)
            ''')
            .gte('tanggal_pesan', startOfDay)
            .order('tanggal_pesan', ascending: false);

        _pesananHariIni = List<Map<String, dynamic>>.from(pesanan)
            .where((p) => p['makanan']?['id_dapur'] == idDapur)
            .toList();
        debugPrint('[Partner] Pesanan hari ini: ${_pesananHariIni.length}');
      } else {
        _hasStore = false;
        debugPrint('[Partner] Belum punya toko, tampilkan onboarding.');
      }
    } catch (e, st) {
      debugPrint('[Partner] Error _loadData: $e\n$st');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Mitra';
    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName.split(' ').first;
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is AuthInitial) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _buildBody(userName),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBody(String userName) {
    final storeName = _dapur?['nama_dapur'] ?? 'Toko Anda';

    return Stack(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: Container(
            height: MediaQuery.of(context).padding.top + 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard Mitra F\u0026B',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.white.withOpacity(0.8)),
                        ),
                        Text(
                          storeName,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Hei, $userName! 👋',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showTokoInfo,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Body ────────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 150),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : !_hasStore
                  ? _buildOnboardingPrompt()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats row (pindah dari header ke body)
                            if (_hasStore)
                              Row(
                                children: [
                                  Expanded(
                                    child: _BodyStatChip(
                                      label: 'Produk Aktif',
                                      value: '${_makananList.length}',
                                      icon: Icons.fastfood_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _BodyStatChip(
                                      label: 'Pesanan Hari Ini',
                                      value: '${_pesananHariIni.length}',
                                      icon: Icons.receipt_long_outlined,
                                      color: const Color(0xFF60A5FA),
                                    ),
                                  ),
                                ],
                              ),
                            if (_hasStore) const SizedBox(height: 16),

                            // Quick Actions
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickActionButton(
                                    icon: Icons.add_circle_outline,
                                    label: 'Tambah\nSurplus',
                                    color: AppColors.primary,
                                    onTap: () => context.push(AppRoutes.partnerAddSurplus).then((_) => _loadData()),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionButton(
                                    icon: Icons.qr_code_scanner,
                                    label: 'Scan\nKupon',
                                    color: const Color(0xFF60A5FA),
                                    onTap: () => context.push(AppRoutes.partnerScanCoupon),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionButton(
                                    icon: Icons.storefront_outlined,
                                    label: 'Info\nToko',
                                    color: const Color(0xFFFBBF24),
                                    onTap: () => _showTokoInfo(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Pesanan Masuk
                            if (_pesananHariIni.isNotEmpty) ...[
                              _SectionHeader(
                                title: 'Pesanan Hari Ini',
                                onSeeAll: null,
                              ),
                              const SizedBox(height: 8),
                              ..._pesananHariIni.take(3).map((p) => _PesananCard(pesanan: p)),
                              const SizedBox(height: 24),
                            ],

                            // Daftar Makanan
                            _SectionHeader(
                              title: 'Makanan Surplus Aktif',
                              onSeeAll: null,
                            ),
                            const SizedBox(height: 8),
                            if (_makananList.isEmpty)
                              _buildEmptyState(
                                'Belum ada makanan',
                                'Tambahkan stok surplus makananmu sekarang!',
                                Icons.fastfood_outlined,
                              )
                            else
                              ..._makananList.map((m) => _MakananCard(
                                    makanan: m,
                                    onRefresh: _loadData,
                                  )),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildOnboardingPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Tokomu Belum Terdaftar',
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Daftarkan restoran atau toko F&B-mu ke Switchen untuk mulai berjualan surplus makanan.',
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.partnerOnboarding).then((_) => _loadData()),
                icon: const Icon(Icons.storefront),
                label: Text('Daftarkan Toko Sekarang',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(subtitle,
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showTokoInfo() {
    if (_dapur == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('Info Toko',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 16),
            _infoRow(Icons.storefront, 'Nama Toko', _dapur!['nama_dapur'] ?? '-'),
            _infoRow(Icons.phone, 'Telepon', _dapur!['telp_dapur'] ?? '-'),
            _infoRow(Icons.location_on, 'Alamat', _dapur!['alamat_dapur'] ?? '-'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                selected: _currentIndex == 0,
                onTap: () {
                  setState(() => _currentIndex = 0);
                  // Sudah di dashboard, tidak perlu navigate
                },
              ),
              _NavItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'Tambah',
                selected: _currentIndex == 1,
                onTap: () {
                  setState(() => _currentIndex = 1);
                  context.push(AppRoutes.partnerAddSurplus).then((_) {
                    setState(() => _currentIndex = 0);
                    _loadData();
                  });
                },
              ),
              _NavItem(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                selected: _currentIndex == 2,
                onTap: () {
                  setState(() => _currentIndex = 2);
                  context.push(AppRoutes.partnerScanCoupon).then((_) {
                    setState(() => _currentIndex = 0);
                  });
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                selected: _currentIndex == 3,
                onTap: () {
                  setState(() => _currentIndex = 3);
                  context.push(AppRoutes.profile).then((_) {
                    setState(() => _currentIndex = 0);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _BodyStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BodyStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text('Lihat Semua',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
          ),
      ],
    );
  }
}

class _PesananCard extends StatelessWidget {
  final Map<String, dynamic> pesanan;

  const _PesananCard({required this.pesanan});

  Color _statusColor(String status) {
    switch (status) {
      case 'Selesai': return Colors.green;
      case 'Menunggu Diambil': return Colors.orange;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = pesanan['status_pesanan'] ?? '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pesanan['makanan']?['nama_makanan'] ?? 'Makanan',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${pesanan['jumlah_pesan']} porsi · Rp${pesanan['total_harga']}',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: GoogleFonts.outfit(
                    fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status))),
          ),
        ],
      ),
    );
  }
}

class _MakananCard extends StatelessWidget {
  final Map<String, dynamic> makanan;
  final VoidCallback onRefresh;

  const _MakananCard({required this.makanan, required this.onRefresh});

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final stok = makanan['stok'] ?? 0;
    final stokColor = stok == 0 ? Colors.red : stok <= 2 ? Colors.orange : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: GestureDetector(
        onTap: () => context.push(
          AppRoutes.partnerEditProduct.replaceFirst(':productId', '${makanan['id_makanan']}'),
        ).then((refreshed) {
          if (refreshed == true) onRefresh();
        }),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (makanan['img_url'] != null && makanan['img_url'].toString().startsWith('http'))
                  ? Image.network(makanan['img_url']!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.surfaceVariant, child: const Icon(Icons.fastfood, color: AppColors.textHint)))
                  : (makanan['img_url'] != null)
                      ? Image.asset('assets/images/${makanan['img_url']}', width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.surfaceVariant, child: const Icon(Icons.fastfood, color: AppColors.textHint)))
                      : Container(
                          width: 56, height: 56,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.fastfood, color: AppColors.textHint)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(makanan['nama_makanan'] ?? '-',
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Rp${_formatPrice(makanan['harga_diskon'] ?? 0)}',
                          style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(width: 6),
                      Text('Rp${_formatPrice(makanan['harga_asli'] ?? 0)}',
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Builder(builder: (ctx) {
                    final asli = (makanan['harga_asli'] as num?)?.toInt() ?? 0;
                    final diskon = (makanan['harga_diskon'] as num?)?.toInt() ?? 0;
                    final persen = asli > 0 ? (((asli - diskon) / asli) * 100).round() : 0;
                    return persen > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Hemat $persen%',
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red.shade700)),
                          )
                        : const SizedBox();
                  }),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: stokColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Sisa: $stok',
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.w700, color: stokColor)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.edit_outlined, size: 16, color: AppColors.textHint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton(
      {required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color, height: 1.2)),
          ],
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

  const _NavItem(
      {required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.textHint, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textHint)),
        ],
      ),
    );
  }
}
