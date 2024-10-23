import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sign_up_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student/connected_page.dart';
import '../prof/connected_page2.dart';
import '../admin/connected_page_admin.dart';
import 'choose_parcours_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  bool _isLoading = false; // bouton de connexion
  bool _isGoogleLoading = false; // overlay de connexion Google
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  Future<void> _signIn(BuildContext context) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);

      DocumentSnapshot userDoc = await userDocRef.get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      String role = userData?['role'] ?? '';

      if (role == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConnectedPage2()),
        );
      } else if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConnectedPageAdmin()),
        );
      } else if (role == 'student') {
        if (userData == null || !userData.containsKey('parcours')) {
          await userDocRef.set({
            'parcours': [],
          }, SetOptions(merge: true));
        }

        List<dynamic> parcours = userData?['parcours'] ?? [];

        if (parcours.isEmpty) {
          // sélection parcours page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    SelectParcoursPage(userId: userCredential.user!.uid)),
          );
        } else {
          // page étudiant
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ConnectedPage()),
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('email');
        await prefs.remove('password');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _isLoginButtonEnabled {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre adresse email.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de réinitialisation envoyé.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de l\'email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/img4k.jpg',
              fit: BoxFit.cover,
            ),
          ),
          //  effet de fondu
          Align(
              alignment: Alignment.bottomCenter,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0), // Transparent au début
                      Colors.white.withOpacity(1.0), //  fin
                    ],
                    stops: [0.0, 0.22], // où commence le fondu
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    // padding: const EdgeInsets.symmetric(
                    //     horizontal: 16.0, vertical: 24.0),
                    padding: const EdgeInsets.fromLTRB(16.0, 70.0, 16.0, 24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Connectez-vous',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Email",
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Mot de passe",
                            icon: Icons.lock,
                            obscureText: !_isPasswordVisible,
                            controller: _passwordController,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                              const Text(
                                "Se souvenir de moi",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLoginButton(),
                          const SizedBox(height: 16),
                          _buildSeparator(),
                          const SizedBox(height: 16),
                          _buildGoogleLoginButton(),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _resetPassword,
                            child: const Text(
                              "Mot de passe oublié?",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Pas encore de compte ? ",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpPage()),
                                  );
                                },
                                child: const Text(
                                  "S'inscrire",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4DAED1),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
          if (_isGoogleLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54, // Overlay semi-transparent
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    required TextEditingController controller,
  }) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: suffixIcon,
        border: const UnderlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap:
          _isLoginButtonEnabled && !_isLoading ? () => _signIn(context) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 2,
              ),
            if (!_isLoading) ...[
              Icon(Icons.login, color: Colors.blue),
              const SizedBox(width: 10),
              const Text(
                "Se connecter",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return const Row(
      children: [
        Expanded(child: Divider(thickness: 0.6, color: Colors.black)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "OU",
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
        ),
        Expanded(child: Divider(thickness: 0.6, color: Colors.black)),
      ],
    );
  }

  Widget _buildGoogleLoginButton() {
    return OutlinedButton.icon(
      onPressed: _handleGoogleSignIn,
      icon: const Icon(FontAwesomeIcons.google, color: Colors.black, size: 16),
      label: const Text(
        "Se connecter avec Google",
        style: TextStyle(fontSize: 14, color: Colors.black),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true; // affiche l'overlay
    });
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication? googleAuth =
            await googleUser.authentication;

        if (googleAuth != null) {
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);

          User? user = userCredential.user;
          if (user != null) {
            DocumentReference userRef =
                FirebaseFirestore.instance.collection('users').doc(user.uid);

            DocumentReference userDocRef = FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid);

            DocumentSnapshot userDoc = await userDocRef.get();
            Map<String, dynamic>? userData =
                userDoc.data() as Map<String, dynamic>?;

            String role = userData?['role'] ?? '';

            if (!userDoc.exists) {
              await userRef.set({
                'email': user.email,
                'displayName': user.displayName,
                'role': 'student',
              });
            }

            userDoc = await userRef.get();

            if (role == 'teacher') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ConnectedPage2()),
              );
            }
            if (role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ConnectedPageAdmin()),
              );
            } else if (role == 'student') {
              if (userData == null || !userData.containsKey('parcours')) {
                await userDocRef.set({
                  'parcours': [],
                }, SetOptions(merge: true));
              }

              List<dynamic> parcours = userData?['parcours'] ?? [];

              if (parcours.isEmpty) {
                //sélection parcours page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SelectParcoursPage(userId: userCredential.user!.uid)),
                );
              } else {
                // page étudiant
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ConnectedPage()),
                );
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Erreur lors de l\'authentification Google.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion Google: $e')),
      );
    } finally {
      setState(() {
        _isGoogleLoading = false; // cache l'overlay
      });
    }
  }
}
