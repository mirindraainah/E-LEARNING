import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/onboarding_screen.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/sign_up_page.dart';
import 'pages/student/connected_page.dart';
import 'pages/prof/connected_page2.dart';
import 'pages/admin/connected_page_admin.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'api/firebase_api.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await FirebaseApi().initNotifications();
  // écouteur de messages en arrière-plan
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  FirebaseMessaging.instance.subscribeToTopic('announcements');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.light(primary: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/connectedpage': (context) => const ConnectedPage(),
        '/connectedpage2': (context) => const ConnectedPage2(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // onboarding pendant le chargement
          return const OnboardingScreen();
        }

        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                //onboarding pendant le chargement
                return const OnboardingScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                Map<String, dynamic>? userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;

                String role = userData?['role'] ?? '';
                // redirection selon le rôle
                if (role == 'teacher') {
                  return const ConnectedPage2();
                } else if (role == 'admin') {
                  return const ConnectedPageAdmin();
                } else {
                  return const ConnectedPage(); // par défaut étudiant
                }
              } else {
                return const LoginPage();
              }
            },
          );
        } else {
          // onboarding
          return const OnboardingScreen();
        }
      },
    );
  }
}
