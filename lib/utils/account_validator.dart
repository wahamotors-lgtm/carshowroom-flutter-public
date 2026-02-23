import '../models/account_model.dart';

/// نتيجة التحقق من الحساب
class AccountWarning {
  final String message;
  final String? suggestedAccountId;
  final String? suggestedAccountName;

  AccountWarning({
    required this.message,
    this.suggestedAccountId,
    this.suggestedAccountName,
  });
}

/// تحقق ذكي من توافق الحساب مع نوع المصروف
class AccountValidator {
  // كلمات مفتاحية لمصاريف الحاويات والشحن (يجب أن تكون purchases)
  static const _containerKeywords = [
    'حاوية', 'جمرك', 'جمارك', 'شحن', 'تخليص', 'ميناء', 'نقل حاوية',
    'container', 'customs', 'shipping', 'clearance', 'port',
  ];

  // كلمات مفتاحية لمصاريف السيارات (يجب أن تكون purchases)
  static const _carKeywords = [
    'سيارة', 'مصروف سيارة', 'نقل سيارة', 'فحص سيارة', 'تأمين سيارة',
    'شراء سيارة', 'car', 'vehicle',
  ];

  // كلمات مفتاحية للمصاريف العامة (يجب أن تكون expense)
  static const _generalExpenseKeywords = [
    'ترويج', 'تيك توك', 'tiktok', 'مياه', 'أكياس', 'كهرباء',
    'إيجار', 'راتب', 'رواتب', 'بنزين', 'قمامة', 'تصفير',
    'تأمين لوحات', 'صيانة مكتب', 'قرطاسية', 'انترنت', 'هاتف',
    'تنظيف', 'ضيافة', 'إعلان', 'دعاية',
  ];

  /// أنواع الحسابات التي تُعد "مشتريات"
  static const _purchaseTypes = ['purchases'];

  /// يتحقق من توافق الحساب المدين مع نوع المصروف
  /// يرجع null إذا صحيح، أو AccountWarning إذا خاطئ
  static AccountWarning? validateDebitAccount({
    required AccountModel? debitAccount,
    required String description,
    String? referenceType,
    required List<AccountModel> allAccounts,
  }) {
    if (debitAccount == null || description.trim().isEmpty) return null;

    final desc = description.trim().toLowerCase();
    final accountType = debitAccount.type;

    // 1. مصروف حاوية/شحن → المدين يجب أن يكون purchases
    if (_matchesKeywords(desc, _containerKeywords) ||
        referenceType == 'container' ||
        referenceType == 'shipment') {
      if (!_purchaseTypes.contains(accountType)) {
        final suggested = _findAccountByType(allAccounts, 'purchases',
            preferred: 'مصاريف شحن وجمرك المشتريات');
        return AccountWarning(
          message:
              'تنبيه: اخترت حساب "${debitAccount.name}" وهو من نوع "${accountTypeLabel(accountType)}"، '
              'لكن هذا المصروف يبدو أنه مصروف حاوية/شحن.\n'
              'الحساب المقترح: ${suggested?.name ?? "حساب مشتريات"}',
          suggestedAccountId: suggested?.id,
          suggestedAccountName: suggested?.name,
        );
      }
    }

    // 2. مصروف سيارة → المدين يجب أن يكون purchases
    else if (_matchesKeywords(desc, _carKeywords) ||
        referenceType == 'car') {
      if (!_purchaseTypes.contains(accountType)) {
        final suggested = _findAccountByType(allAccounts, 'purchases');
        return AccountWarning(
          message:
              'تنبيه: اخترت حساب "${debitAccount.name}" وهو من نوع "${accountTypeLabel(accountType)}"، '
              'لكن هذا المصروف يبدو أنه مصروف سيارة.\n'
              'الحساب المقترح: ${suggested?.name ?? "حساب مشتريات"}',
          suggestedAccountId: suggested?.id,
          suggestedAccountName: suggested?.name,
        );
      }
    }

    // 3. مصاريف عامة → المدين يجب أن يكون expense
    else if (_matchesKeywords(desc, _generalExpenseKeywords)) {
      if (_purchaseTypes.contains(accountType)) {
        final suggested = _findAccountByType(allAccounts, 'expense',
            preferred: 'مصاريف عامة');
        return AccountWarning(
          message:
              'تنبيه: اخترت حساب "${debitAccount.name}" وهو من نوع "مشتريات"، '
              'لكن هذا المصروف يبدو أنه مصروف عام.\n'
              'الحساب المقترح: ${suggested?.name ?? "حساب مصاريف"}',
          suggestedAccountId: suggested?.id,
          suggestedAccountName: suggested?.name,
        );
      }
    }

    return null;
  }

  /// يتحقق أن المدين والدائن مختلفان
  static AccountWarning? validateSameAccount({
    required String? debitAccountId,
    required String? creditAccountId,
  }) {
    if (debitAccountId != null &&
        creditAccountId != null &&
        debitAccountId == creditAccountId) {
      return AccountWarning(
        message: 'خطأ: الحساب المدين والدائن يجب أن يكونا مختلفين',
      );
    }
    return null;
  }

  /// يتحقق من توافق الوصف مع التصنيف (للمصاريف الجماعية بدون حسابات)
  /// يرجع null إذا صحيح، أو AccountWarning إذا خاطئ
  static AccountWarning? validateCategory({
    required String description,
    required String category,
  }) {
    if (description.trim().isEmpty) return null;
    final desc = description.trim().toLowerCase();

    // تصنيفات الشحن/الجمرك
    const shippingCategories = ['shipping', 'customs', 'clearance', 'port_fees'];
    // تصنيفات السيارات
    const carCategories = ['car_expense', 'transport'];

    // وصف حاوية/شحن + تصنيف غير شحن
    if (_matchesKeywords(desc, _containerKeywords) &&
        !shippingCategories.contains(category)) {
      return AccountWarning(
        message: 'تنبيه: الوصف "$description" يبدو أنه مصروف شحن/جمرك، '
            'لكن التصنيف المختار "${_getCategoryLabel(category)}".\n'
            'هل تريد تغيير التصنيف إلى "جمارك" أو "شحن"؟',
      );
    }

    // وصف مصاريف عامة + تصنيف شحن/سيارة
    if (_matchesKeywords(desc, _generalExpenseKeywords) &&
        (shippingCategories.contains(category) ||
            carCategories.contains(category))) {
      return AccountWarning(
        message: 'تنبيه: الوصف "$description" يبدو أنه مصروف عام، '
            'لكن التصنيف المختار "${_getCategoryLabel(category)}".\n'
            'هل تريد تغيير التصنيف إلى "أخرى"؟',
      );
    }

    return null;
  }

  static String _getCategoryLabel(String category) {
    const labels = {
      'shipping': 'شحن', 'customs': 'جمارك', 'transport': 'نقل',
      'loading': 'تحميل', 'clearance': 'تخليص', 'port_fees': 'رسوم ميناء',
      'government': 'رسوم حكومية', 'car_expense': 'مصروف سيارة', 'other': 'أخرى',
    };
    return labels[category] ?? category;
  }

  // ── Helpers ──

  static bool _matchesKeywords(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw.toLowerCase())) return true;
    }
    return false;
  }

  static AccountModel? _findAccountByType(
    List<AccountModel> accounts,
    String type, {
    String? preferred,
  }) {
    if (preferred != null) {
      final match = accounts.where(
          (a) => a.type == type && a.name.contains(preferred));
      if (match.isNotEmpty) return match.first;
    }
    final matches = accounts.where((a) => a.type == type);
    return matches.isNotEmpty ? matches.first : null;
  }
}
