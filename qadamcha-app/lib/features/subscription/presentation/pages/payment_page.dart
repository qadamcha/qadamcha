import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_success_page.dart';

class PaymentPage extends StatefulWidget {
  final SubscriptionPlan plan;
  final PaymentOrder order;
  final Future<OrderStatus> Function() checkOrderStatus;

  const PaymentPage({
    super.key,
    required this.plan,
    required this.order,
    required this.checkOrderStatus,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isCheckingPayment = false;
  Timer? _pollingTimer;
  int _loadProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onProgress: (progress) {
          if (mounted) setState(() => _loadProgress = progress);
        },
        onNavigationRequest: (request) {
          final url = request.url;
          // Payme callback URL larini tutish
          if (url.contains('success') || url.contains('callback')) {
            _startPolling();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.order.checkoutUrl));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (_isCheckingPayment) return;
    setState(() => _isCheckingPayment = true);

    int attempts = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts > 20) {
        timer.cancel();
        if (mounted) {
          setState(() => _isCheckingPayment = false);
          _showError('To\'lov holatini aniqlash imkoni bo\'lmadi');
        }
        return;
      }

      try {
        final status = await widget.checkOrderStatus();
        if (status.paid && mounted) {
          timer.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(plan: widget.plan),
            ),
          );
        }
      } catch (_) {
        // Keyingi urinishda qayta tekshiriladi
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onClose() {
    // WebView yopilganda to'lovni tekshirib ko'rish
    if (!_isCheckingPayment) {
      _checkOnceAndPop();
    }
  }

  Future<void> _checkOnceAndPop() async {
    try {
      final status = await widget.checkOrderStatus();
      if (status.paid && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(plan: widget.plan),
          ),
        );
        return;
      }
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  BackButtonBox(onPressed: _onClose),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payme orqali to\'lov',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        Text(
                          '${widget.plan.label} — ${widget.plan.formattedPrice}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading indicator
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadProgress / 100,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),

            // Payment checking overlay or WebView
            Expanded(
              child: _isCheckingPayment
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'To\'lov tekshirilmoqda...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Iltimos, kutib turing',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    )
                  : WebViewWidget(controller: _controller),
            ),

            // Security footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                border: const Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Payme xavfsiz to\'lov tizimi',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
