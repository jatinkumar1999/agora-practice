import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:permission_handler/permission_handler.dart';

// Firebase background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Platform.isIOS) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAARiXeZEPCOzSJfIyj_K0Kfxd19FCA9Uc',
        appId: '1:1048332606637:ios:0b119719274a9450d13a24',
        messagingSenderId: '1048332606637',
        projectId: 'pastor-pals-91984',
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyADR98RwhKcHq8jlpzbejWU7TApvgrQBzw',
        appId: '1:73676730074:android:f49f29456ecd7362e0ffe3',
        messagingSenderId: '73676730074',
        projectId: 'agora-demo-521986',
      ),
    );
  }

  log('backgroudn==>>${message.notification?.toMap()}');
  RemoteNotification? notification = message.notification;
  //
  
    if (Platform.isAndroid) {
      showNotification(
        notification.hashCode,
        message.data,
      );
    }
  
}

Future<void> bgHandler() async {
  if (Platform.isIOS) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAARiXeZEPCOzSJfIyj_K0Kfxd19FCA9Uc',
        appId: '1:1048332606637:ios:0b119719274a9450d13a24',
        messagingSenderId: '1048332606637',
        projectId: 'pastor-pals-91984',
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyADR98RwhKcHq8jlpzbejWU7TApvgrQBzw',
        appId: '1:73676730074:android:f49f29456ecd7362e0ffe3',
        messagingSenderId: '73676730074',
        projectId: 'agora-demo-521986',
      ),
    );
  }
}

class FCM {
  int _badgeCount = 0; // Badge count tracker

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'Demo Agora',
    'Demo Agora Notification',
    importance: Importance.high,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Get FCM token and save it locally
  Future<String?> getfcmToken() async {
    var token = await FirebaseMessaging.instance.getToken();
    log('FCM TOKEN==>>$token');
    return token;
  }

  // Initialize FCM
  Future initFcm() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isIOS) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAARiXeZEPCOzSJfIyj_K0Kfxd19FCA9Uc',
          appId: '1:1048332606637:ios:0b119719274a9450d13a24',
          messagingSenderId: '1048332606637',
          projectId: 'pastor-pals-91984',
        ),
      );
    } else {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyADR98RwhKcHq8jlpzbejWU7TApvgrQBzw',
          appId: '1:73676730074:android:f49f29456ecd7362e0ffe3',
          messagingSenderId: '73676730074',
          projectId: 'agora-demo-521986',
        ),
      );
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Reset badge count on app launch
    resetBadgeCount();

    // Notification initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.initialize(iosSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationClick(jsonDecode(details.payload ?? ''));
      },
    );

    await _handleInitialMessage();
    // listenNotification();

    await requestNotificationPermision();
  }

  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data);
    }
  }

  Future<void> requestNotificationPermision() async {
    bool granted = await Permission.notification.isGranted;
    if (granted) {
    } else {
      if (Platform.isAndroid) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(sound: true, alert: true, badge: true);
      }
    }
  }

  // Listen for notifications
  Future listenNotification() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      log('Message Listener');

      // if (notification != null) {
      // incrementBadgeCount(); // Increment badge count for new notifications
      Map<String, dynamic> data = message.data;

      if (Platform.isAndroid) {
        showNotification(
          notification.hashCode,
          data,
        );
        // }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // resetBadgeCount(); // Reset badge count when the app is opened via notification
      log('backgroudn==>>${message.notification?.toMap()}');
      RemoteNotification? notification = message.notification;
      //
        if (Platform.isAndroid) {
          showNotification(
            notification.hashCode,
            message.data,
          );
        
      }

      // _handleNotificationClick(message.data);
    });
  }

  void _handleNotificationClick(Map<String, dynamic>? payloadData) {
    if (payloadData != null) {
    } else {
      log('Notification payload is null');
    }
  }

  // Badge count functions
  void updateBadgeCount(int count) {
    _badgeCount = count;
    FlutterAppBadgeControl.updateBadgeCount(_badgeCount);
  }

  void incrementBadgeCount() {
    _badgeCount++;
    FlutterAppBadgeControl.updateBadgeCount(_badgeCount);
  }

  void resetBadgeCount() {
    _badgeCount = 0;
    FlutterAppBadgeControl.removeBadge();
  }

  Future<void> _removeNotification() async {
    resetBadgeCount();
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

// Show local notification
Future<void> showNotification(int id, Map<String, dynamic> data) async {
  log('showNotification==>>$data');

  CallKitParams callKitParams = CallKitParams(
    id: '_currentUuid',
    nameCaller: 'Jatin KUmar',
    appName: 'Callkit',
    // avatar: 'https://i.pravatar.cc/100',
    handle: '0123456789',
    type: 1,
    textAccept: 'Accept',
    textDecline: 'Decline',
    // missedCallNotification: NotificationParams(
    //   showNotification: true,
    //   isShowCallback: true,
    //   subtitle: 'Missed call',
    //   callbackText: 'Call back',
    // ),
    // callingNotification: NotificationParams(
    //   showNotification: true,
    //   isShowCallback: true,
    //   subtitle: 'Calling...',
    //   callbackText: 'Hang Up',
    // ),
    duration: 30000,
    extra: {
      'callId': data['callId'],
      'callerId': data['callerId'],
      'type': data['type'],
    },
    headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
    android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        isImportant: true,
        isCustomSmallExNotification: true,
        // logoUrl: 'https://i.pravatar.cc/100',
        ringtonePath: 'system_ringtone_default',
        // backgroundColor: '#0955fa',
        // // backgroundUrl: 'https://i.pravatar.cc/500',
        // actionColor: '#4CAF50',
        // textColor: '#ffffff',
        incomingCallNotificationChannelName: "Incoming Call",
        missedCallNotificationChannelName: "Missed Call",
        isShowCallID: false),
    // ios: IOSParams(
    //   iconName: 'CallKitLogo',
    //   handleType: 'generic',
    //   supportsVideo: true,
    //   maximumCallGroups: 2,
    //   maximumCallsPerCallGroup: 1,
    //   audioSessionMode: 'default',
    //   audioSessionActive: true,
    //   audioSessionPreferredSampleRate: 44100.0,
    //   audioSessionPreferredIOBufferDuration: 0.005,
    //   supportsDTMF: true,
    //   supportsHolding: true,
    //   supportsGrouping: false,
    //   supportsUngrouping: false,
    //   ringtonePath: 'system_ringtone_default',
    // ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);

  // flutterLocalNotificationsPlugin.show(
  //   id,
  //   title,
  //   message,
  //   NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       channel.id,
  //       channel.name,
  //       importance: Importance.high,
  //       color: Colors.blue,
  //       icon: 'mipmap/ic_launcher',
  //       fullScreenIntent: true,
  //       playSound: true,
  //       actions: <AndroidNotificationAction>[
  //         const AndroidNotificationAction('accept', 'Accept'),
  //         const AndroidNotificationAction('reject', 'Reject',
  //             cancelNotification: true),
  //       ],
  //     ),
  //     iOS: const DarwinNotificationDetails(
  //       presentAlert: true,
  //       presentBadge: true,
  //     ),
  //   ),
  //   payload: jsonEncode(data), // Include payload here
  // );
}
