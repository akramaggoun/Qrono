import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../student/student_dashboard.dart';
import '../professor/professor_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

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
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _matriculeController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      final role = authProvider.userRole?.toLowerCase();
      if (role == 'student') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()));
      } else if (role == 'professor') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ProfessorDashboard()));
      } else if (role == 'admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()));
      }
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Incorrect credentials. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── الشريط الجانبي الأكاديمي ──────────────────────────
          _buildSideBanner(),

          // ── نموذج تسجيل الدخول ────────────────────────────────
          Expanded(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الشعار
                          _buildLogo(),
                          const SizedBox(height: 40),

                          // عنوان القسم
                          const Text(
                            'Portal Login',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Enter your university credentials to access the platform.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // حقل المعرف
                          _buildLabel('Matricule / URN'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _matriculeController,
                            hint: 'Ex: 202312345',
                            icon: Icons.badge_outlined,
                            validator: (val) =>
                                (val == null || val.isEmpty) ? 'This field is required' : null,
                          ),
                          const SizedBox(height: 20),

                          // حقل كلمة المرور
                          _buildLabel('Password'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordController,
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (val) =>
                                (val == null || val.isEmpty) ? 'This field is required' : null,
                          ),
                          const SizedBox(height: 32),

                          // زر الدخول
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white))
                                  : const Text(
                                      'LOG IN',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // معلومات اتصال الدعم
                          _buildSupportNote(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── الشريط الجانبي الأكاديمي ─────────────────────────────────
  Widget _buildSideBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // على الشاشات الصغيرة لا يظهر الشريط الجانبي
        final width = MediaQuery.of(context).size.width;
        if (width < 600) return const SizedBox.shrink();

        return Container(
          width: 260,
          decoration: const BoxDecoration(
            color: AppColors.primary,
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.white, size: 44),
                  SizedBox(height: 20),
                  Text(
                    'QRONO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Academic\nAttendance\nManagement System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Divider(color: Colors.white24, thickness: 1),
                  SizedBox(height: 16),
                  _RoleInfoItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Administrator',
                    desc: 'Full system management',
                  ),
                  SizedBox(height: 14),
                  _RoleInfoItem(
                    icon: Icons.school_outlined,
                    label: 'Professor',
                    desc: 'Sessions and attendance',
                  ),
                  SizedBox(height: 14),
                  _RoleInfoItem(
                    icon: Icons.person_outline,
                    label: 'Student',
                    desc: 'Attendance tracking',
                  ),
                  SizedBox(height: 32),
                  Text(
                    'v2.0 — Larbi Ben Mhidi University',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.qr_code_scanner_rounded,
              color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QRONO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 3,
              ),
            ),
            Text(
              'Academic Portal',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textLight,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
      ),
      validator: validator,
    );
  }

  Widget _buildSupportNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'For any assistance, contact the information technology service of your institution.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;

  const _RoleInfoItem({
    required this.icon,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            Text(desc,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
