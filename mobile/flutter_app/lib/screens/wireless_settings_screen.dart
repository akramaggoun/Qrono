import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';

class WirelessSettingsScreen extends StatefulWidget {
  const WirelessSettingsScreen({super.key});

  @override
  State<WirelessSettingsScreen> createState() => _WirelessSettingsScreenState();
}

class _WirelessSettingsScreenState extends State<WirelessSettingsScreen> {
  final TextEditingController _tunnelUrlController = TextEditingController();
  bool _isWirelessMode = false;

  @override
  void initState() {
    super.initState();
    _isWirelessMode = ApiConfig.isWirelessAccess;
    _tunnelUrlController.text = _isWirelessMode ? ApiConfig.baseUrl : '';
  }

  @override
  void dispose() {
    _tunnelUrlController.dispose();
    super.dispose();
  }

  void _toggleConnectionMode(bool? isWireless) {
    if (isWireless == null) return;
    setState(() {
      _isWirelessMode = isWireless;
    });

    if (!isWireless) {
      _showRestartDialog('Local Network', ApiConstants.defaultBaseUrl);
    }
  }

  void _applyWirelessSettings() {
    final url = _tunnelUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tunnel URL')),
      );
      return;
    }

    if (!url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL must start with https://')),
      );
      return;
    }

    _showRestartDialog('Wireless (Cloudflare Tunnel)', url);
  }

  void _showRestartDialog(String mode, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch to $mode Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New API URL: $url'),
            const SizedBox(height: 10),
            const Text('Changes apply immediately, but restarting is recommended if you are already logged in.'),
            const SizedBox(height: 10),
            const Text('Make sure the backend is accessible at this URL.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _persistAndNotify(mode, url);
            },
            child: const Text('Apply & Restart'),
          ),
        ],
      ),
    );
  }

  Future<void> _persistAndNotify(String mode, String url) async {
    if (mode.startsWith('Local')) {
      await ApiConfig.resetToDefault();
    } else {
      await ApiConfig.setBaseUrl(url);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Saved $mode API URL. Restart app if you see old data.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wireless Settings'),
        backgroundColor: AppColors.primaryTeal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('Local Network'),
                    subtitle: const Text('http://localhost:3000/api'),
                    value: false,
                    groupValue: _isWirelessMode,
                    onChanged: _toggleConnectionMode,
                  ),
                  RadioListTile<bool>(
                    title: const Text('Wireless (Cloudflare Tunnel)'),
                    subtitle: const Text('Custom tunnel URL'),
                    value: true,
                    groupValue: _isWirelessMode,
                    onChanged: _toggleConnectionMode,
                  ),
                ],
              ),
            ),
            if (_isWirelessMode) ...[
              const SizedBox(height: 20),
              const Text(
                'Cloudflare Tunnel URL',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tunnelUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://qrono-api.yourdomain.com/api',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter your Cloudflare tunnel URL. Make sure the tunnel is running.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyWirelessSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Wireless Settings'),
                ),
              ),
            ],
            const SizedBox(height: 30),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Instructions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Install cloudflared\n'
                      '2. Run: cloudflared tunnel login\n'
                      '3. Run: cloudflared tunnel create qrono-tunnel\n'
                      '4. Update config.yaml with your domain\n'
                      '5. Run: ./devops/tunnel/start-tunnel.sh\n'
                      '6. Enter tunnel URL above and apply',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}