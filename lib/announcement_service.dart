import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class AnnouncementService {
  // URL de l'API FCM
  final String fcmUrl =
      'https://fcm.googleapis.com/v1/projects/elearning-e23e4/messages:send';

  // Scope requis pour FCM
  final List<String> fcmScopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
  ];

  // envoye notification FCM
  Future<void> sendNotification(String content) async {
    try {
      // charge fichier JSON du compte de service
      final serviceAccount =
          await rootBundle.loadString('lib/assets/service_account.json');
      final data = json.decode(serviceAccount);

      // crée les informations d'identification à partir du fichier de compte de service
      final accountCredentials = ServiceAccountCredentials.fromJson(data);

      // génère un client authentifié avec OAuth 2.0
      final client =
          await clientViaServiceAccount(accountCredentials, fcmScopes);

      // tronque le contenu s'il est trop long + ...
      String truncatedContent =
          content.length > 100 ? content.substring(0, 100) + '...' : content;

// rendu
      final body = {
        "message": {
          "topic": "announcements",
          "notification": {
            "title": "📢 Cours ENI : Nouvelle annonce",
            "body": truncatedContent, // contenu tronqué
          },
        },
      };

      // envoie la requête HTTP POST avec le jeton OAuth
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${client.credentials.accessToken.data}', // jeton d'accès
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Notification envoyée avec succès');
      } else {
        print('Erreur lors de l\'envoi de la notification : ${response.body}');
      }
    } catch (e) {
      print('Erreur : $e');
    }
  }
}
