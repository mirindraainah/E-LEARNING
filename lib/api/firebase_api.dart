import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// crée canal de notification
Future<void> createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_notification_channel_id', // correspond au AndroidManifest.xml
    'High Importance Notifications', // nom canal
    description: 'Ce canal est utilisé pour les notifications importantes.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// messages en arrière-plan
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // initialise les notifications
  Future<void> initNotifications() async {
    // Demander la permission d'envoyer des notifications
    await _firebaseMessaging.requestPermission();

    // token FCM
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token: $fCMToken');

    // canal de notification
    await createNotificationChannel();

    // messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    //  messages en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          'Message reçu en premier plan: ${message.notification?.title}, ${message.notification?.body}');

      if (message.notification != null) {
        // notification dans la barre lorsque l'application est en premier plan
        _showNotification(
            message.notification!.title!, message.notification!.body!);
      }
    });
  }

  //afficher la notification
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_notification_channel_id',
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notification
      title, // Titre de la notification
      body, // Corps de la notification
      platformChannelSpecifics, // Détails de la notification
    );
  }
}


//feyzBUudTriih1nxh2FMIn:APA91bH0Y59zyc0cXif7Z8WfQt84ny9ImhRRB3CSdfz5zLEg7S2u9AsS_WMu0N4Y0xKHBhMH6i-3e4Y8hW6LsVoe1cwRfFvcJhoHDwG8DW6gBBJOL3tDMyiLVmHoMCDutbru8YSgzaaE
