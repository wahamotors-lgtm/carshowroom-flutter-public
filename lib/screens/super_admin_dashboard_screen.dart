import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../config/routes.dart';
import '../config/theme.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});
  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  late final DataService _ds;
  late final StorageService _storage;
  bool _isLoading = true;
  String? _error;

  // Stats
  int _totalTenants = 0;
  int _activeTenants = 0;
  int _inactiveTenants = 0;
  int _totalUsers = 0;

  // Tenants list
  List<Map<String, dynamic>> _tenants = [];
  List<Map<String, dynamic>> _filteredTenants = [];
  List<Map<String, dynamic>> _notifications = [];
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _storage = StorageService();
    _searchC.addListener(_filterTenants);
    _loadAll();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<String> get _adminToken async {
    return await _storage.getAdminToken() ?? '';
  }

  void _filterTenants() {
    final q = _searchC.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredTenants = _tenants);
    } else {
      setState(() {
        _filteredTenants = _tenants.where((t) {
          final name = (t['companyName'] ?? t['company_name'] ?? t['name'] ?? '').toString().toLowerCase();
          final email = (t['email'] ?? '').toString().toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      });
    }
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = await _adminToken;

      final results = await Future.wait([
        _ds.getAdminStats(token).catchError((_) => <String, dynamic>{}),
        _ds.getAdminTenants(token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getAdminNotifications(token).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;

      // Parse stats
      final stats = results[0] as Map<String, dynamic>;
      _totalTenants = _pi(stats['totalTenants'] ?? stats['total_tenants'] ?? 0);
      _activeTenants = _pi(stats['activeTenants'] ?? stats['active_tenants'] ?? 0);
      _inactiveTenants = _pi(stats['inactiveTenants'] ?? stats['inactive_tenants'] ?? 0);
      _totalUsers = _pi(stats['totalUsers'] ?? stats['total_users'] ?? 0);

      // Parse tenants
      _tenants = results[1] as List<Map<String, dynamic>>;
      _filteredTenants = _tenants;

      // Parse notifications
      _notifications = results[2] as List<Map<String, dynamic>>;

      // If stats are empty, calculate from tenants
      if (_totalTenants == 0 && _tenants.isNotEmpty) {
        _totalTenants = _tenants.length;
        _activeTenants = _tenants.where((t) => t['is_active'] == true || t['isActive'] == true || t['status'] == 'active').length;
        _inactiveTenants = _totalTenants - _activeTenants;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  int _pi(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _toggleTenant(Map<String, dynamic> tenant) async {
    final token = await _adminToken;
    final id = (tenant['id'] ?? tenant['_id'] ?? '').toString();
    if (id.isEmpty) return;
    try {
      await _ds.toggleAdminTenant(token, id);
      if (!mounted) return;
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'فشل تغيير الحالة'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteTenant(Map<String, dynamic> tenant) async {
    final name = tenant['companyName'] ?? tenant['company_name'] ?? tenant['name'] ?? '';
    final id = (tenant['id'] ?? tenant['_id'] ?? '').toString();
    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الشركة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text('هل تريد حذف "$name" نهائياً؟', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontSize: 15))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _adminToken;
      await _ds.deleteAdminTenant(token, id);
      if (!mounted) return;
      _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الشركة بنجاح'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف الشركة'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showCreateTenantDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إنشاء شركة جديدة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: 'اسم الشركة',
                  prefixIcon: const Icon(Icons.business, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailC,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return 'مطلوب';
                  if (!v.contains('@')) return 'بريد غير صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: passC,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.length < 6 ? '6 أحرف على الأقل' : null,
              ),
            ]),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                final token = await _adminToken;
                await _ds.createAdminTenant(token, {
                  'companyName': nameC.text.trim(),
                  'email': emailC.text.trim(),
                  'password': passC.text,
                });
                if (!mounted) return;
                _loadAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إنشاء الشركة بنجاح'), backgroundColor: AppColors.success),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e is ApiException ? e.message : 'فشل إنشاء الشركة'), backgroundColor: AppColors.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('إنشاء', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const Divider(height: 20),
          if (_notifications.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('لا توجد إشعارات', style: TextStyle(color: Color(0xFF94A3B8))))
          else
            ...(_notifications.take(10).map((n) => ListTile(
              leading: const Icon(Icons.notifications_outlined, color: Color(0xFFDC2626)),
              title: Text((n['title'] ?? n['message'] ?? '').toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text((n['created_at'] ?? n['createdAt'] ?? '').toString().split('T').first, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تسجيل الخروج', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('هل تريد تسجيل الخروج؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لا', style: TextStyle(fontSize: 15))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _storage.clearAll();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.superAdminLogin);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('نعم، خروج', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المدير العام', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Stack(children: [
            IconButton(icon: const Icon(Icons.notifications_outlined, size: 22), onPressed: _showNotifications),
            if (_notifications.isNotEmpty) Positioned(right: 6, top: 6, child: Container(
              padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text('${_notifications.length}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
            )),
          ]),
          IconButton(icon: const Icon(Icons.refresh, size: 22), onPressed: _loadAll),
          IconButton(icon: const Icon(Icons.logout, size: 22), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTenantDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAll,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]))
              : RefreshIndicator(
                  color: const Color(0xFFDC2626),
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      // Header
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('لوحة التحكم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text('إدارة جميع الشركات والمستخدمين', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ])),
                        Row(children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(DateFormat('d MMMM yyyy', 'ar').format(DateTime.now()), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ]),
                      ]),
                      const SizedBox(height: 16),

                      // Stats
                      _buildStatsGrid(),
                      const SizedBox(height: 14),

                      // Search
                      _buildSearchBar(),
                      const SizedBox(height: 14),

                      // Tenants list
                      _buildTenantsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
      children: [
        _statCard('إجمالي الشركات', '$_totalTenants', Icons.business, const Color(0xFF3B82F6), const Color(0xFF4F46E5)),
        _statCard('شركات نشطة', '$_activeTenants', Icons.check_circle_outline, const Color(0xFF10B981), const Color(0xFF059669)),
        _statCard('شركات متوقفة', '$_inactiveTenants', Icons.pause_circle_outline, const Color(0xFFF59E0B), const Color(0xFFEA580C)),
        _statCard('إجمالي المستخدمين', '$_totalUsers', Icons.people_outline, const Color(0xFF8B5CF6), const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color gradEnd) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.08), gradEnd.withValues(alpha: 0.15)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.9))),
          ),
        ])),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchC,
        decoration: InputDecoration(
          hintText: 'بحث عن شركة...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
          suffixIcon: _searchC.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () { _searchC.clear(); _filterTenants(); })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTenantsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.business, size: 18, color: Color(0xFF3B82F6)),
          const SizedBox(width: 6),
          Expanded(child: Text('الشركات (${_filteredTenants.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
        ]),
        const SizedBox(height: 14),
        _filteredTenants.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(children: [
                  Icon(Icons.business_outlined, size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(_searchC.text.isNotEmpty ? 'لا توجد نتائج' : 'لا توجد شركات', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
              )
            : Column(children: _filteredTenants.map((tenant) => _buildTenantCard(tenant)).toList()),
      ]),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final name = tenant['companyName'] ?? tenant['company_name'] ?? tenant['name'] ?? '';
    final email = tenant['email'] ?? '';
    final isActive = tenant['is_active'] == true || tenant['isActive'] == true || tenant['status'] == 'active';
    final plan = tenant['subscription_plan'] ?? tenant['subscriptionPlan'] ?? tenant['plan'] ?? 'مجاني';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.business, color: isActive ? AppColors.success : AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(email.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'نشط' : 'متوقف',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? AppColors.success : AppColors.error),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.card_membership, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text('الخطة: $plan', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const Spacer(),
          // Toggle
          SizedBox(
            height: 30,
            child: Switch(
              value: isActive,
              activeColor: AppColors.success,
              onChanged: (_) => _toggleTenant(tenant),
            ),
          ),
          // Delete
          SizedBox(
            width: 32, height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              onPressed: () => _deleteTenant(tenant),
            ),
          ),
        ]),
      ]),
    );
  }
}
