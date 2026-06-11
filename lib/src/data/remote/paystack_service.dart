import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';

class PaystackPlusService {
  static const String publicKey =
      "pk_test_c0e443cac2fea129a33b802ec7a3b25fe6e72791";
  static const String secretKey =
      "sk_test_b5adf7fee6e8755de201bc9a228a2732c84d6a7f";

  Future<void> startPayment({
    required BuildContext context,
    required double amount,
    required String email,
  }) async {
    try {
      final reference = "MONAMI${DateTime.now().millisecondsSinceEpoch}";
      final koboAmount = (amount * 100).toInt().toString();

      await FlutterPaystackPlus.openPaystackPopup(
        publicKey: publicKey,
        secretKey: secretKey, // Remove later for production
        context: context,
        customerEmail: email,
        amount: koboAmount,
        currency: "NGN",
        reference: reference,
        callBackUrl: "https://monami.com",
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Successful")),
          );
        },
        onClosed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Cancelled")),
          );
        },
      );
    } catch (e) {
      debugPrint("Payment Error: $e");
    }
  }
}
