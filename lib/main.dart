import 'package:flutter/material.dart';
import 'package:pratikum_dua_kelompok_tiga/camera.dart' show CameraExampleHome;
import 'package:pratikum_dua_kelompok_tiga/connectivity_plus.dart'
    show ConnectivityPage;
import 'package:pratikum_dua_kelompok_tiga/geolocator.dart'
    show GeolocatorWidget;
import 'package:pratikum_dua_kelompok_tiga/image_picker.dart' show MyAppImage;
import 'package:pratikum_dua_kelompok_tiga/mobile_scanner.dart' show MobileScannerSimple;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum Plugin Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: 
        const Color.from(alpha: 1, red: 0.816, green: 0.851, blue: 0.969)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Menu Praktikum Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Map<String, dynamic>> _menus = [
    {
      'title': 'Camera',
      'icon': Icons.camera_alt_rounded,
      'color': const Color(0xff7B1FA2),
      'page': const CameraExampleHome(),
    },
    {
      'title': 'Connectivity Plus',
      'icon': Icons.wifi_rounded,
      'color': const Color(0xff1565C0),
      'page': const ConnectivityPage(),
    },
    {
      'title': 'Geolocator',
      'icon': Icons.location_on_rounded,
      'color': const Color(0xff2E7D32),
      'page': const GeolocatorWidget(),
    },
    {
      'title': 'Image Picker',
      'icon': Icons.image_rounded,
      'color': const Color(0xffE65100),
      'page': const MyAppImage(),
    },
    {
      'title': 'Mobile Scanner',
      'icon': Icons.qr_code_scanner_rounded,
      'color': const Color(0xff00838F),
      'page': const MobileScannerSimple(),
    },
  ];

  Widget _menuCard(Map<String, dynamic> menu) {
    final Color color = menu['color'] as Color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => menu['page'] as Widget),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      menu['icon'] as IconData,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      menu['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 243, 121, 237), Color.fromARGB(255, 190, 61, 230)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Praktikum',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plugin Flutter 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pilih menu di bawah untuk memulai',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffF3E5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menu Utama',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 61, 58, 60),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            children: _menus
                                .map((menu) => _menuCard(menu))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}