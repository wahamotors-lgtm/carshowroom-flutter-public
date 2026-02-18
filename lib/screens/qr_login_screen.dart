import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key});
  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isScanning = false;
  bool _scanned = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  void _startScanner() {
    setState(() {
      _isScanning = true;
      _scanned = false;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    });
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() { _isScanning = false; });
  }

  Future<void> _onScanDetected(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final scannedToken = barcodes.first.rawValue;
    if (scannedToken == null || scannedToken.isEmpty) return;

    setState(() { _scanned = true; });
    _stopScanner();

    // Validate token format (JWT tokens are typically long base64 strings)
    if (scannedToken.length < 20) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز QR غير صالح'), backgroundColor: AppColors.error),
      );
      setState(() { _scanned = false; });
      return;
    }

    // Save scanned token
    try {
      final storageService = StorageService();
      await storageService.saveToken(scannedToken);
      await storageService.saveLoginType('tenant');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح'), backgroundColor: AppColors.success),
      );

      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل حفظ بيانات الجلسة'), backgroundColor: AppColors.error),
      );
      setState(() { _scanned = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دخول QR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'عرض رمز QR', icon: Icon(Icons.qr_code, size: 20)),
            Tab(text: 'مسح رمز QR', icon: Icon(Icons.qr_code_scanner, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShowQrTab(),
          _buildScanQrTab(),
        ],
      ),
    );
  }

  Widget _buildShowQrTab() {
    final token = _token;

    if (token.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.no_accounts_outlined, size: 40, color: AppColors.error),
        ),
        const SizedBox(height: 20),
        const Text('لم يتم تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 8),
        const Text('يرجى تسجيل الدخول أولاً لعرض رمز QR', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.tenantLogin),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]));
    }

    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('امسح هذا الرمز من جهاز آخر لتسجيل الدخول بنفس الحساب',
              style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500))),
          ]),
        ),
        const SizedBox(height: 30),

        // QR Code
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: QrImageView(
            data: token,
            version: QrVersions.auto,
            size: 240,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1E293B)),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1E293B)),
          ),
        ),
        const SizedBox(height: 24),

        const Text('رمز تسجيل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text('صالح للجلسة الحالية فقط', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ]),
    ));
  }

  Widget _buildScanQrTab() {
    if (_isScanning && _scannerController != null) {
      return Stack(children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: _onScanDetected,
        ),
        // Scan overlay
        Center(child: Container(
          width: 260, height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        )),
        // Top instruction
        Positioned(top: 40, left: 0, right: 0, child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
          child: const Text('وجّه الكاميرا نحو رمز QR', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ))),
        // Close button
        Positioned(bottom: 40, left: 0, right: 0, child: Center(child: ElevatedButton.icon(
          onPressed: _stopScanner,
          icon: const Icon(Icons.close, size: 20),
          label: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ))),
      ]);
    }

    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.qr_code_scanner, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text('مسح رمز QR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 10),
        const Text('امسح رمز QR من جهاز آخر لتسجيل\nالدخول بسرعة بدون كلمة مرور', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.6)),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _startScanner,
          icon: const Icon(Icons.camera_alt_outlined, size: 22),
          label: const Text('مسح رمز QR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('كيفية الاستخدام:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 8),
            _instructionStep('1', 'افتح التطبيق على الجهاز الآخر'),
            _instructionStep('2', 'اذهب إلى "تسجيل دخول QR"'),
            _instructionStep('3', 'اعرض رمز QR من الجهاز الآخر'),
            _instructionStep('4', 'امسح الرمز من هنا'),
          ]),
        ),
      ]),
    ));
  }

  Widget _instructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textGray))),
      ]),
    );
  }
}
