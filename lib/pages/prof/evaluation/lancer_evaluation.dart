import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LancerEvaluationPage extends StatefulWidget {
  final String qcmId;

  const LancerEvaluationPage({Key? key, required this.qcmId}) : super(key: key);

  @override
  _LancerEvaluationPageState createState() => _LancerEvaluationPageState();
}

class _LancerEvaluationPageState extends State<LancerEvaluationPage> {
  String? selectedMention;
  List<String> selectedParcours = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lancer l\'évaluation'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection de la mention
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('mention').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                final mentions = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sélectionner une mention',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedMention,
                  items: mentions.map((mention) {
                    return DropdownMenuItem(
                      value: mention.id,
                      child: Text(mention['nom']),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedMention = value;
                      selectedParcours = []; // Réinitialiser les parcours sélectionnés
                    });
                  },
                );
              },
            ),

            SizedBox(height: 20),

            // Sélection des parcours si une mention est sélectionnée
            if (selectedMention != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('mention')
                    .doc(selectedMention)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  final parcoursListe = List<String>.from(snapshot.data!['parcours'] ?? []);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Parcours disponibles:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...parcoursListe.map((parcours) {
                        return CheckboxListTile(
                          title: Text(parcours),
                          value: selectedParcours.contains(parcours),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedParcours.add(parcours);
                              } else {
                                selectedParcours.remove(parcours);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  );
                },
              ),

            Expanded(child: Container()),

            // Bouton de lancement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _lancerEvaluation(),
                child: Text('Lancer l\'évaluation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lancerEvaluation() async {
    if (selectedMention == null || selectedParcours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('evaluations_actives')
          .doc(widget.qcmId)
          .set({
        'mentionId': selectedMention,
        'parcours': selectedParcours,
        'status': 'scheduled',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Évaluation programmée avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la programmation: $e')),
      );
    }
  }
}
