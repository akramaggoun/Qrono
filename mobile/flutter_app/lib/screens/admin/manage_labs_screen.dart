import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/laboratory_model.dart';
import '../../providers/admin_provider.dart';
import 'package:provider/provider.dart';
import 'entity_stats_screen.dart';

class ManageLabsScreen extends StatefulWidget {
  const ManageLabsScreen({super.key});

  @override
  State<ManageLabsScreen> createState() => _ManageLabsScreenState();
}

class _ManageLabsScreenState extends State<ManageLabsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filterStatus = 'All';

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
    final nameCtrl = TextEditingController(text: lab?.name ?? '');
    final buildingCtrl = TextEditingController(text: lab?.building ?? '');
    final roomCtrl = TextEditingController(text: lab?.roomNumber ?? '');
    final capCtrl = TextEditingController(text: lab?.capacity.toString() ?? '');
    bool isActive = lab?.isActive ?? true;
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
                  Text(isEditing ? 'Update Laboratory' : 'New Resource Facility', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 24),
                  _label('LABORATORY / HALL NAME'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. CS Computing Lab 01', prefixIcon: Icon(Icons.science_rounded, size: 20)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('BUILDING'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: buildingCtrl,
                              decoration: const InputDecoration(hintText: 'Block A', prefixIcon: Icon(Icons.apartment_rounded, size: 20)),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                       ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('ROOM ID'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: roomCtrl,
                              decoration: const InputDecoration(hintText: '101', prefixIcon: Icon(Icons.meeting_room_rounded, size: 20)),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('STUDENT CAPACITY'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 40', prefixIcon: Icon(Icons.groups_rounded, size: 20)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required field';
                      if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _label('RESOURCE STATUS'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Available for Sessions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary))),
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
                        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                        final labData = {
                          'name': nameCtrl.text,
                          'building': buildingCtrl.text,
                          'room_number': roomCtrl.text,
                          'capacity': int.parse(capCtrl.text),
                          'isActive': isActive,
                        };
                        bool success = isEditing ? await adminProvider.updateLaboratory(lab.id, labData) : await adminProvider.addLaboratory(labData);
                        if (!mounted) return;
                        if (success) {
                          Navigator.pop(ctx);
                          _showSnack(isEditing ? 'Facility updated' : 'Facility added successfully', AppColors.success);
                        } else {
                          _showSnack(adminProvider.errorMessage ?? 'Operation failed', AppColors.danger);
                        }
                      },
                      child: Text(isEditing ? 'UPDATE FACILITY' : 'ADD FACILITY', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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

  void _confirmDelete(LaboratoryModel lab) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Laboratory?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text('"${lab.name}" will be permanently removed from the system.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteLaboratory(lab.id);
              if (success && mounted) {
                Navigator.pop(context);
                _showSnack('Laboratory removed', AppColors.success);
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
          builder: (_, p, __) {
            final active = p.laboratories.where((l) => l.isActive).length;
            final total = p.laboratories.length;
            return Column(
              children: [
                const Text('CAMPUS RESOURCES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                Text('$active active facilities out of $total', style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLabDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final filtered = _getFilteredLabs(adminProvider.laboratories);
          if (adminProvider.isLoading && adminProvider.laboratories.isEmpty) {
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
                        hintText: 'Search by facility name or building...',
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
                        children: ['All', 'Active', 'Inactive'].map((f) {
                          final sel = _filterStatus == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w900 : FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary)),
                              selected: sel,
                              onSelected: (_) => setState(() => _filterStatus = f),
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
                        itemBuilder: (_, i) => _buildLabCard(filtered[i]),
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
          Icon(Icons.layers_clear_rounded, size: 64, color: AppColors.textLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No laboratories found', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLabCard(LaboratoryModel lab) {
    final statusColor = lab.isActive ? AppColors.success : AppColors.danger;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border.withOpacity(0.5)), boxShadow: AppColors.softShadow),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EntityStatsScreen(
              entityId: lab.id,
              type: 'lab',
              title: lab.name,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lab.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                        Text('${lab.building} — Room ${lab.roomNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  _statusIndicator(lab.isActive, statusColor),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
              Row(
                children: [
                  _buildMetaIcon(Icons.groups_rounded, '${lab.capacity} Seats'),
                  const SizedBox(width: 16),
                  _buildMetaIcon(Icons.location_on_rounded, lab.building),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.edit_note_rounded, color: AppColors.info, size: 24), onPressed: () => _showLabDialog(lab: lab)),
                  IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 24), onPressed: () => _confirmDelete(lab)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(active ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildMetaIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
