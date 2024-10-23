import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home/home_page.dart';
import 'visio/visio_page.dart';
import 'profile/profile_page.dart';
import 'courses/courses_page.dart';
import 'evaluation/list.dart';
import 'select_parcours.dart';

class ConnectedPage2 extends StatefulWidget {
  const ConnectedPage2({super.key});

  @override
  _ConnectedPage2State createState() => _ConnectedPage2State();
}

class _ConnectedPage2State extends State<ConnectedPage2> {
  int _selectedIndex = 0; // défaut annonce

  // liste des pages
  final List<Widget> _pages = [
    const HomePage(),
    const SelectParcoursPage(),
    ListeQCMPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _pages[_selectedIndex], // afficher page selectionnée
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(top: 20),
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
                      ? _activeIcon(CupertinoIcons.home, 'Accueil')
                      : const Icon(CupertinoIcons.home),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _selectedIndex == 1
                      ? _activeIcon(CupertinoIcons.book, 'Cours')
                      : const Icon(CupertinoIcons.book),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _selectedIndex == 2
                      ? _activeIcon(CupertinoIcons.video_camera, 'Visio')
                      : const Icon(CupertinoIcons.video_camera),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _selectedIndex == 3
                      ? _activeIcon(CupertinoIcons.profile_circled, 'Profil')
                      : const Icon(CupertinoIcons.profile_circled),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
