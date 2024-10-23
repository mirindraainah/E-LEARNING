// import 'package:flutter/material.dart';

// class VisioPage extends StatelessWidget {
//   const VisioPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text('Bienvenue à Visio',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//     );
//   }
// }
//697cfd582a3bc7e72514c27eff3194b511831033e317d339c31a3d5944dc9c7f
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class VisioPage extends StatefulWidget {
//   const VisioPage({Key? key}) : super(key: key);

//   @override
//   _VisioPageState createState() => _VisioPageState();
// }

// class _VisioPageState extends State<VisioPage> {
//   late WebViewController _controller;
//   final String _baseUrl = "https://meet.jit.si"; // URL de base de Jitsi Meet
//   late String meetingUrl; // URL de la réunion

//   @override
//   void initState() {
//     super.initState();
//     meetingUrl = "about:blank"; // Initialiser l'URL de la réunion
//   }

//   void _createMeeting() {
//     // Générer un ID unique basé sur l'heure actuelle
//     String meetingId = DateTime.now().millisecondsSinceEpoch.toString();
//     meetingUrl = "$_baseUrl/$meetingId"; // URL complète de la réunion
//     setState(() {}); // Mettre à jour l'interface
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Créer une réunion de visio'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: _createMeeting, // Créer une nouvelle réunion
//           ),
//         ],
//       ),
//       body: WebViewWidget(
//         controller: WebViewController()
//           ..setJavaScriptMode(
//               JavaScriptMode.unrestricted) // Activer le JavaScript
//           ..loadRequest(Uri.parse(meetingUrl)), // Charger l'URL de la réunion
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VisioPage extends StatefulWidget {
  const VisioPage({super.key});

  @override
  _VisioPageState createState() => _VisioPageState();
}

class _VisioPageState extends State<VisioPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isAuthenticated = true;
        _userEmail = user.email ?? '';
      });
      _createAndJoinMeeting();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signIn() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(
        GoogleAuthProvider(),
      );
      setState(() {
        _isAuthenticated = true;
        _userEmail = userCredential.user?.email ?? '';
      });
      _createAndJoinMeeting();
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAndJoinMeeting() async {
    String roomName =
        'meeting-${_userEmail.split('@')[0]}-${DateTime.now().millisecondsSinceEpoch}';
    String encodedRoomName = Uri.encodeComponent(roomName);
    String encodedUserEmail = Uri.encodeComponent(_userEmail);

    // Créer un document pour la réunion dans Firestore
    await FirebaseFirestore.instance.collection('meetings').add({
      'roomName': roomName,
      'createdBy': _userEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    String meetingUrl =
        'https://meet.jit.si/$encodedRoomName#userInfo.displayName="$encodedUserEmail"';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(meetingUrl));

    setState(() {
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visio Conférence'),
      ),
      body: _isAuthenticated
          ? Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!)
                else
                  const Center(child: Text('Préparation de la réunion...')),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            )
          : Center(
              child: ElevatedButton(
                onPressed: _signIn,
                child: const Text('Se connecter avec Google'),
              ),
            ),
    );
  }
}
