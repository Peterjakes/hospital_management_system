import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

/// Handles push notification setup: permissions, device token capture and
/// storage, and displaying notifications while the app is open.
///
/// Previously this app had no push notification capability at all — no
/// firebase_messaging dependency, no permission requests, nothing. This
/// only covers the CLIENT side (receiving and displaying notifications).
/// Actually SENDING a notification (e.g. "doctor accepted your booking")
/// requires a small backend using the Firebase Admin SDK, since FCM push
/// sends must originate from a trusted server, never directly from the
/// Flutter app. See the accompanying backend setup notes.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Call once at app startup, after Firebase.initializeApp().
  /// Requests permission and sets up message listeners. Does NOT save a
  /// token yet — that only happens once a user is signed in, via
  /// [saveTokenForUser].
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // iOS requires explicit permission; Android 13+ also requires it.
    // Older Android versions grant this automatically.
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications are needed because FCM does NOT automatically
    // show a system notification when the app is in the FOREGROUND —
    // that only happens automatically for background/terminated states.
    // Without this, a notification would silently arrive with no visible
    // alert while the user has the app open.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    // Foreground messages: show a local notification manually.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Background/terminated: FCM shows the notification automatically.
    // This listener fires when the user TAPS a notification that opened
    // or resumed the app from background — hook for future deep-linking
    // (e.g. jumping straight to the relevant appointment).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Intentionally left as a hook. Deep-link navigation depends on the
      // notification's data payload, which is defined by the backend
      // when specific notification types are wired up.
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'hms_default_channel',
      'Hospital Management Notifications',
      channelDescription: 'Appointment updates, prescriptions, and reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  /// Fetches the device's current FCM token and saves it to the given
  /// user's Firestore document, so a backend can later target pushes at
  /// them specifically. Call this right after a successful sign-in or
  /// registration.
  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestoreService.updateUserFcmToken(userId, token);
      }

      // Tokens can rotate (e.g. app reinstall, token expiry). Keep the
      // stored token current for as long as this user stays signed in
      // in this app session.
      _messaging.onTokenRefresh.listen((newToken) {
        _firestoreService.updateUserFcmToken(userId, newToken);
      });
    } catch (e) {
      // Notification setup failing should never block sign-in/booking —
      // the app's core functionality doesn't depend on push notifications.
      // ignore: avoid_print
      print('Failed to save FCM token: $e');
    }
  }
}