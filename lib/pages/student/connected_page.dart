import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home/home_page.dart';
import 'visio/visio_page.dart';
import 'profile/profile_page.dart';
import 'forum/forum.dart';
import 'courses/courses_page.dart';
import 'evaluation/countdown.dart';
import 'evaluation/evaluation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/choose_parcours_page.dart';

class ConnectedPage extends StatefulWidget {
  const ConnectedPage({super.key});

  @override
  ConnectedPageState createState() => ConnectedPageState(); // Changez ici
}

class ConnectedPageState extends State<ConnectedPage> {
  // Changez ici
  int _selectedIndex = 0;

  void updateSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomePage(),
    const CoursesPage(),
    const VisioPage(),
    ForumPage(),
    CountdownPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserParcours();
  }

  Future<void> _checkUserParcours() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    List<dynamic> parcours = userDoc['parcours'] ?? [];
    if (parcours.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => SelectParcoursPage(userId: userId)),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: _selectedIndex == 0
                      ? _activeIcon(CupertinoIcons.bell_fill, 'Annonce')
                      : const Icon(CupertinoIcons.bell),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _selectedIndex == 1
                      ? _activeIcon(CupertinoIcons.book_fill, 'Cours')
                      : const Icon(CupertinoIcons.book),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _selectedIndex == 2
                      ? _activeIcon(CupertinoIcons.videocam_fill, 'Visio')
                      : const Icon(CupertinoIcons.videocam),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _selectedIndex == 3
                      ? _activeIcon(
                          CupertinoIcons.chat_bubble_text_fill, 'Forum')
                      : const Icon(CupertinoIcons.chat_bubble_text),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _selectedIndex == 4
                      ? _activeIcon(CupertinoIcons.bookmark_fill, 'QCM')
                      : const Icon(CupertinoIcons.bookmark),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _selectedIndex == 5
                      ? _activeIcon(CupertinoIcons.person_fill, 'Profil')
                      : const Icon(CupertinoIcons.person),
                  label: '',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey[600],
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
            ),
          ),
        ));
  }

  Widget _activeIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
