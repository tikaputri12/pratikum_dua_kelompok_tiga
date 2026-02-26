import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ── Warna tema baby pink ──────────────────────────────────────────────────────
const _pink = Color(0xFFFFB6C1); // baby pink
const _pinkDark = Color(0xFFF48FB1); // pink sedikit lebih gelap
const _pinkLight = Color(0xFFFCE4EC); // pink sangat muda
const _pinkOverlay = Color(0xCCF8BBD0); // overlay transparan

// ── Simple Scanner ────────────────────────────────────────────────────────────
class MobileScannerSimple extends StatefulWidget {
  const MobileScannerSimple({super.key});

  @override
  State<MobileScannerSimple> createState() => _MobileScannerSimpleState();
}

class _MobileScannerSimpleState extends State<MobileScannerSimple> {
  Barcode? _barcode;
  bool _torchOn = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
  }

  Widget _barcodePreview(Barcode? value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          value == null ? Icons.qr_code_scanner : Icons.check_circle_outline,
          color: value == null ? Colors.white70 : Colors.white,
          size: 28,
        ),
        const SizedBox(height: 6),
        Text(
          value == null
              ? 'Arahkan kamera ke barcode / QR code'
              : (value.displayValue ?? 'Tidak ada nilai'),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Sederhana'),
        backgroundColor: _pinkDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Tombol torch / flash
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Nyalakan/Matikan Flash',
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _controller.toggleTorch();
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera
          MobileScanner(controller: _controller, onDetect: _handleBarcode),

          // Kotak bidik di tengah
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: _pink, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Panel hasil scan di bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: _pinkOverlay,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _barcodePreview(_barcode),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Home ─────────────────────────────────────────────────────────────────────
class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  Widget _buildItem(
    BuildContext context,
    String label,
    String subtitle,
    Widget page,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        unawaited(
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => page)),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _pinkLight,
                radius: 28,
                child: Icon(icon, size: 28, color: _pinkDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: _pinkDark, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Header bergradasi baby pink
      appBar: AppBar(
        title: const Text(
          'Mobile Scanner 🌸',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_pinkDark, _pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_pinkLight, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Banner kecil di atas
            Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: _pink.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFF880E4F)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih mode scanner di bawah ini.',
                      style: TextStyle(
                        color: Color(0xFF880E4F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Daftar menu
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildItem(
                    context,
                    'Scanner Sederhana',
                    'Scanner dasar tanpa controller, mudah digunakan.',
                    const MobileScannerSimple(),
                    Icons.qr_code_scanner,
                  ),
                  _buildItem(
                    context,
                    'Scanner Lanjutan',
                    'Scanner dengan controller lengkap dan berbagai kontrol.',
                    const MobileScanner(),
                    Icons.settings_remote,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Entry point ───────────────────────────────────────────────────────────────
void main() {
  runApp(
    MaterialApp(
      title: 'Mobile Scanner 🌸',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _pink),
        useMaterial3: true,
      ),
      home: const ExampleHome(),
    ),
  );
}


