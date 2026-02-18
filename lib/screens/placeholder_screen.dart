import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String currentRoute;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(currentRoute: currentRoute),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'قريباً...\nهذه الصفحة قيد التطوير',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
