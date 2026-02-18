import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});
  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getActivityLogs(_token);
      if (!mounted) return;
      setState(() { _logs = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = 'فشل تحميل سجل النشاط'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل النشاط', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.activityLogPage),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : _logs.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.history_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد سجلات', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20), itemCount: _logs.length,
              itemBuilder: (ctx, i) => _buildCard(_logs[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> log) {
    final action = log['action'] ?? log['activity'] ?? '';
    final user = log['user_name'] ?? log['userName'] ?? log['user'] ?? '';
    final details = log['details'] ?? log['description'] ?? '';
    final date = log['created_at'] ?? log['createdAt'] ?? log['date'] ?? '';
    final module = log['module'] ?? log['entity_type'] ?? log['entityType'] ?? '';

    IconData icon;
    Color iconColor;
    switch (action.toString().toLowerCase()) {
      case 'create': case 'add': icon = Icons.add_circle_outline; iconColor = AppColors.success; break;
      case 'update': case 'edit': icon = Icons.edit_outlined; iconColor = const Color(0xFF2563EB); break;
      case 'delete': case 'remove': icon = Icons.delete_outline; iconColor = AppColors.error; break;
      case 'login': icon = Icons.login; iconColor = AppColors.primary; break;
      case 'logout': icon = Icons.logout; iconColor = const Color(0xFFD97706); break;
      default: icon = Icons.history; iconColor = AppColors.textMuted;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 20)),
        title: Text(_actionLabel(action.toString()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (details.toString().isNotEmpty) Text(details.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          Row(children: [
            if (user.toString().isNotEmpty) ...[
              const Icon(Icons.person_outline, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 2),
              Text(user.toString(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(width: 8),
            ],
            if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ]),
        ]),
        trailing: module.toString().isNotEmpty ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(4)),
          child: Text(module.toString(), style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ) : null,
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action.toLowerCase()) {
      case 'create': case 'add': return 'إنشاء';
      case 'update': case 'edit': return 'تعديل';
      case 'delete': case 'remove': return 'حذف';
      case 'login': return 'تسجيل دخول';
      case 'logout': return 'تسجيل خروج';
      case 'view': return 'عرض';
      case 'export': return 'تصدير';
      default: return action;
    }
  }
}
