import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart' as timeago_fr;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../component/skeletonB.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _removedAnnouncements = [];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago_fr.FrMessages());
    _loadRemovedAnnouncements();
  }

  Future<void> _loadRemovedAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _removedAnnouncements = prefs.getStringList('removedAnnouncements') ?? [];
    });
  }

  Future<void> _saveRemovedAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('removedAnnouncements', _removedAnnouncements);
  }

  Future<List<QueryDocumentSnapshot>> _fetchAnnouncements() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs;
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Annonces',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            // color: Colors.blue[300],
            color: Colors.grey, 
           
          ),
        ),
        // backgroundColor: Colors.blue[50],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _fetchAnnouncements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return const Center(
                    child: SkeletonLoader(),
                  );
                },
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Oups ! Erreur de chargement',
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18), // erreur en gris
                ),
              );
            }

            final announcements = snapshot.data ?? [];

            return ListView.builder(
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];

                if (_removedAnnouncements.contains(announcement.id)) {
                  return SizedBox.shrink();
                }

                return Dismissible(
                    key: Key(announcement.id),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[
                            100], // arrière-plan de suppression
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Icon(Icons.delete,
                          color:
                              Colors.blue[300]), 
                    ),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[
                            100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Icon(Icons.delete,
                          color:
                              Colors.blue[300]), //  suppression en bleu
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        _removedAnnouncements.add(announcement.id);
                        _saveRemovedAnnouncements();
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Annonce retirée 🗑️'),
                          action: SnackBarAction(
                            label: 'Oups ! Annuler',
                            onPressed: () {
                              setState(() {
                                _removedAnnouncements.remove(announcement.id);
                                _saveRemovedAnnouncements();
                              });
                            },
                          ),
                          backgroundColor:
                              Colors.blueGrey[700], // couleur SnackBar
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(
                              vertical: 3), // espace entre les cartes
                          decoration: BoxDecoration(
                            color:
                                _getColorBasedOnAge(announcement['timestamp']),
                            border: Border(
                              left: BorderSide(
                                color: Colors.cyan,
                                width: 4,
                              ),
                            ),
                            borderRadius:
                                BorderRadius.circular(8), // Coins arrondis
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2), // Ombre
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTimeAgo(announcement['timestamp']
                                        as Timestamp?),
                                    style: TextStyle(
                                      color: Colors.blueGrey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Icon(
                                    _getIconBasedOnAge(
                                        announcement['timestamp']),
                                    color:
                                        Colors.pinkAccent, 
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                announcement['content'] ?? '...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueGrey[
                                      900], 
                                ),
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                color: Colors.grey[400],
                                thickness: 1, 
                                height: 20,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  announcement['email'] ?? '...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Colors.cyan[700], 
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                          height: 0,
                        ),
                      ],
                    ));
              },
            );
          },
        ),
      ),
    );
  }

  Color _getColorBasedOnAge(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inHours < 23) {
      // return Colors.blue[50]!;
      return Colors.green[50]!;
    } else {
      return Color(0xFFD9EAF6);
    }
  }

  IconData _getIconBasedOnAge(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inHours < 23) {
      return Icons.new_releases; // annonces récentes
    } else {
      return Icons.article; // annonces plus anciennes
    }
  }
}

