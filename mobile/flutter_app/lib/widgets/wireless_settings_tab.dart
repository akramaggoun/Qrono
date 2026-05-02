import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/config/api_config.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';

class WirelessSettingsTab extends StatefulWidget {
  const WirelessSettingsTab({super.key});

  @override
  State<WirelessSettingsTab> createState() => _WirelessSettingsTabState();
}

class _WirelessSettingsTabState extends State<WirelessSettingsTab> {
  final TextEditingController _tunnelUrlController = TextEditingController();
  bool _isWirelessMode = false;

  @override
  void initState() {
    super.initState();
    _isWirelessMode = ApiConfig.isWirelessAccess;
    _tunnelUrlController.text = ApiConfig.baseUrl;
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
        SnackBar(content: Text('enter_tunnel_url'.tr())),
      );
      return;
    }

    if (!url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('url_must_start_https'.tr())),
      );
      return;
    }

    _showRestartDialog('Wireless (Cloudflare Tunnel)', url);
  }

  void _showRestartDialog(String mode, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${'switch_to_mode'.tr()} $mode', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'new_api_url'.tr()}\n$url', style: const TextStyle(fontSize: 13, color: AppColors.grayText)),
            const SizedBox(height: 16),
            Text('restart_recommended'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr(), style: const TextStyle(color: AppColors.grayText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _persistAndNotify(mode, url);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('apply_and_restart'.tr()),
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
      SnackBar(
        content: Text('✅ ${'saved_api_url'.tr()} $mode'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'connection_mode'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E)),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: Text('local_network'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(ApiConstants.defaultBaseUrl, style: const TextStyle(fontSize: 12)),
                value: false,
                activeColor: AppColors.primaryTeal,
                groupValue: _isWirelessMode,
                onChanged: _toggleConnectionMode,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              RadioListTile<bool>(
                title: Text('wireless_cloudflare'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('custom_tunnel_url'.tr(), style: const TextStyle(fontSize: 12)),
                value: true,
                activeColor: AppColors.primaryTeal,
                groupValue: _isWirelessMode,
                onChanged: _toggleConnectionMode,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ],
          ),
        ),
        if (_isWirelessMode) ...[
          const SizedBox(height: 24),
          Text(
            'cloudflare_tunnel_url'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1C1E)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: TextField(
              controller: _tunnelUrlController,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'https://qrono-api.yourdomain.com/api',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.transparent,
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primaryTeal),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              ),
              keyboardType: TextInputType.url,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'enter_cloudflare_url_desc'.tr(),
              style: const TextStyle(color: AppColors.grayText, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _applyWirelessSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primaryTeal.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text('apply_wireless_settings'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'setup_instructions'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'setup_instructions_desc'.tr(),
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],        // ← FIXED: was missing, closes the main Column's children list
    );
  }
}