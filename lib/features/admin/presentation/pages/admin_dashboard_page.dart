import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;
  Map<String, int> _stats = {
    'pending_mitra': 0,
    'pending_menu': 0,
    'total_mitra': 0,
    'total_makanan': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final pendingMitra = await client
          .from('permintaan_mitra')
          .select('id_permintaan')
          .eq('status', 'pending');
      final pendingMenu = await client
          .from('permintaan_makanan')
          .select('id_permintaan')
          .eq('status', 'pending');
      final totalMitra = await client.from('dapur').select('id_dapur');
      final totalMakanan = await client.from('makanan').select('id_makanan');

      setState(() {
        _stats = {
          'pending_mitra': (pendingMitra as List).length,
          'pending_menu': (pendingMenu as List).length,
          'total_mitra': (totalMitra as List).length,
          'total_makanan': (totalMakanan as List).length,
        };
      });
    } catch (e) {
      debugPrint('[Admin] Error load stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String adminName = 'Admin';
    if (authState is AuthAuthenticated) {
      adminName = authState.user.fullName.split(' ').first;
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is AuthInitial) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _loadStats,
          color: const Color(0xFF1E3A5F),
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
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
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 24,
                      right: 24,
                      bottom: 28,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.admin_panel_settings, color: Colors.white, size: 12),
                                      const SizedBox(width: 6),
                                      Text('ADMIN SWITCHEN',
                                          style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Hei, $adminName! 👋',
                                    style: GoogleFonts.outfit(
                                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                                Text('Pantau & kelola ekosistem Switchen',
                                    style: GoogleFonts.outfit(
                                        fontSize: 13, color: Colors.white.withOpacity(0.75))),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Stats cards
                        _isLoading
                            ? const Center(
                                child: SizedBox(
                                    height: 60,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                            : Row(
                                children: [
                                  _HeaderStat(
                                    label: 'Menunggu\nPersetujuan Toko',
                                    value: '${_stats['pending_mitra']}',
                                    color: const Color(0xFFFBBF24),
                                  ),
                                  const SizedBox(width: 10),
                                  _HeaderStat(
                                    label: 'Menunggu\nPersetujuan Menu',
                                    value: '${_stats['pending_menu']}',
                                    color: const Color(0xFF60A5FA),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Quick Access Menu
                    Text('Aksi Cepat',
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _AdminMenuCard(
                          icon: Icons.storefront_outlined,
                          title: 'Permintaan Toko',
                          subtitle: '${_stats['pending_mitra']} menunggu',
                          color: const Color(0xFF1E3A5F),
                          badgeCount: _stats['pending_mitra'] ?? 0,
                          onTap: () => context.push(AppRoutes.adminApprovalMitra).then((_) => _loadStats()),
                        ),
                        _AdminMenuCard(
                          icon: Icons.fastfood_outlined,
                          title: 'Permintaan Menu',
                          subtitle: '${_stats['pending_menu']} menunggu',
                          color: const Color(0xFF065F46),
                          badgeCount: _stats['pending_menu'] ?? 0,
                          onTap: () => context.push(AppRoutes.adminApprovalMenu).then((_) => _loadStats()),
                        ),
                        _AdminMenuCard(
                          icon: Icons.menu_book_outlined,
                          title: 'Katalog Menu',
                          subtitle: '${_stats['total_makanan']} item aktif',
                          color: const Color(0xFF4C1D95),
                          badgeCount: 0,
                          onTap: () => context.push(AppRoutes.adminKatalog),
                        ),
                        _AdminMenuCard(
                          icon: Icons.people_outline,
                          title: 'Mitra Aktif',
                          subtitle: '${_stats['total_mitra']} toko bergabung',
                          color: const Color(0xFF7C2D12),
                          badgeCount: 0,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Summary info
                    Text('Ringkasan Hari Ini',
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      icon: Icons.store,
                      color: const Color(0xFF1E3A5F),
                      title: 'Mitra Terdaftar',
                      value: '${_stats['total_mitra']} Toko',
                      subtitle: 'Total toko aktif di Switchen',
                    ),
                    const SizedBox(height: 10),
                    _SummaryCard(
                      icon: Icons.set_meal,
                      color: const Color(0xFF065F46),
                      title: 'Menu Tersedia',
                      value: '${_stats['total_makanan']} Item',
                      subtitle: 'Total item makanan aktif',
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AdminNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                selected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _AdminNavItem(
                icon: Icons.storefront_rounded,
                label: 'Toko',
                selected: _currentIndex == 1,
                badge: (_stats['pending_mitra'] ?? 0) > 0,
                onTap: () {
                  setState(() => _currentIndex = 1);
                  context.push(AppRoutes.adminApprovalMitra).then((_) {
                    setState(() => _currentIndex = 0);
                    _loadStats();
                  });
                },
              ),
              _AdminNavItem(
                icon: Icons.fastfood_rounded,
                label: 'Menu',
                selected: _currentIndex == 2,
                badge: (_stats['pending_menu'] ?? 0) > 0,
                onTap: () {
                  setState(() => _currentIndex = 2);
                  context.push(AppRoutes.adminApprovalMenu).then((_) {
                    setState(() => _currentIndex = 0);
                    _loadStats();
                  });
                },
              ),
              _AdminNavItem(
                icon: Icons.menu_book_rounded,
                label: 'Katalog',
                selected: _currentIndex == 3,
                onTap: () {
                  setState(() => _currentIndex = 3);
                  context.push(AppRoutes.adminKatalog).then((_) {
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

// ── Widgets ──────────────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: GoogleFonts.outfit(
                          fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(label,
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: Colors.white.withOpacity(0.75), height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
                const Spacer(),
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(subtitle,
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withOpacity(0.7))),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$badgeCount',
                      style: GoogleFonts.outfit(
                          fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.badge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1E3A5F);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(icon, color: selected ? activeColor : AppColors.textHint, size: 26),
              if (badge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? activeColor : AppColors.textHint)),
        ],
      ),
    );
  }
}
