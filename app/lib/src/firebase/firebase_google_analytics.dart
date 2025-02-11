import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_leaf_kit/flutter_leaf_kit_datetime.dart';

class FirebaseGoogleAnalytics {
  static Future<bool> isSupported() async {
    return await FirebaseAnalytics.instance.isSupported();
  }

  static Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {
    await FirebaseAnalytics.instance.setUserId(
      id: id,
      callOptions: callOptions,
    );
  }

  static Future<void> enterAppMain({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {
    final Map<String, Object> parameters = {
      'id': (id != null) ? id : '',
      'timestamp': LFDate.now(isUtc: true).microsecondsSinceEpoch.toString(),
    };
    await FirebaseAnalytics.instance.logEvent(
      name: 'enter_app_main',
      parameters: parameters,
      callOptions: callOptions,
    );
  }
}
