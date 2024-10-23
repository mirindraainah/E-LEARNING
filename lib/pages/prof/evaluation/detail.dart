import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailsQCMPage extends StatelessWidget {
  final String qcmId;

  DetailsQCMPage({required this.qcmId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du QCM'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance.collection('qcm').doc(qcmId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Une erreur est survenue'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('QCM non trouvé'));
          }

          var qcmData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> questions = qcmData['questions'] ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(qcmData['titre'] ?? 'Sans titre',
                    style: Theme.of(context).textTheme.headlineMedium),
                SizedBox(height: 8),
                Text('Durée: ${qcmData['duree']} minutes'),
                SizedBox(height: 8),
                Text(
                    'Date d\'évaluation: ${DateFormat('dd/MM/yyyy HH:mm').format((qcmData['dateEvaluation'] as Timestamp).toDate())}'),
                SizedBox(height: 16),
                if (qcmData['illustration'] != null)
                  Image.network(qcmData['illustration'], height: 200),
                SizedBox(height: 16),
                Text('Questions:',
                    style: Theme.of(context).textTheme.headlineMedium),
                SizedBox(height: 8),
                ...questions.asMap().entries.map((entry) {
                  int index = entry.key;
                  var question = entry.value;
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${index + 1}: ${question['texte']}',
                          ),
                          SizedBox(height: 8),
                          Text('Type: ${question['type']}'),
                          SizedBox(height: 8),
                          if (question['type'] == 'choixMultiple')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Options:'),
                                ...question['options']
                                    .map((option) => Text('- $option'))
                                    .toList(),
                              ],
                            ),
                          SizedBox(height: 8),
                          Text(
                              'Réponse correcte: ${question['reponseCorrecte']}'),
                          SizedBox(height: 8),
                          Text('Barème: ${question['bareme']} point(s)'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
