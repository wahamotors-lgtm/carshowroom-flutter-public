import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

// ── Category helpers ──

const Map<String, String> _categoryLabels = {
  'shipping': 'شحن',
  'customs': 'جمارك',
  'transport': 'نقل',
  'loading': 'تحميل',
  'clearance': 'تخليص',
  'port_fees': 'رسوم ميناء',
  'government': 'رسوم حكومية',
  'car_expense': 'مصروف سيارة',
  'other': 'أخرى',
};

const List<String> _currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

class BulkExpenseScreen extends StatefulWidget {
  const BulkExpenseScreen({super.key});

  @override
  State<BulkExpenseScreen> createState() => _BulkExpenseScreenState();
}

class _BulkExpenseScreenState extends State<BulkExpenseScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  // ── Shared fields ──
  DateTime _sharedDate = DateTime.now();
  String _sharedCurrency = 'USD';
  String _sharedCategory = 'other';

  // ── Dynamic rows ──
  final List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    final api = ApiService();
    _ds = DataService(api);
    _addEmptyRow();
    _loadData();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      (row['desc'] as TextEditingController).dispose();
      (row['amount'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  // ── Data loading ──

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final accounts = await _ds.getAccounts(_token);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'فشل تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  // ── Row management ──

  void _addEmptyRow() {
    _rows.add({
      'desc': TextEditingController(),
      'amount': TextEditingController(),
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    final row = _rows[index];
    (row['desc'] as TextEditingController).dispose();
    (row['amount'] as TextEditingController).dispose();
    setState(() {
      _rows.removeAt(index);
    });
  }

  void _clearForm() {
    for (final row in _rows) {
      (row['desc'] as TextEditingController).dispose();
      (row['amount'] as TextEditingController).dispose();
    }
    setState(() {
      _rows.clear();
      _sharedDate = DateTime.now();
      _sharedCurrency = 'USD';
      _sharedCategory = 'other';
      _addEmptyRow();
    });
  }

  // ── Computed total ──

  double get _runningTotal {
    double total = 0;
    for (final row in _rows) {
      final txt = (row['amount'] as TextEditingController).text.trim();
      total += double.tryParse(txt) ?? 0;
    }
    return total;
  }

  // ── Date formatting ──

  String get _formattedDate =>
      '${_sharedDate.year}-${_sharedDate.month.toString().padLeft(2, '0')}-${_sharedDate.day.toString().padLeft(2, '0')}';

  // ── Submit logic ──

  Future<void> _submit() async {
    // Validate rows
    final validRows = <Map<String, String>>[];
    for (int i = 0; i < _rows.length; i++) {
      final desc = (_rows[i]['desc'] as TextEditingController).text.trim();
      final amountStr =
          (_rows[i]['amount'] as TextEditingController).text.trim();
      final amount = double.tryParse(amountStr);
      if (desc.isEmpty && amountStr.isEmpty) continue; // skip empty rows
      if (desc.isEmpty) {
        _showError('السطر ${i + 1}: الوصف مطلوب');
        return;
      }
      if (amount == null || amount <= 0) {
        _showError('السطر ${i + 1}: المبلغ غير صحيح');
        return;
      }
      validRows.add({'description': desc, 'amount': amountStr});
    }

    if (validRows.isEmpty) {
      _showError('أضف مصروف واحد على الأقل');
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تأكيد الإرسال',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سيتم إرسال ${validRows.length} مصروف',
              style: const TextStyle(fontSize: 15, color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'الإجمالي: ${_runningTotal.toStringAsFixed(2)} $_sharedCurrency',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'التاريخ: $_formattedDate',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textGray),
              textAlign: TextAlign.center,
            ),
            Text(
              'التصنيف: ${_categoryLabels[_sharedCategory] ?? _sharedCategory}',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('تأكيد الإرسال',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Send expenses one by one
    setState(() => _isSubmitting = true);
    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < validRows.length; i++) {
      if (!mounted) return;
      // Update progress message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري الإرسال ${i + 1} من ${validRows.length}...'),
          backgroundColor: AppColors.blue600,
          duration: const Duration(seconds: 30),
        ),
      );

      try {
        await _ds.createExpense(_token, {
          'description': validRows[i]['description'],
          'amount': double.tryParse(validRows[i]['amount']!) ?? 0,
          'currency': _sharedCurrency,
          'category': _sharedCategory,
          'date': _formattedDate,
        });
        successCount++;
      } catch (_) {
        failCount++;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _isSubmitting = false);

    if (failCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال $successCount مصروف بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      _clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'تم إرسال $successCount بنجاح، فشل $failCount مصروف'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // ── Date picker ──

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sharedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _sharedDate = picked);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مصروف جماعي',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.bulkExpense),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style:
                              const TextStyle(color: AppColors.textGray)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSharedHeaderCard(),
                          const SizedBox(height: 16),
                          _buildExpenseRowsSection(),
                          const SizedBox(height: 16),
                          _buildRunningTotalCard(),
                          const SizedBox(height: 20),
                          _buildSubmitButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    if (_isSubmitting)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'جاري الإرسال...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  // ── Shared header card ──

  Widget _buildSharedHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings, size: 20,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text(
                'الإعدادات المشتركة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date picker
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'التاريخ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                suffixIcon:
                    const Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                _formattedDate,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Currency + Category row
          Row(
            children: [
              // Currency dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sharedCurrency,
                  decoration: InputDecoration(
                    labelText: 'العملة',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                  ),
                  items: _currencies
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (v) =>
                          setState(() => _sharedCurrency = v!),
                ),
              ),
              const SizedBox(width: 12),
              // Category dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _sharedCategory,
                  decoration: InputDecoration(
                    labelText: 'التصنيف',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                  ),
                  items: _categoryLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (v) =>
                          setState(() => _sharedCategory = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dynamic expense rows section ──

  Widget _buildExpenseRowsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, size: 20,
                    color: AppColors.blue600),
              ),
              const SizedBox(width: 10),
              Text(
                'المصاريف (${_rows.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '$_sharedCurrency',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Expense row cards
        ...List.generate(_rows.length, (index) {
          return _buildExpenseRowCard(index);
        }),

        const SizedBox(height: 12),

        // Add row button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() => _addEmptyRow());
                  },
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'إضافة سطر',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseRowCard(int index) {
    final descController = _rows[index]['desc'] as TextEditingController;
    final amountController = _rows[index]['amount'] as TextEditingController;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row number badge
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Description + Amount fields
          Expanded(
            child: Column(
              children: [
                // Description
                TextField(
                  controller: descController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'الوصف',
                    hintText: 'وصف المصروف',
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                // Amount
                TextField(
                  controller: amountController,
                  enabled: !_isSubmitting,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    hintText: '0.00',
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    isDense: true,
                    suffixText: _sharedCurrency,
                    suffixStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Delete button
          IconButton(
            onPressed: _isSubmitting || _rows.length <= 1
                ? null
                : () => _removeRow(index),
            icon: Icon(
              Icons.close,
              size: 20,
              color: _rows.length <= 1
                  ? AppColors.textMuted
                  : AppColors.error,
            ),
            tooltip: 'حذف السطر',
            padding: const EdgeInsets.all(8),
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ── Running total card ──

  Widget _buildRunningTotalCard() {
    final total = _runningTotal;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calculate_outlined,
                size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإجمالي',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'مجموع جميع الأسطر',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)} $_sharedCurrency',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit button ──

  Widget _buildSubmitButton() {
    final validCount = _rows.where((row) {
      final desc = (row['desc'] as TextEditingController).text.trim();
      final amount = (row['amount'] as TextEditingController).text.trim();
      return desc.isNotEmpty && amount.isNotEmpty;
    }).length;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(
          _isSubmitting
              ? 'جاري الإرسال...'
              : 'إرسال المصاريف ($validCount)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
