import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_button.dart';
import '../widgets/logo_header.dart';

class TenantRegisterScreen extends StatefulWidget {
  const TenantRegisterScreen({super.key});

  @override
  State<TenantRegisterScreen> createState() => _TenantRegisterScreenState();
}

class _TenantRegisterScreenState extends State<TenantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await auth.registerTenant(
      companyName: _companyNameController.text,
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.activation,
        arguments: {
          'tenantId': response['tenantId'],
          'email': _emailController.text,
        },
      );
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'فشل التسجيل';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const LogoHeader(iconSize: 48, fontSize: 24, textColor: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'البرنامج المحاسبي المتكامل',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                _buildRegisterCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إنشاء حساب جديد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'سجّل شركتك واحصل على فترة تجريبية مجانية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

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

            _buildDarkField('اسم الشركة', _companyNameController, Icons.business,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null),
            const SizedBox(height: 14),
            _buildDarkField('اسم المالك', _ownerNameController, Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null),
            const SizedBox(height: 14),
            _buildDarkField('البريد الإلكتروني', _emailController, Icons.email_outlined,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
              if (v!.isEmpty) return 'مطلوب';
              if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
              return null;
            }),
            const SizedBox(height: 14),
            _buildDarkField('رقم الهاتف (اختياري)', _phoneController, Icons.phone_outlined,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _buildDarkField('كلمة المرور', _passwordController, Icons.lock_outline,
                obscure: _obscurePassword,
                toggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                validator: (v) {
              if (v!.isEmpty) return 'مطلوب';
              if (v.length < 6) return 'الحد الأدنى 6 أحرف';
              return null;
            }),
            const SizedBox(height: 14),
            _buildDarkField(
                'تأكيد كلمة المرور', _confirmPasswordController, Icons.lock_outline,
                obscure: _obscureConfirm,
                toggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
              if (v != _passwordController.text) return 'كلمة المرور غير متطابقة';
              return null;
            }),
            const SizedBox(height: 28),

            LoadingButton(
              text: 'إنشاء حساب تجريبي مجاني',
              isLoading: _isLoading,
              gradient: const LinearGradient(
                colors: [AppColors.blue600, Color(0xFF3B82F6)],
              ),
              onPressed: _handleRegister,
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'لديك حساب بالفعل؟ ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      color: AppColors.blue400,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
