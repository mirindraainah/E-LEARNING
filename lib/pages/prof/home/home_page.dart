import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart' as timeago_fr;
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../component/skeletonA.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../announcement_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _editAnnouncementController =
      TextEditingController();
  List<String> _removedAnnouncements = [];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago_fr.FrMessages());
    _loadRemovedAnnouncements();
  }

  Future<void> _loadRemovedAnnouncements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _removedAnnouncements =
          prefs.getStringList('removed_announcements') ?? [];
    });
  }

  Future<void> _saveRemovedAnnouncements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('removed_announcements', _removedAnnouncements);
  }

  Random random = Random();

  Color _getColorBasedOnAge(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    // annonce moins de 23 heures
    if (difference.inHours < 23) {
      return Colors.green[50]!;
    } else {
      return Color(0xFFD9EAF6);
    }
  }

  Future<void> addAnnouncement(
      String userId, String email, String content) async {
    // Ajouter l'annonce dans Firestore
    await FirebaseFirestore.instance.collection('announcements').add({
      'userId': userId,
      'email': email,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await AnnouncementService().sendNotification(content);
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }

  Future<void> updateAnnouncement(
      String announcementId, String newContent) async {
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(announcementId)
        .update({'content': newContent});
  }

  Future<String?> getUserEmail(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['email'] : null;
  }

  void showEditDialog(String announcementId, String currentContent) {
    _editAnnouncementController.text = currentContent; // contrôleur d'édition

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier l\'annonce'),
          content: TextField(
            controller: _editAnnouncementController,
            decoration: const InputDecoration(
              labelText: 'Contenu de l\'annonce',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newContent = _editAnnouncementController.text;
                if (newContent.isNotEmpty) {
                  Navigator.of(context).pop();
                  await updateAnnouncement(announcementId, newContent);
                  _editAnnouncementController
                      .clear(); // réinitialise contrôleur d'édition
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veuillez entrer un contenu valide.')),
                  );
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  String getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Inconnu';
    }
    DateTime dateTime = timestamp.toDate();
    return timeago.format(dateTime, locale: 'fr');
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? 'inconnu';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau d\'annonces',
            style:
                TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _announcementController,
              decoration: InputDecoration(
                labelText: 'Nouvelle annonce',
                hintText: 'Entrez votre annonce ici',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.blue,
                  ),
                  onPressed: () async {
                    String? email = await getUserEmail(userId);
                    if (email != null) {
                      String content = _announcementController.text;
                      if (content.isNotEmpty) {
                        await addAnnouncement(userId, email, content);

                        _announcementController.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Annonce ajoutée avec succès.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Veuillez entrer du contenu pour l\'annonce.')),
                        );
                      }
                    }
                  },
                ),
              ),
              maxLines: 3,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SkeletonLoader(),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Erreur lors du chargement des annonces'));
                }

                final announcements = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];

                    Color announcementColor = _getColorBasedOnAge(
                        announcement['timestamp'] as Timestamp? ??
                            Timestamp.now());

                    if (_removedAnnouncements.contains(announcement.id)) {
                      return SizedBox.shrink();
                    }
                    return Dismissible(
                        key: Key(announcement.id),
                        background: Container(
                          color: Color.fromARGB(210, 253, 228, 233),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Color.fromARGB(210, 253, 228, 233),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            _removedAnnouncements.add(announcement.id);
                          });
                          _saveRemovedAnnouncements();
                          // snackbar annulation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Annonce retirée.'),
                              action: SnackBarAction(
                                label: 'Annuler',
                                onPressed: () {
                                  // annule suppression en réajoutant l'annonce
                                  setState(() {
                                    _removedAnnouncements
                                        .remove(announcement.id);
                                  });
                                  _saveRemovedAnnouncements();
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: announcementColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      announcement['timestamp'] != null
                                          ? getTimeAgo(
                                              announcement!['timestamp']
                                                  as Timestamp?)
                                          : 'Inconnu',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
                                    ),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            showEditDialog(
                                                announcement.id,
                                                announcement['content'] ??
                                                    '...');
                                          } else if (value == 'delete') {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Confirmer la suppression'),
                                                  content: const Text(
                                                      'Êtes-vous sûr de vouloir supprimer cette annonce ?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child:
                                                          const Text('Annuler'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        Navigator.of(context)
                                                            .pop();
                                                        await deleteAnnouncement(
                                                            announcement.id);
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Annonce supprimée.')),
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors.white),
                                                      child: const Text(
                                                          'Supprimer'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (announcement['userId'] ==
                                              userId) ...[
                                            const PopupMenuItem<String>(
                                                value: 'edit',
                                                child: Text('Modifier')),
                                            const PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Text('Supprimer')),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  announcement['content'] ?? '...',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Divider(
                                  color: Colors.grey[400],
                                  thickness: 1,
                                  height: 20,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    announcement['email'] ?? '...',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyan),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
