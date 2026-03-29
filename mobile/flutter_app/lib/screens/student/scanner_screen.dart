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
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      _startCamera();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _startCamera() async {
    try {
      await controller.start();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error starting camera: $e');
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
        final success = await presenceProvider.scanQR(code); // UML Step 3-8

        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPresenceScreen(
                attendanceData: presenceProvider.attendanceData!,
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(presenceProvider.errorMessage ?? "Erreur de scan"),
            backgroundColor: Colors.redAccent,
          ));
          // Redémarrer le scan après une brève pause
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
      appBar: AppBar(
        title: const Text('Scanner QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryTeal),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _isPermissionGranted
              ? MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Accès caméra requis pour scanner',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _checkPermission,
                        child: const Text('ACCORDER L\'AUTORISATION'),
                      ),
                    ],
                  ),
                ),
          
          if (_isPermissionGranted)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryTeal, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Placez le code QR dans le cadre',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          switch (state.torchState) {
                            case TorchState.on:
                              return const Icon(Icons.flash_on, color: AppColors.primaryTeal);
                            default:
                              return const Icon(Icons.flash_off, color: Colors.white);
                          }
                        },
                      ),
                      onPressed: () => controller.toggleTorch(),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 40),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                      onPressed: () => controller.switchCamera(),
                      iconSize: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
