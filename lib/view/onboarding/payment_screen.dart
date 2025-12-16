import 'package:flutter/material.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';

class CheckoutPage extends StatelessWidget {
  final String checkoutUrl;

  const CheckoutPage({super.key, required this.checkoutUrl});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains('/success')) {
              _handlePaymentSuccess(context, request.url);
              return NavigationDecision.prevent;
            }
            if (request.url.contains('/cancel')) {
              Navigator.pop(context);
              TopSnackBar.show(
        context,
        message: "Payment cancelled",
        backgroundColor: Colors.red,
      );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.blueAccent,
      ),
      body: WebViewWidget(controller: controller),
    );
  }

  void _handlePaymentSuccess(BuildContext context, String url) {
    final uri = Uri.parse(url);
    final sessionId = uri.queryParameters['session_id'];

    debugPrint('✅ PAYMENT SUCCESS');
    debugPrint('🔑 Session ID: $sessionId');

    Navigator.of(context).pop();

    context.go('/home');

    Future.delayed(const Duration(milliseconds: 300), () {
      TopSnackBar.show(
        context,
        message: "🎉 Subscription activated successfully!",
        backgroundColor: Colors.green,
      );
      
    });
  }
}
