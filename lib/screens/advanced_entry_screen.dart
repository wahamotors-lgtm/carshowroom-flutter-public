import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/account_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../models/account_model.dart';

// ── Journal line model ──

class _JournalLine {
  String? accountId;
  final TextEditingController debitController;
  final TextEditingController creditController;

  _JournalLine()
      : debitController = TextEditingController(),
        creditController = TextEditingController();

  double get debit => double.tryParse(debitController.text.trim()) ?? 0;
  double get credit => double.tryParse(creditController.text.trim()) ?? 0;

  void dispose() {
    debitController.dispose();
    creditController.dispose();
  }
}

// ── Screen ──

class AdvancedEntryScreen extends StatefulWidget {
  const AdvancedEntryScreen({super.key});

  @override
  State<AdvancedEntryScreen> createState() => _AdvancedEntryScreenState();
}

class _AdvancedEntryScreenState extends State<AdvancedEntryScreen> {
  late final AccountService _accountService;

  List<AccountModel> _accounts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  // Header fields
  int _entryNumber = 0;
  DateTime _entryDate = DateTime.now();
  final _descriptionController = TextEditingController();
  String _currency = 'USD';

  // Journal lines
  final List<_JournalLine> _lines = [];

  // Notes
  final _notesController = TextEditingController();

  static const _currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

