import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

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

  int get _total => 10000 * _qty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rincian Pesanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Detail Item ──────────────────────────────────────
            const _SectionTitle('Detail Item'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=200&q=80',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70, height: 70,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.fastfood, color: AppColors.textHint),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Butter Croissant',
                          style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.storefront_outlined, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Toko Roti Braga',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Jumlah',
                                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                            Row(children: [
                              _QtyBtn(
                                icon: Icons.remove_circle_outline,
                                onTap: () {
                                  if (_qty > 1) setState(() => _qty--);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('$_qty',
                                    style: GoogleFonts.outfit(
                                        fontSize: 15, fontWeight: FontWeight.w700)),
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

            const SizedBox(height: 20),

            // ── Informasi Pengambilan ────────────────────────────
            const _SectionTitle('Informasi Pengambilan'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: const Column(
                children: [
                  _InfoRow(
                    icon: Icons.access_time,
                    iconColor: AppColors.accent,
                    label: 'Waktu Ambil (Self-Pickup)',
                    value: 'Hari ini, 18.00 - 20.00 WIB',
                  ),
                  Divider(color: AppColors.divider, height: 20),
                  _InfoRow(
                    icon: Icons.location_on,
                    iconColor: AppColors.accent,
                    label: 'Lokasi Toko',
                    value: 'Toko Roti Braga\nJl. Braga No. 99, Bandung (0.5 km)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Metode Pembayaran ────────────────────────────────
            const _SectionTitle('Pilih Metode Pembayaran'),
            const SizedBox(height: 12),
            Container(
              decoration: _cardDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPayment,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Pilih metode pembayaran',
                        style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 14)),
                  ),
                  isExpanded: true,
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  ),
                  items: _paymentMethods
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(m, style: GoogleFonts.outfit(fontSize: 14)),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPayment = v),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Rincian Pembayaran ───────────────────────────────
            const _SectionTitle('Rincian Pembayaran'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _PayRow(
                    label: 'Metode Pembayaran',
                    value: _selectedPayment ?? '-',
                  ),
                  const SizedBox(height: 8),
                  _PayRow(
                    label: 'Butter Croissant (x$_qty)',
                    value: 'Rp${_formatPrice(_total)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Bottom Confirm Bar ───────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20, 14, 20,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Konfirmasi Pesanan',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              'Rp${_formatPrice(_total)}',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  String _formatPrice(int price) => price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.discountBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
          Text(label,
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
        child: Icon(icon, color: AppColors.primary, size: 24),
      );
}
