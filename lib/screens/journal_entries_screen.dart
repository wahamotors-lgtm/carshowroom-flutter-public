import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/account_model.dart';
import '../models/journal_entry_model.dart';
import '../providers/auth_provider.dart';
import '../services/account_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

// Reference type options with Arabic labels and colors
const Map<String, String> _referenceTypeLabels = {
  'car': '\u0633\u064a\u0627\u0631\u0629',
  'sale': '\u0628\u064a\u0639',
  'expense': '\u0645\u0635\u0631\u0648\u0641',
  'container': '\u062d\u0627\u0648\u064a\u0629',
  'shipment': '\u0634\u062d\u0646\u0629',
};

Color _referenceTypeColor(String type) {
  switch (type) {
    case 'car':
      return AppColors.blue600;
    case 'sale':
      return AppColors.success;
    case 'expense':
      return AppColors.error;
    case 'container':
      return AppColors.teal500;
    case 'shipment':
      return AppColors.purple700;
    default:
      return AppColors.textMuted;
  }
}

class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({super.key});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  late final AccountService _accountService;
  List<JournalEntryModel> _entries = [];
  List<JournalEntryModel> _filteredEntries = [];
  List<AccountModel> _accounts = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _accountService = AccountService(ApiService());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _accountService.getJournalEntries(_token),
        _accountService.getAccounts(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<JournalEntryModel>;
        _accounts = results[1] as List<AccountModel>;
        // Sort by entry number descending (newest first)
        _entries.sort((a, b) => b.entryNumber.compareTo(a.entryNumber));
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : '\u0641\u0634\u0644 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0642\u064a\u0648\u062f';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredEntries = List.from(_entries);
    } else {
      _filteredEntries = _entries.where((e) {
        final descMatch = e.description.toLowerCase().contains(query);
        final debitName = _accountName(e.debitAccountId).toLowerCase();
        final creditName = _accountName(e.creditAccountId).toLowerCase();
        final accountMatch = debitName.contains(query) || creditName.contains(query);
        final entryNumMatch = e.entryNumber.toString().contains(query);
        return descMatch || accountMatch || entryNumMatch;
      }).toList();
    }
  }

  String _accountName(String id) {
    final account = _accounts.where((a) => a.id == id).firstOrNull;
    return account?.name ?? '\u063a\u064a\u0631 \u0645\u0639\u0631\u0648\u0641';
  }

  String _referenceTypeLabel(String? type) {
    if (type == null || type.isEmpty) return '';
    return _referenceTypeLabels[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0642\u064a\u0648\u062f \u0645\u062d\u0627\u0633\u0628\u064a\u0629',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.journalEntries),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _applyFilter()),
              decoration: InputDecoration(
                hintText: '\u0628\u062d\u062b \u0639\u0646 \u0642\u064a\u062f...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _applyFilter());
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Entry count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Text(
              '${_filteredEntries.length} \u0642\u064a\u062f',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Divider(height: 1),

          // Entry list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _filteredEntries.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: _filteredEntries.length,
                              itemBuilder: (context, index) => _buildEntryCard(_filteredEntries[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final hasSearch = _searchController.text.trim().isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u0646\u062a\u0627\u0626\u062c \u0644\u0644\u0628\u062d\u062b' : '\u0644\u0627 \u062a\u0648\u062c\u062f \u0642\u064a\u0648\u062f \u0645\u062d\u0627\u0633\u0628\u064a\u0629',
            style: const TextStyle(color: AppColors.textGray),
          ),
          const SizedBox(height: 4),
          Text(
            hasSearch ? '\u062c\u0631\u0628 \u0643\u0644\u0645\u0627\u062a \u0628\u062d\u062b \u0623\u062e\u0631\u0649' : '\u0627\u0636\u063a\u0637 + \u0644\u0625\u0636\u0627\u0641\u0629 \u0642\u064a\u062f \u062c\u062f\u064a\u062f',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(JournalEntryModel entry) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEntryDetails(entry),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: entry number + description + date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${entry.entryNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  // Reference type badge
                  if (entry.referenceType != null && entry.referenceType!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _referenceTypeColor(entry.referenceType!).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _referenceTypeLabel(entry.referenceType),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _referenceTypeColor(entry.referenceType!),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    entry.date,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Debit and credit accounts
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _accountName(entry.debitAccountId),
                            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _accountName(entry.creditAccountId),
                            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${entry.amount.toStringAsFixed(2)} ${entry.currency}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
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

  void _showEntryDetails(JournalEntryModel entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text(
                  '\u0642\u064a\u062f #${entry.entryNumber}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _detailRow('\u0627\u0644\u062a\u0627\u0631\u064a\u062e', entry.date),
                _detailRow('\u0627\u0644\u0648\u0635\u0641', entry.description),
                _detailRow('\u062d\u0633\u0627\u0628 \u0645\u062f\u064a\u0646', _accountName(entry.debitAccountId)),
                _detailRow('\u062d\u0633\u0627\u0628 \u062f\u0627\u0626\u0646', _accountName(entry.creditAccountId)),
                _detailRow('\u0627\u0644\u0645\u0628\u0644\u063a', '${entry.amount.toStringAsFixed(2)} ${entry.currency}'),
                if (entry.referenceType != null && entry.referenceType!.isNotEmpty)
                  _detailRow('\u0646\u0648\u0639 \u0627\u0644\u0645\u0631\u062c\u0639', _referenceTypeLabel(entry.referenceType)),
                if (entry.referenceId != null && entry.referenceId!.isNotEmpty)
                  _detailRow('\u0631\u0642\u0645 \u0627\u0644\u0645\u0631\u062c\u0639', entry.referenceId!),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  _detailRow('\u0645\u0644\u0627\u062d\u0638\u0627\u062a', entry.notes!),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteEntry(entry);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('\u062d\u0630\u0641 \u0627\u0644\u0642\u064a\u062f'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog() {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u064a\u062c\u0628 \u0625\u0636\u0627\u0641\u0629 \u062d\u0633\u0627\u0628\u0627\u062a \u0623\u0648\u0644\u0627\u064b'), backgroundColor: AppColors.error),
      );
      return;
    }

    final descController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final referenceIdController = TextEditingController();
    String? debitAccountId;
    String? creditAccountId;
    String currency = 'USD';
    String? referenceType;
    final formKey = GlobalKey<FormState>();
    const currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '\u0625\u0636\u0627\u0641\u0629 \u0642\u064a\u062f \u0645\u062d\u0627\u0633\u0628\u064a',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: '\u0627\u0644\u0648\u0635\u0641',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    validator: (v) => v!.trim().isEmpty ? '\u0645\u0637\u0644\u0648\u0628' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: debitAccountId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '\u062d\u0633\u0627\u0628 \u0645\u062f\u064a\u0646 (\u0645\u0646)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: _accounts.map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(a.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => debitAccountId = v),
                    validator: (v) => v == null ? '\u0645\u0637\u0644\u0648\u0628' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: creditAccountId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '\u062d\u0633\u0627\u0628 \u062f\u0627\u0626\u0646 (\u0625\u0644\u0649)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: _accounts.map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(a.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => creditAccountId = v),
                    validator: (v) => v == null ? '\u0645\u0637\u0644\u0648\u0628' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '\u0627\u0644\u0645\u0628\u0644\u063a',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          validator: (v) {
                            if (v!.trim().isEmpty) return '\u0645\u0637\u0644\u0648\u0628';
                            if (double.tryParse(v) == null || double.parse(v) <= 0) return '\u063a\u064a\u0631 \u0635\u062d\u064a\u062d';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currency,
                          decoration: InputDecoration(
                            labelText: '\u0627\u0644\u0639\u0645\u0644\u0629',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          ),
                          items: currencies.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (v) => setDialogState(() => currency = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: '\u0645\u0644\u0627\u062d\u0638\u0627\u062a (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Reference type dropdown
                  DropdownButtonFormField<String>(
                    value: referenceType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '\u0646\u0648\u0639 \u0627\u0644\u0645\u0631\u062c\u0639 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('\u0628\u062f\u0648\u0646', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                      ...['car', 'sale', 'expense', 'container', 'shipment'].map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          _referenceTypeLabels[type] ?? type,
                          style: const TextStyle(fontSize: 13),
                        ),
                      )),
                    ],
                    onChanged: (v) => setDialogState(() {
                      referenceType = v;
                      if (v == null) referenceIdController.clear();
                    }),
                  ),
                  // Reference ID - only shown when reference_type is selected
                  if (referenceType != null) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: referenceIdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '\u0631\u0642\u0645 \u0627\u0644\u0645\u0631\u062c\u0639 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('\u0625\u0644\u063a\u0627\u0621'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (debitAccountId == creditAccountId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('\u0627\u0644\u062d\u0633\u0627\u0628 \u0627\u0644\u0645\u062f\u064a\u0646 \u0648\u0627\u0644\u062f\u0627\u0626\u0646 \u064a\u062c\u0628 \u0623\u0646 \u064a\u0643\u0648\u0646\u0627 \u0645\u062e\u062a\u0644\u0641\u064a\u0646'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _createEntry(
                  description: descController.text.trim(),
                  debitAccountId: debitAccountId!,
                  creditAccountId: creditAccountId!,
                  amount: double.parse(amountController.text.trim()),
                  currency: currency,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  referenceType: referenceType,
                  referenceId: referenceIdController.text.trim().isEmpty ? null : referenceIdController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('\u0625\u0636\u0627\u0641\u0629', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createEntry({
    required String description,
    required String debitAccountId,
    required String creditAccountId,
    required double amount,
    required String currency,
    String? notes,
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      final entryNumber = await _accountService.getNextEntryNumber(_token);
      final now = DateTime.now();
      await _accountService.createJournalEntry(_token, {
        'entry_number': entryNumber,
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'description': description,
        'debit_account_id': debitAccountId,
        'credit_account_id': creditAccountId,
        'amount': amount,
        'currency': currency,
        if (notes != null) 'notes': notes,
        if (referenceType != null) 'reference_type': referenceType,
        if (referenceId != null) 'reference_id': referenceId,
      });
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('\u062a\u0645 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0642\u064a\u062f'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : '\u0641\u0634\u0644 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0642\u064a\u062f'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmDeleteEntry(JournalEntryModel entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('\u062d\u0630\u0641 \u0627\u0644\u0642\u064a\u062f', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          '\u0647\u0644 \u0623\u0646\u062a \u0645\u062a\u0623\u0643\u062f \u0645\u0646 \u062d\u0630\u0641 \u0642\u064a\u062f #${entry.entryNumber}\u061f',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textGray),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('\u0625\u0644\u063a\u0627\u0621')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _accountService.deleteJournalEntry(_token, entry.id);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0642\u064a\u062f'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e is ApiException ? e.message : '\u0641\u0634\u0644 \u062d\u0630\u0641 \u0627\u0644\u0642\u064a\u062f'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('\u062d\u0630\u0641', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
