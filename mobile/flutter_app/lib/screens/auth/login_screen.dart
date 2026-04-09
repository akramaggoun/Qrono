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
        print('🚀 NAVIGATING TO DASHBOARD (Student)');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboard()));
      } else if (role == 'professor') {
        print('🚀 NAVIGATING TO DASHBOARD (Professor)');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfessorDashboard()));
      } else if (role == 'admin') {
        print('🚀 NAVIGATING TO DASHBOARD (Admin)');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      }
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Identifiants incorrects. Réessayez.');
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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 100, width: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryTeal, Color(0xFF00695C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryTeal.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 12)),
                          ],
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, size: 56, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'QRONO',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 6, color: Color(0xFF1A1C1E)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PRECISION ATTENDANCE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.grayText, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),

                const Text('Login to Continue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
                const SizedBox(height: 8),
                const Text('Enter your credentials to access the portal', style: TextStyle(fontSize: 13, color: AppColors.grayText, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),

                _buildTextField(
                  controller: _matriculeController,
                  label: 'URN or Email',
                  hint: '202312345',
                  icon: Icons.badge_rounded,
                  validator: (val) => (val == null || val.isEmpty) ? 'Required field' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  validator: (val) => (val == null || val.isEmpty) ? 'Required field' : null,
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
                      shadowColor: AppColors.primaryTeal.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Text('SIGN IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 40),

                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1, color: Color(0xFFECEFF1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('EXPLORE AS', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    ),
                    const Expanded(child: Divider(thickness: 1, color: Color(0xFFECEFF1))),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _buildRoleButton('Student', Icons.school_rounded, AppColors.primaryTeal, () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboard()));
                    }),
                    const SizedBox(width: 12),
                    _buildRoleButton('Professor', Icons.assignment_ind_rounded, Colors.blueAccent, () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfessorDashboard()));
                    }),
                  ],
                ),
                const SizedBox(height: 40),

                Center(
                  child: Text('Version 2.0.1 • Precision Lab Sync', 
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1C1E)),
        decoration: InputDecoration(
          labelText: label,
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

  Widget _buildRoleButton(String role, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(role, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
