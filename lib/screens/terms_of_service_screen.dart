import 'package:flutter/material.dart';
import '../config/theme.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});
  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شروط الاستخدام', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.gavel_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('شروط الاستخدام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                Text('آخر تحديث: يناير 2025', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
            ]),
            const SizedBox(height: 24),

            _sectionTitle('القبول بالشروط'),
            _sectionBody(
              'باستخدامك لنظام كارواتس المحاسبي لإدارة السيارات، فإنك توافق على الالتزام بشروط الاستخدام هذه. '
              'إذا كنت لا توافق على أي من هذه الشروط، يرجى عدم استخدام النظام.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('وصف الخدمة'),
            _sectionBody(
              'كارواتس هو نظام محاسبي سحابي متكامل مصمم لإدارة:\n'
              '- مخزون السيارات (شراء، بيع، شحن، تتبع).\n'
              '- العمليات المالية والمحاسبية.\n'
              '- إدارة العملاء والموردين.\n'
              '- إدارة الموظفين والرواتب.\n'
              '- التقارير والإحصائيات.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('حسابات المستخدمين'),
            _sectionBody(
              '- أنت مسؤول عن الحفاظ على سرية بيانات تسجيل الدخول الخاصة بك.\n'
              '- يجب أن تكون المعلومات المقدمة عند التسجيل صحيحة ودقيقة.\n'
              '- لا يجوز مشاركة حسابك مع أشخاص غير مصرح لهم.\n'
              '- أنت مسؤول عن جميع الأنشطة التي تتم من خلال حسابك.\n'
              '- يجب إبلاغنا فوراً في حالة أي استخدام غير مصرح به.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('الاشتراك والدفع'),
            _sectionBody(
              '- تتوفر خطط اشتراك مختلفة حسب احتياجات عملك.\n'
              '- الأسعار قابلة للتغيير مع إشعار مسبق بـ 30 يوماً.\n'
              '- يتم تجديد الاشتراك تلقائياً ما لم يتم إلغاؤه.\n'
              '- في حالة عدم الدفع، قد يتم تعليق الحساب مؤقتاً.\n'
              '- الفترة التجريبية المجانية تخضع لشروط محددة.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('استخدام النظام'),
            _sectionBody(
              'يلتزم المستخدم بما يلي:\n'
              '- استخدام النظام للأغراض القانونية فقط.\n'
              '- عدم محاولة اختراق أو التلاعب بالنظام.\n'
              '- عدم نقل أو نشر فيروسات أو برمجيات ضارة.\n'
              '- عدم استخدام النظام بطريقة تؤثر سلباً على أداء الخوادم.\n'
              '- الالتزام بقوانين حماية البيانات المعمول بها.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('الملكية الفكرية'),
            _sectionBody(
              '- جميع حقوق الملكية الفكرية للنظام محفوظة لشركة كارواتس.\n'
              '- لا يجوز نسخ أو تعديل أو توزيع أي جزء من النظام.\n'
              '- بياناتك تبقى ملكاً لك وتحتفظ بجميع حقوقك عليها.\n'
              '- يُمنح لك ترخيص محدود وغير حصري لاستخدام النظام.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('حدود المسؤولية'),
            _sectionBody(
              '- النظام مقدم "كما هو" دون ضمانات صريحة أو ضمنية.\n'
              '- لا نتحمل مسؤولية أي خسائر ناتجة عن انقطاع الخدمة.\n'
              '- لا نتحمل مسؤولية دقة البيانات المدخلة من قبل المستخدمين.\n'
              '- نبذل قصارى جهدنا لضمان توفر الخدمة بنسبة 99.9%.\n'
              '- في حالة حدوث خلل، نلتزم بإصلاحه في أسرع وقت ممكن.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('إنهاء الخدمة'),
            _sectionBody(
              '- يمكنك إلغاء اشتراكك في أي وقت.\n'
              '- نحتفظ بحق تعليق أو إنهاء الحسابات المخالفة للشروط.\n'
              '- عند الإنهاء، يمكنك تصدير بياناتك خلال 30 يوماً.\n'
              '- بعد 90 يوماً من الإنهاء، يتم حذف البيانات نهائياً.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('التعديلات على الشروط'),
            _sectionBody(
              'نحتفظ بحق تعديل هذه الشروط في أي وقت. '
              'سيتم إخطارك بأي تغييرات جوهرية عبر البريد الإلكتروني أو إشعار داخل النظام. '
              'استمرارك في استخدام النظام بعد التعديل يعني قبولك للشروط الجديدة.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('القانون الواجب التطبيق'),
            _sectionBody(
              'تخضع هذه الشروط للقوانين المعمول بها. '
              'في حالة وجود أي نزاع، يتم حله ودياً أولاً، '
              'وفي حالة عدم التوصل لحل، يتم اللجوء إلى المحاكم المختصة.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('تواصل معنا'),
            _sectionBody(
              'لأي استفسارات حول شروط الاستخدام:\n'
              '- البريد الإلكتروني: info@carwhats.com\n'
              '- الموقع الإلكتروني: https://carwhats.group',
            ),
            const SizedBox(height: 16),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'باستخدامك لنظام كارواتس، فإنك توافق على جميع الشروط والأحكام المذكورة أعلاه.',
                style: TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ]),
    );
  }

  Widget _sectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textGray, height: 1.8)),
    );
  }
}
