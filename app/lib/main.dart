import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_leaf_kit/flutter_leaf_kit_common.dart';
import 'package:flutter_leaf_kit/flutter_leaf_kit_component.dart';

import 'src/firebase/firebase_message.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();

    runApp(const MyApp());
  }, (error, stackTrace) {
    // Zone ( to catch all unhandled-asynchronous-errors )
    Logging.e(':: Interceptor Zone Error : $error, StackTrace : $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanager Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Tanager Flutter Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    FirebaseMessage.shared.registerTokenWithPermission().then((token) async {
      Logging.d('FirebaseMessage token: $token');
    });

    FirebaseMessage.shared.listenInitialMessageApp((message) async {
      Logging.d(
          'FirebaseMessage InitialMessageApp message: ${message.toMap()}');
      Map<String, dynamic> data = message.data;
      Future.delayed(const Duration(milliseconds: 500), () {
        _processPushNotificationData(data: data);
      });
    });

    FirebaseMessage.shared.listenMessageOpenedApp((message) async {
      Logging.d('FirebaseMessage MessageOpenedApp message: ${message.toMap()}');
      Map<String, dynamic> data = message.data;
      Future.delayed(const Duration(milliseconds: 500), () {
        _processPushNotificationData(data: data);
      });
    });

    FirebaseMessage.shared.listenForegroundMessaging((message) {
      Logging.d('FirebaseMessage Foreground message: ${message.toMap()}');
      String? title = message.notification?.title;
      String? body = message.notification?.body;
      Map<String, dynamic> data = message.data;
      if (title != null) {
        _showPushNotification(title: title, body: body, data: data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '1',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //
          _showPushNotification(title: 'title', body: 'body', data: null);
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _processPushNotificationData({
    required Map<String, dynamic> data,
  }) {
    try {
      final item = data['item'];
      print('item: $item');
    } catch (e) {
      Logging.e('PushNotificationData error: $e');
    }
  }

  void _showPushNotification({
    required String title,
    required String? body,
    required Map<String, dynamic>? data,
  }) {
    AssetImage symbol =
        const AssetImage('assets/launcher_icon/launcher-icon-prod.png');

    LFStackPushNotification.shared
        .enqueue(
          LFPushNotification(
            title: title,
            body: body,
            icon: Image(image: symbol, width: 20.0, height: 20.0),
            titleTextStyle: const TextStyle(
              fontSize: 16,
              decoration: TextDecoration.none,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
            ),
            bodyTextStyle: const TextStyle(
              fontSize: 16,
              decoration: TextDecoration.none,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w400,
            ),
            data: data,
            onTap: (data) {
              if (data == null) {
                return;
              }
              _processPushNotificationData(data: data);
            },
          ),
        )
        .show(context);
  }
}
