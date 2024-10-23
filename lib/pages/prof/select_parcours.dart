import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'courses/courses_page.dart';

class SelectParcoursPage extends StatefulWidget {
  const SelectParcoursPage({super.key});

  @override
  _SelectParcoursPageState createState() => _SelectParcoursPageState();
}

class _SelectParcoursPageState extends State<SelectParcoursPage> {
  String? _selectedParcours;
  Map<String, List<String>> _mentionParcoursMap = {};

  @override
  void initState() {
    super.initState();
    _loadParcours();
  }

  Future<void> _loadParcours() async {
    try {
      // mentions et parcours
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('mention').get();

      Map<String, List<String>> loadedMentions = {};
      for (var doc in snapshot.docs) {
        String mentionNom = doc['nom'] ?? '';
        if (doc['parcours'] != null && doc['parcours'] is List) {
          List<String> parcours = List<String>.from(
              doc['parcours'].where((element) => element != null));
          loadedMentions[mentionNom] = parcours;
        }
      }

      setState(() {
        _mentionParcoursMap = loadedMentions;
      });
    } catch (e) {
      print("Erreur lors du chargement des parcours: $e");
    }
  }

  void _onParcoursSelected(String? parcours) {
    setState(() {
      _selectedParcours = parcours;
    });
  }

  void _onProceed() {
    if (_selectedParcours != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoursesPage(parcours: _selectedParcours!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un parcours')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionnez un parcours'),
        backgroundColor: Colors.grey[200],
        automaticallyImplyLeading: false, // omettre flèche de retour
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Choisissez un parcours pour ajouter des cours :'),
            Expanded(
              child: ListView(
                children: _mentionParcoursMap.entries.map((entry) {
                  String mentionNom = entry.key;
                  List<String> parcoursList = entry.value;

                  return ExpansionTile(
                    title: Text('Mention : $mentionNom'),
                    children: parcoursList.map((parcours) {
                      return RadioListTile<String?>(
                        title: Text(parcours),
                        value: parcours,
                        groupValue: _selectedParcours,
                        onChanged: _onParcoursSelected,
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            GestureDetector(
              onTap: _onProceed,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward, color: Colors.blue),
                    const SizedBox(width: 10),
                    const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
