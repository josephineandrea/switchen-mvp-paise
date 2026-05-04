import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  int _qty = 1;
  String? _selectedPayment;
  final List<String> _paymentMethods = ['QRIS', 'Transfer Bank', 'OVO', 'GoPay'];

  Map<String, dynamic>? _foodData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('makanan')
          .select('*, dapur(nama_dapur, alamat_dapur, jarak_dummy)')
          .eq('id_makanan', widget.orderId)
          .single();
      
      setState(() {
        _foodData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_foodData == null) {
      return const Scaffold(body: Center(child: Text('Gagal memuat detail makanan')));
    }

    final data = _foodData!;
    final harga = (data['harga_diskon'] as num).toInt();
    final totalHarga = harga * _qty;
    final dapur = data['dapur'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 45,
              bottom: 30,
              left: 8,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 4),
                Text(
                  'Rincian Pesanan',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle('Detail Item'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (data['img_url'] != null && data['img_url'].toString().startsWith('http'))
                              ? Image.network(
                                  data['img_url'],
                                  width: 80, height: 80, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80, height: 80, color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/${data['img_url']}',
                                  width: 80, height: 80, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80, height: 80, color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['nama_makanan'] ?? 'Tanpa Nama',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.storefront_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(dapur['nama_dapur'] ?? 'Toko',
                                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                              ]),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Jumlah', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  Row(children: [
                                    _QtyBtn(
                                      icon: Icons.remove_circle_outline,
                                      onTap: () { if (_qty > 1) setState(() => _qty--); },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Text('$_qty', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                    ),
                                    _QtyBtn(
                                      icon: Icons.add_circle_outline,
                                      onTap: () => setState(() => _qty++),
                                    ),
                                  ]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _SectionTitle('Informasi Pengambilan'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        const _InfoRow(
                          icon: Icons.access_time, 
                          title: 'Waktu Ambil (Self-Pickup)', 
                          valueBold: 'Hari ini, 18.00 - 20.00 WIB'
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.location_on, 
                          title: 'Lokasi Toko', 
                          valueBold: dapur['nama_dapur'] ?? 'Toko',
                          valueLight: '${dapur['alamat_dapur'] ?? ''} (${dapur['jarak_dummy'] ?? '0.5'} km)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _SectionTitle('Pilih Metode Pembayaran'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: _cardDecoration(),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPayment,
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        ),
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16), 
                          child: Text('Pilih metode pembayaran', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                        ),
                        isExpanded: true,
                        items: _paymentMethods.map((m) => DropdownMenuItem(value: m, 
                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(m, style: GoogleFonts.outfit(fontSize: 14))))).toList(),
                        onChanged: (v) => setState(() => _selectedPayment = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _SectionTitle('Rincian Pembayaran'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _PayRow(label: 'Metode Pembayaran', value: _selectedPayment ?? '-'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: _DashedDivider(),
                        ),
                        _PayRow(label: '${data['nama_makanan']} ( x$_qty )', value: 'Rp${_formatPrice(totalHarga)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 20),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            if (_selectedPayment == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih metode pembayaran dulu!')));
            } else {
              context.push(AppRoutes.orderCheckout, extra: {
                'id_makanan': widget.orderId,
                'nama_makanan': data['nama_makanan'],
                'nama_toko': dapur['nama_dapur'],
                'jumlah_pesan': _qty,
                'total_harga': totalHarga,
                'metode_pembayaran': _selectedPayment,
              });
            }
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Konfirmasi Pesanan', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                Text('Rp${_formatPrice(totalHarga)}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      );

  String _formatPrice(int price) => price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueBold;
  final String? valueLight;

  const _InfoRow({required this.icon, required this.title, required this.valueBold, this.valueLight});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFFF6B6B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(valueBold, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (valueLight != null) ...[
                  const SizedBox(height: 4),
                  Text(valueLight!, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                ]
              ],
            ),
          ),
        ],
      );
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  const _PayRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: AppColors.primary, size: 20),
      );
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: const DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE0E0E0))),
            );
          }),
        );
      },
    );
  }
}