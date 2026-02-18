import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = <_ReportItem>[
      _ReportItem(
        icon: Icons.balance_outlined,
        title: 'ميزان المراجعة',
        subtitle: 'مراجعة أرصدة الحسابات والتأكد من توازنها',
        route: AppRoutes.trialBalance,
        color: const Color(0xFF7C3AED),
      ),
      _ReportItem(
        icon: Icons.trending_up_outlined,
        title: 'الأرباح والخسائر',
        subtitle: 'تقرير الإيرادات والمصروفات وصافي الربح',
        route: AppRoutes.profitsPage,
        color: const Color(0xFF059669),
      ),
      _ReportItem(
        icon: Icons.point_of_sale_outlined,
        title: 'تقرير المبيعات',
        subtitle: 'تفاصيل المبيعات والإيرادات حسب الفترة',
        route: AppRoutes.salesPage,
        color: const Color(0xFFD97706),
      ),
      _ReportItem(
        icon: Icons.receipt_long_outlined,
        title: 'تقرير المصروفات',
        subtitle: 'تحليل المصروفات وتصنيفها حسب النوع',
        route: AppRoutes.expenseRecord,
        color: const Color(0xFFEA580C),
      ),
      _ReportItem(
        icon: Icons.people_outline,
        title: 'تقرير العملاء',
        subtitle: 'بيانات العملاء وأرصدتهم والمعاملات',
        route: AppRoutes.customersPage,
        color: const Color(0xFF0891B2),
      ),
      _ReportItem(
        icon: Icons.local_shipping_outlined,
        title: 'تقرير الموردين',
        subtitle: 'بيانات الموردين والمشتريات والأرصدة',
        route: AppRoutes.suppliersPage,
        color: const Color(0xFF2563EB),
      ),
      _ReportItem(
        icon: Icons.badge_outlined,
        title: 'تقرير الموظفين',
        subtitle: 'بيانات الموظفين والرواتب والحضور',
        route: AppRoutes.employeesPage,
        color: const Color(0xFF7C3AED),
      ),
      _ReportItem(
        icon: Icons.inventory_2_outlined,
        title: 'تقرير الحاويات',
        subtitle: 'حالة الحاويات والشحنات وتفاصيلها',
        route: AppRoutes.containersPage,
        color: const Color(0xFF0284C7),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التقارير',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.reportsPage),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.assessment_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مركز التقارير',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'استعرض جميع التقارير المالية والإدارية',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'التقارير المتاحة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Reports grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportCard(
                  icon: report.icon,
                  title: report.title,
                  subtitle: report.subtitle,
                  color: report.color,
                  onTap: () => Navigator.pushReplacementNamed(context, report.route),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ReportItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  const _ReportItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_left, size: 16, color: color),
                      ],
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
