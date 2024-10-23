import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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
  late PageController _pageController;
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
    _pageController = PageController();
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
            // 5 minutes warning
            _showWarning = true;
            _showTimeWarning();
          }
        } else {
          _timer.cancel();
          _submitQCM(isTimeUp: true);
        }
      });
    });
  }

  void _showTimeWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attention !'),
        content: Text('Il ne reste plus que 5 minutes !'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
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
              onPressed: () => Navigator.pop(context, true),
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
                Navigator.of(context).popUntil((route) => route.isFirst);
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
    _pageController.dispose();
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
    double progressValue = (_currentQuestionIndex + 1) / questions.length;

    return WillPopScope(
      onWillPop: () async {
        bool? confirmExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Quitter le QCM ?'),
            content: Text(
                'Vos réponses ne seront pas enregistrées. Êtes-vous sûr de vouloir quitter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Non'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Oui'),
                // style: ElevatedButton.styleFrom(
                //   backgroundColor: Colors.red,
                // ),
              ),
            ],
          ),
        );
        return confirmExit ?? false;
      },
      child: Scaffold(
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
        body: Column(
          children: [
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 6,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                onPageChanged: (index) {
                  setState(() => _currentQuestionIndex = index);
                  _progressAnimationController.forward(from: 0.0);
                },
                itemBuilder: (context, index) {
                  return _buildQuestionCard(questions[index], index);
                },
              ),
            ),
            _buildNavigationBar(questions.length),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int questionIndex) {
    return SingleChildScrollView(
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

  Widget _buildNavigationBar(int totalQuestions) {
    bool hasAnswered = _userAnswers[_currentQuestionIndex]?.isNotEmpty ?? false;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentQuestionIndex > 0)
            ElevatedButton.icon(
              onPressed: () {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Précédent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
              ),
            ),
          if (_currentQuestionIndex > 0) SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: hasAnswered
                  ? () {
                      if (_currentQuestionIndex < totalQuestions - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _submitQCM();
                      }
                    }
                  : null,
              icon: Icon(
                _currentQuestionIndex < totalQuestions - 1
                    ? Icons.arrow_forward
                    : Icons.check,
              ),
              label: Text(
                _currentQuestionIndex < totalQuestions - 1
                    ? 'Suivant'
                    : 'Terminer',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
