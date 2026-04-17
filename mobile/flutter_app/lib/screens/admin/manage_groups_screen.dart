import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../providers/admin_provider.dart';
import 'package:provider/provider.dart';
import 'entity_stats_screen.dart';

class ManageGroupsScreen extends StatefulWidget {
  const ManageGroupsScreen({super.key});

  @override
  State<ManageGroupsScreen> createState() => _ManageGroupsScreenState();
}

class _ManageGroupsScreenState extends State<ManageGroupsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchGroups();
    });
  }

  List<GroupModel> _getFilteredGroups(List<GroupModel> groups) {
    return groups
        .where((g) =>
            g.name.toLowerCase().contains(_query.toLowerCase()) ||
            g.yearLevel.toLowerCase().contains(_query.toLowerCase()) ||
            g.specialty.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  Color _levelColor(String level) {
    final l = level.toLowerCase();
    if (l.contains('master')) return AppColors.accent;
    if (l.contains('doctorate') || l.contains('phd')) return AppColors.danger;
    return AppColors.primary;
  }

  void _showGroupDialog({GroupModel? group}) {
    final isEditing = group != null;
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final yearCtrl = TextEditingController(text: group?.yearLevel ?? '');
    final specialtyCtrl = TextEditingController(text: group?.specialty ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'Update Academic Group' : 'Initialize New Group', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 24),
                _label('OFFICIAL GROUP NAME'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. L3 Computer Science - G01', prefixIcon: Icon(Icons.label_important_rounded, size: 20)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                ),
                const SizedBox(height: 20),
                _label('ACADEMIC LEVEL / YEAR'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: yearCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. License 3, Master 1...', prefixIcon: Icon(Icons.school_rounded, size: 20)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                ),
                const SizedBox(height: 20),
                _label('SPECIALTY / FIELD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: specialtyCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Artificial Intelligence, Networking...', prefixIcon: Icon(Icons.workspace_premium_rounded, size: 20)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                      final groupData = {
                        'name': nameCtrl.text.trim(),
                        'year_level': yearCtrl.text.trim(),
                        'specialty': specialtyCtrl.text.trim(),
                      };
                      bool success = isEditing ? await adminProvider.updateGroup(group.id, groupData) : await adminProvider.addGroup(groupData);
                      if (!mounted) return;
                      if (success) {
                        Navigator.pop(context);
                        _showSnack(isEditing ? 'Group information updated' : 'Academic group created successfully', AppColors.success);
                      } else {
                        _showSnack(adminProvider.errorMessage ?? 'Operation failed', AppColors.danger);
                      }
                    },
                    child: Text(isEditing ? 'UPDATE GROUP' : 'CREATE GROUP', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Disband Academic Group?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text('The group "${group.name}" will be removed. This action may affect linked students and schedules.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteGroup(group.id);
              if (success && mounted) {
                Navigator.pop(context);
                _showSnack('Group removed successfully', AppColors.success);
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

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Consumer<AdminProvider>(
          builder: (_, p, __) => Column(
            children: [
              const Text('ACADEMIC GROUPS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              Text('${p.groups.length} active cohorts found', style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.group_add_rounded, color: Colors.white),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final filtered = _getFilteredGroups(adminProvider.groups);
          if (adminProvider.isLoading && adminProvider.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name, level or specialty...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.cancel_outlined, size: 20), onPressed: () => setState(() { _query = ''; _searchController.clear(); })) : null,
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _buildGroupCard(filtered[i]),
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
          Icon(Icons.diversity_3_rounded, size: 64, color: AppColors.textLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No academic groups found', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final color = _levelColor(group.yearLevel);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border.withOpacity(0.5)), boxShadow: AppColors.softShadow),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EntityStatsScreen(
              entityId: group.id,
              type: 'group',
              title: group.name,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.groups_rounded, color: color, size: 24),
        ),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(group.yearLevel.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(group.specialty, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_note_rounded, color: AppColors.info, size: 22), onPressed: () => _showGroupDialog(group: group)),
            IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 22), onPressed: () => _confirmDelete(group)),
          ],
        ),
      ),
    );
  }
}
