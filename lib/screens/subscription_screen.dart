import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final DataService _ds;
  Map<String, dynamic>? _subscription;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadData();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _ds.getSubscriptionStatus(_token);
      if (!mounted) return;
      setState(() { _subscription = result; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل بيانات الاشتراك'; _isLoading = false; });
    }
  }

  String _getPlanLabel(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'monthly': return 'شهري';
      case 'yearly': return 'سنوي';
      case 'trial': return 'تجريبي';
      case 'free': return 'مجاني';
      case 'premium': return 'مميز';
      default: return plan ?? 'غير محدد';
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return 'فعّال';
      case 'expired': return 'منتهي';
      case 'trial': return 'فترة تجريبية';
      case 'cancelled': return 'ملغى';
      case 'suspended': return 'معلّق';
      default: return status ?? 'غير معروف';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return AppColors.success;
      case 'expired': return AppColors.error;
      case 'trial': return const Color(0xFFD97706);
      case 'cancelled': return AppColors.error;
      case 'suspended': return const Color(0xFFDB2777);
      default: return AppColors.textMuted;
    }
  }

  bool _isExpired() {
    final status = (_subscription?['status'] ?? '').toString().toLowerCase();
    return status == 'expired' || status == 'cancelled' || status == 'suspended';
  }

  int _getDaysRemaining() {
    final endDate = _subscription?['trial_end_date'] ?? _subscription?['trialEndDate'] ?? _subscription?['end_date'] ?? _subscription?['endDate'];
    if (endDate == null) return 0;
    final end = DateTime.tryParse(endDate.toString());
    if (end == null) return 0;
    return end.difference(DateTime.now()).inDays;
  }

  Future<void> _processPayment(String plan, double amount) async {
    setState(() => _isProcessing = true);
    try {
      final result = await _ds.createSubscriptionPayment(_token, {
        'plan': plan,
        'amount': amount,
        'currency': 'AED',
      });
      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Check if there's a payment URL to open
      final paymentUrl = result['payment_url'] ?? result['paymentUrl'] ?? result['url'];
      if (paymentUrl != null && paymentUrl.toString().isNotEmpty) {
        final uri = Uri.parse(paymentUrl.toString());
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'تم إرسال طلب الدفع'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData(); // Reload subscription status
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'فشل إنشاء طلب الدفع'), backgroundColor: AppColors.error),
      );
    }
  }

  void _confirmPayment(String plan, double amount, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الاشتراك', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Icon(Icons.card_membership, size: 40, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text('$amount د.إ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('سيتم توجيهك إلى صفحة الدفع لإتمام العملية.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textGray)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _processPayment(plan, amount); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('متابعة الدفع', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراك', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.subscriptionPage),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildDetailsCard(),
                      const SizedBox(height: 16),
                      if (_isExpired()) ...[
                        _buildExpiredNotice(),
                        const SizedBox(height: 16),
                      ],
                      _buildPricingCards(),
                      const SizedBox(height: 16),
                      _buildInfoNotice(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final status = (_subscription?['status'] ?? '').toString();
    final plan = (_subscription?['plan'] ?? _subscription?['subscription_plan'] ?? '').toString();
    final statusColor = _getStatusColor(status);
    final daysRemaining = _getDaysRemaining();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _isExpired()
            ? const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)])
            : AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: (_isExpired() ? AppColors.error : AppColors.primary).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(
            _isExpired() ? Icons.warning_amber_rounded : Icons.verified_outlined,
            size: 48,
            color: _isExpired() ? AppColors.error : Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusLabel(status),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _isExpired() ? AppColors.error : Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'الخطة: ${_getPlanLabel(plan)}',
            style: TextStyle(fontSize: 14, color: _isExpired() ? AppColors.textGray : Colors.white.withValues(alpha: 0.8)),
          ),
          if (daysRemaining > 0 && !_isExpired()) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(
                'متبقي $daysRemaining يوم',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final trialEndDate = _subscription?['trial_end_date'] ?? _subscription?['trialEndDate'] ?? '';
    final endDate = _subscription?['end_date'] ?? _subscription?['endDate'] ?? '';
    final startDate = _subscription?['start_date'] ?? _subscription?['startDate'] ?? _subscription?['created_at'] ?? '';
    final daysRemaining = _getDaysRemaining();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text('تفاصيل الاشتراك', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (startDate.toString().isNotEmpty)
                  _detailRow(Icons.play_arrow_outlined, 'تاريخ البدء', startDate.toString().split('T').first),
                if (trialEndDate.toString().isNotEmpty)
                  _detailRow(Icons.timer_outlined, 'انتهاء التجريبي', trialEndDate.toString().split('T').first),
                if (endDate.toString().isNotEmpty)
                  _detailRow(Icons.event_outlined, 'تاريخ الانتهاء', endDate.toString().split('T').first),
                _detailRow(Icons.hourglass_bottom, 'الأيام المتبقية', daysRemaining > 0 ? '$daysRemaining يوم' : 'منتهي'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اشتراكك منتهي!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.error)),
                const SizedBox(height: 4),
                Text(
                  'يرجى تجديد الاشتراك للاستمرار في استخدام جميع ميزات التطبيق.',
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('خطط الاشتراك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ),
        // Monthly plan
        _buildPlanCard(
          title: 'الاشتراك الشهري',
          price: '299',
          currency: 'د.إ',
          period: '/ شهر',
          features: ['جميع الميزات', 'دعم فني', 'نسخ احتياطي يومي', 'إلغاء في أي وقت'],
          color: AppColors.blue600,
          bgColor: const Color(0xFFEFF6FF),
          onSubscribe: () => _confirmPayment('monthly', 299, 'الاشتراك الشهري'),
        ),
        const SizedBox(height: 12),
        // Yearly plan
        _buildPlanCard(
          title: 'الاشتراك السنوي',
          price: '3600',
          currency: 'د.إ',
          period: '/ سنة',
          features: ['جميع الميزات', 'دعم فني أولوية', 'نسخ احتياطي يومي', 'توفير شهرين مجاناً'],
          color: AppColors.primary,
          bgColor: const Color(0xFFF0FDF4),
          onSubscribe: () => _confirmPayment('yearly', 3600, 'الاشتراك السنوي'),
          recommended: true,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String currency,
    required String period,
    required List<String> features,
    required Color color,
    required Color bgColor,
    required VoidCallback onSubscribe,
    bool recommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: recommended ? color : const Color(0xFFE2E8F0), width: recommended ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          if (recommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              child: const Center(child: Text('الأفضل قيمة', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('$currency $period', style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('اشترك الآن', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text('معلومات هامة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          _tipRow('جميع المدفوعات آمنة ومشفرة.'),
          const SizedBox(height: 6),
          _tipRow('يمكنك إلغاء الاشتراك في أي وقت.'),
          const SizedBox(height: 6),
          _tipRow('للدعم الفني تواصل عبر البريد الإلكتروني.'),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.circle, size: 6, color: AppColors.textMuted)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.4))),
      ],
    );
  }
}
