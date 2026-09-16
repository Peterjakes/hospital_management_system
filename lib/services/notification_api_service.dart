import 'package:http/http.dart' as http;
import 'dart:convert';

/// Calls the separate hms-notifications-server backend to trigger push
/// notifications. This app has no way to send FCM pushes directly — that
/// has to happen from a trusted server, never the client — so this is
/// just a thin wrapper around three HTTP endpoints.
///
/// Every method here fails silently (logs, doesn't throw) by design.
/// A notification failing to send should never block or fail the actual
/// action that triggered it (booking, status change, prescription save).
class NotificationApiService {
  static const String _baseUrl = 'https://hms-notifications-server.onrender.com';

  static Future<void> notifyBookingCreated({
    required String doctorId,
    required String patientName,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    await _post('/notify/booking-created', {
      'doctorId': doctorId,
      'patientName': patientName,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
    });
  }

  static Future<void> notifyStatusChanged({
    required String patientId,
    required String status,
    required String doctorName,
  }) async {
    await _post('/notify/status-changed', {
      'patientId': patientId,
      'status': status,
      'doctorName': doctorName,
    });
  }

  static Future<void> notifyPrescriptionReady({
    required String patientId,
    required String doctorName,
  }) async {
    await _post('/notify/prescription-ready', {
      'patientId': patientId,
      'doctorName': doctorName,
    });
  }

  static Future<void> _post(String path, Map<String, dynamic> body) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // ignore: avoid_print
      print('NotificationApiService: failed to call $path: $e');
    }
  }
}