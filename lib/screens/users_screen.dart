import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadData();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final users = await _ds.getUsers(_token);
      if (!mounted) return;
      setState(() { _users = users; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل المستخدمين'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) { _filtered = List.from(_users); } else {
      _filtered = _users.where((u) {
        final fullName = (u['full_name'] ?? u['fullName'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final username = (u['username'] ?? '').toString().toLowerCase();
        return fullName.contains(q) || email.contains(q) || username.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمين', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.usersPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog, child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController, onChanged: (_) => setState(() => _applyFilter()),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو البريد...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                filled: true, fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
            child: Text('${_filtered.length} مستخدم', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          const Divider(height: 1),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
                : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.person_off_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا يوجد مستخدمين', style: TextStyle(color: AppColors.textGray))]))
                : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData,
                    child: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length, itemBuilder: (ctx, i) => _buildUserCard(_filtered[i]))),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final fullName = user['full_name'] ?? user['fullName'] ?? '';
    final email = user['email'] ?? '';
    final role = (user['role'] ?? 'staff').toString().toLowerCase();
    final isActive = user['is_active'] ?? user['isActive'] ?? true;
    final lastLogin = user['last_login'] ?? user['lastLogin'] ?? '';

    Color roleColor; String roleLabel;
    switch (role) {
      case 'admin': roleColor = const Color(0xFF7C3AED); roleLabel = 'مدير'; break;
      default: roleColor = const Color(0xFF2563EB); roleLabel = 'موظف'; break;
    }

    final bool active = isActive == true || isActive == 1 || isActive.toString() == 'true';

    String lastLoginText = '';
    if (lastLogin.toString().isNotEmpty && lastLogin.toString() != 'null') {
      try {
        final dt = DateTime.parse(lastLogin.toString());
        lastLoginText = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        lastLoginText = lastLogin.toString();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUserDetails(user),
        onLongPress: () => _showActions(user),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.person, color: roleColor, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fullName.toString().isNotEmpty ? fullName.toString() : (user['username'] ?? '').toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.email_outlined, size: 12, color: AppColors.textMuted), const SizedBox(width: 3),
              Flexible(child: Text(email.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            if (lastLoginText.isNotEmpty) ...[const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.access_time, size: 12, color: AppColors.textMuted), const SizedBox(width: 3),
                Text(lastLoginText, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ],
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor))),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (active ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(active ? 'نشط' : 'معطل', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? AppColors.success : AppColors.error))),
          ]),
        ])),
      ),
    );
  }

  void _showActions(Map<String, dynamic> user) {
    final id = user['_id'] ?? user['id'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showEditDialog(user); }),
        ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _confirmDelete(id.toString()); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  void _showAddDialog() {
    final usernameC = TextEditingController(); final emailC = TextEditingController();
    final passwordC = TextEditingController(); final fullNameC = TextEditingController();
    String role = 'staff';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة مستخدم', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(fullNameC, 'الاسم الكامل', Icons.person),
        _input(usernameC, 'اسم المستخدم', Icons.account_circle_outlined),
        _input(emailC, 'البريد الإلكتروني', Icons.email_outlined, keyboard: TextInputType.emailAddress),
        _input(passwordC, 'كلمة المرور', Icons.lock_outlined, obscure: true),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: role,
          items: const [DropdownMenuItem(value: 'admin', child: Text('مدير')), DropdownMenuItem(value: 'staff', child: Text('موظف'))],
          onChanged: (v) => setS(() => role = v!),
          decoration: InputDecoration(labelText: 'الصلاحية', prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (usernameC.text.trim().isEmpty || emailC.text.trim().isEmpty || passwordC.text.trim().isEmpty) return; Navigator.pop(ctx);
          try { await _ds.createUser(_token, {'username': usernameC.text.trim(), 'email': emailC.text.trim(), 'password': passwordC.text.trim(), 'full_name': fullNameC.text.trim(), 'role': role, 'is_active': true}); _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المستخدم'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الإضافة'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _showEditDialog(Map<String, dynamic> user) {
    final id = user['_id'] ?? user['id'] ?? '';
    final usernameC = TextEditingController(text: user['username'] ?? '');
    final emailC = TextEditingController(text: user['email'] ?? '');
    final fullNameC = TextEditingController(text: user['full_name'] ?? user['fullName'] ?? '');
    String role = (user['role'] ?? 'staff').toString().toLowerCase();
    if (!['admin', 'staff'].contains(role)) role = 'staff';
    bool isActive = user['is_active'] ?? user['isActive'] ?? true;
    if (isActive is! bool) isActive = isActive == 1 || isActive.toString() == 'true';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل المستخدم', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(fullNameC, 'الاسم الكامل', Icons.person),
        _input(usernameC, 'اسم المستخدم', Icons.account_circle_outlined),
        _input(emailC, 'البريد الإلكتروني', Icons.email_outlined, keyboard: TextInputType.emailAddress),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: role,
          items: const [DropdownMenuItem(value: 'admin', child: Text('مدير')), DropdownMenuItem(value: 'staff', child: Text('موظف'))],
          onChanged: (v) => setS(() => role = v!),
          decoration: InputDecoration(labelText: 'الصلاحية', prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: SwitchListTile(
          title: const Text('الحساب نشط', style: TextStyle(fontSize: 14)), value: isActive as bool,
          activeColor: AppColors.primary,
          onChanged: (v) => setS(() => isActive = v),
          contentPadding: EdgeInsets.zero,
        )),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _ds.updateUser(_token, id.toString(), {'username': usernameC.text.trim(), 'email': emailC.text.trim(), 'full_name': fullNameC.text.trim(), 'role': role, 'is_active': isActive}); _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل التعديل'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف المستخدم', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذا المستخدم نهائياً؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _ds.deleteUser(_token, id); _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success)); }
          catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard, bool obscure = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: keyboard, obscureText: obscure, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );

  void _showUserDetails(Map<String, dynamic> user) {
    final fullName = user['full_name'] ?? user['fullName'] ?? '';
    final role = (user['role'] ?? 'staff').toString().toLowerCase();
    Color roleColor; String roleLabel;
    switch (role) {
      case 'admin': roleColor = const Color(0xFF7C3AED); roleLabel = 'مدير'; break;
      default: roleColor = const Color(0xFF2563EB); roleLabel = 'موظف'; break;
    }

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(width: 60, height: 60, decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.person, color: roleColor, size: 32)),
            const SizedBox(height: 12),
            Text(fullName.toString().isNotEmpty ? fullName.toString() : (user['username'] ?? '').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(roleLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: roleColor))),
            const SizedBox(height: 16),
            ..._detailRows(user),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showEditDialog(user); }, icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(width: 10),
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _confirmDelete((user['_id'] ?? user['id'] ?? '').toString()); }, icon: const Icon(Icons.delete, size: 18), label: const Text('حذف'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
          ]),
        )),
      ),
    );
  }

  List<Widget> _detailRows(Map<String, dynamic> user) {
    final isActive = user['is_active'] ?? user['isActive'] ?? true;
    final bool active = isActive == true || isActive == 1 || isActive.toString() == 'true';
    String lastLoginText = '-';
    final lastLogin = user['last_login'] ?? user['lastLogin'] ?? '';
    if (lastLogin.toString().isNotEmpty && lastLogin.toString() != 'null') {
      try {
        final dt = DateTime.parse(lastLogin.toString());
        lastLoginText = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        lastLoginText = lastLogin.toString();
      }
    }

    final fields = <MapEntry<String, String>>[
      MapEntry('اسم المستخدم', '${user['username'] ?? '-'}'),
      MapEntry('البريد الإلكتروني', '${user['email'] ?? '-'}'),
      MapEntry('الاسم الكامل', '${user['full_name'] ?? user['fullName'] ?? '-'}'),
      MapEntry('الصلاحية', (user['role'] ?? 'staff').toString().toLowerCase() == 'admin' ? 'مدير' : 'موظف'),
      MapEntry('الحالة', active ? 'نشط' : 'معطل'),
      MapEntry('آخر تسجيل دخول', lastLoginText),
    ];
    return fields.where((f) => f.value != '-' && f.value != 'null').map((f) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 120, child: Text(f.key, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(f.value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ]),
    )).toList();
  }
}
