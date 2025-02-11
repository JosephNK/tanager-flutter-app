import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_leaf_kit/flutter_leaf_kit_common.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseParserData {
  final String? title;
  final String? body;

  FirebaseParserData({
    required this.title,
    required this.body,
  });
}

FirebaseParserData parserRemoteData(dynamic data) {
  try {
    return FirebaseParserData(
      title: null,
      body: null,
    );
  } catch (e) {
    rethrow;
  }
}

////////////////////////////////////////////////////////////////////////////////

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logging.d('FirebaseMessage Messaging Background message: $message');
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  await setupFlutterNotifications();
}

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }

  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );
  isFlutterLocalNotificationsInitialized = true;
}

////////////////////////////////////////////////////////////////////////////////

class FirebaseMessage {
  static final FirebaseMessage _instance = FirebaseMessage._internal();

  static FirebaseMessage get shared => _instance;

  FirebaseMessage._internal() {
    Logging.d('FirebaseMessage Init');
    setupFlutterNotifications();
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Permission
  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus;
  }

  /// Token and Permission
  Future<String?> registerTokenWithPermission({
    bool usingPlatform = false,
  }) async {
    try {
      final status = await requestPermission();
      if (status != AuthorizationStatus.authorized) {
        return null;
      }
      if (usingPlatform && Platform.isIOS) {
        return await _messaging.getAPNSToken();
      }
      return await _messaging.getToken();
    } catch (e) {
      Logging.e('FirebaseMessage registerTokenWithPermission error: $e');
    }
    return null;
  }

  /// Event :: getInitialMessage
  Future<void> listenInitialMessageApp(
      ValueChanged<RemoteMessage>? callBack) async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      callBack?.call(message);
    }
  }

  /// Event :: onMessageOpenedApp
  Future<void> listenMessageOpenedApp(
      ValueChanged<RemoteMessage>? callBack) async {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      callBack?.call(message);
    });
  }

  /// Event :: onMessage
  Future<void> listenForegroundMessaging(
      ValueChanged<RemoteMessage>? callBack) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      callBack?.call(message);
    });
  }

  /// Event :: onBackgroundMessage
  Future<void> listenBackgroundMessaging() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

/// LocalNotificationsPlugin Helper
extension LocalNotificationsExtension on FirebaseMessage {
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (Platform.isAndroid) {
      final List<ActiveNotification> activeNotifications =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()!
              .getActiveNotifications();
      return activeNotifications;
    }
    return [];
  }

  Future<void> cancel(int id, {String? tag}) async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .cancel(id, tag: tag);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
