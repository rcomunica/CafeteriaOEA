import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../network/api_client.dart';
import '../../features/orders/domain/order_item.dart';

class WompiConfig {
  WompiConfig._();

  // Reemplaza estos valores con los de tu comercio en Wompi.
  static const publicKey = 'pub_test_5cwW5kMsBeBjAQuKVwRUrT2QqPGdrta9';
  static const integritySecret =
      'test_integrity_tWbSzgIqy7mv64RyesfEVvbHmkl833MQ';
  static const currency = 'COP';
  static const checkoutUrl = 'https://checkout.wompi.co/p/';
  static const redirectPath = '/payment_notifications/processing.php';
  static String get redirectUrl => '${ApiClient.baseUrl}$redirectPath';

  static bool get isConfigured =>
      publicKey != 'REEMPLAZAR_CON_PUBLIC_KEY' &&
      integritySecret != 'REEMPLAZAR_CON_INTEGRITY_SECRET';

  static Uri checkoutUri(
    OrderItem order, {
    required String transactionReference,
  }) {
    final reference = transactionReference;
    final amountInCents = (order.total * 100).round();
    final raw = '$reference$amountInCents$currency$integritySecret';
    final signature = sha256.convert(utf8.encode(raw)).toString();

    print(
      Uri.https('checkout.wompi.co', '/p/', {
        'public-key': publicKey,
        'currency': currency,
        'amount-in-cents': '$amountInCents',
        'reference': reference,
        'signature:integrity': signature,
        'redirect-url': redirectUrl,
      }),
    );

    return Uri.https('checkout.wompi.co', '/p/', {
      'public-key': publicKey,
      'currency': currency,
      'amount-in-cents': '$amountInCents',
      'reference': reference,
      'signature:integrity': signature,
      // 'redirect-url': redirectUrl,
    });
  }
}
