// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'exam_webview.dart'; // pastikan file ini ada untuk ExamWebView
import 'kiosk_mode.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  String _timeString = "";
  String _dateString = "";
  Timer? _timer;
  int _selectedIndex = 0;

  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateDateTime(),
    );
    _loadSavedUrl();

    // Mulai Kiosk Mode saat halaman muncul
    KioskMode.start();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.8,
      upperBound: 1.0,
      value: 1.0,
    );
    _fabScale = CurvedAnimation(parent: _fabController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _linkController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _updateDateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _timeString = DateFormat("HH:mm").format(now);
        _dateString = DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(now);
      });
    }
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString('exam_url');
    if (savedUrl != null) {
      _linkController.text = savedUrl;
    }
  }

  Future<void> _saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_url', url);
  }

  void _openWeb(String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link ujian tidak boleh kosong!")),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format link tidak valid!")),
      );
      return;
    }

    _saveUrl(url);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExamWebView(url: url)),
    );
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Konfirmasi"),
            content: const Text("Apakah Anda yakin ingin keluar aplikasi?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Tidak")),
              TextButton(
                  onPressed: () {
                    // Stop Kiosk Mode sebelum keluar aplikasi
                    KioskMode.stop();
                    if (Platform.isAndroid || Platform.isIOS) {
                      SystemNavigator.pop();
                    } else {
                      exit(0);
                    }
                  },
                  child: const Text("Ya")),
            ],
          ),
        ) ??
        false;
  }

  void _showPanduanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Panduan"),
        content: const SingleChildScrollView(
          child: Text(
            "1. Berdoa Sebelum memulai Ujian\n"
            "2. Pastikan Sudah terkoneksi Wifi Madrasah\n"
            "3. Pastikan Batrey Smartphone masih tersisa 60%\n"
            "4. Matikan Rotasi pada Smartphone\n"
            "5. Matikan pengaturan layar otomatis gelap\n"
            "6. Akan terjadi pelanggaran jika keluar dari aplikasi ujian\n"
            "7. Tombol keluar aplikasi dipojok kanan atas",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MlkitQrScanner()),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        double scale = 1.0;
        Color bgColor = Colors.teal;

        return GestureDetector(
          onTapDown: (_) {
            setState(() {
              scale = 0.85; // lebih kecil saat ditekan
              bgColor = Colors.blue.shade700; // lebih gelap
            });
          },
          onTapUp: (_) {
            setState(() {
              scale = 1.0; // balik normal
              bgColor = Colors.blue;
            });
            Future.delayed(const Duration(milliseconds: 150), onTap);
          },
          onTapCancel: () {
            setState(() {
              scale = 1.0;
              bgColor = Colors.blue;
            });
          },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut, // bounce effect
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: bgColor,
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showExitDialog,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // HEADER
            Stack(
              children: [
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/background_menu.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 70, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Selamat Datang",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      // const Text("Selamat Pagi",
                      //     style: TextStyle(
                      //         fontSize: 20,
                      //         color: Colors.purple,
                      //         fontWeight: FontWeight.bold)),
                      // const SizedBox(height: 4),
                      const Text("PESERTA UJIAN BERBASIS ANDROID",
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Center(
                        child: Column(
                          children: [
                            Text(_timeString,
                                style: const TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal)),
                            Text(_dateString,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // KONTEN
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 50),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Image.asset("assets/exam_home.png",
                          width: 200, height: 200, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _linkController,
                        decoration: InputDecoration(
                          hintText: "Link Ujian https://.....",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol MULAI
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizeTransition(
                        sizeFactor: _fabScale,
                        axisAlignment: -1,
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _openWeb(_linkController.text),
                            child: const Text(
                              "MULAI",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Menu 5 Bulatan
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCircleButton(
                            icon: Icons.star_rate,
                            label: "Rate",
                            onTap: () => launchUrl(
                              Uri.parse(
                                  "https://play.google.com/store/apps/details?id=com.beetechmedia.flutterexambro"),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                          _buildCircleButton(
                            icon: Icons.share,
                            label: "Share",
                            onTap: () => Share.share(
                                "Coba aplikasi ini: https://play.google.com/store/apps/details?id=com.beetechmedia.flutterexambro"),
                          ),
                          _buildCircleButton(
                            icon: Icons.menu_book,
                            label: "Panduan",
                            onTap: _showPanduanDialog,
                          ),
                          _buildCircleButton(
                            icon: Icons.qr_code_scanner,
                            label: "QR-Code",
                            onTap: _openQrScanner,
                          ),
                          _buildCircleButton(
                            icon: Icons.exit_to_app,
                            label: "Keluar",
                            onTap: () => _showExitDialog(),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),

            // Footer Versi
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  "Version : f.25002",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MlkitQrScanner extends StatefulWidget {
  const MlkitQrScanner({Key? key}) : super(key: key);

  @override
  State<MlkitQrScanner> createState() => _MlkitQrScannerState();
}

class _MlkitQrScannerState extends State<MlkitQrScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isDetected = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isDetected) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _isDetected = true;

        if (mounted) {
          Navigator.pop(context); // keluar dari scanner
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExamWebView(url: rawValue),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bee Exambro QRScanner"), backgroundColor: Colors.teal),
      body: Stack(
        children: [
          /// kamera scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          /// kotak panduan scan
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

