import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/account_model.dart';
import '../providers/auth_provider.dart';
import '../services/account_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final AccountService _accountService;
  List<AccountModel> _accounts = [];
  List<AccountModel> _filteredAccounts = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _accountService = AccountService(ApiService());
    _loadAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accounts = await _accountService.getAccounts(_token);
      debugPrint('Accounts loaded: ${accounts.length}');
      for (final a in accounts.take(3)) {
        debugPrint('  Account: id=${a.id}, name=${a.name}, parentId=${a.parentId}, type=${a.type}');
      }
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _applyFilter();
        _isLoading = false;
      });
      debugPrint('Root accounts: ${_rootAccounts.length}, filtered: ${_filteredAccounts.length}');
    } catch (e, st) {
      debugPrint('Accounts error: $e');
      debugPrint('Stack: $st');
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل الحسابات';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredAccounts = List.from(_accounts);
    } else {
      _filteredAccounts = _accounts.where((a) {
        return a.name.toLowerCase().contains(query) ||
            accountTypeLabel(a.type).contains(query) ||
            a.type.toLowerCase().contains(query);
      }).toList();
    }
  }

  // Build tree: get root accounts (no parentId)
  List<AccountModel> get _rootAccounts {
    return _filteredAccounts.where((a) => a.parentId == null || a.parentId!.isEmpty).toList();
  }

  List<AccountModel> _childrenOf(String parentId) {
    return _filteredAccounts.where((a) => a.parentId == parentId).toList();
  }

  bool _hasChildren(String id) {
    return _filteredAccounts.any((a) => a.parentId == id);
  }

  double _totalWithChildren(AccountModel account) {
    double total = account.balance;
    for (final child in _childrenOf(account.id)) {
      total += _totalWithChildren(child);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الحسابات',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_expandedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.unfold_less),
              tooltip: 'طي الكل',
              onPressed: () => setState(() => _expandedIds.clear()),
            )
          else
            IconButton(
              icon: const Icon(Icons.unfold_more),
              tooltip: 'توسيع الكل',
              onPressed: () {
                setState(() {
                  for (final a in _accounts) {
                    if (_hasChildren(a.id)) _expandedIds.add(a.id);
                  }
                });
              },
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.accounts),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddAccountDialog(),
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
                hintText: 'بحث عن حساب...',
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

          // Account count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Text(
              '${_filteredAccounts.length} حساب',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Divider(height: 1),

          // Account list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _rootAccounts.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadAccounts,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: _rootAccounts.length,
                              itemBuilder: (context, index) {
                                return _buildAccountTile(_rootAccounts[index], 0);
                              },
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
          Text(_error!, style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAccounts,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('لا توجد حسابات', style: TextStyle(color: AppColors.textGray, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('اضغط + لإضافة حساب جديد', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAccountTile(AccountModel account, int depth) {
    final hasChildren = _hasChildren(account.id);
    final isExpanded = _expandedIds.contains(account.id);
    final children = hasChildren ? _childrenOf(account.id) : <AccountModel>[];
    final totalBalance = _totalWithChildren(account);
    final indent = depth * 16.0;

    return Column(
      children: [
        InkWell(
          onTap: () => _showAccountDetails(account),
          onLongPress: () => _showAccountActions(account),
          child: Container(
            padding: EdgeInsets.fromLTRB(16 + indent, 12, 12, 12),
            decoration: BoxDecoration(
              color: depth == 0 ? Colors.white : Colors.white.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Expand/collapse toggle
                if (hasChildren)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedIds.remove(account.id);
                        } else {
                          _expandedIds.add(account.id);
                        }
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.textGray,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 36),

                // Type icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _typeColor(account.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _typeIcon(account.type),
                    color: _typeColor(account.type),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),

                // Name + type label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: depth == 0 ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        accountTypeLabel(account.type),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatBalance(account.balance),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: account.balance >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                    if (hasChildren && totalBalance != account.balance)
                      Text(
                        'الإجمالي: ${_formatBalance(totalBalance)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (account.currency != null)
                      Text(
                        account.currency!,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),

                // System badge
                if (account.isSystemAccount)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.lock, size: 12, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),

        // Children
        if (hasChildren && isExpanded)
          ...children.map((child) => _buildAccountTile(child, depth + 1)),
      ],
    );
  }

  String _formatBalance(double balance) {
    final abs = balance.abs();
    if (abs >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '${(balance / 1000).toStringAsFixed(1)}K';
    }
    return balance.toStringAsFixed(balance.truncateToDouble() == balance ? 0 : 2);
  }

  IconData _typeIcon(String type) {
    const icons = {
      'cash_box': Icons.savings_outlined,
      'bank': Icons.account_balance,
      'customer': Icons.person_outline,
      'supplier': Icons.local_shipping_outlined,
      'revenue': Icons.trending_up,
      'expense': Icons.trending_down,
      'showroom': Icons.storefront_outlined,
      'customs': Icons.gavel_outlined,
      'employee': Icons.badge_outlined,
      'purchases': Icons.shopping_cart_outlined,
      'capital': Icons.account_balance_wallet_outlined,
      'shipping_company': Icons.flight_outlined,
    };
    return icons[type] ?? Icons.folder_outlined;
  }

  Color _typeColor(String type) {
    const colors = {
      'cash_box': Color(0xFF059669),
      'bank': Color(0xFF2563EB),
      'customer': Color(0xFF0891B2),
      'supplier': Color(0xFFD97706),
      'revenue': Color(0xFF16A34A),
      'expense': Color(0xFFDC2626),
      'showroom': Color(0xFF7C3AED),
      'customs': Color(0xFF9333EA),
      'employee': Color(0xFF2563EB),
      'purchases': Color(0xFFEA580C),
      'capital': Color(0xFF059669),
      'shipping_company': Color(0xFF0284C7),
    };
    return colors[type] ?? const Color(0xFF64748B);
  }

  // ── Dialogs ──

  void _showAccountDetails(AccountModel account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AccountDetailSheet(
        account: account,
        childCount: _childrenOf(account.id).length,
        totalBalance: _totalWithChildren(account),
        onEdit: () {
          Navigator.pop(context);
          _showEditAccountDialog(account);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(account);
        },
      ),
    );
  }

  void _showAccountActions(AccountModel account) {
    if (account.isSystemAccount) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.blue600),
              title: const Text('تعديل الحساب'),
              onTap: () {
                Navigator.pop(context);
                _showEditAccountDialog(account);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.primary),
              title: const Text('إضافة حساب فرعي'),
              onTap: () {
                Navigator.pop(context);
                _showAddAccountDialog(parentId: account.id, parentName: account.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('حذف الحساب', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(account);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog({String? parentId, String? parentName}) {
    final nameController = TextEditingController();
    String selectedType = 'other';
    String? selectedCurrency;
    final formKey = GlobalKey<FormState>();

    final types = [
      'cash_box', 'bank', 'customer', 'supplier', 'revenue', 'expense',
      'showroom', 'customs', 'employee', 'purchases', 'capital',
      'shipping_company', 'other',
    ];

    const currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            parentName != null ? 'حساب فرعي - $parentName' : 'إضافة حساب جديد',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الحساب',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'نوع الحساب',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: types.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(accountTypeLabel(t), style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'العملة (اختياري)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('بدون تحديد', style: TextStyle(fontSize: 14))),
                      ...currencies.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 14)),
                      )),
                    ],
                    onChanged: (v) => setDialogState(() => selectedCurrency = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _createAccount(
                  name: nameController.text.trim(),
                  type: selectedType,
                  currency: selectedCurrency,
                  parentId: parentId,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(AccountModel account) {
    final nameController = TextEditingController(text: account.name);
    String selectedType = account.type;
    final formKey = GlobalKey<FormState>();

    final types = [
      'cash_box', 'bank', 'customer', 'supplier', 'revenue', 'expense',
      'showroom', 'customs', 'employee', 'purchases', 'capital',
      'shipping_company', 'other',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'تعديل الحساب',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الحساب',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: types.contains(selectedType) ? selectedType : 'other',
                    decoration: InputDecoration(
                      labelText: 'نوع الحساب',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: types.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(accountTypeLabel(t), style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _updateAccount(
                  account.id,
                  name: nameController.text.trim(),
                  type: selectedType,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AccountModel account) {
    if (account.isSystemAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن حذف حساب نظام'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'حذف الحساب',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${account.name}"؟\nلا يمكن التراجع عن هذا الإجراء.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textGray),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount(account.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── API Actions ──

  Future<void> _createAccount({
    required String name,
    required String type,
    String? currency,
    String? parentId,
  }) async {
    try {
      await _accountService.createAccount(_token, {
        'name': name,
        'type': type,
        'balance': 0,
        if (currency != null) 'currency': currency,
        if (parentId != null) 'parent_id': parentId,
      });
      _loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الحساب'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إضافة الحساب'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateAccount(String id, {required String name, required String type}) async {
    try {
      await _accountService.updateAccount(_token, id, {
        'name': name,
        'type': type,
      });
      _loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل الحساب'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تعديل الحساب'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteAccount(String id) async {
    try {
      await _accountService.deleteAccount(_token, id);
      _loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحساب'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حذف الحساب'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ── Account Detail Bottom Sheet ──

class _AccountDetailSheet extends StatelessWidget {
  final AccountModel account;
  final int childCount;
  final double totalBalance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountDetailSheet({
    required this.account,
    required this.childCount,
    required this.totalBalance,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Account name
              Text(
                account.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  accountTypeLabel(account.type),
                  style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),

              // Info cards
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: 'الرصيد',
                      value: account.balance.toStringAsFixed(2),
                      color: account.balance >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoCard(
                      label: 'العملة',
                      value: account.currency ?? 'متعددة',
                      color: AppColors.blue600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoCard(
                      label: 'حسابات فرعية',
                      value: '$childCount',
                      color: AppColors.purple700,
                    ),
                  ),
                ],
              ),
              if (childCount > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'الإجمالي مع الفروع: ',
                        style: TextStyle(fontSize: 13, color: AppColors.textGray),
                      ),
                      Text(
                        totalBalance.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Actions
              if (!account.isSystemAccount)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('تعديل'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blue600,
                          side: const BorderSide(color: AppColors.blue600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('حذف'),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
