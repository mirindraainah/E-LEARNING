import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'evaluation.dart';

class CountdownPage extends StatefulWidget {
  @override
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  ValueNotifier<Duration> _currentDifference =
      ValueNotifier(Duration(seconds: 0));
  StreamSubscription? _evaluationSubscription;
  StreamSubscription? _qcmSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
    _startRealTimeTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _evaluationSubscription?.cancel();
    _qcmSubscription?.cancel();
    _animationController.dispose();
    _currentDifference.dispose();
    super.dispose();
  }

  void _startRealTimeTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      if (_currentEvaluationData != null) {
        final dateEvaluation =
            (_currentEvaluationData!['dateEvaluation'] as Timestamp).toDate();
        final duree = _currentEvaluationData!['duree'] as int;
        final endTime = dateEvaluation.add(Duration(minutes: duree));
        final now = DateTime.now();

        if (now.isAfter(dateEvaluation) && now.isBefore(endTime)) {
          // L'évaluation est en cours
          _timer?.cancel();
          _navigateToQCM(_currentEvaluationId!, _currentEvaluationData!);
        } else if (now.isBefore(dateEvaluation)) {
          // Mise à jour du compte à rebours
          _currentDifference.value = dateEvaluation.difference(now);
        } else {
          // L'évaluation est terminée
          _currentEvaluationData = null;
          _currentEvaluationId = null;
        }
      }
    });
  }

  Map<String, dynamic>? _currentEvaluationData;
  String? _currentEvaluationId;

  Future<void> _navigateToQCM(
      String evaluationId, Map<String, dynamic> qcmData) async {
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QCMPage(
          evaluationId: evaluationId,
          qcmData: qcmData,
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getEvaluationsStream(List<dynamic> userParcours) {
    return FirebaseFirestore.instance
        .collection('evaluations_actives')
        .where('parcours', isEqualTo: userParcours)
        .where('status', isEqualTo: 'scheduled')
        .snapshots();
  }

  Stream<DocumentSnapshot> _getQCMStream(String evaluationId) {
    return FirebaseFirestore.instance
        .collection('qcm')
        .doc(evaluationId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Évaluations'),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final userParcours = userData['parcours'] as List<dynamic>;

          return StreamBuilder<QuerySnapshot>(
            stream: _getEvaluationsStream(userParcours),
            builder: (context, snapshot) {
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                _currentEvaluationData = null;
                _currentEvaluationId = null;
                return _buildNoEvaluationMessage();
              }

              final evaluationActive = snapshot.data!.docs.first;
              final evaluationId = evaluationActive.id;
              _currentEvaluationId = evaluationId;

              return StreamBuilder<DocumentSnapshot>(
                stream: _getQCMStream(evaluationId),
                builder: (context, qcmSnapshot) {
                  if (!qcmSnapshot.hasData || qcmSnapshot.hasError) {
                    _currentEvaluationData = null;
                    return _buildNoEvaluationMessage();
                  }

                  final qcmData =
                      qcmSnapshot.data!.data() as Map<String, dynamic>;
                  _currentEvaluationData = qcmData;

                  final dateEvaluation =
                      (qcmData['dateEvaluation'] as Timestamp).toDate();
                  final duree = qcmData['duree'] as int;
                  final title = qcmData['titre'] ?? 'Évaluation sans titre';
                  final now = DateTime.now();
                  final endTime = dateEvaluation.add(Duration(minutes: duree));

                  if (now.isAfter(dateEvaluation) && now.isBefore(endTime)) {
                    // Redirection immédiate si l'évaluation est en cours
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _navigateToQCM(evaluationId, qcmData);
                    });
                    return Center(child: CircularProgressIndicator());
                  } else if (now.isAfter(endTime)) {
                    return _buildNoEvaluationMessage();
                  }

                  return ValueListenableBuilder<Duration>(
                    valueListenable: _currentDifference,
                    builder: (context, difference, child) {
                      return _buildEvaluationCountdown(
                          title, difference, duree);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoEvaluationMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'Aucune évaluation prévue',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Vous serez notifié lorsqu\'une évaluation sera programmée',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCountdown(
      String title, Duration difference, int duree) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      difference.inSeconds <= 60 ? _scaleAnimation.value : 1.0,
                  child: Text(
                    'Prochaine évaluation dans',
                    style: TextStyle(
                      fontSize: 18,
                      color: difference.inSeconds <= 60
                          ? Colors.white70
                          : Colors.white70,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            _buildCountdownTimer(difference),
            SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Durée de l\'évaluation',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$duree minutes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBlock(int value, String label, bool isHighlighted) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.red.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.red : Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isHighlighted ? Colors.red.shade200 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer(Duration difference) {
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    final isCloseToStart = difference.inSeconds <= 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeBlock(days, 'Jours', isCloseToStart),
        SizedBox(width: 16),
        _buildTimeBlock(hours, 'Heures', isCloseToStart),
        SizedBox(width: 16),
        _buildTimeBlock(minutes, 'Minutes', isCloseToStart),
        SizedBox(width: 16),
        _buildTimeBlock(seconds, 'Secondes', isCloseToStart),
      ],
    );
  }
}
