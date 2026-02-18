import 'package:flutter/material.dart';
import '../config/theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                child: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('سياسة الخصوصية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                Text('آخر تحديث: يناير 2025', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
            ]),
            const SizedBox(height: 24),

            _sectionTitle('مقدمة'),
            _sectionBody(
              'نحن في كارواتس نلتزم بحماية خصوصيتك وبياناتك الشخصية. '
              'توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية المعلومات التي تقدمها لنا '
              'عند استخدام نظام كارواتس المحاسبي لإدارة السيارات.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('المعلومات التي نجمعها'),
            _sectionBody(
              '1. معلومات الحساب: الاسم، البريد الإلكتروني، رقم الهاتف، اسم الشركة.\n'
              '2. بيانات الأعمال: معلومات السيارات، المبيعات، المشتريات، البيانات المالية.\n'
              '3. معلومات تقنية: عنوان IP، نوع المتصفح، نظام التشغيل، سجلات الوصول.\n'
              '4. بيانات الاستخدام: تفاعلك مع النظام، الصفحات التي تزورها، الإجراءات التي تتخذها.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('كيف نستخدم معلوماتك'),
            _sectionBody(
              '- تقديم وتحسين خدمات النظام المحاسبي.\n'
              '- إدارة حسابك وتوفير الدعم الفني.\n'
              '- إرسال إشعارات مهمة حول حسابك أو تحديثات النظام.\n'
              '- تحليل الاستخدام لتحسين تجربة المستخدم.\n'
              '- الامتثال للمتطلبات القانونية والتنظيمية.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('حماية البيانات'),
            _sectionBody(
              'نستخدم إجراءات أمنية متقدمة لحماية بياناتك، تشمل:\n'
              '- تشفير البيانات أثناء النقل والتخزين (SSL/TLS).\n'
              '- نظام مصادقة متعدد العوامل.\n'
              '- نسخ احتياطية منتظمة ومشفرة.\n'
              '- مراقبة أمنية مستمرة على مدار الساعة.\n'
              '- فصل بيانات كل شركة (Multi-tenant isolation).',
            ),
            const SizedBox(height: 20),

            _sectionTitle('مشاركة البيانات'),
            _sectionBody(
              'لا نبيع أو نؤجر بياناتك الشخصية لأطراف ثالثة. '
              'قد نشارك معلوماتك فقط في الحالات التالية:\n'
              '- بموافقتك الصريحة.\n'
              '- للامتثال لأمر قضائي أو متطلب قانوني.\n'
              '- لحماية حقوقنا أو سلامة المستخدمين.\n'
              '- مع مقدمي خدمات موثوقين يعملون نيابة عنا (مثل الاستضافة).',
            ),
            const SizedBox(height: 20),

            _sectionTitle('حقوقك'),
            _sectionBody(
              'لديك الحق في:\n'
              '- الوصول إلى بياناتك الشخصية وتصديرها.\n'
              '- تصحيح أي معلومات غير دقيقة.\n'
              '- طلب حذف بياناتك (مع مراعاة المتطلبات القانونية).\n'
              '- الاعتراض على معالجة بياناتك.\n'
              '- سحب موافقتك في أي وقت.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('ملفات تعريف الارتباط'),
            _sectionBody(
              'نستخدم ملفات تعريف الارتباط (Cookies) لتحسين تجربتك وتذكر تفضيلاتك. '
              'يمكنك التحكم في إعدادات ملفات تعريف الارتباط من خلال متصفحك.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('الاحتفاظ بالبيانات'),
            _sectionBody(
              'نحتفظ ببياناتك طالما أن حسابك نشط أو حسب ما يقتضيه القانون. '
              'عند إغلاق حسابك، يتم حذف بياناتك خلال 90 يوماً ما لم يتطلب القانون خلاف ذلك.',
            ),
            const SizedBox(height: 20),

            _sectionTitle('تواصل معنا'),
            _sectionBody(
              'إذا كانت لديك أي أسئلة حول سياسة الخصوصية، يمكنك التواصل معنا عبر:\n'
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
                'باستخدامك لنظام كارواتس، فإنك توافق على شروط سياسة الخصوصية هذه.',
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
