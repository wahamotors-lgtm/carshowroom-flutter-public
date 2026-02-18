import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getNotes(_token);
      if (!mounted) return;
      setState(() { _notes = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = 'فشل تحميل الملاحظات'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملاحظات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.notesPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : _notes.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.note_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد ملاحظات', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), itemCount: _notes.length,
              itemBuilder: (ctx, i) => _buildCard(_notes[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> note) {
    final id = note['_id'] ?? note['id'] ?? '';
    final title = note['title'] ?? '';
    final content = note['content'] ?? note['body'] ?? note['text'] ?? '';
    final date = note['created_at'] ?? note['createdAt'] ?? note['date'] ?? '';
    final priority = note['priority'] ?? '';

    Color priorityColor;
    switch (priority.toString().toLowerCase()) {
      case 'high': case 'urgent': priorityColor = AppColors.error; break;
      case 'medium': priorityColor = const Color(0xFFD97706); break;
      default: priorityColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _confirmDelete(id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.note, color: priorityColor, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(title.isNotEmpty ? title : 'ملاحظة', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
              if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
            if (content.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(content.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final titleC = TextEditingController();
    final contentC = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة ملاحظة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: titleC, decoration: InputDecoration(
          labelText: 'العنوان', prefixIcon: const Icon(Icons.title, size: 20), filled: true, fillColor: AppColors.bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ))),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: contentC, maxLines: 4, decoration: InputDecoration(
          labelText: 'المحتوى', alignLabelWithHint: true, filled: true, fillColor: AppColors.bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (titleC.text.trim().isEmpty && contentC.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            try {
              await _ds.createNote(_token, { 'title': titleC.text.trim(), 'content': contentC.text.trim() });
              _load();
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إضافة الملاحظة'), backgroundColor: AppColors.error));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف الملاحظة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذه الملاحظة؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try { await _ds.deleteNote(_token, id); _load(); }
            catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الحذف'), backgroundColor: AppColors.error)); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}
