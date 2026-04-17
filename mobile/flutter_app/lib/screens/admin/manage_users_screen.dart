import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/professor_model.dart';
import '../../models/admin_model.dart';
import '../../models/group_model.dart';
import '../../providers/admin_provider.dart';
import '../../core/storage/token_storage.dart';
import 'entity_stats_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filterRole = 'All';

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
    if (token == null && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    return users.where((u) {
      bool matchSearch = u.fullName.toLowerCase().contains(_query.toLowerCase());
      if (u is StudentModel) {
        matchSearch = matchSearch || (u.urn?.contains(_query) ?? false);
      }
      final matchRole = _filterRole == 'All' ||
          (_filterRole == 'Student' && u.role == UserRole.student) ||
          (_filterRole == 'Teacher' && u.role == UserRole.professor) ||
          (_filterRole == 'Admin' && u.role == UserRole.admin);
      return matchSearch && matchRole;
    }).toList();
  }

  Color _roleColor(UserModel u) {
    if (u.role == UserRole.professor) return AppColors.info;
    if (u.role == UserRole.admin) return AppColors.primary;
    return AppColors.success;
  }

  IconData _roleIcon(UserModel u) {
    if (u.role == UserRole.professor) return Icons.school_rounded;
    if (u.role == UserRole.admin) return Icons.admin_panel_settings_rounded;
    return Icons.person_rounded;
  }

  String _roleName(UserModel u) {
    if (u.role == UserRole.professor) return 'Teacher';
    if (u.role == UserRole.admin) return 'Admin';
    return 'Student';
  }

  String _roleSubtitle(UserModel u) {
    if (u.role == UserRole.professor) return u.email;
    if (u.role == UserRole.admin) return u.email;
    return 'URN: ${u.matricule ?? "N/A"}';
  }

  void _showUserDialog({UserModel? user}) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final isEditing = user != null;
    String selectedRole = user?.role.value ?? 'student';
    bool isActive = user?.isActive ?? true;
    String? selectedGroupId = (user is StudentModel)
        ? user.groupId
        : (adminProvider.groups.isNotEmpty ? adminProvider.groups[0].id : null);

    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();
    final extra1Ctrl = TextEditingController(text: user?.matricule ?? '');
    final extra2Ctrl = TextEditingController();
    bool passwordVisible = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(isEditing ? 'Update User Account' : 'Create New User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 24),
                  _dialogLabel('ACCOUNT ROLE'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.manage_accounts_rounded, size: 20), filled: true, fillColor: AppColors.background),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student Account')),
                      DropdownMenuItem(value: 'professor', child: Text('Teacher Account')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                    ],
                    onChanged: (v) => setSheet(() {
                      selectedRole = v!;
                      if (selectedRole == 'student' && selectedGroupId == null && adminProvider.groups.isNotEmpty) {
                        selectedGroupId = adminProvider.groups[0].id;
                      }
                    }),
                  ),
                  const SizedBox(height: 20),
                  _dialogLabel('FULL NAME'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. John Doe', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                  ),
                  const SizedBox(height: 20),
                  if (selectedRole == 'student') ...[
                    _dialogLabel('UNIVERSITY REGISTRATION NUMBER (URN)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: extra1Ctrl,
                      decoration: const InputDecoration(hintText: 'e.g. 202312345', prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                    ),
                    const SizedBox(height: 20),
                    if (adminProvider.groups.isNotEmpty) ...[
                      _dialogLabel('ASSIGNED ACADEMIC GROUP'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedGroupId,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.hub_outlined, size: 20)),
                        items: adminProvider.groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                        onChanged: (v) => setSheet(() => selectedGroupId = v),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                  _dialogLabel('EMAIL ADDRESS'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'email@example.com', prefixIcon: Icon(Icons.alternate_email_rounded, size: 20)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                  ),
                  const SizedBox(height: 20),
                  _dialogLabel(isEditing ? 'NEW PASSWORD (OPTIONAL)' : 'INITIAL PASSWORD'),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (_, setPwd) => TextFormField(
                      controller: passwordCtrl,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        hintText: isEditing ? 'Leave blank to keep current' : 'Min. 6 characters',
                        prefixIcon: const Icon(Icons.lock_person_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: AppColors.textLight, size: 20),
                          onPressed: () => setPwd(() => passwordVisible = !passwordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (!isEditing && (v == null || v.isEmpty)) return 'Password required';
                        if (v != null && v.isNotEmpty && v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (selectedRole == 'professor') ...[
                    _dialogLabel('TEACHER IDENTIFICATION CODE'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: extra1Ctrl,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.fingerprint_rounded, size: 20)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                    ),
                    const SizedBox(height: 20),
                    _dialogLabel('ASSIGNED DEPARTMENT'),
                    const SizedBox(height: 8),
                    TextFormField(controller: extra2Ctrl, decoration: const InputDecoration(hintText: 'Computer Science, Math...', prefixIcon: Icon(Icons.business_rounded, size: 20))),
                    const SizedBox(height: 20),
                  ],
                  _dialogLabel('ACCOUNT STATUS'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Active & Functional', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary))),
                        Switch(value: isActive, activeColor: AppColors.success, onChanged: (v) => setSheet(() => isActive = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final userData = {
                          'name': nameCtrl.text,
                          'role': selectedRole,
                          'isActive': isActive,
                          if (passwordCtrl.text.isNotEmpty) 'password': passwordCtrl.text,
                          'email': emailCtrl.text,
                          if (selectedRole == 'student') ...{'urn': extra1Ctrl.text, 'groupId': selectedGroupId},
                          if (selectedRole == 'professor') ...{'professorCode': extra1Ctrl.text, 'department': extra2Ctrl.text},
                        };
                        bool success = isEditing ? await adminProvider.updateUser(user.id, userData) : await adminProvider.addUser(userData);
                        if (!mounted) return;
                        if (success) {
                          Navigator.pop(ctx);
                          _showSnack(isEditing ? 'Account updated' : 'User account created', AppColors.success);
                        } else {
                          _showSnack(adminProvider.errorMessage ?? 'Operation failed', AppColors.danger);
                        }
                      },
                      child: Text(isEditing ? 'UPDATE ACCOUNT' : 'CREATE ACCOUNT', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
                  ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remove User Account?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text('The account for "${user.fullName}" will be permanently removed or deactivated.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteUser(user.id);
              if (success && mounted) {
                Navigator.pop(context);
                _showSnack('Account removed successfully', AppColors.success);
              }
            },
            child: const Text('REMOVE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _dialogLabel(String text) => Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Consumer<AdminProvider>(
          builder: (_, p, __) => Column(
            children: [
              const Text('RECORDS MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              Text('${p.users.length} registered users found', style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final filtered = _getFilteredUsers(adminProvider.users);
          if (adminProvider.isLoading && adminProvider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or URN...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.cancel_rounded, size: 20), onPressed: () => setState(() { _query = ''; _searchController.clear(); })) : null,
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Student', 'Teacher', 'Admin'].map((f) {
                          final sel = _filterRole == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w900 : FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary)),
                              selected: sel,
                              onSelected: (_) => setState(() => _filterRole = f),
                              backgroundColor: AppColors.background,
                              selectedColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: sel ? AppColors.primary : AppColors.divider)),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _buildUserCard(filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: AppColors.textLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No users found', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final color = _roleColor(user);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: user.isActive ? AppColors.border.withOpacity(0.5) : AppColors.danger.withOpacity(0.2)), boxShadow: AppColors.softShadow),
      child: ListTile(
        onTap: user.role == UserRole.admin 
          ? null 
          : () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => EntityStatsScreen(
                  entityId: user.id, 
                  type: user.role == UserRole.student ? 'student' : 'professor', 
                  title: user.fullName
                )
              )
            ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(_roleIcon(user), color: color, size: 24)),
            Container(width: 12, height: 12, decoration: BoxDecoration(color: user.isActive ? AppColors.success : AppColors.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
          ],
        ),
        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(_roleName(user).toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                Expanded(child: Text(_roleSubtitle(user), style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_note_rounded, color: AppColors.info, size: 22), onPressed: () => _showUserDialog(user: user)),
            IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 22), onPressed: () => _confirmDelete(user)),
          ],
        ),
      ),
    );
  }
}
