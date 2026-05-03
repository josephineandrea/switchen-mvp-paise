import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _userRole = 'consumer';

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      Map<String, dynamic> data;

      if (user != null && user.email != null) {
        data = await supabase
            .from('account')
            .select()
            .eq('email', user.email!)
            .single();
      } else {
        data = await supabase
            .from('account')
            .select()
            .eq('id_pelanggan', 1)
            .single();
      }

      setState(() {
        _userData = data;
        _userRole = data['role'] ?? 'consumer';
        _nameCtrl.text = data['nama_account'] ?? '';
        _phoneCtrl.text = data['no_hp'] ?? '';
        _addressCtrl.text = data['alamat'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetch profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profil',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              _buildEditField('Nama Lengkap', _nameCtrl, Icons.person_outline),
              const SizedBox(height: 16),
              _buildEditField('Nomor HP', _phoneCtrl, Icons.phone_android),
              const SizedBox(height: 16),
              _buildEditField('Alamat', _addressCtrl, Icons.location_on_outlined),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Simpan Perubahan',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateProfile() async {
    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('account').update({
        'nama_account': _nameCtrl.text.trim(),
        'no_hp': _phoneCtrl.text.trim(),
        'alamat': _addressCtrl.text.trim(),
      }).eq('id_pelanggan', _userData!['id_pelanggan']);

      await _fetchUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = _userData?['nama_account'] ?? 'Jane Doe';
    final email = _userData?['email'] ?? 'janedoe@email.com';
    final noHp = _userData?['no_hp'] ?? '-';
    final alamat = _userData?['alamat'] ?? 'Belum ada alamat';

    final avatarUrl =
        'https://ui-avatars.com/api/?name=${nama.replaceAll(' ', '+')}&background=00615F&color=fff&size=128&bold=true';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is AuthInitial) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 50),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 60,
                          bottom: 80,
                        ),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Profil Saya',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage(avatarUrl),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nama,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _showEditSheet,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(Icons.person, 'Nama Lengkap', nama),
                                const Divider(color: AppColors.divider, height: 1),
                                _buildInfoRow(Icons.email, 'Email', email),
                                const Divider(color: AppColors.divider, height: 1),
                                _buildInfoRow(Icons.phone, 'Nomor HP', noHp),
                                const Divider(color: AppColors.divider, height: 1),
                                _buildInfoRow(Icons.location_on, 'Alamat', alamat),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    title: Text('Konfirmasi',
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary)),
                                    content: Text('Yakin mau keluar dari akun ini?',
                                        style: GoogleFonts.outfit(
                                            color: AppColors.textSecondary)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => context.pop(),
                                        child: Text('Batal',
                                            style: GoogleFonts.outfit(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          context.pop();
                                          context
                                              .read<AuthBloc>()
                                              .add(const AuthSignOutRequested());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF6B6B),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: Text('Ya, Keluar',
                                            style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF0F0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.logout, color: Color(0xFFFF6B6B), size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Keluar Akun',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFF6B6B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _isLoading ? null : _buildBottomNav(context),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    if (_userRole == 'admin') return const SizedBox.shrink();

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
            children: _userRole == 'partner'
                ? [
                    _NavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      selected: false,
                      onTap: () => context.go(AppRoutes.partnerDashboard),
                    ),
                    _NavItem(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Tambah',
                      selected: false,
                      onTap: () => context.push(AppRoutes.partnerAddSurplus),
                    ),
                    _NavItem(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan QR',
                      selected: false,
                      onTap: () => context.push(AppRoutes.partnerScanCoupon),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      selected: true,
                      onTap: () {},
                    ),
                  ]
                : [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Beranda',
                      selected: false,
                      onTap: () => context.go(AppRoutes.home),
                    ),
                    _NavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Pesanan',
                      selected: false,
                      onTap: () => context.go(AppRoutes.orderHistory),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      selected: true,
                      onTap: () {},
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