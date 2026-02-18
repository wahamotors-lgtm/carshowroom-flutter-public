import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late final DataService _dataService;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataService = DataService(ApiService());
    _loadData();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _dataService.getEmployees(_token);
      if (!mounted) return;
      setState(() { _employees = data; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل الموظفين'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_employees);
    } else {
      _filtered = _employees.where((emp) {
        final name = (emp['name'] ?? '').toString().toLowerCase();
        final code = (emp['code'] ?? emp['employee_code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموظفين', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.employeesPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddEmployeeDialog,
        child: const Icon(Icons.person_add),
      ),
      body: Column(children: [
        // -- Search bar --
        Container(
          color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _applyFilter()),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الكود...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
              filled: true, fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        // -- Count --
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
          child: Text('${_filtered.length} موظف', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        const Divider(height: 1),
        // -- List --
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ]))
                  : _filtered.isEmpty
                      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.badge_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('لا يوجد موظفين', style: TextStyle(color: AppColors.textGray)),
                        ]))
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  // ── Employee Card ──

  Widget _buildCard(Map<String, dynamic> emp) {
    final name = emp['name'] ?? '';
    final code = emp['code'] ?? emp['employee_code'] ?? '';
    final role = emp['role'] ?? '';
    final email = emp['email'] ?? '';
    final isActive = emp['is_active'] ?? emp['isActive'] ?? true;
    final salary = emp['salary'] ?? emp['base_salary'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.blue600.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.person, color: AppColors.blue600, size: 22)),
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (code.toString().isNotEmpty) Text('كود: $code', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (role.toString().isNotEmpty) Text(role.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (email.toString().isNotEmpty) Text(email.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: (isActive == true ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(isActive == true ? 'نشط' : 'معطل', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive == true ? AppColors.success : AppColors.error)),
          ),
          if (salary != null) ...[const SizedBox(height: 4), Text('\$$salary', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark))],
        ]),
        onLongPress: () => _showEmployeeActions(emp),
      ),
    );
  }

  // ── Actions Bottom Sheet (Edit / Delete) ──

  void _showEmployeeActions(Map<String, dynamic> emp) {
    final id = emp['id']?.toString() ?? emp['_id']?.toString();
    if (id == null) return;
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.edit_outlined, color: AppColors.blue600),
        title: const Text('تعديل'),
        onTap: () { Navigator.pop(ctx); _showEditEmployeeDialog(emp); },
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: AppColors.error),
        title: const Text('حذف', style: TextStyle(color: AppColors.error)),
        onTap: () { Navigator.pop(ctx); _confirmDelete(id, emp['name'] ?? ''); },
      ),
    ])));
  }

  // ── Add Employee Dialog ──

  void _showAddEmployeeDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final roleC = TextEditingController();
    final salaryC = TextEditingController();
    bool isActive = true;
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة موظف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: nameC,
            decoration: InputDecoration(labelText: 'اسم الموظف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailC,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneC,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: roleC,
            decoration: InputDecoration(labelText: 'الوظيفة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: salaryC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'الراتب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('الحالة:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('نشط'),
              selected: isActive,
              selectedColor: AppColors.success.withValues(alpha: 0.2),
              onSelected: (_) => setDialogState(() => isActive = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('معطل'),
              selected: !isActive,
              selectedColor: AppColors.error.withValues(alpha: 0.2),
              onSelected: (_) => setDialogState(() => isActive = false),
            ),
          ]),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                final body = <String, dynamic>{
                  'name': nameC.text.trim(),
                  'is_active': isActive,
                  if (emailC.text.trim().isNotEmpty) 'email': emailC.text.trim(),
                  if (phoneC.text.trim().isNotEmpty) 'phone': phoneC.text.trim(),
                  if (roleC.text.trim().isNotEmpty) 'role': roleC.text.trim(),
                  if (salaryC.text.trim().isNotEmpty) 'salary': num.tryParse(salaryC.text.trim()) ?? 0,
                };
                await _dataService.createEmployee(_token, body);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الموظف بنجاح'), backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة الموظف'), backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('إضافة'),
          ),
        ],
      ),
    ));
  }

  // ── Edit Employee Dialog ──

  void _showEditEmployeeDialog(Map<String, dynamic> emp) {
    final id = emp['id']?.toString() ?? emp['_id']?.toString();
    if (id == null) return;

    final nameC = TextEditingController(text: emp['name'] ?? '');
    final emailC = TextEditingController(text: emp['email'] ?? '');
    final phoneC = TextEditingController(text: emp['phone'] ?? '');
    final roleC = TextEditingController(text: emp['role'] ?? '');
    final salaryC = TextEditingController(text: (emp['salary'] ?? emp['base_salary'] ?? '').toString());
    bool isActive = emp['is_active'] ?? emp['isActive'] ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل الموظف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: nameC,
            decoration: InputDecoration(labelText: 'اسم الموظف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailC,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneC,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: roleC,
            decoration: InputDecoration(labelText: 'الوظيفة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: salaryC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'الراتب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('الحالة:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('نشط'),
              selected: isActive,
              selectedColor: AppColors.success.withValues(alpha: 0.2),
              onSelected: (_) => setDialogState(() => isActive = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('معطل'),
              selected: !isActive,
              selectedColor: AppColors.error.withValues(alpha: 0.2),
              onSelected: (_) => setDialogState(() => isActive = false),
            ),
          ]),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                final body = <String, dynamic>{
                  'name': nameC.text.trim(),
                  'email': emailC.text.trim(),
                  'phone': phoneC.text.trim(),
                  'role': roleC.text.trim(),
                  'is_active': isActive,
                };
                final salaryVal = num.tryParse(salaryC.text.trim());
                if (salaryVal != null) body['salary'] = salaryVal;
                await _dataService.updateEmployee(_token, id, body);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل الموظف بنجاح'), backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تعديل الموظف'), backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('حفظ'),
          ),
        ],
      ),
    ));
  }

  // ── Delete Confirmation ──

  void _confirmDelete(String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف الموظف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('حذف "$name"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await _dataService.deleteEmployee(_token, id);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الموظف'), backgroundColor: AppColors.success));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف الموظف'), backgroundColor: AppColors.error));
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف'),
        ),
      ],
    ));
  }
}
