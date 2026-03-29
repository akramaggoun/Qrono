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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.fetchUsers();
      adminProvider.fetchGroups();
    });
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    return users.where((u) {
      bool matchSearch = u.fullName.toLowerCase().contains(_query.toLowerCase());
      if (u is StudentModel) {
        matchSearch = matchSearch || (u as StudentModel).urn.contains(_query);
      }
      
      final matchRole = _filterRole == 'All' ||
          (_filterRole == 'Student'   && u is StudentModel) ||
          (_filterRole == 'Professor' && u is ProfessorModel) ||
          (_filterRole == 'Admin'     && u is AdminModel);
      return matchSearch && matchRole;
    }).toList();
  }

  // ── couleur/icône par rôle ────────────────────────────────
  Color _roleColor(UserModel u) {
    if (u is ProfessorModel) return Colors.blue;
    if (u is AdminModel)     return Colors.purple;
    return AppColors.primaryTeal;
  }
  IconData _roleIcon(UserModel u) {
    if (u is ProfessorModel) return Icons.school;
    if (u is AdminModel)     return Icons.admin_panel_settings;
    return Icons.person;
  }
  String _roleName(UserModel u) {
    if (u is ProfessorModel) return 'Professor';
    if (u is AdminModel)     return 'Admin';
    return 'Student';
  }

  String _roleSubtitle(UserModel u) {
    if (u is ProfessorModel) return u.department;
    if (u is AdminModel)     return u.email;
    return 'URN: ${(u as StudentModel).urn}';
  }

  // ── Dialog ajout/édition ──────────────────────────────────
  void _showUserDialog({UserModel? user}) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final isEditing = user != null;
    String selectedRole  = user?.role ?? 'student';
    bool isActive        = user?.isActive ?? true;
    String? selectedGroupId = (user is StudentModel) ? user.groupId : (adminProvider.groups.isNotEmpty ? adminProvider.groups[0].id : null);

    final nameCtrl      = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl     = TextEditingController(text: user?.email ?? '');
    final passwordCtrl  = TextEditingController();  // jamais pré-remplie pour la sécurité
    final extra1Ctrl    = TextEditingController(
        text: (user is StudentModel) ? user.urn : (user is ProfessorModel ? user.professorCode : ''));
    final extra2Ctrl    = TextEditingController(
        text: (user is StudentModel) ? user.studentCode : (user is ProfessorModel ? user.department : ''));
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
                        color: _roleColor(user ?? StudentModel(id: '', matricule: '', fullName: '', email: '', isActive: true, createdAt: DateTime.now(), urn: '', studentCode: '')).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.manage_accounts_outlined, color: AppColors.primaryTeal),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing 
                         ? 'Edit User Details'
                         : 'Add New User',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // IHM : sélection du rôle en premier = oriente le reste du formulaire
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role *', prefixIcon: Icon(Icons.manage_accounts_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'student',   child: Text('Student')),
                      DropdownMenuItem(value: 'professor', child: Text('Professor')),
                      DropdownMenuItem(value: 'admin',     child: Text('Administrator')),
                    ],
                    onChanged: (v) => setSheet(() => selectedRole = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Full Name *', 
                        hintText: 'Ahmed Benali', 
                        prefixIcon: Icon(Icons.person_outline)
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                  ),
                  const SizedBox(height: 12),

                  // IHM : champs conditionnels selon le rôle — formulaire adaptatif
                  if (selectedRole == 'student') ...[
                    TextFormField(
                      controller: extra1Ctrl,
                      decoration: const InputDecoration(labelText: 'رقم التسجيل (URN):', hintText: 'Ex: 202312345', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email *', 
                        hintText: 'user@univ-khenchela.dz',
                        prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── Mot de passe (tous les rôles) ──────────────────────
                  StatefulBuilder(
                    builder: (_, setPwdState) => TextFormField(
                      controller: passwordCtrl,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: isEditing ? 'New Password (optional)' : 'Temporary Password *',
                        hintText: isEditing ? 'Leave empty to keep current' : 'Min. 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off,
                              color: AppColors.grayText, size: 20),
                          onPressed: () => setPwdState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (!isEditing && (v == null || v.isEmpty)) return 'Password required';
                        if (v != null && v.isNotEmpty && v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (selectedRole == 'student' && adminProvider.groups.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedGroupId,
                      decoration: const InputDecoration(labelText: 'Group:', prefixIcon: Icon(Icons.groups_outlined)),
                      items: adminProvider.groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                      onChanged: (v) => setSheet(() => selectedGroupId = v),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (selectedRole == 'professor') ...[
                    TextFormField(
                      controller: extra1Ctrl,
                      decoration: const InputDecoration(labelText: 'Professor Code *', prefixIcon: Icon(Icons.fingerprint)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: extra2Ctrl,
                      decoration: const InputDecoration(labelText: 'Department', hintText: 'Computer Science, IT...', prefixIcon: Icon(Icons.workspaces_outlined)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setSheet(() => isActive = v),
                    activeColor: AppColors.primaryTeal,
                    title: const Text('Account Active', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(isActive ? 'User can log in' : 'Access disabled',
                        style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.redAccent)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),

                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(isEditing ? Icons.save_outlined : Icons.person_add_alt, size: 18),
                        label: Text(isEditing 
                          ? 'Update' 
                          : 'Create'),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          final userData = {
                            'full_name': nameCtrl.text,
                            'role': selectedRole,
                            'is_active': isActive,
                            if (passwordCtrl.text.isNotEmpty) 'password': passwordCtrl.text,
                            'email': emailCtrl.text,
                            if (selectedRole == 'student') ...{
                              'urn': extra1Ctrl.text,
                              'group_id': selectedGroupId,
                            },
                            if (selectedRole == 'professor') ...{
                              'professor_code': extra1Ctrl.text,
                              'department': extra2Ctrl.text,
                            },
                          };

                          bool success;
                          if (isEditing) {
                            success = await adminProvider.updateUser(user.id, userData);
                          } else {
                            success = await adminProvider.addUser(userData);
                          }

                          if (success && mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(isEditing ? 'User updated successfully' : 'User created successfully'),
                              ]),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ));
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(adminProvider.errorMessage ?? "An error occurred."),
                              backgroundColor: Colors.redAccent,
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
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Text('Delete User?'),
        ]),
        content: Text('"${user.fullName}" will be deleted (or deactivated if linked to existing data).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteUser(user.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Operation successful'),
                  ]),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
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
            const Text('User Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${Provider.of<AdminProvider>(context).users.length} users', style: const TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        hintText: 'Name or URN...',
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
                        const Text('No users found', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
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

    return Container(
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
          Tooltip(message: 'Edit', child: IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent), onPressed: () => _showUserDialog(user: user))),
          Tooltip(message: 'Delete', child: IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _confirmDelete(user))),
        ]),
      ),
    );
  }
}
