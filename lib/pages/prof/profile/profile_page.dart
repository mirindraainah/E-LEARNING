import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmation = await _showSignOutConfirmationDialog(context);
    if (confirmation == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacementNamed('/login');
      } catch (e) {
        _showSnackBar(context, 'Erreur de déconnexion : $e');
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmation = await _showConfirmationDialog(context);
    if (confirmation == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        await user?.delete();
        _showSnackBar(context, 'Compte supprimé avec succès');
        Navigator.of(context).pushReplacementNamed('/login');
      } catch (e) {
        _showSnackBar(context, 'Erreur lors de la suppression du compte : $e');
      }
    }
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content:
              const Text('Êtes-vous sûr de vouloir supprimer votre compte ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showSignOutConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // image email
  Widget _getProfileImage(User? user) {
    if (user?.photoURL != null) {
      return Image.network(
        user!.photoURL!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _getInitialsImage(user.email);
        },
      );
    } else {
      return _getInitialsImage(user?.email);
    }
  }

  // image avec les initiales
  Widget _getInitialsImage(String? email) {
    String initials =
        email != null && email.isNotEmpty ? email[0].toUpperCase() : '?';
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Text(
        initials,
        style: TextStyle(fontSize: 40, color: Colors.black),
      ),
    );
  }

  Widget _buildQrCode(User? user) {
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildQrSkeleton();
        }

        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('Aucune donnée disponible');
        }

        Map<String, dynamic> userData = snapshot.data!.data() ?? {};

        String qrData =
            "Nom: ${user.displayName ?? 'N/A'}\nEmail: ${user.email ?? 'N/A'}\n";

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 10),
              const Text(
                "Scannez pour partager",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQrSkeleton() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              Icons.qr_code,
              size: 100,
              color: Colors.grey[400],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 200,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Photo de profil
                ClipOval(
                  child: _getProfileImage(user),
                ),
                const SizedBox(height: 20),
                // Nom d'utilisateur
                Text(
                  user?.displayName ?? user?.email ?? 'Nom inconnu',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  user?.email ?? 'Email inconnu',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Code QR
                _buildQrCode(user),

                // Bouton Déconnexion
                _buildProfileButton(
                  Icons.logout,
                  'Déconnexion',
                  Colors.blue,
                  () => _signOut(context),
                ),

                // Bouton Supprimer
                _buildProfileButton(
                  Icons.delete_forever,
                  'Supprimer le compte',
                  Colors.red,
                  () => _deleteAccount(context),
                ),
              ],
            ),
          ),
        ));
  }

  // boutons personnalisés
  Widget _buildProfileButton(
      IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
