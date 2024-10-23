import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MentionPage extends StatelessWidget {
  const MentionPage({super.key});

  Future<void> addMention(String nomMention, List<String> parcours) async {
    CollectionReference mentions =
        FirebaseFirestore.instance.collection('mention');

    await mentions
        .add({
          'nom': nomMention,
          'parcours': parcours,
        })
        .then((value) => print("Mention ajoutée: $nomMention"))
        .catchError((error) => print("Erreur lors de l'ajout: $error"));
  }

  Future<List<Map<String, dynamic>>> fetchMentions() async {
    CollectionReference mentions =
        FirebaseFirestore.instance.collection('mention');
    QuerySnapshot snapshot = await mentions.get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'nom': doc['nom'] as String,
              'parcours': doc['parcours'] as List<dynamic>,
            })
        .toList();
  }

  void _showAddMentionDialog(BuildContext context) {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController parcoursController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une Mention'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration:
                    const InputDecoration(labelText: 'Nom de la Mention'),
              ),
              TextField(
                controller: parcoursController,
                decoration: const InputDecoration(
                    labelText: 'Parcours (séparés par des virgules)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final nomMention = nomController.text;
                final parcoursList = parcoursController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList();
                if (nomMention.isNotEmpty && parcoursList.isNotEmpty) {
                  addMention(nomMention, parcoursList);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ajouter'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Bienvenue à Mention',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: () => _showAddMentionDialog(context),
            child: const Text('Ajouter Mentions'),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchMentions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Aucune mention trouvée.');
              }

              List<Map<String, dynamic>> mentionsList = snapshot.data!;
              return Column(
                children: mentionsList.map((mention) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mention: ${mention['nom']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...mention['parcours'].map((parcours) {
                        return Text('- $parcours',
                            style: const TextStyle(fontSize: 16));
                      }).toList(),
                      const SizedBox(height: 10),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
