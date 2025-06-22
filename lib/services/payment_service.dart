import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../api_keys.dart';
import '../models/event.dart';
import '../services/pricing_service.dart';

/// Service to handle LiqPay payment integration
class PaymentService {
  static const String _liqpayUrl = 'https://www.liqpay.ua/api/3/checkout';

  /// Exchange rates cache (simplified version - in production use a real exchange API)
  static const Map<String, double> _exchangeRates = {
    'USD': 1.0, // Base currency
    'EUR': 0.85,
    'UAH': 40.5,
    'GBP': 0.75,
    'CAD': 1.35,
    'AUD': 1.45,
  };

  /// Convert amount to USD if currency is not USD
  double _convertToUSD(double amount, String currency) {
    if (currency == 'USD') return amount;
    
    final rate = _exchangeRates[currency] ?? 1.0;
    // Convert to USD (divide by rate since rates are USD to currency)
    return amount / rate;
  }

  /// Generate signature for LiqPay request
  String _generateSignature(String data) {
    final signString = '${ApiKeys.liqpayPrivateKey}$data${ApiKeys.liqpayPrivateKey}';
    final bytes = utf8.encode(signString);
    final digest = sha1.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// Create payment data for LiqPay
  Map<String, dynamic> _createPaymentData({
    required String orderId,
    required double amount,
    required String currency,
    required String description,
    String? resultUrl,
    String? serverUrl,
  }) {
    return {
      'version': '3',
      'public_key': ApiKeys.liqpayPublicKey,
      'action': 'pay',
      'amount': amount,
      'currency': currency,
      'description': description,
      'order_id': orderId,
      'sandbox': '1', // Test mode
      'language': 'en',
      'result_url': resultUrl,
      'server_url': serverUrl,
    };
  }

  /// Create LiqPay checkout URL for web browser payment
  Future<String> createCheckoutUrl({
    required Event event,
    required EventPrice eventPrice,
    required int ticketsCount,
    String? resultUrl,
    String? serverUrl,
  }) async {
    // Convert to USD if not already in USD
    final double amountUSD = _convertToUSD(
      eventPrice.price * ticketsCount, 
      eventPrice.currency
    );

    // Round to 2 decimal places
    final double finalAmount = double.parse(amountUSD.toStringAsFixed(2));

    // Generate unique order ID
    final orderId = 'ticket_${event.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    final description = 'Tickets for ${event.name} (${ticketsCount}x)';

    final paymentData = _createPaymentData(
      orderId: orderId,
      amount: finalAmount,
      currency: 'USD', // Always use USD as per requirements
      description: description,
      resultUrl: resultUrl,
      serverUrl: serverUrl,
    );

    // Encode data to base64
    final dataString = json.encode(paymentData);
    final data = base64.encode(utf8.encode(dataString));
    
    // Generate signature
    final signature = _generateSignature(data);

    // Create form data for POST request
    final formData = {
      'data': data,
      'signature': signature,
    };

    // Return the checkout URL with form data encoded
    final encodedFormData = formData.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$_liqpayUrl?$encodedFormData';
  }

  /// Create payment form data for WebView
  Map<String, String> createPaymentFormData({
    required Event event,
    required EventPrice eventPrice,
    required int ticketsCount,
    String? resultUrl,
    String? serverUrl,
  }) {
    // Convert to USD if not already in USD
    final double amountUSD = _convertToUSD(
      eventPrice.price * ticketsCount, 
      eventPrice.currency
    );

    // Round to 2 decimal places
    final double finalAmount = double.parse(amountUSD.toStringAsFixed(2));

    // Generate unique order ID
    final orderId = 'ticket_${event.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    final description = 'Tickets for ${event.name} (${ticketsCount}x)';

    final paymentData = _createPaymentData(
      orderId: orderId,
      amount: finalAmount,
      currency: 'USD', // Always use USD as per requirements
      description: description,
      resultUrl: resultUrl,
      serverUrl: serverUrl,
    );

    // Encode data to base64
    final dataString = json.encode(paymentData);
    final data = base64.encode(utf8.encode(dataString));
    
    // Generate signature
    final signature = _generateSignature(data);

    return {
      'data': data,
      'signature': signature,
    };
  }

  /// Validate payment callback
  bool validateCallback(Map<String, dynamic> callbackData) {
    try {
      final data = callbackData['data'] as String?;
      final receivedSignature = callbackData['signature'] as String?;
      
      if (data == null || receivedSignature == null) return false;
      
      final expectedSignature = _generateSignature(data);
      return expectedSignature == receivedSignature;
    } catch (e) {
      return false;
    }
  }

  /// Parse callback data
  Map<String, dynamic>? parseCallbackData(String data) {
    try {
      final decodedData = base64.decode(data);
      final jsonString = utf8.decode(decodedData);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if payment was successful
  bool isPaymentSuccessful(Map<String, dynamic> callbackData) {
    final status = callbackData['status'] as String?;
    return status == 'success';
  }

  /// Get formatted amount for display
  String getFormattedAmount(double amount, String currency) {
    if (currency == 'USD') {
      final convertedAmount = _convertToUSD(amount, currency);
      return '\$${convertedAmount.toStringAsFixed(2)}';
    }
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Get amount in USD for payment
  double getAmountInUSD(double amount, String currency) {
    return _convertToUSD(amount, currency);
  }
}