  @override
  void initState() {
    super.initState();
    _accountService = AccountService(ApiService());
    // Start with 2 empty lines
    _lines.add(_JournalLine());
    _lines.add(_JournalLine());
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
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
      final results = await Future.wait([
        _accountService.getAccounts(_token),
        _accountService.getNextEntryNumber(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _accounts = results[0] as List<AccountModel>;
        _entryNumber = results[1] as int;
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

  // ── Balance calculations ──

  double get _totalDebits {
    double total = 0;
    for (final line in _lines) {
      total += line.debit;
    }
    return total;
  }

  double get _totalCredits {
    double total = 0;
    for (final line in _lines) {
      total += line.credit;
    }
    return total;
  }

  double get _difference => (_totalDebits - _totalCredits).abs();

  bool get _isBalanced =>
      _totalDebits > 0 && _totalCredits > 0 && _difference < 0.001;

  // ── Line management ──

  void _addLine() {
    setState(() {
      _lines.add(_JournalLine());
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يحتوي القيد على سطرين على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  // ── Date picker ──

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
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
      setState(() => _entryDate = picked);
    }
  }

  // ── Format date ──

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ── Submit ──

  Future<void> _submit() async {
    // Validate description
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال وصف القيد'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate all lines have accounts
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].accountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى اختيار الحساب في السطر ${i + 1}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_lines[i].debit == 0 && _lines[i].credit == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى إدخال مبلغ مدين أو دائن في السطر ${i + 1}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('القيد غير متوازن - مجموع المدين لا يساوي مجموع الدائن'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateStr = _formatDate(_entryDate);

      // Build debit lines and credit lines
      final debitLines = <_JournalLine>[];
      final creditLines = <_JournalLine>[];
      for (final line in _lines) {
        if (line.debit > 0) debitLines.add(line);
        if (line.credit > 0) creditLines.add(line);
      }

      // Create journal entries pairing debit and credit accounts
      // For compound entries, we create multiple entries sharing the same entry_number
      int successCount = 0;
      for (final dLine in debitLines) {
        for (final cLine in creditLines) {
          // Distribute amounts: use the minimum of remaining debit/credit
          // For simplicity, send each combination as a separate entry
          final amount = dLine.debit <= cLine.credit ? dLine.debit : cLine.credit;
          if (amount <= 0) continue;

          await _accountService.createJournalEntry(_token, {
            'entry_number': _entryNumber,
            'date': dateStr,
            'description': _descriptionController.text.trim(),
            'debit_account_id': dLine.accountId,
            'credit_account_id': cLine.accountId,
            'amount': amount,
            'currency': _currency,
            'notes': _notesController.text.trim(),
            'type': 'advanced',
          });
          successCount++;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل القيد المتقدم بنجاح ($successCount قيود)'),
          backgroundColor: AppColors.success,
        ),
      );

      // Clear form
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : 'فشل تسجيل القيد',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _descriptionController.clear();
    _notesController.clear();
    _currency = 'USD';
    _entryDate = DateTime.now();
    for (final line in _lines) {
      line.dispose();
    }
    _lines.clear();
    _lines.add(_JournalLine());
    _lines.add(_JournalLine());
    // Reload to get next entry number
    _loadData();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'قيد متقدم',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.advancedEntry),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildErrorView()
              : _buildForm(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header card
          _buildHeaderCard(),
          const SizedBox(height: 14),

          // 2. Journal lines section
          _buildLinesSection(),
          const SizedBox(height: 14),

          // 3. Balance bar
          _buildBalanceBar(),
          const SizedBox(height: 14),

          // 4. Notes
          _buildNotesCard(),
          const SizedBox(height: 18),

          // 5. Submit button
          _buildSubmitButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── 1. Header Card ──

  Widget _buildHeaderCard() {
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
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.library_books_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'بيانات القيد',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Entry number + Date row
          Row(
            children: [
              // Entry number (read-only)
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: '$_entryNumber',
                  decoration: InputDecoration(
                    labelText: 'رقم القيد',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    prefixIcon: const Icon(
                      Icons.tag,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Date picker
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                    child: Text(
                      _formatDate(_entryDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'وصف القيد',
              hintText: 'أدخل وصف القيد المحاسبي...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              prefixIcon: const Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Currency dropdown
          DropdownButtonFormField<String>(
            value: _currency,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'العملة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              prefixIcon: const Icon(
                Icons.currency_exchange,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
            items: _currencies
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _currency = v!),
          ),
        ],
      ),
    );
  }

  // ── 2. Journal Lines Section ──

  Widget _buildLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.format_list_numbered,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'سطور القيد',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${_lines.length} سطور',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Lines list
        ...List.generate(_lines.length, (i) => _buildLineCard(i)),

        const SizedBox(height: 10),

        // Add line button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'إضافة سطر',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineCard(int index) {
    final line = _lines[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line header row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.blue600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'سطر ${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGray,
                ),
              ),
              const Spacer(),
              // Delete button
              InkWell(
                onTap: () => _removeLine(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Account dropdown
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: line.accountId,
            decoration: InputDecoration(
              labelText: 'الحساب',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              prefixIcon: const Icon(
                Icons.account_balance_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
            items: _accounts
                .map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      a.name,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => line.accountId = v),
          ),
          const SizedBox(height: 10),

          // Debit + Credit row
          Row(
            children: [
              // Debit
              Expanded(
                child: TextFormField(
                  controller: line.debitController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'مدين',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              // Credit
              Expanded(
                child: TextFormField(
                  controller: line.creditController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'دائن',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: AppColors.success,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Balance Bar ──

  Widget _buildBalanceBar() {
    final balanced = _isBalanced;
    final barColor = balanced ? AppColors.success : AppColors.error;
    final bgColor = balanced
        ? AppColors.success.withValues(alpha: 0.08)
        : AppColors.error.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: barColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          // Totals row
          Row(
            children: [
              // Total debits
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'إجمالي المدين',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _totalDebits.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              // Equals / Not equals icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  balanced ? Icons.check : Icons.close,
                  size: 20,
                  color: barColor,
                ),
              ),
              // Total credits
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'إجمالي الدائن',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _totalCredits.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Difference row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              balanced
                  ? 'القيد متوازن'
                  : 'الفرق: ${_difference.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Notes Card ──

  Widget _buildNotesCard() {
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
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'ملاحظات (اختياري)',
          hintText: 'أدخل أي ملاحظات إضافية...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Icon(
              Icons.notes_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── 5. Submit Button ──

  Widget _buildSubmitButton() {
    final canSubmit = _isBalanced && !_isSubmitting;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canSubmit ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.3),
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canSubmit ? 2 : 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canSubmit
                        ? Icons.check_circle_outline
                        : Icons.block_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    canSubmit ? 'تسجيل القيد' : 'القيد غير متوازن',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
