import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/event.dart';
import '../services/payment_service.dart';
import '../services/pricing_service.dart';

class LiqPayPaymentScreen extends StatefulWidget {
  final Event event;
  final EventPrice eventPrice;
  final int ticketsCount;
  final Function(bool success, String? orderId) onPaymentResult;

  const LiqPayPaymentScreen({
    super.key,
    required this.event,
    required this.eventPrice,
    required this.ticketsCount,
    required this.onPaymentResult,
  });

  @override
  State<LiqPayPaymentScreen> createState() => _LiqPayPaymentScreenState();
}

class _LiqPayPaymentScreenState extends State<LiqPayPaymentScreen> {
  late final WebViewController _webViewController;
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Failed to load payment page: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle result URL redirects
            if (request.url.contains('payment-result')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadPaymentPage();
  }

  void _loadPaymentPage() {
    try {
      // Get payment form data
      final formData = _paymentService.createPaymentFormData(
        event: widget.event,
        eventPrice: widget.eventPrice,
        ticketsCount: widget.ticketsCount,
        resultUrl: 'https://example.com/payment-result',
      );

      // Create HTML form that auto-submits to LiqPay
      final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Processing...</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        .spinner {
            width: 40px;
            height: 40px;
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
            margin: 20px auto;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        h1 {
            margin: 0 0 10px 0;
            font-size: 24px;
            font-weight: 600;
        }
        p {
            margin: 0;
            opacity: 0.8;
            font-size: 16px;
        }
        .payment-info {
            margin-top: 20px;
            padding: 20px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            text-align: left;
        }
        .payment-info div {
            margin: 8px 0;
            display: flex;
            justify-content: space-between;
        }
        .payment-info strong {
            color: #FFD700;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Processing Payment</h1>
        <div class="spinner"></div>
        <p>Redirecting to secure payment gateway...</p>
        
        <div class="payment-info">
            <div><span>Event:</span> <strong>${widget.event.name}</strong></div>
            <div><span>Tickets:</span> <strong>${widget.ticketsCount}</strong></div>
            <div><span>Amount:</span> <strong>\$${_paymentService.getAmountInUSD(widget.eventPrice.price * widget.ticketsCount, widget.eventPrice.currency).toStringAsFixed(2)} USD</strong></div>
        </div>
    </div>

    <form id="liqpay-form" action="https://www.liqpay.ua/api/3/checkout" method="POST" style="display: none;">
        <input type="hidden" name="data" value="${formData['data']}" />
        <input type="hidden" name="signature" value="${formData['signature']}" />
    </form>

    <script>
        // Auto-submit form after 2 seconds
        setTimeout(function() {
            document.getElementById('liqpay-form').submit();
        }, 2000);
    </script>
</body>
</html>
      ''';

      _webViewController.loadHtmlString(html);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to initialize payment: $e';
      });
    }
  }

  void _handlePaymentResult(String url) {
    // Parse the result URL to determine payment status
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];
    final orderId = uri.queryParameters['order_id'];
    
    final success = status == 'success';
    widget.onPaymentResult(success, orderId);
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Cancel payment
            widget.onPaymentResult(false, null);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Payment info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Event: ${widget.event.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tickets: ${widget.ticketsCount}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_paymentService.getAmountInUSD(widget.eventPrice.price * widget.ticketsCount, widget.eventPrice.currency).toStringAsFixed(2)} USD',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // WebView content
          Expanded(
            child: _hasError
                ? _buildErrorView()
                : Stack(
                    children: [
                      WebViewWidget(controller: _webViewController),
                      if (_isLoading)
                        Container(
                          color: colorScheme.surface.withOpacity(0.8),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading secure payment...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    widget.onPaymentResult(false, null);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = null;
                    });
                    _loadPaymentPage();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
