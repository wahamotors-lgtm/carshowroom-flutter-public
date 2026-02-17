import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/routes.dart';
import '../providers/auth_provider.dart';

class WebViewDashboard extends StatefulWidget {
  const WebViewDashboard({super.key});

  @override
  State<WebViewDashboard> createState() => _WebViewDashboardState();
}

class _WebViewDashboardState extends State<WebViewDashboard> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;

  late final String _targetUrl;
  late final UnmodifiableListView<UserScript> _userScripts;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token ?? '';
    final tenantJson = auth.tenant != null ? jsonEncode(auth.tenant) : '{}';
    final userJson = auth.user != null ? jsonEncode(auth.user) : '{}';
    final employeeJson = auth.employee != null ? jsonEncode(auth.employee) : 'null';
    final loginType = auth.loginType;

    _targetUrl = loginType == 'employee'
        ? ApiConfig.webAppEmployeeDashboard
        : ApiConfig.webAppDashboard;

    // Build localStorage injection script that runs BEFORE page JS
    final jsSource = '''
      try {
        localStorage.setItem('authToken', '${_escapeJs(token)}');
        localStorage.setItem('tenantInfo', '${_escapeJs(tenantJson)}');
        localStorage.setItem('currentUser', '${_escapeJs(userJson)}');
        ${employeeJson != 'null' ? "localStorage.setItem('loggedInEmployee', '${_escapeJs(employeeJson)}');" : ''}
        ${loginType == 'employee' ? "localStorage.setItem('loggedInEmployee', '${_escapeJs(employeeJson)}');" : ''}
      } catch(e) {
        console.log('Auth injection error: ' + e.message);
      }
    ''';

    _userScripts = UnmodifiableListView([
      UserScript(
        source: jsSource,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackButton();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(_targetUrl),
                ),
                initialUserScripts: _userScripts,
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  useOnDownloadStart: true,
                  allowFileAccess: true,
                  allowContentAccess: true,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  supportMultipleWindows: false,
                  horizontalScrollBarEnabled: false,
                  verticalScrollBarEnabled: true,
                  userAgent: 'CarWhatsApp/1.0 (Android; Flutter)',
                  cacheMode: CacheMode.LOAD_DEFAULT,
                  clearCache: false,
                  transparentBackground: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() => _isLoading = true);
                },
                onLoadStop: (controller, url) {
                  setState(() => _isLoading = false);
                },
                onProgressChanged: (controller, progress) {
                  setState(() => _progress = progress / 100);
                },
                shouldOverrideUrlLoading: (controller, action) async {
                  final url = action.request.url.toString();

                  // Open external links in system browser
                  if (url.startsWith('https://wa.me') ||
                      url.startsWith('whatsapp://') ||
                      url.startsWith('mailto:') ||
                      url.startsWith('tel:') ||
                      url.startsWith('intent:')) {
                    try {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                    return NavigationActionPolicy.CANCEL;
                  }

                  // Detect logout - redirect to native login
                  if (url.contains('#/tenant-login') ||
                      url.contains('#/login') && !url.contains('employee')) {
                    _handleLogout();
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onDownloadStartRequest: (controller, request) async {
                  try {
                    await launchUrl(request.url,
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                onConsoleMessage: (controller, message) {
                  // Debug: print console messages
                  debugPrint('WebView Console: ${message.message}');
                },
                onReceivedError: (controller, request, error) {
                  debugPrint('WebView Error: ${error.description}');
                },
              ),

              // Loading indicator
              if (_isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF059669),
                    ),
                    minHeight: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackButton() async {
    if (_webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();
      if (canGoBack) {
        _webViewController!.goBack();
        return;
      }
    }

    if (!mounted) return;

    // Show exit dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'هل تريد تسجيل الخروج من التطبيق؟',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('لا', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('نعم، خروج',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      _handleLogout();
    }
  }

  void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, AppRoutes.tenantLogin);
  }

  String _escapeJs(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }
}
