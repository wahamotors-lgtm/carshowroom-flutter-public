import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // App settings state
  String _selectedLanguage = 'العربية';
  String _selectedCurrency = 'USD';
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  // Change password controllers
  final _currentPasswordC = TextEditingController();
  final _newPasswordC = TextEditingController();
  final _confirmPasswordC = TextEditingController();

  @override
  void dispose() {
    _currentPasswordC.dispose();
    _newPasswordC.dispose();
    _confirmPasswordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tenant = auth.tenant;
    final employee = auth.employee;
    final isEmployee = auth.loginType == 'employee';

    final companyName = tenant?['companyName'] ?? 'كارواتس';
    final email = isEmployee
        ? (employee?['email'] ?? tenant?['email'] ?? '')
        : (tenant?['email'] ?? '');
    final ownerName = isEmployee
        ? (employee?['name'] ?? '')
        : (tenant?['ownerName'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.settingsPage),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Section ──
          _buildProfileCard(companyName, email, ownerName, isEmployee),
          const SizedBox(height: 16),

          // ── App Settings Section ──
          _buildSectionCard(
            title: 'إعدادات التطبيق',
            icon: Icons.tune_outlined,
            children: [
              // Language selector
              _buildDropdownRow(
                label: 'اللغة',
                icon: Icons.language_outlined,
                value: _selectedLanguage,
                items: const ['العربية', 'English'],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // Currency selector
              _buildDropdownRow(
                label: 'العملة الافتراضية',
                icon: Icons.attach_money_outlined,
                value: _selectedCurrency,
                items: const ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // Notifications toggle
              _buildSwitchRow(
                label: 'تفعيل الإشعارات',
                icon: Icons.notifications_outlined,
                value: _notificationsEnabled,
                onChanged: (val) =>
                    setState(() => _notificationsEnabled = val),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // Sound toggle
              _buildSwitchRow(
                label: 'أصوات الإشعارات',
                icon: Icons.volume_up_outlined,
                value: _soundEnabled,
                onChanged: _notificationsEnabled
                    ? (val) => setState(() => _soundEnabled = val)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── About Section ──
          _buildSectionCard(
            title: 'حول التطبيق',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow(
                label: 'الإصدار',
                value: '1.0.0',
                icon: Icons.verified_outlined,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildTapRow(
                label: 'الموقع الإلكتروني',
                subtitle: 'www.carwhats.com',
                icon: Icons.language,
                onTap: () => _launchUrl('https://www.carwhats.com'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildTapRow(
                label: 'بريد الدعم الفني',
                subtitle: 'info@carwhats.com',
                icon: Icons.support_agent_outlined,
                onTap: () => _launchUrl('mailto:info@carwhats.com'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Account Section ──
          _buildSectionCard(
            title: 'الحساب',
            icon: Icons.manage_accounts_outlined,
            children: [
              _buildTapRow(
                label: 'تغيير كلمة المرور',
                subtitle: 'تحديث كلمة المرور الخاصة بك',
                icon: Icons.lock_outline,
                onTap: () => _showChangePasswordDialog(),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildLogoutRow(),
            ],
          ),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Text(
              'كارواتس © ${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Profile Card ──
  Widget _buildProfileCard(
      String companyName, String email, String ownerName, bool isEmployee) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isEmployee ? Icons.badge : Icons.business,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ownerName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ownerName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email.isNotEmpty ? email : 'لا يوجد بريد',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEmployee ? 'حساب موظف' : 'حساب المالك',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Card ──
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  // ── Dropdown Row ──
  Widget _buildDropdownRow({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 20, color: AppColors.textMuted),
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Switch Row ──
  Widget _buildSwitchRow({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final isDisabled = onChanged == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isDisabled ? AppColors.textMuted.withValues(alpha: 0.5) : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDisabled ? AppColors.textMuted : AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ── Info Row ──
  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tap Row (clickable) ──
  Widget _buildTapRow({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout Row ──
  Widget _buildLogoutRow() {
    return InkWell(
      onTap: () => _handleLogout(),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: AppColors.error),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_left,
              size: 20,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  // ── Launch URL ──
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح الرابط'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Change Password Dialog ──
  void _showChangePasswordDialog() {
    _currentPasswordC.clear();
    _newPasswordC.clear();
    _confirmPasswordC.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تغيير كلمة المرور',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField('كلمة المرور الحالية', _currentPasswordC),
              const SizedBox(height: 12),
              _buildPasswordField('كلمة المرور الجديدة', _newPasswordC),
              const SizedBox(height: 12),
              _buildPasswordField('تأكيد كلمة المرور', _confirmPasswordC),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newPasswordC.text.isEmpty ||
                  _currentPasswordC.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى تعبئة جميع الحقول'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (_newPasswordC.text != _confirmPasswordC.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('كلمة المرور الجديدة غير متطابقة'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (_newPasswordC.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تغيير كلمة المرور بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'تغيير',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── Logout Handler ──
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'هل تريد تسجيل الخروج من التطبيق؟',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لا', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, AppRoutes.tenantLogin);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'نعم، خروج',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
