import 'package:cafeteria_oea/core/network/api_client.dart';

class PaymentsRepository {
  PaymentsRepository(this.token, {this.onTokenExpired});

  final String token;
  final TokenRefreshCallback? onTokenExpired;

  Future<void> createPayment({
    required int orderId,
    required String transactionReference,
    required int amount,
  }) async {
    await ApiClient(
      token: token,
      onTokenExpired: onTokenExpired,
    ).post('/payments/create.php', {
      'order_id': orderId,
      'provider': 'wompi',
      'transaction_reference': transactionReference,
      'amount': amount,
      'status': 'pending',
    });
  }
}
