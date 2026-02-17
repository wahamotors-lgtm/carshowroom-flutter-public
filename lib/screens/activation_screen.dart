import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_button.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _tenantId;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _tenantId = args?['tenantId'];
    _email = args?['email'];
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleActivate() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _errorMessage = 'أدخل رمز التفعيل المكون من 6 أرقام');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await auth.activateTenant(_tenantId!, _codeController.text);

    if (!mounted) return;

    if (response['success'] == true) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'فشل التفعيل';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleResend() async {
    if (_tenantId == null) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await auth.resendActivationCode(_tenantId!);

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة إرسال رمز التفعيل'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'فشل إعادة إرسال الرمز';
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'خطأ في الاتصال بالسيرفر';
      });
    }

    if (mounted) {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mail icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.blue600.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: AppColors.blue400,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'تفعيل الحساب',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'تم إرسال رمز التفعيل إلى\n${_email ?? "بريدك الإلكتروني"}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Code input
                    LayoutBuilder(builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 300;
                      final otpFontSize = isSmall ? 22.0 : 28.0;
                      final otpSpacing = isSmall ? 8.0 : 12.0;
                      return TextFormField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: otpFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: otpSpacing,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: otpFontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: otpSpacing,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.blue400, width: 2),
                        ),
                      ),
                    );
                    }),
                    const SizedBox(height: 28),

                    // Activate button
                    LoadingButton(
                      text: 'تفعيل الحساب',
                      isLoading: _isLoading,
                      gradient: const LinearGradient(
                        colors: [AppColors.blue600, Color(0xFF3B82F6)],
                      ),
                      onPressed: _handleActivate,
                    ),
                    const SizedBox(height: 20),

                    // Resend
                    TextButton(
                      onPressed: _isResending ? null : _handleResend,
                      child: Text(
                        _isResending ? 'جاري الإرسال...' : 'إعادة إرسال الرمز',
                        style: TextStyle(
                          color: AppColors.blue400.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Back to register
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'العودة للتسجيل',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
