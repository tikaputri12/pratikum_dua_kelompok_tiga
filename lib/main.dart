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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  Widget menuButton(String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(title),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            menuButton("Camera", const CameraExampleHome()),

            menuButton("Connectivity Plus", const ConnectivityPage()),

            menuButton("Geolocator", const GeolocatorWidget()),

            menuButton("Image Picker", const MyAppImage()),

            menuButton("Mobile_Scanner", const MobileScannerSimple()),
          ],
        ),
      ),
    );
  }
}
