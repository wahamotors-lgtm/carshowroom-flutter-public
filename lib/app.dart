import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/routes.dart';
import 'screens/splash_screen.dart';
import 'screens/tenant_login_screen.dart';
import 'screens/tenant_register_screen.dart';
import 'screens/activation_screen.dart';
import 'screens/employee_login_screen.dart';
import 'screens/webview_dashboard.dart';

class CarWhatsApp extends StatelessWidget {
  const CarWhatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كارواتس',
      debugShowCheckedModeBanner: false,
      // RTL Arabic
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      locale: const Locale('ar'),
      theme: ThemeData(
        textTheme: GoogleFonts.tajawalTextTheme(),
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF059669),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.tenantLogin: (_) => const TenantLoginScreen(),
        AppRoutes.tenantRegister: (_) => const TenantRegisterScreen(),
        AppRoutes.activation: (_) => const ActivationScreen(),
        AppRoutes.employeeLogin: (_) => const EmployeeLoginScreen(),
        AppRoutes.dashboard: (_) => const WebViewDashboard(),
      },
    );
  }
}
