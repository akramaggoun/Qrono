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
      final role = authProvider.userRole;
      if (role == 'student') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboard()));
      } else if (role == 'professor') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfessorDashboard()));
      } else if (role == 'admin') {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // IHM: Identité de l'app claire et mémorisable (Logo + Titre)
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryTeal, AppColors.primaryTeal.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryTeal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, size: 52, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'QRONO',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.black87),
                      ),
                      const Text(
                        'Smart Attendance System',
                        style: TextStyle(fontSize: 13, color: AppColors.grayText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                // IHM : Titre de section clair (où suis-je ?)
                const Text('Welcome Back 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 6),
                const Text('Login to your account', style: TextStyle(fontSize: 13, color: AppColors.grayText)),
                const SizedBox(height: 25),

                // IHM: Label visible + placeholder explicite + validation inline
                TextFormField(
                  controller: _matriculeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'URN or Email',
                    hintText: 'Ex: 202312345 or user@univ.dz',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.badge_outlined, color: AppColors.primaryTeal, size: 20),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Le matricule est requis';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.lock_outline, color: AppColors.primaryTeal, size: 20),
                    ),
                    // IHM: affordance claire pour voir/cacher le mot de passe
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: AppColors.grayText, size: 20),
                      tooltip: _isPasswordVisible ? 'Masquer' : 'Afficher',
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Le mot de passe est requis';
                    if (val.length < 4) return 'Minimum 4 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // IHM: Bouton principal (CTA) grand, contrasté, feedback visuel de chargement
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      shadowColor: AppColors.primaryTeal.withOpacity(0.3),
                    ),
                    child: authProvider.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              SizedBox(width: 12),
                              Text('Connexion en cours...', style: TextStyle(fontSize: 15)),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, size: 20),
                              SizedBox(width: 10),
                              Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                // IHM: Séparateur visuel clair entre action réelle et démo
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('MODE DÉMO', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 14),

                // IHM: badges rôle clairs avec icônes + couleur distinctive par rôle
                Row(
                  children: [
                    _buildDemoButton('Student', Icons.person, AppColors.primaryTeal, () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboard()));
                    }),
                    const SizedBox(width: 10),
                    _buildDemoButton('Professor', Icons.school, Colors.blueAccent, () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfessorDashboard()));
                    }),
                    const SizedBox(width: 10),
                    _buildDemoButton('Admin', Icons.admin_panel_settings, Colors.purple, () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
                    }),
                  ],
                ),
                const SizedBox(height: 40),

                // IHM: Pied de page discret (non perturbateur)
                Center(
                  child: Text('© 2024 Université de Khenchela', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // IHM: Bouton de démo compact, icône + label + couleur = rôle immédiatement identifiable
  Widget _buildDemoButton(String role, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
