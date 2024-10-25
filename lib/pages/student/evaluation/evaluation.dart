import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../connected_page.dart';

class QCMPage extends StatefulWidget {
  final String evaluationId;
  final Map<String, dynamic> qcmData;

  QCMPage({
    required this.evaluationId,
    required this.qcmData,
  });

  @override
  _QCMPageState createState() => _QCMPageState();
}

class _QCMPageState extends State<QCMPage> with SingleTickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  int _currentQuestionIndex = 0;
  Map<int, List<String>> _userAnswers = {};
  late Timer _timer;
  int _remainingTime = 0;
  bool _isSubmitting = false;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _initializeQCM();
  }

  void _initializeQCM() {
    _remainingTime = widget.qcmData['duree'] * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          if (_remainingTime <= 300 && !_showWarning) {
            _showWarning = true;
          }
        } else {
          _timer.cancel();
          _submitQCM(isTimeUp: true);
        }
      });
    });
  }

  Future<void> _submitQCM({bool isTimeUp = false}) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    if (!isTimeUp) {
      bool confirm = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Confirmer la soumission'),
          content: Text('Êtes-vous sûr de vouloir terminer le QCM ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => {
                _submitQCM(),
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => ConnectedPage()),
                  (route) => false,
                )
              },
              child: Text('Oui'),
            ),
          ],
        ),
      );

      if (!confirm) {
        setState(() => _isSubmitting = false);
        return;
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await FirebaseFirestore.instance
          .collection('reponses_evaluations')
          .doc('${widget.evaluationId}_${user.uid}')
          .set({
        'evaluationId': widget.evaluationId,
        'userId': user.uid,
        'reponses':
            _userAnswers.map((key, value) => MapEntry(key.toString(), value)),
        'tempsRestant': _remainingTime,
        'dateSubmission': FieldValue.serverTimestamp(),
        'completed': true,
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(isTimeUp ? 'Temps écoulé !' : 'QCM terminé'),
          content: Text(isTimeUp
              ? 'Le temps imparti est écoulé. Vos réponses ont été enregistrées.'
              : 'Vos réponses ont été enregistrées avec succès.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => ConnectedPage()),
                  (route) => false,
                );
              },
              child: Text('Retour à l\'accueil'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text(
              'Une erreur est survenue lors de la soumission du QCM. Veuillez réessayer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressAnimationController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> questions =
        List<Map<String, dynamic>>.from(widget.qcmData['questions']);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.qcmData['titre'] ?? 'QCM'),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _remainingTime <= 300
                  ? Colors.red.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  color: _remainingTime <= 300 ? Colors.red : null,
                ),
                SizedBox(width: 8),
                Text(
                  _formatTime(_remainingTime),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _remainingTime <= 300 ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _remainingTime / (widget.qcmData['duree'] * 60),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 6,
            ),
            ...questions.asMap().entries.map<Widget>((entry) {
              int index = entry.key;
              return _buildQuestionCard(entry.value, index);
            }).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitQCM,
        label: Text('Soumettre le QCM'),
        icon: Icon(Icons.check),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int questionIndex) {
    return SizedBox(
      width: MediaQuery.of(context).size.width *
          1.0, // Ajustez la largeur comme souhaité
      child: Card(
        margin: EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${questionIndex + 1}',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                question['texte'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (question['imageUrl'] != null) ...[
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    question['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(Icons.error_outline, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 20),
              Text(
                question['type'] == 'choixMultiple'
                    ? 'Sélectionnez toutes les réponses correctes'
                    : 'Sélectionnez la bonne réponse',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 12),
              ...question['options'].asMap().entries.map<Widget>((entry) {
                int optionIndex = entry.key;
                String option = entry.value;
                bool isSelected =
                    _userAnswers[questionIndex]?.contains(option) ?? false;

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          if (question['type'] == 'choixMultiple') {
                            _userAnswers[questionIndex] ??= [];
                            if (isSelected) {
                              _userAnswers[questionIndex]!.remove(option);
                            } else {
                              _userAnswers[questionIndex]!.add(option);
                            }
                          } else {
                            _userAnswers[questionIndex] = [option];
                          }
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            question['type'] == 'choixMultiple'
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _userAnswers[questionIndex] ??= [];
                                        if (value == true) {
                                          _userAnswers[questionIndex]!
                                              .add(option);
                                        } else {
                                          _userAnswers[questionIndex]!
                                              .remove(option);
                                        }
                                      });
                                    },
                                  )
                                : Radio<String>(
                                    value: option,
                                    groupValue:
                                        _userAnswers[questionIndex]?.first,
                                    onChanged: (String? value) {
                                      setState(() {
                                        _userAnswers[questionIndex] = [value!];
                                      });
                                    },
                                  ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isSelected ? Colors.blue : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}