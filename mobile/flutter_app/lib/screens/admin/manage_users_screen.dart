import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/professor_model.dart';
import '../../models/admin_model.dart';
import '../../models/group_model.dart';
import '../../providers/admin_provider.dart';
import 'package:provider/provider.dart';
import '../../core/storage/token_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'student_stats_admin_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filterRole = 'All'; // All / Student / Professor / Admin

  @override
  void initState() {
    super.initState();
    _checkToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.fetchUsers();
      adminProvider.fetchGroups();
    });
  }

  Future<void> _checkToken() async {
    final token = await TokenStorage.getToken();
    print('🔑 TOKEN IN ADMIN SCREEN: $token');
    if (token == null && mounted) {
      print('❌ NO TOKEN — Redirecting to login');
      // Navigator.pushReplacementNamed(context, '/login') per instructions
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    return users.where((u) {
      bool matchSearch = u.fullName.toLowerCase().contains(_query.toLowerCase());
      if (u.role == 'student') {
        matchSearch = matchSearch || u.matricule.contains(_query);
      }
      
      final matchRole = _filterRole == 'All' ||
          (_filterRole == 'Student'   && u.role == 'student') ||
          (_filterRole == 'Professor' && u.role == 'professor') ||
          (_filterRole == 'Admin'     && u.role == 'admin');
      return matchSearch && matchRole;
    }).toList();
  }

  // ── couleur/icône par rôle ────────────────────────────────
  Color _roleColor(UserModel u) {
    if (u.role == 'professor') return Colors.blue;
    if (u.role == 'admin')     return Colors.purple;
    return AppColors.primaryTeal;
  }
  IconData _roleIcon(UserModel u) {
    if (u.role == 'professor') return Icons.school;
    if (u.role == 'admin')     return Icons.admin_panel_settings;
    return Icons.person;
  }
  String _roleName(UserModel u) {
    if (u.role == 'professor') return 'Professor';
    if (u.role == 'admin')     return 'Admin';
    return 'Student';
  }

  String _roleSubtitle(UserModel u) {
    if (u.role == 'professor') return u.email;
    if (u.role == 'admin')     return u.email;
    return 'URN: ${u.matricule}';
  }

  // ── Dialog ajout/édition ──────────────────────────────────
  void _showUserDialog({UserModel? user}) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final isEditing = user != null;
    String selectedRole  = user?.role ?? 'student';
    bool isActive        = user?.isActive ?? true;
    String? selectedGroupId;
    
    // Safety check for group ID if it's a student
    if (selectedRole == 'student' && user != null) {
       // We can try to get the groupId from the json if we don't want to cast
       // But since we want to be safe, let's just use the adminProvider groups as fallback
       selectedGroupId = (adminProvider.groups.isNotEmpty ? adminProvider.groups[0].id : null);
    }

    final nameCtrl      = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl     = TextEditingController(text: user?.email ?? '');
    final passwordCtrl  = TextEditingController();  // jamais pré-remplie pour la sécurité
    final extra1Ctrl    = TextEditingController(text: user?.matricule ?? '');
    final extra2Ctrl    = TextEditingController();
    bool _passwordVisible = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _roleColor(user ?? UserModel(id: '', matricule: '', fullName: '', email: '', isActive: true, createdAt: DateTime.now(), role: 'student')).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.manage_accounts_outlined, color: AppColors.primaryTeal),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing 
                         ? 'edit_user_details'.tr()
                         : 'add_new_user'.tr(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // IHM : sélection du rôle en premier = oriente le reste du formulaire
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(labelText: 'role_required'.tr(), prefixIcon: const Icon(Icons.manage_accounts_outlined)),
                    items: [
                      DropdownMenuItem(value: 'student',   child: Text('filter_student'.tr())),
                      DropdownMenuItem(value: 'professor', child: Text('filter_professor'.tr())),
                      DropdownMenuItem(value: 'admin',     child: Text('filter_admin'.tr())),
                    ],
                    onChanged: (v) => setSheet(() => selectedRole = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: 'full_name_required'.tr(), 
                        hintText: 'Ahmed Benali', 
                        prefixIcon: const Icon(Icons.person_outline)
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'required_field'.tr() : null,
                  ),
                  const SizedBox(height: 12),

                  // IHM : champs conditionnels selon le rôle — formulaire adaptatif
                  if (selectedRole == 'student') ...[
                    TextFormField(
                      controller: extra1Ctrl,
                      decoration: InputDecoration(labelText: 'urn_label'.tr(), hintText: 'Ex: 202312345', prefixIcon: const Icon(Icons.badge_outlined)),
                      validator: (v) => (v == null || v.isEmpty) ? 'required_field'.tr() : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: 'email_required'.tr(), 
                        hintText: 'user@univ-khenchela.dz',
                        prefixIcon: const Icon(Icons.email_outlined)),
                    validator: (v) => (v == null || v.isEmpty) ? 'required_field'.tr() : null,
                  ),
                  const SizedBox(height: 12),

                  // ── Mot de passe (tous les rôles) ──────────────────────
                  StatefulBuilder(
                    builder: (_, setPwdState) => TextFormField(
                      controller: passwordCtrl,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: isEditing ? 'new_password_optional'.tr() : 'temp_password_required'.tr(),
                        hintText: isEditing ? 'leave_empty_keep_current'.tr() : 'min_6_chars'.tr(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off,
                              color: AppColors.grayText, size: 20),
                          onPressed: () => setPwdState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (!isEditing && (v == null || v.isEmpty)) return 'password_required'.tr();
                        if (v != null && v.isNotEmpty && v.length < 6) return 'min_6_chars_error'.tr();
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (selectedRole == 'student' && adminProvider.groups.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedGroupId,
                      decoration: InputDecoration(labelText: 'group_label'.tr(), prefixIcon: const Icon(Icons.groups_outlined)),
                      items: adminProvider.groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                      onChanged: (v) => setSheet(() => selectedGroupId = v),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (selectedRole == 'professor') ...[
                    TextFormField(
                      controller: extra1Ctrl,
                      decoration: InputDecoration(labelText: 'professor_code_required'.tr(), prefixIcon: const Icon(Icons.fingerprint)),
                      validator: (v) => (v == null || v.isEmpty) ? 'required_field'.tr() : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: extra2Ctrl,
                      decoration: InputDecoration(labelText: 'department_label'.tr(), hintText: 'Computer Science, IT...', prefixIcon: const Icon(Icons.workspaces_outlined)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setSheet(() => isActive = v),
                    activeColor: AppColors.primaryTeal,
                    title: Text('account_active'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(isActive ? 'user_can_login'.tr() : 'access_disabled'.tr(),
                        style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.redAccent)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),

                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr()))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(isEditing ? Icons.save_outlined : Icons.person_add_alt, size: 18),
                        label: Text(isEditing ? 'update_btn'.tr() : 'create_btn'.tr()),
                        onPressed: () async {
                          print('🔴 BUTTON PRESSED: Add/Edit User');
                          final isValid = formKey.currentState!.validate();
                          print('🟡 FORM VALID: $isValid');
                          if (!isValid) return;
                          
                          final userData = {
                            'name': nameCtrl.text,
                            'role': selectedRole,
                            'isActive': isActive,
                            if (passwordCtrl.text.isNotEmpty) 'password': passwordCtrl.text,
                            'email': emailCtrl.text,
                            if (selectedRole == 'student') ...{
                              'urn': extra1Ctrl.text,
                              'groupId': selectedGroupId,
                            },
                            if (selectedRole == 'professor') ...{
                              'professorCode': extra1Ctrl.text,
                              'department': extra2Ctrl.text,
                            },
                          };

                          print('🟠 CALLING adminProvider.addUser/updateUser()');
                          bool success;
                          if (isEditing) {
                            success = await adminProvider.updateUser(user.id, userData);
                          } else {
                            success = await adminProvider.addUser(userData);
                          }

                          if (!mounted) return;

                          if (success) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(isEditing ? 'user_updated_success'.tr() : 'user_created_success'.tr()),
                              ]),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(adminProvider.errorMessage ?? "error_occurred".tr()),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ));
                          }
                        },
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Text('delete_user_prompt'.tr()),
        ]),
        content: Text('delete_user_desc'.tr(args: [user.fullName])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteUser(user.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [
                    const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('operation_successful'.tr()),
                  ]),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            },
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('user_management_title'.tr(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('users_count'.tr(args: [Provider.of<AdminProvider>(context).users.length.toString()]), style: const TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: Text('new_btn'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final filtered = _getFilteredUsers(adminProvider.users);
          
          if (adminProvider.isLoading && adminProvider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'search_name_urn'.tr(),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.grayText),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, size: 18, color: AppColors.grayText),
                                onPressed: () => setState(() { _query = ''; _searchController.clear(); }))
                            : null,
                        filled: true,
                        fillColor: AppColors.cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Student', 'Professor', 'Admin'].map((f) {
                          final sel = _filterRole == f;
                          final colors = {
                            'Student': AppColors.primaryTeal,
                            'Professor': Colors.blue,
                            'Admin': Colors.purple,
                            'All': Colors.black87,
                          };
                          final c = colors[f]!;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _filterRole = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel ? c.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: sel ? c : Colors.grey.shade300),
                                ),
                                child: Text(f, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? c : Colors.black54)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.person_search, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('no_users_found'.tr(), style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildUserCard(filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final color = _roleColor(user);
    final sub   = _roleSubtitle(user);

    return InkWell(
      onTap: user.role == 'student' 
        ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentStatsAdminScreen(studentId: user.id, studentName: user.fullName)))
        : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: user.isActive ? AppColors.borderColor : Colors.redAccent.withOpacity(0.25)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Stack(alignment: Alignment.bottomRight, children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(_roleIcon(user), color: color, size: 22),
            ),
            // IHM : indicateur de statut en overlay — 2 infos en 1 espace
            Container(
              width: 11, height: 11,
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green : Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ]),
          title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(_roleName(user), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
                const SizedBox(width: 6),
                Flexible(child: Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.grayText), overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Tooltip(message: 'edit_tooltip'.tr(), child: IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent), onPressed: () => _showUserDialog(user: user))),
            Tooltip(message: 'delete_tooltip'.tr(), child: IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _confirmDelete(user))),
          ]),
        ),
      ),
    );
  }
}
