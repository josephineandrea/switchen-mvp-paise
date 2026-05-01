import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderCheckoutPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderCheckoutPage({super.key, required this.orderData});

  @override
  State<OrderCheckoutPage> createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  String? paymentData; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _prosesPembayaran();
  }

  Future<void> _prosesPembayaran() async {
    final String metode = widget.orderData['metode_pembayaran'] ?? 'QRIS';
    bool isTransferBank = metode == 'Transfer Bank';

    if (isTransferBank) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          paymentData = "8801234567890123";
          isLoading = false;
        });
      }
    } else {
      const secretKey = 'xnd_development_AkFbGcvP7NCZHQqG44Jqycs0fez2IdioTQGb2HOw7Z7nTrDpQpHg2mo9fLvIQYc';
      final base64Key = base64Encode(utf8.encode('$secretKey:'));

      final url = Uri.parse('https://api.xendit.co/qr_codes');
      final body = jsonEncode({
        "reference_id": "SWITCHEN-${DateTime.now().millisecondsSinceEpoch}",
        "type": "DYNAMIC",
        "currency": "IDR",
        "amount": widget.orderData['total_harga'] ?? 10000,
      });

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Basic $base64Key',
            'api-version': '2022-07-31',
          },
          body: body,
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            setState(() {
              paymentData = data['qr_string']; 
              isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Future<void> _simpanKeDatabase() async {
    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final String userId = supabase.auth.currentUser?.id ?? '1';

      final now = DateTime.now();
      final String formattedDate = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      final String uniqueId = now.millisecondsSinceEpoch.toString().characters.takeLast(3).toString();
      final String customOrderCode = "SW-$formattedDate-$uniqueId";

      final List<Map<String, dynamic>> response = await supabase.from('pemesanan').insert({
        'id_makanan': widget.orderData['id_makanan'] ?? 0,
        'id_pelanggan': userId, 
        'jumlah_pesan': widget.orderData['jumlah_pesan'] ?? 1,
        'total_harga': widget.orderData['total_harga'] ?? 0,
        'status_pesanan': 'Siap Diambil',
        'metode_pembayaran': widget.orderData['metode_pembayaran'] ?? 'Transfer Bank',
        'tanggal_pesan': now.toIso8601String(),
        'kode_qr': customOrderCode, 
      }).select();

      if (response.isNotEmpty) {
        final int newId = response.first['id_pesanan']; 
        await supabase.from('pembayaran').insert({
          'id_pesanan': newId, 
          'status_pembayaran': 'Berhasil',
          'total_bayar': widget.orderData['total_harga'] ?? 0,
        });
        final String formattedOrderId = "PSN-${newId.toString().padLeft(6, '0')}";

        if (mounted) {
          context.push(AppRoutes.orderSuccess, extra: formattedOrderId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String metode = widget.orderData['metode_pembayaran'] ?? 'QRIS';
    bool isTransferBank = metode == 'Transfer Bank';

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
                  'Pembayaran $metode',
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
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : paymentData != null
                      ? SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isTransferBank ? 'Transfer ke Virtual Account' : 'Scan untuk Membayar',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Switchen - ${widget.orderData['nama_makanan']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 32),

                              Container(
                                padding: const EdgeInsets.all(32),
                                margin: const EdgeInsets.symmetric(horizontal: 40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: isTransferBank
                                    ? _buildVirtualAccountUI(context)
                                    : _buildQrUI(),
                              ),

                              const SizedBox(height: 48),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: isLoading ? null : _simpanKeDatabase,
                                  child: Container(
                                    height: 56,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Simulasi Pembayaran Berhasil',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        )
                      : const Text('Gagal memuat pembayaran. Coba lagi.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualAccountUI(BuildContext context) {
    return Column(
      children: [
        Image.network(
          'https://1.bp.blogspot.com/-1wO_xK-8x9Y/YOc0oX9m61I/AAAAAAAAHTo/6U_MhI6rQ1k9-1n-U20d91oVjV8B1P_xQCLcBGAsYHQ/s16000/bca.png',
          height: 30,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.account_balance, 
              size: 36, 
              color: Color(0xFF00615F), 
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Nomor Virtual Account',
          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              paymentData!, 
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: paymentData!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nomor disalin!')),
                );
              },
              child: const Icon(Icons.copy, color: AppColors.primary, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Total: Rp${_formatPrice(widget.orderData['total_harga'] ?? 0)}',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrUI() {
    return QrImageView(
      data: paymentData!,
      version: QrVersions.auto,
      size: 200.0,
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}