import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../component/skeleton.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _userParcours;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchUserParcours();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _fetchUserParcours() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          // premier parcours
          List<dynamic>? parcoursList =
              userDoc.data()?['parcours'] as List<dynamic>?;
          if (parcoursList != null && parcoursList.isNotEmpty) {
            _userParcours = parcoursList.first as String?;
            print("Premier parcours de l'utilisateur : $_userParcours");
          } else {
            _userParcours = null;
            print("Aucun parcours trouvé pour cet utilisateur.");
          }
        });
      }
    }
  }

  double _calculateProgress(List<dynamic> documents, List<dynamic> audio,
      List<dynamic> video, List<dynamic> openedLessons) {
    int totalLessons = documents.length + audio.length + video.length;

    if (totalLessons == 0) {
      return 0.0; // Pas de leçons, donc pas de progression
    }

    int openedCount = openedLessons.length;

    // progression ne dépasse pas 1 (100%)
    return (openedCount > totalLessons) ? 1.0 : openedCount / totalLessons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
              ),
            )),
        // backgroundColor: Colors.grey[200],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('parcours', isEqualTo: _userParcours)
                    .snapshots()
                    .asyncMap((snapshot) async {
                  var courses =
                      await Future.wait(snapshot.docs.map((doc) async {
                    var data = doc.data() as Map<String, dynamic>;

                    List<dynamic> documents = data['documents'] ?? [];
                    List<dynamic> audio = data['audio'] ?? [];
                    List<dynamic> video = data['video'] ?? [];

                    List<dynamic> openedLessons = [];

                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      var userProgressDoc = await FirebaseFirestore.instance
                          .collection('userProgress')
                          .doc(userId)
                          .collection('courses')
                          .doc(doc.id)
                          .get();

                      openedLessons =
                          userProgressDoc.data()?['openedLessons'] ?? [];
                    }
                    double progress = _calculateProgress(
                        documents, audio, video, openedLessons);
                    setState(() {}); //ici
                    return {
                      "id": doc.id,
                      "title": data['title'],
                      "progress": progress,
                      "progressPercentage": progress * 100,
                      "totalLessons":
                          documents.length + audio.length + video.length,
                      "imageUrl": data['imageUrl'],
                    };
                  }));

                  if (_searchQuery.isNotEmpty) {
                    courses = courses.where((course) {
                      return course['title']
                          .toLowerCase()
                          .contains(_searchQuery);
                    }).toList();
                  }

                  return courses;
                }),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: SkeletonLoader());
                  }

                  var courses = snapshot.data!;
                  return ListView.builder(
                    itemCount: courses.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                    itemBuilder: (context, index) {
                      var course = courses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CourseDetailsPage(courseId: course['id']),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // Image de fond
                                  SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: course['imageUrl'] != null &&
                                            course['imageUrl'].isNotEmpty
                                        ? Image.network(
                                            course['imageUrl'],
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'lib/assets/image1.jpg',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  // Overlay gradient
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Contenu
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course['title'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${course['totalLessons']} Leçons',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Stack(
                                            children: [
                                              Container(
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              FractionallySizedBox(
                                                widthFactor: course['progress'],
                                                child: Container(
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: Colors.greenAccent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${(course['progressPercentage'] as double).toStringAsFixed(1)}% complété',
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Icône de flèche
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
