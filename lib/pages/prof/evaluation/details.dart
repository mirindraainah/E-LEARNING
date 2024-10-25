import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class CreerEditerQCMPage extends StatefulWidget {
  final String? qcmId;

  CreerEditerQCMPage({this.qcmId});

  @override
  _CreerEditerQCMPageState createState() => _CreerEditerQCMPageState();
}

class _CreerEditerQCMPageState extends State<CreerEditerQCMPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _dureeController = TextEditingController();
  DateTime _dateEvaluation = DateTime.now();
  List<Question> _questions = [];
  List<TextEditingController> _questionControllers = [];
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.qcmId != null) {
      _chargerDonneesQCM();
    }
  }

  double _calculateTotalBareme() {
    return _questions.fold(0, (sum, question) => sum + question.bareme);
  }

  void _chargerDonneesQCM() async {
    DocumentSnapshot qcmDoc = await FirebaseFirestore.instance
        .collection('qcm')
        .doc(widget.qcmId)
        .get();
    if (qcmDoc.exists) {
      setState(() {
        _titreController.text = qcmDoc['titre'];
        _dureeController.text = qcmDoc['duree'].toString();
        _dateEvaluation = qcmDoc['dateEvaluation'].toDate();
        _imageUrl = qcmDoc['illustration'];

        // Charger les questions et leurs contrôleurs
        _questions = (qcmDoc['questions'] as List)
            .map((q) => Question.fromMap(q))
            .toList();
        _questionControllers = _questions
            .map((question) => TextEditingController(text: question.texte))
            .toList();
      });
    }
  }

  Future<void> _selectionnerImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref =
        FirebaseStorage.instance.ref().child('qcm_images/$fileName');
    UploadTask uploadTask = ref.putFile(_imageFile!);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _ajouterQuestion() {
    setState(() {
      _questions.add(Question(
          type: QuestionType.choixMultiple,
          texte: '',
          options: [],
          reponsesCorrectes: [],
          bareme: 1));
    });
    _questionControllers
        .add(TextEditingController()); // Ajoutez le contrôleur ici
  }

  Future<void> _sauvegarderQCM() async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }

      // Filtrer les options vides
      for (var question in _questions) {
        if (question.type == QuestionType.choixMultiple) {
          // Nettoie les options vides pour les questions à choix multiples
          question.options = question.options
              .where((option) => option.trim().isNotEmpty)
              .toList();
          // S'assure que les réponses correctes existent dans les options
          question.reponsesCorrectes = question.reponsesCorrectes
              .where((response) => question.options.contains(response))
              .toList();
        } else {
          // Pour les réponses libres, s'assure qu'il n'y a pas de réponses vides
          question.reponsesCorrectes = question.reponsesCorrectes
              .where((reponse) => reponse.trim().isNotEmpty)
              .toList();
        }
      }

      Map<String, dynamic> qcmData = {
        'titre': _titreController.text,
        'duree': int.parse(_dureeController.text),
        'dateEvaluation': Timestamp.fromDate(_dateEvaluation),
        'illustration': imageUrl,
        'questions': _questions.map((q) => q.toMap()).toList(),
      };

      if (widget.qcmId != null) {
        await FirebaseFirestore.instance
            .collection('qcm')
            .doc(widget.qcmId)
            .update(qcmData);
      } else {
        await FirebaseFirestore.instance.collection('qcm').add(qcmData);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.qcmId != null ? 'Éditer QCM' : 'Créer QCM'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _sauvegarderQCM,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildHeaderSection(),
                  SizedBox(height: 24),
                  _buildQuestionsSection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterQuestion,
        child: Icon(Icons.add),
        tooltip: 'Ajouter une question',
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titreController,
              decoration: InputDecoration(
                labelText: 'Titre du QCM',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Veuillez entrer un titre' : null,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dureeController,
                    decoration: InputDecoration(
                      labelText: 'Durée (minutes)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Veuillez entrer une durée' : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dateEvaluation,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_dateEvaluation),
                        );
                        if (time != null) {
                          setState(() {
                            _dateEvaluation = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date d\'évaluation',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(_dateEvaluation),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: _imageFile != null || _imageUrl != null
                  ? Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _imageFile = null;
                              _imageUrl = null;
                            });
                          },
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _selectionnerImage,
                      icon: Icon(Icons.add_photo_alternate),
                      label: Text('Ajouter une image'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImageQcm(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref =
        FirebaseStorage.instance.ref().child('qcm_question_images/$fileName');
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _selectQuestionImage(int questionIndex) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File imageFile = File(image.path);
      String? imageUrl = await _uploadImageQcm(imageFile);
      if (imageUrl != null) {
        setState(() {
          _questions[questionIndex].imageUrl = imageUrl;
        });
      }
    }
  }

  void _removeQuestionImage(int questionIndex) {
    setState(() {
      _questions[questionIndex].imageUrl = null;
    });
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ajout du total des barèmes
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.stars, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Total des points :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                '${_calculateTotalBareme().toStringAsFixed(1)} pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
        Text('Questions', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16),
        ..._questions.asMap().entries.map((entry) {
          int index = entry.key;
          Question question = entry.value;
          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text('Question ${index + 1}'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _questionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Texte de la question',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        onChanged: (value) {
                          setState(() {
                            _questions[index].texte = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      _buildQuestionImageSection(question, index),
                      SizedBox(height: 16),
                      DropdownButtonFormField<QuestionType>(
                        value: question.type,
                        decoration: InputDecoration(
                          labelText: 'Type de question',
                          border: OutlineInputBorder(),
                        ),
                        items: QuestionType.values.map((QuestionType type) {
                          return DropdownMenuItem<QuestionType>(
                            value: type,
                            child: Text(type == QuestionType.choixMultiple
                                ? 'Choix multiple'
                                : 'Réponse libre'),
                          );
                        }).toList(),
                        onChanged: (QuestionType? newValue) {
                          setState(() {
                            _questions[index].type = newValue!;
                            if (newValue != QuestionType.choixMultiple) {
                              _questions[index].reponsesCorrectes.clear();
                            }
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      if (question.type == QuestionType.choixMultiple)
                        _buildChoixMultipleOptions(question, index),
                      if (question.type == QuestionType.reponseLibre)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              initialValue:
                                  question.reponsesCorrectes.join('\n'),
                              decoration: InputDecoration(
                                labelText: 'Réponses acceptées',
                                helperText:
                                    'Entrez chaque réponse sur une nouvelle ligne',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: null,
                              onChanged: (value) {
                                setState(() {
                                  // Sépare les réponses par les sauts de ligne et retire les espaces inutiles
                                  _questions[index].reponsesCorrectes = value
                                      .split('\n')
                                      .map((s) => s.trim())
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                });
                              },
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Nombre de réponses acceptées: ${question.reponsesCorrectes.length}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: question.bareme.toString(),
                        decoration: InputDecoration(
                          labelText: 'Barème',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          setState(() {
                            _questions[index].bareme =
                                double.tryParse(value) ?? 1.0;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _questions.removeAt(index);
                            _questionControllers[index].dispose();
                            _questionControllers.removeAt(index);
                          });
                        },
                        icon: Icon(Icons.delete),
                        label: Text('Supprimer la question'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color.fromARGB(255, 250, 155, 148),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildQuestionImageSection(Question question, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Image de la question',
            style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        if (question.imageUrl != null)
          Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: () {
                  // Optionally, you can add a function to view the image in full screen
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(question.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => _removeQuestionImage(index),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: () => _selectQuestionImage(index),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Ajouter une image',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChoixMultipleOptions(Question question, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...question.options.asMap().entries.map((optionEntry) {
          int optionIndex = optionEntry.key;
          String option = optionEntry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: option,
                    decoration: InputDecoration(
                      labelText: 'Option ${optionIndex + 1}',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _questions[questionIndex].options[optionIndex] = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Checkbox(
                  value: question.reponsesCorrectes
                      .contains(option), // Mettez à jour ici
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        question.reponsesCorrectes
                            .add(option); // Ajoutez l'option
                      } else {
                        question.reponsesCorrectes
                            .remove(option); // Retirez l'option
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _questions[questionIndex].options.add('');
            });
          },
          icon: Icon(Icons.add),
          label: Text('Ajouter une option'),
        ),
      ],
    );
  }
}

enum QuestionType {
  choixMultiple,
  reponseLibre,
}

class Question {
  String texte;
  QuestionType type;
  List<String> options;
  List<String> reponsesCorrectes;
  double bareme;
  String? imageUrl; // New field for question image

  Question({
    required this.texte,
    required this.type,
    required this.options,
    required this.reponsesCorrectes,
    required this.bareme,
    this.imageUrl,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      texte: map['texte'] ?? '',
      type: QuestionType.values
          .firstWhere((e) => e.toString() == 'QuestionType.${map['type']}'),
      options: List<String>.from(map['options'] ?? []),
      reponsesCorrectes: List<String>.from(map['reponsesCorrectes'] ?? []),
      bareme: map['bareme'] ?? 1,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'texte': texte,
      'type': type.toString().split('.').last,
      'options': options,
      'reponsesCorrectes': reponsesCorrectes,
      'bareme': bareme,
      'imageUrl': imageUrl,
    };
  }
}
