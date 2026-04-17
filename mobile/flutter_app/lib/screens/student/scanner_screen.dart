import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/presence_provider.dart';
import 'confirm_presence_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      _startCamera();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _startCamera() async {
    try {
      await controller.start();
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.displayValue;
      if (code != null) {
        controller.stop();
        final presenceProvider = Provider.of<PresenceProvider>(context, listen: false);
        final success = await presenceProvider.scanQR(code);

        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConfirmPresenceScreen(
                attendanceData: presenceProvider.attendanceData!,
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(presenceProvider.errorMessage ?? 'Verification Failed'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24),
          ));
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) controller.start();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('QR SCANNER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_isPermissionGranted)
            MobileScanner(controller: controller, onDetect: _onDetect)
          else
            _buildPermissionPlaceholder(),

          if (_isPermissionGranted) _buildScannerOverlay(),
          
          if (_isPermissionGranted) _buildActionControls(),
        ],
      ),
    );
  }

  Widget _buildPermissionPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.camera_rounded, color: Colors.white, size: 64),
            ),
            const SizedBox(height: 32),
            const Text('Camera Access Required', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text(
              'Please grant camera permission to scan attendance QR codes and verify your presence.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('GRANT ACCESS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Stack(
              children: [
                ..._buildNeonCorners(),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
            child: const Text(
              'ALIGN QR CODE WITHIN THE FRAME',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls() {
    return Positioned(
      bottom: 64,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGlassButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: state.torchState == TorchState.on ? Colors.amber : Colors.white,
                );
              },
            ),
            onTap: () => controller.toggleTorch(),
          ),
          const SizedBox(width: 40),
          _buildGlassButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onTap: () => controller.switchCamera(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required Widget icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(50), width: 1),
        ),
        child: Center(child: icon),
      ),
    );
  }

  List<Widget> _buildNeonCorners() {
    const size = 30.0;
    const thickness = 4.0;
    const radius = 40.0;

    return [
      Positioned(top: 0, left: 0, child: _corner(top: true, left: true, r: radius, s: size, t: thickness)),
      Positioned(top: 0, right: 0, child: _corner(top: true, left: false, r: radius, s: size, t: thickness)),
      Positioned(bottom: 0, left: 0, child: _corner(top: false, left: true, r: radius, s: size, t: thickness)),
      Positioned(bottom: 0, right: 0, child: _corner(top: false, left: false, r: radius, s: size, t: thickness)),
    ];
  }

  Widget _corner({required bool top, required bool left, required double r, required double s, required double t}) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: AppColors.primary, width: t) : BorderSide.none,
          bottom: !top ? BorderSide(color: AppColors.primary, width: t) : BorderSide.none,
          left: left ? BorderSide(color: AppColors.primary, width: t) : BorderSide.none,
          right: !left ? BorderSide(color: AppColors.primary, width: t) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? Radius.circular(r) : Radius.zero,
          topRight: top && !left ? Radius.circular(r) : Radius.zero,
          bottomLeft: !top && left ? Radius.circular(r) : Radius.zero,
          bottomRight: !top && !left ? Radius.circular(r) : Radius.zero,
        ),
      ),
    );
  }
}
