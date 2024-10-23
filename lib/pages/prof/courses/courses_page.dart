import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'course_details_page.dart';
import 'package:intl/intl.dart';
import '../../../component/skeleton.dart';

class CoursesPage extends StatefulWidget {
  final String parcours; // Ajoutez cet argument
  const CoursesPage({super.key, required this.parcours});

  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUserId = user?.uid;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _showEditCourseDialog(Map<String, dynamic> course) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditCourseDialog(course: course);
      },
    );
  }

  Future<void> _deleteCourse(String courseId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce cours ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
              ),
            )),
        // backgroundColor: Colors.grey[200],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('courses')
              .where('ownerId', isEqualTo: _currentUserId)
              .where('parcours', isEqualTo: widget.parcours)
              .snapshots()
              .map((snapshot) {
            var courses = snapshot.docs.map((doc) {
              return {
                "id": doc.id,
                "title": doc['title'],
                "description": doc['description'],
                "createdAt": doc['createdAt'],
                "imageUrl":
                    doc.data().containsKey('imageUrl') ? doc['imageUrl'] : null,
              };
            }).toList();

            if (_searchQuery.isNotEmpty) {
              courses = courses.where((course) {
                return course['title'].toLowerCase().contains(_searchQuery);
              }).toList();
            }

            return courses;
          }),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: SkeletonLoader());
            }

            var courses = snapshot.data!;
            return ListView.builder(
              itemCount: courses.length,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              itemBuilder: (context, index) {
                var course = courses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CourseDetailsPage(courseId: course['id']),
                        ),
                      );
                    },
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // image de fond
                            SizedBox.expand(
                              child: course['imageUrl'] != null &&
                                      course['imageUrl'].isNotEmpty
                                  ? Image.network(
                                      course['imageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                            color: Colors.grey[300]);
                                      },
                                    )
                                  : Image.asset(
                                      'lib/assets/image1.jpg',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            // Overlay gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            // Contenu
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    course['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ajouté le: ${course['createdAt'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(course['createdAt'].toDate().toLocal()) : 'Date non disponible'}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Options (modifier/supprimer)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PopupMenuButton<String>(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.more_vert,
                                      color: Colors.white, size: 20),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditCourseDialog(course);
                                  } else if (value == 'delete') {
                                    _deleteCourse(course['id']);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('Modifier'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Supprimer'),
                                  ),
                                ],
                              ),
                            ),
                            // flèche
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddCourseDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCourseDialog(selectedParcours: widget.parcours);
      },
    );
  }
}

class AddCourseDialog extends StatefulWidget {
  final String selectedParcours;

  const AddCourseDialog({Key? key, required this.selectedParcours})
      : super(key: key);

  @override
  _AddCourseDialogState createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('courses/${_selectedImage!.name}');
    await imageRef.putFile(File(_selectedImage!.path));
    return await imageRef.getDownloadURL();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = pickedImage;
      });
    }
  }

  Future<void> _onAddCoursePressed() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? imageUrl = await _uploadImage();

      // ajout cours
      await FirebaseFirestore.instance.collection('courses').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'ownerId': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': Timestamp.now(),
        'parcours': widget.selectedParcours,
      });

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ajouter un Cours', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Titre'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un titre';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _selectedImage == null
                            ? const Center(child: Text('Ajouter une image'))
                            : Image.file(File(_selectedImage!.path),
                                fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _onAddCoursePressed,
                            child: const Text('Ajouter'),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditCourseDialog extends StatefulWidget {
  final Map<String, dynamic> course;

  const EditCourseDialog({Key? key, required this.course}) : super(key: key);

  @override
  _EditCourseDialogState createState() => _EditCourseDialogState();
}

class _EditCourseDialogState extends State<EditCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course['title']);
    _descriptionController =
        TextEditingController(text: widget.course['description']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = pickedImage;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('courses/${_selectedImage!.name}');
    await imageRef.putFile(File(_selectedImage!.path));
    return await imageRef.getDownloadURL();
  }

  Future<void> _updateCourse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      }

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course['id'])
          .update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl ?? widget.course['imageUrl'],
      });

      Navigator.of(context).pop();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Modifier le Cours',
                      style: TextStyle(fontSize: 18)),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un titre';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _selectedImage == null
                              ? (widget.course['imageUrl'] != null
                                  ? Image.network(
                                      widget.course['imageUrl'],
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(
                                      child: Text('Ajouter une image')))
                              : Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      if (_selectedImage != null ||
                          widget.course['imageUrl'] != null)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                widget.course['imageUrl'] = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 20, color: Colors.red),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoading
                      ? SkeletonLoader()
                      : ElevatedButton(
                          onPressed: _updateCourse,
                          child: const Text('Sauvegarder'),
                        ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
