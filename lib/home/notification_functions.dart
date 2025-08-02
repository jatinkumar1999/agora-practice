import 'dart:developer';

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendPushNotification({
  required String callId,
  required String callerId,
  required String token,
}) async {
  try {
    log('token==>>$token');

    final response = await http.post(
      Uri.parse('http://192.168.1.5:8000/api/v1/order/sendNotification'),
      headers: {
        'Content-Type': 'application/json',
        // Add auth token here if your API is protected
        // 'Authorization': 'Bearer your_api_key',
      },
      body: jsonEncode({
        'token': token,
        'title': "Order Placed",
        'message': "Your order has been placed successfully.",
        'type': "order",
        'callId': callId,
        'callerId': callerId,
      }),
    );

    log('response==>>${response.body}');
    if (response.statusCode == 200) {
      print('✅ Notification sent successfully.');
    } else {
      print('❌ Failed to send notification: ${response.body}');
    }
  } catch (e) {
    print('🔥 Error sending notification: $e');
  }
}

Future<String?> fetchAgoraToken(String channelName, String uid) async {
  try {
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.5:8000/api/v1/agora/rtc-token?channel=$channelName&uid=$uid'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    }
  } catch (e) {
    log('asd==>>$e');
  }
  return null;
}
