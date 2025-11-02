// mobile_qr_scanner.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MobileQrScanner extends StatefulWidget {
  final Function(String) onDetect;
  const MobileQrScanner({Key? key, required this.onDetect}) : super(key: key);

  @override
  State<MobileQrScanner> createState() => _MobileQrScannerState();
}

class _MobileQrScannerState extends State<MobileQrScanner> {
  final MobileScannerController _controller = MobileScannerController();

  bool _isDetected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Kamera scanner
        MobileScanner(
          controller: _controller,
          onDetect: (BarcodeCapture capture) {
            if (_isDetected) return; // cegah multi-callback
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final raw = barcodes.first.rawValue;
              if (raw != null && raw.isNotEmpty) {
                _isDetected = true;
                widget.onDetect(raw);
              }
            }
          },
        ),

        /// Overlay
        const ScannerOverlay(),
      ],
    );
  }
}

/// Overlay kotak + garis merah animasi
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({Key? key}) : super(key: key);

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);
  late final Animation<double> _animation =
      Tween<double>(begin: 0, end: 1).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;

      final boxSize = width * 0.6;
      final left = (width - boxSize) / 2;
      final top = (height - boxSize) / 2;

      return Stack(children: [
        // top overlay
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: Container(color: Colors.black.withOpacity(0.55))),
        // left
        Positioned(
            top: top,
            left: 0,
            width: left,
            height: boxSize,
            child: Container(color: Colors.black.withOpacity(0.55))),
        // right
        Positioned(
            top: top,
            left: left + boxSize,
            right: 0,
            height: boxSize,
            // ignore: deprecated_member_use
            child: Container(color: Colors.black.withOpacity(0.55))),
        // bottom
        Positioned(
            top: top + boxSize,
            left: 0,
            right: 0,
            bottom: 0,
            // ignore: deprecated_member_use
            child: Container(color: Colors.black.withOpacity(0.55))),
        // border kotak
        Positioned(
          top: top,
          left: left,
          child: Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        // garis merah animasi
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final y = top + (boxSize * _animation.value);
            return Positioned(
              top: y,
              left: left + 4,
              child: Container(
                width: boxSize - 8,
                height: 3,
                color: Colors.redAccent.withOpacity(0.95),
              ),
            );
          },
        ),
      ]);
    });
  }
}
