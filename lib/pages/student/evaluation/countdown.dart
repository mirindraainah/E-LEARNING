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
  bool _isCountdownFinished = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Duration? _currentDifference;
  bool _isCountdownStarted = false;
  bool _hasActiveEvaluation = false;

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToQCM(
      String evaluationId, Map<String, dynamic> qcmData) async {
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

  void _checkEvaluationExpiration(DateTime dateEvaluation, int duree,
      String evaluationId, Map<String, dynamic> qcmData) async {
    final DateTime endTime = dateEvaluation.add(Duration(minutes: duree));
    final now = DateTime.now();

    if (now.isAfter(endTime)) {
      // L'évaluation est déjà terminée
      if (_hasActiveEvaluation) {
        // Ne pas afficher le message si c'est déjà inactif
        // setState(() {
        //   _hasActiveEvaluation = false; // Aucune évaluation active
        // });
      }
    } else if (now.isAfter(dateEvaluation)) {
      // L'évaluation a commencé mais n'est pas encore terminée
      if (!_hasActiveEvaluation) {
        // Ne pas rediriger si déjà actif
        setState(() {
          _hasActiveEvaluation = true; // Une évaluation est active
        });
        Future.microtask(() async {
          await _navigateToQCM(evaluationId, qcmData);
        });
      }
    } else {
      setState(() {
        _hasActiveEvaluation = true; // Une évaluation est active
      });
    }
  }

  void _startCountdown(
      Duration difference, String evaluationId, Map<String, dynamic> qcmData) {
    if (_timer != null) return;

    _currentDifference = difference;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_currentDifference!.inSeconds <= 0) {
          _timer?.cancel();
          _hasActiveEvaluation = false; // Met à jour l'état de l'évaluation
        } else {
          _currentDifference =
              Duration(seconds: _currentDifference!.inSeconds - 1);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Évaluations'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData ||
                  userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final userParcours = userData['parcours'];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('evaluations_actives')
                    .where('parcours', isEqualTo: userParcours)
                    .where('status', isEqualTo: 'scheduled')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data!.docs.isEmpty) {
                    return _buildNoEvaluationMessage();
                  }

                  final evaluationActive = snapshot.data!.docs.first;
                  final evaluationId = evaluationActive.id;

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('qcm')
                        .doc(evaluationId)
                        .snapshots(),
                    builder: (context, qcmSnapshot) {
                      if (qcmSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!qcmSnapshot.hasData || qcmSnapshot.hasError) {
                        return _buildNoEvaluationMessage();
                      }

                      final qcmData =
                          qcmSnapshot.data!.data() as Map<String, dynamic>;
                      final dateEvaluation =
                          (qcmData['dateEvaluation'] as Timestamp).toDate();
                      final duree = qcmData['duree'] as int;
                      final title = qcmData['titre'] ?? 'Évaluation sans titre';

                      // Vérifier si l'évaluation est expirée
                      _checkEvaluationExpiration(
                          dateEvaluation, duree, evaluationId, qcmData);

                      final difference =
                          dateEvaluation.difference(DateTime.now());

                      // Démarrer le compte à rebours si nécessaire
                      if (!_isCountdownStarted) {
                        _isCountdownStarted =
                            true; // Marquez le compte à rebours comme démarré
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _startCountdown(difference, evaluationId, qcmData);
                        });
                      }

                      // Afficher l'évaluation seulement si active
                      if (_hasActiveEvaluation) {
                        return _buildEvaluationCountdown(
                            title, _currentDifference ?? difference, duree);
                      } else {
                        return _buildNoEvaluationMessage(); // Afficher message si pas d'évaluation
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
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
                          ? Colors.red
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
