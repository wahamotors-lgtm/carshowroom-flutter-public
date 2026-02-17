import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_button.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _companyEmailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isResendingOtp = false;
  String? _errorMessage;

  // OTP state
  bool _showOtp = false;
  String? _employeeId;
  String? _maskedEmail;

  @override
  void dispose() {
    _companyEmailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await auth.loginEmployee(
      _companyEmailController.text,
      _codeController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (response['success'] == true && response['requiresOTP'] != true) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else if (response['requiresOTP'] == true) {
      setState(() {
        _showOtp = true;
        _employeeId = response['employeeId'];
        _maskedEmail = response['maskedEmail'];
      });
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'فشل تسجيل الدخول';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _errorMessage = 'أدخل رمز التحقق المكون من 6 أرقام');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await auth.verifyEmployeeOtp(
      _employeeId!,
      _otpController.text,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'رمز التحقق غير صحيح';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleResendOtp() async {
    if (_employeeId == null) return;

    setState(() {
      _isResendingOtp = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await auth.resendEmployeeOtp(_employeeId!);

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة إرسال رمز التحقق'),
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
      setState(() => _isResendingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.purple),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _showOtp ? _buildOtpCard() : _buildLoginCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blue600, AppColors.purple700],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),

            const Text(
              'دخول الموظفين',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'أدخل بيانات الدخول الخاصة بك',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),

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
              const SizedBox(height: 16),
            ],

            // Company email
            _buildDarkField(
              'البريد الإلكتروني للشركة',
              _companyEmailController,
              Icons.business,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) return 'مطلوب';
                if (!v.contains('@')) return 'بريد غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Employee code
            _buildDarkField(
              'كود الموظف',
              _codeController,
              Icons.badge_outlined,
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 14),

            // Password
            _buildDarkField(
              'كلمة المرور',
              _passwordController,
              Icons.lock_outline,
              obscure: _obscurePassword,
              toggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 28),

            // Login button
            LoadingButton(
              text: 'تسجيل الدخول',
              isLoading: _isLoading,
              gradient: LinearGradient(
                colors: [AppColors.blue600, AppColors.purple700],
              ),
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 20),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'الرجوع لتسجيل دخول الشركة',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Company email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  'info@carwhats.com',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),

          const Text(
            'التحقق من البريد',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم إرسال رمز التحقق إلى\n${_maskedEmail ?? "بريدك"}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

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
            const SizedBox(height: 16),
          ],

          // OTP input
          TextFormField(
            controller: _otpController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 12,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 28,
                letterSpacing: 12,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          LoadingButton(
            text: 'تأكيد',
            isLoading: _isLoading,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
            ),
            onPressed: _handleVerifyOtp,
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: _isResendingOtp ? null : _handleResendOtp,
            child: Text(
              _isResendingOtp ? 'جاري الإرسال...' : 'إعادة إرسال الرمز',
              style: TextStyle(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          TextButton(
            onPressed: () => setState(() {
              _showOtp = false;
              _errorMessage = null;
            }),
            child: Text(
              'العودة لتسجيل الدخول',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextDirection? textDirection,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textDirection: textDirection,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue400, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFCA5A5)),
      ),
    );
  }
}
