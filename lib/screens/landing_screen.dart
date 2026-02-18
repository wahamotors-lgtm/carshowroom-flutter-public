import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildFeaturesSection(),
            _buildStatsSection(),
            _buildPricingSection(),
            _buildCtaSection(context),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0D9488), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(children: [
        // Logo area
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(Icons.directions_car, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('كارواتس', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('CarWhats Group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 3)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text('النظام المحاسبي المتكامل لإدارة معارض السيارات',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
        ),
        const SizedBox(height: 30),
        // CTA Buttons
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.tenantLogin),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.tenantRegister),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حساب جديد', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ]),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // FEATURES SECTION
  // ═══════════════════════════════════════
  Widget _buildFeaturesSection() {
    const features = [
      _FeatureItem(icon: Icons.directions_car, title: 'إدارة المخزون', description: 'تتبع جميع السيارات من الشراء حتى البيع مع حالات متعددة', color: Color(0xFF3B82F6)),
      _FeatureItem(icon: Icons.account_balance, title: 'المحاسبة المالية', description: 'نظام محاسبي متكامل مع قيود يومية وميزان مراجعة', color: Color(0xFF8B5CF6)),
      _FeatureItem(icon: Icons.point_of_sale, title: 'إدارة المبيعات', description: 'تسجيل المبيعات والعمولات وحساب الأرباح تلقائياً', color: Color(0xFF10B981)),
      _FeatureItem(icon: Icons.local_shipping, title: 'الشحن والحاويات', description: 'تتبع الشحنات والحاويات من كوريا إلى المعرض', color: Color(0xFFF59E0B)),
      _FeatureItem(icon: Icons.assessment, title: 'التقارير المتقدمة', description: 'تقارير شاملة عن الأداء والأرباح والمبيعات', color: Color(0xFFEF4444)),
      _FeatureItem(icon: Icons.people, title: 'متعدد المستخدمين', description: 'صلاحيات متعددة للموظفين مع تسجيل النشاطات', color: Color(0xFF06B6D4)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      color: Colors.white,
      child: Column(children: [
        const Text('مميزات النظام', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text('كل ما تحتاجه لإدارة معرضك في مكان واحد', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 28),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: features.map((f) => _buildFeatureCard(f)).toList(),
        ),
      ]),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: feature.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(feature.icon, color: feature.color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(feature.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(feature.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // STATS SECTION
  // ═══════════════════════════════════════
  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(children: [
        Text('أرقام نفتخر بها', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.9))),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _statItem('+500', 'معرض يستخدم النظام')),
          Expanded(child: _statItem('+10K', 'سيارة مسجلة')),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _statItem('+5K', 'عملية بيع شهرياً')),
          Expanded(child: _statItem('24/7', 'دعم فني متواصل')),
        ]),
      ]),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
    ]);
  }

  // ═══════════════════════════════════════
  // PRICING SECTION
  // ═══════════════════════════════════════
  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      color: AppColors.bgLight,
      child: Column(children: [
        const Text('خطط الاشتراك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text('اختر الخطة المناسبة لمعرضك', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 24),

        // Free plan
        _pricingCard(
          title: 'الخطة المجانية',
          price: 'مجاناً',
          period: 'للأبد',
          color: const Color(0xFF64748B),
          features: ['10 سيارات كحد أقصى', 'مستخدم واحد', 'التقارير الأساسية', 'دعم عبر البريد'],
          isPopular: false,
        ),
        const SizedBox(height: 12),

        // Pro plan
        _pricingCard(
          title: 'الخطة الاحترافية',
          price: '\$29',
          period: 'شهرياً',
          color: AppColors.primary,
          features: ['سيارات غير محدودة', 'حتى 5 مستخدمين', 'جميع التقارير', 'الشحن والحاويات', 'النسخ الاحتياطي', 'دعم فني أولوي'],
          isPopular: true,
        ),
        const SizedBox(height: 12),

        // Enterprise plan
        _pricingCard(
          title: 'خطة المؤسسات',
          price: '\$79',
          period: 'شهرياً',
          color: const Color(0xFF8B5CF6),
          features: ['كل مميزات الاحترافية', 'مستخدمين غير محدودين', 'API مخصص', 'مدير حساب مخصص', 'تخصيص كامل', 'اتفاقية مستوى الخدمة'],
          isPopular: false,
        ),
      ]),
    );
  }

  Widget _pricingCard({
    required String title,
    required String price,
    required String period,
    required Color color,
    required List<String> features,
    required bool isPopular,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular ? Border.all(color: color, width: 2) : Border.all(color: Colors.grey.shade200),
        boxShadow: isPopular ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))] : null,
      ),
      child: Column(children: [
        if (isPopular) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: const Text('الأكثر شيوعاً', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
        ],
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(price, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color)),
          if (period.isNotEmpty && price != 'مجاناً') ...[
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('/ $period', style: TextStyle(fontSize: 13, color: Colors.grey.shade500))),
          ],
        ]),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(Icons.check_circle, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(f, style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
          ]),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // CTA SECTION
  // ═══════════════════════════════════════
  Widget _buildCtaSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF9333EA), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(children: [
        const Text('ابدأ الآن مجاناً', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 10),
        Text('سجّل حسابك وابدأ بإدارة معرضك خلال دقائق', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.tenantRegister),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 6,
          ),
          child: const Text('إنشاء حساب مجاني', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.tenantLogin),
          child: Text('لديك حساب بالفعل؟ سجّل دخولك', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      color: const Color(0xFF0F172A),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.directions_car, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          const Text('كارواتس', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        Text('النظام المحاسبي المتكامل لإدارة معارض السيارات', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
        const SizedBox(height: 16),
        Divider(color: Colors.white.withValues(alpha: 0.1)),
        const SizedBox(height: 12),
        Text('جميع الحقوق محفوظة  2024 CarWhats Group',
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
      ]),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
