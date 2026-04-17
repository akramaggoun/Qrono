import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/laboratory_model.dart';
import '../../providers/admin_provider.dart';
import 'package:provider/provider.dart';

class ManageLabsScreen extends StatefulWidget {
  const ManageLabsScreen({super.key});

  @override
  State<ManageLabsScreen> createState() => _ManageLabsScreenState();
}

class _ManageLabsScreenState extends State<ManageLabsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filterStatus = 'All'; // All / Active / Inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchLaboratories();
    });
  }

  List<LaboratoryModel> _getFilteredLabs(List<LaboratoryModel> labs) {
    return labs.where((l) {
      final matchSearch = l.name.toLowerCase().contains(_query.toLowerCase()) ||
          l.building.toLowerCase().contains(_query.toLowerCase());
      final matchFilter = _filterStatus == 'All' ||
          (_filterStatus == 'Active' && l.isActive) ||
          (_filterStatus == 'Inactive' && !l.isActive);
      return matchSearch && matchFilter;
    }).toList();
  }


  void _showLabDialog({LaboratoryModel? lab}) {
    final isEditing = lab != null;
    final nameCtrl     = TextEditingController(text: lab?.name ?? '');
    final buildingCtrl = TextEditingController(text: lab?.building ?? '');
    final roomCtrl     = TextEditingController(text: lab?.roomNumber ?? '');
    final capCtrl      = TextEditingController(text: lab?.capacity.toString() ?? '');
    bool isActive      = lab?.isActive ?? true;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.science_outlined, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(width: 12),
                  Text(isEditing ? 'Edit Laboratory' : 'New Laboratory',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                const Text('All fields marked * are required.',
                    style: TextStyle(fontSize: 11, color: AppColors.grayText)),
                const SizedBox(height: 20),

                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Laboratory Name *', hintText: 'Ex: Lab Info 01', prefixIcon: Icon(Icons.label_outline)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: buildingCtrl,
                      decoration: const InputDecoration(labelText: 'Building *', hintText: 'Block A', prefixIcon: Icon(Icons.apartment_outlined)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: roomCtrl,
                      decoration: const InputDecoration(labelText: 'Room No. *', hintText: '101', prefixIcon: Icon(Icons.door_back_door_outlined)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacity (No. students) *', prefixIcon: Icon(Icons.people_outline)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Valid number required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // IHM : SwitchListTile avec description — état compris sans explication
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setSheet(() => isActive = v),
                  activeColor: AppColors.primaryTeal,
                  title: const Text('Room Available', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(isActive ? 'Accessible for sessions' : 'Unavailable or under maintenance',
                      style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(isEditing ? Icons.save_outlined : Icons.add, size: 18),
                      label: Text(isEditing ? 'Save' : 'Add'),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                        
                        final labData = {
                          'name': nameCtrl.text,
                          'building': buildingCtrl.text,
                          'room_number': roomCtrl.text,
                          'capacity': int.parse(capCtrl.text),
                          'is_active': isActive,
                        };

                        bool success;
                        if (isEditing) {
                          success = await adminProvider.updateLaboratory(lab!.id, labData);
                        } else {
                          success = await adminProvider.addLaboratory(labData);
                        }

                        if (success && mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(isEditing ? 'Laboratoire mis à jour' : 'Laboratoire ajouté'),
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
    );
  }

  void _confirmDelete(LaboratoryModel lab) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Text('Delete this Lab?'),
        ]),
        content: Text('"${lab.name}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteLaboratory(lab.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Laboratoire supprimé'),
                  ]),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
            const Text('Laboratoires', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${Provider.of<AdminProvider>(context).laboratories.where((l) => l.isActive).length}/${Provider.of<AdminProvider>(context).laboratories.length} actifs', 
                 style: const TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLabDialog(),
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add_business_outlined, color: Colors.white),
        label: const Text('Add Lab', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final filtered = _getFilteredLabs(adminProvider.laboratories);
          final activeCount = adminProvider.laboratories.where((l) => l.isActive).length;
          final labs = adminProvider.laboratories;

          if (adminProvider.isLoading && adminProvider.laboratories.isEmpty) {
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
                        hintText: 'Name or building...',
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
                    Row(
                      children: ['All', 'Active', 'Inactive'].map((f) {
                        final sel = _filterStatus == f;
                        Color c = f == 'Active' ? Colors.green : (f == 'Inactive' ? Colors.redAccent : Colors.black87);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filterStatus = f),
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
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No laboratories found', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildLabCard(filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabCard(LaboratoryModel lab) {
    final statusColor = lab.isActive ? Colors.green : Colors.redAccent;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.science_outlined, color: AppColors.primaryTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(lab.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${lab.building} — Room ${lab.roomNumber}', style: const TextStyle(fontSize: 12, color: AppColors.grayText)),
                  ]),
                ),
                // IHM : badge statut  = état système visible sans action requise
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(lab.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                  ]),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                // IHM : icône + valeur = scan rapide, pas besoin de lire le label
                _buildMeta(Icons.people_outline, '${lab.capacity} seats'),
                const SizedBox(width: 20),
                _buildMeta(Icons.apartment_outlined, lab.building),
                const Spacer(),
                Tooltip(message: 'Edit', child: IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent), onPressed: () => _showLabDialog(lab: lab))),
                Tooltip(message: 'Delete', child: IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _confirmDelete(lab))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.grayText),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    ],
  );
}
