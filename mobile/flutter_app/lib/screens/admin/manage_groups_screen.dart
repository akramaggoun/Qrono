import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../providers/admin_provider.dart';
import 'package:provider/provider.dart';

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
    return groups.where((g) =>
        g.name.toLowerCase().contains(_query.toLowerCase()) ||
        g.yearLevel.toLowerCase().contains(_query.toLowerCase()) ||
        g.specialty.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  // ── couleur par niveau ─────────────────────────────────────
  Color _levelColor(String level) {
    if (level.startsWith('Master')) return Colors.purple;
    if (level.startsWith('Doctorat')) return Colors.red;
    return AppColors.primaryTeal;
  }

  // ── Dialog création / édition ──────────────────────────────
  void _showGroupDialog({GroupModel? group}) {
    final isEditing = group != null;
    final nameCtrl      = TextEditingController(text: group?.name ?? '');
    final yearCtrl      = TextEditingController(text: group?.yearLevel ?? '');
    final specialtyCtrl = TextEditingController(text: group?.specialty ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,  // IHM : feuille remonte pour laisser le clavier visible
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IHM : titre contextuel — l'utilisateur sait exactement ce qu'il fait
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.groups, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Text(isEditing ? 'Edit Group' : 'New Group',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              // IHM : champs avec labels persistants et hints explicatifs
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  hintText: 'Ex: L3 CS S1 — Group 01',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: yearCtrl,
                decoration: const InputDecoration(
                  labelText: 'Study Level *',
                  hintText: 'Ex: Year 3, Master 1...',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: specialtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  hintText: 'Ex: Computer Science, Networks...',
                  prefixIcon: Icon(Icons.workspaces_outlined),
                ),
              ),
              const SizedBox(height: 24),
              // IHM : boutons CTA bien différenciés (primaire vs secondaire)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(isEditing ? Icons.save_outlined : Icons.add, size: 18),
                        label: Text(isEditing ? 'Save' : 'Create'),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                          
                          final groupData = {
                            'name': nameCtrl.text,
                            'year_level': yearCtrl.text,
                            'specialty': specialtyCtrl.text,
                          };

                          bool success;
                          if (isEditing) {
                            success = await adminProvider.updateGroup(group.id, groupData);
                          } else {
                            success = await adminProvider.addGroup(groupData);
                          }

                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(isEditing ? 'Group updated' : 'Group created successfully'),
                              ]),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ));
                          }
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(GroupModel group) {
    // IHM : confirmation avant action destructrice irréversible
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Text('Confirm Deletion'),
        ]),
        content: Text('Delete "${group.name}"? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteGroup(group.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Group deleted'),
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
            const Text('Groups & Promotions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${Provider.of<AdminProvider>(context).groups.length} groups registered', style: const TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupDialog(),
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text('New Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final filtered = _getFilteredGroups(adminProvider.groups);
          
          if (adminProvider.isLoading && adminProvider.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // IHM : barre de recherche sticky
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search for a group...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.grayText),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.grayText),
                            onPressed: () => setState(() { _query = ''; _searchController.clear(); }),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.cardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildGroupCard(filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final color = _levelColor(group.yearLevel);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.groups, color: color),
        ),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // IHM : badge niveau + spécialité = info dense mais lisible
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(group.yearLevel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(group.specialty, style: const TextStyle(fontSize: 11, color: AppColors.grayText), overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // IHM : icones avec Tooltip pour l'accessibilité
            Tooltip(
              message: 'Edit',
              child: IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent), onPressed: () => _showGroupDialog(group: group)),
            ),
            Tooltip(
              message: 'Delete',
              child: IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _confirmDelete(group)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No groups found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 6),
          const Text('Modify your search', style: TextStyle(color: AppColors.grayText, fontSize: 13)),
        ],
      ),
    );
  }
}
