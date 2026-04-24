import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/constants/app_colors.dart';
import '../widgets/wireless_settings_tab.dart';

class WirelessSettingsScreen extends StatelessWidget {
  const WirelessSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('wireless_settings'.tr()),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: WirelessSettingsTab(),
      ),
    );
  }
}