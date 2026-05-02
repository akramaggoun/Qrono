import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../student/student_dashboard.dart';
import '../professor/professor_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/wireless_settings_tab.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // IHM: Valider avant l'envoi (prévention des erreurs)
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _matriculeController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      final role = authProvider.userRole?.toLowerCase();
      if (role == 'student') {
        debugPrint('🚀 NAVIGATING TO DASHBOARD (Student)');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboard()));
      } else if (role == 'professor') {
        debugPrint('🚀 NAVIGATING TO DASHBOARD (Professor)');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfessorDashboard()));
      } else if (role == 'admin') {
        debugPrint('🚀 NAVIGATING TO DASHBOARD (Admin)');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      }
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? context.tr('incorrect_credentials'));
    }
  }

  void _showError(String message) {
    // IHM: Feedback explicite et contextuel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    const bgColor = Color(0xFFF8FAFB);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Language Selector (Top Right)
              Padding(
                padding: const EdgeInsets.only(right: 32.0, top: 16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: const LanguageSelectorButton(),
                ),
              ),

              // Header Section (Logo & Title)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      height: 80, width: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryTeal, Color(0xFF00695C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QRONO',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4, color: Color(0xFF1A1C1E)),
                    ),
                    const Text(
                      'PRECISION ATTENDANCE',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.grayText, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // TabBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primaryTeal,
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryTeal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.grayText,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'sign_in'.tr().toUpperCase()),
                      Tab(text: 'connection'.tr().toUpperCase()),
                    ],
                  ),
                ),
              ),

              // TabBarView content
              Expanded(
                child: TabBarView(
                  children: [
                    // Login Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('login_to_continue'.tr(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
                            const SizedBox(height: 6),
                            Text('enter_credentials'.tr(), style: const TextStyle(fontSize: 13, color: AppColors.grayText, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 32),
                            _buildTextField(
                              controller: _matriculeController,
                              labelKey: 'urn_email',
                              hint: '202312345',
                              icon: Icons.badge_rounded,
                              validator: (val) => (val == null || val.isEmpty) ? 'required_field'.tr() : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _passwordController,
                              labelKey: 'password',
                              hint: '••••••••',
                              icon: Icons.lock_rounded,
                              isPassword: true,
                              validator: (val) => (val == null || val.isEmpty) ? 'required_field'.tr() : null,
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                                    : Text('sign_in'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Center(
                              child: Text('version'.tr(),
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Connection Tab
                    const SingleChildScrollView(
                      padding: EdgeInsets.all(32.0),
                      child: WirelessSettingsTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelKey,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1C1E)),
        decoration: InputDecoration(
          labelText: labelKey.tr(),
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryTeal, size: 20),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.grayText, size: 20),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        validator: validator,
      ),
    );
  }
}


