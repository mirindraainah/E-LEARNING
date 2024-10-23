import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String searchQuery = '';

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  Future<void> supprimerCompte(String userId, BuildContext context) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce compte ?'),
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

    if (confirmation == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé avec succès')),
        );
      } catch (e) {
        print("Erreur lors de la suppression du compte : $e");
      }
    }
  }

  Future<void> toggleRole(String userId, String currentRole) async {
    String newRole = currentRole == 'student' ? 'teacher' : 'student';
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content:
              Text('Êtes-vous sûr de vouloir changer le rôle en "$newRole" ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Changer'),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'role': newRole});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rôle mis à jour : $newRole')),
        );
      } catch (e) {
        print("Erreur lors de la mise à jour du rôle : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etudiant',
            style:
                TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: updateSearchQuery,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Rechercher un étudiant',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    contentPadding: const EdgeInsets.all(16.0),
                  ),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SkeletonLoader(
                    builder: Container(
                      margin: const EdgeInsets.all(8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: SkeletonLoader(
                            builder: Container(
                              height: 20.0,
                              width: double.infinity,
                              color: Colors.grey[300],
                            ),
                          ),
                          subtitle: SkeletonLoader(
                            builder: Container(
                              height: 16.0,
                              width: double.infinity,
                              color: Colors.grey[300],
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    items: 5,
                    period: const Duration(milliseconds: 1000),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement'));
                }

                final enseignants = snapshot.data!.docs;

                final filteredStudents = enseignants.where((enseignant) {
                  final data = enseignant.data() as Map<String, dynamic>;
                  final displayName = (data['displayName'] ?? '').toLowerCase();
                  final email = (data['email'] ?? '').toLowerCase();
                  return displayName.contains(searchQuery) ||
                      email.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  shrinkWrap: true, // ajusté au contenu du listview
                  physics:
                      const NeverScrollableScrollPhysics(), // désactive le défilement
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final enseignant =
                        filteredStudents[index].data() as Map<String, dynamic>;
                    String displayName = enseignant['displayName'] ?? '';
                    String email = enseignant['email'] ?? 'Email inconnu';
                    String userId = filteredStudents[index].id;
                    String role = enseignant['role'] ?? 'student';

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          displayName.isNotEmpty ? displayName : email,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(
                            displayName.isNotEmpty ? Icons.person : Icons.email,
                            color: Colors.white,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              supprimerCompte(userId, context);
                            } else if (value == 'toggleRole') {
                              toggleRole(userId, role);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem<String>(
                                value: 'toggleRole',
                                child: Text('Changer le rôle'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ];
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
