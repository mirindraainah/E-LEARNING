import 'package:elearn/pages/student/connected_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectParcoursPage extends StatefulWidget {
  final String userId;
  const SelectParcoursPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SelectParcoursPageState createState() => _SelectParcoursPageState();
}

class _SelectParcoursPageState extends State<SelectParcoursPage> {
  Map<String, List<String>> mentionParcoursMap = {};
  String? selectedParcours;
  String? selectedMentionId; // Variable pour stocker le mentionId
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchParcours();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchParcours() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('mention').get();

      Map<String, List<String>> loadedMentionParcoursMap = {};
      for (var doc in snapshot.docs) {
        String mentionName = doc['nom'];
        if (doc['parcours'] != null && doc['parcours'] is List) {
          List<String> parcours = List<String>.from(
              doc['parcours'].where((element) => element != null));
          loadedMentionParcoursMap[mentionName] = parcours;
        }
      }

      setState(() {
        mentionParcoursMap = loadedMentionParcoursMap;
      });

      if (mentionParcoursMap.isEmpty) {
        print("Aucune mention trouvée dans la collection mention.");
      } else {
        print("${mentionParcoursMap.length} mentions trouvées.");
      }
    } catch (e) {
      print("Erreur lors du chargement des parcours: $e");
    }
  }

  Future<void> _selectParcours() async {
    if (selectedParcours != null && selectedMentionId != null) {
      String? matricule = _matriculeController.text.isNotEmpty
          ? _matriculeController.text
          : null;

      String? fullName =
          _nameController.text.isNotEmpty ? _nameController.text : null;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'parcours': FieldValue.arrayUnion([selectedParcours]),
        'matricule': matricule,
        'fullName': fullName, // Nouveau champ ajouté
        'mentionId': selectedMentionId, // Stocker le mentionId
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConnectedPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un parcours et une mention')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisissez votre parcours'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _matriculeController,
                    decoration: InputDecoration(
                      labelText: 'Matricule',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom et Prénom', // Champ pour le nom complet
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                ...mentionParcoursMap.entries.map((entry) {
                  String mentionName = entry.key;
                  List<String> parcoursList = entry.value;

                  return ExpansionTile(
                    title: Text(mentionName),
                    onExpansionChanged: (isOpen) {
                      if (isOpen) {
                        selectedMentionId =
                            entry.key; // Stocker le mentionId sélectionné
                      }
                    },
                    children: parcoursList.map((parcours) {
                      return ListTile(
                        title: Text(parcours),
                        trailing: Radio<String>(
                          value: parcours,
                          groupValue: selectedParcours,
                          onChanged: (value) {
                            setState(() {
                              selectedParcours = value;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ],
            ),
          ),
          GestureDetector(
            onTap: _selectParcours,
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
    );
  }
}
