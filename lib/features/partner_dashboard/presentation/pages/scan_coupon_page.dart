import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/constants/app_colors.dart';

class ScanCouponPage extends StatefulWidget {
  const ScanCouponPage({super.key});

  @override
  State<ScanCouponPage> createState() => _ScanCouponPageState();
}

class _ScanCouponPageState extends State<ScanCouponPage> {
  final _kodeCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isScannerActive = true;
  Map<String, dynamic>? _orderResult;
  String? _errorMessage;

  MobileScannerController scannerController = MobileScannerController();

  @override
  void dispose() {
    _kodeCtrl.dispose();
    scannerController.dispose();
    super.dispose();
  }

  Future<void> _cariPesanan(String kode) async {
    if (kode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _orderResult = null;
      _errorMessage = null;
      _isScannerActive = false; // Matikan scanner sementara saat memproses
    });

    try {
      final data = await Supabase.instance.client
          .from('pemesanan')
          .select('''
            id_pesanan, status_pesanan, jumlah_pesan, total_harga, kode_qr,
            makanan:id_makanan(nama_makanan),
            account:id_pelanggan(nama_account)
          ''')
          .eq('kode_qr', kode)
          .maybeSingle();

      if (data == null) {
        setState(() {
          _errorMessage = 'Kode QR tidak ditemukan.';
          _isScannerActive = true;
        });
      } else {
        setState(() => _orderResult = data);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan sistem.';
        _isScannerActive = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _konfirmasiPengambilan() async {
    if (_orderResult == null) return;
    final id = _orderResult!['id_pesanan'];

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('pemesanan')
          .update({'status_pesanan': 'Selesai'})
          .eq('id_pesanan', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan Berhasil Diselesaikan!'),
            backgroundColor: AppColors.primary,
          ),
        );
        setState(() {
          _orderResult = null;
          _kodeCtrl.clear();
          _isScannerActive = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan Kupon',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Arahkan kamera ke kode QR pembeli',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // --- AREA KAMERA SCANNER ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: _isScannerActive
                          ? MobileScanner(
                              controller: scannerController,
                              onDetect: (capture) {
                                final List<Barcode> barcodes = capture.barcodes;
                                for (final barcode in barcodes) {
                                  if (barcode.rawValue != null) {
                                    _cariPesanan(barcode.rawValue!);
                                    break;
                                  }
                                }
                              },
                            )
                          : Container(
                              color: Colors.black87,
                              child: const Center(
                                child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 50),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Manual input (Tetap ada sebagai cadangan)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _kodeCtrl,
                          decoration: InputDecoration(
                            hintText: 'Atau masukkan kode manual...',
                            hintStyle: GoogleFonts.outfit(fontSize: 13),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.1)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _cariPesanan(_kodeCtrl.text.trim()),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(_errorMessage!, style: GoogleFonts.outfit(color: Colors.red, fontSize: 13)),
                    ),

                  if (_orderResult != null) _buildResultCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _resRow('Pembeli', _orderResult!['account']?['nama_account'] ?? '-'),
          _resRow('Menu', _orderResult!['makanan']?['nama_makanan'] ?? '-'),
          _resRow('Jumlah', '${_orderResult!['jumlah_pesan']} porsi'),
          _resRow('Total', 'Rp${_orderResult!['total_harga']}'),
          const Divider(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _konfirmasiPengambilan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Konfirmasi Selesai', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _isScannerActive = true),
            child: const Text('Scan Ulang'),
          )
        ],
      ),
    );
  }

  Widget _resRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
          Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}