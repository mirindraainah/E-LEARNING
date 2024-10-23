import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'pdf_view_page.dart';
import 'video_player_page.dart';
import 'audio_player_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../component/skeleton.dart';

class CourseDetailsPage extends StatefulWidget {
  final String courseId;

  const CourseDetailsPage({super.key, required this.courseId});

  @override
  _CourseDetailsPageState createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMediaType = 'documents';
  bool _isSelectionMode = false;
  List<Map<String, dynamic>> _selectedItems = [];
  String _courseDescription = '';
  String _courseTitle = '';
  ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCourseDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  void _loadCourseDetails() async {
    DocumentSnapshot courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .get();
    if (courseSnapshot.exists) {
      var courseData = courseSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _courseTitle = courseData['title'] ?? 'Cours sans titre';
        _courseDescription =
            courseData['description'] ?? 'Aucune description disponible.';
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCourseHeader(),
          _buildMediaTypeSelector(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: SkeletonLoader());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                      child: Text('Aucun détail trouvé pour ce cours'));
                }
                var courseData = snapshot.data!.data() as Map<String, dynamic>;
                return _buildMediaListView(courseData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    final description = _courseDescription;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _courseTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _isExpandedNotifier.value = !_isExpandedNotifier.value;
            },
            child: ValueListenableBuilder<bool>(
              valueListenable: _isExpandedNotifier,
              builder: (context, isExpanded, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExpanded
                          ? description
                          : description.length > 60
                              ? description.substring(0, 60) + '...'
                              : description,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    if (description.length > 60)
                      Text(
                        isExpanded ? 'Voir moins' : 'Voir plus',
                        style: const TextStyle(color: Colors.blue),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMediaTypeButton('Documents', 'documents'),
            _buildMediaTypeButton('Vidéos', 'video'),
            _buildMediaTypeButton('Audios', 'audio'),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTypeButton(String label, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedMediaType = type;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedMediaType == type
              ? Colors.green.shade200
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: _isSelectionMode
          ? Text('${_selectedItems.length} sélectionné(s)')
          : _buildSearchField(),
      actions: _buildAppBarActions(),
      leading: _isSelectionMode ? _buildCancelSelectionButton() : null,
    );
  }

  Widget _buildSearchField() {
    return Container(
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
    );
  }

  List<Widget> _buildAppBarActions() {
    return _isSelectionMode
        ? [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.black),
              onPressed: _selectedItems.isEmpty
                  ? null
                  : () async {
                      for (var item in _selectedItems) {
                        String url = item['url'] ?? '';
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Erreur de téléchargement d\'un fichier'),
                            ),
                          );
                        }
                      }
                    },
            ),
          ]
        : [];
  }

  IconButton _buildCancelSelectionButton() {
    return IconButton(
      icon: const Icon(Icons.close, color: Colors.black),
      onPressed: () {
        setState(() {
          _isSelectionMode = false;
          _selectedItems.clear();
        });
      },
    );
  }

  Widget _buildMediaListView(Map<String, dynamic> courseData) {
    var mediaList =
        _filterMediaList(courseData[_selectedMediaType] as List<dynamic>?);
    return mediaList.isEmpty
        ? const Center(child: Text('Aucun média trouvé.'))
        : ListView.builder(
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              return _buildMediaCard(mediaList[index]);
            },
          );
  }

  List<Map<String, dynamic>> _filterMediaList(List<dynamic>? mediaData) {
    if (mediaData == null || mediaData.isEmpty) return [];

    return mediaData
        .where((media) => media is Map<String, dynamic>)
        .map((media) {
      var name = media['name'] as String? ?? 'Sans titre';
      var url = media['url'] as String? ?? '';
      var timestamp = media['timestamp'] as Timestamp?;
      return {
        'name': name,
        'url': url,
        'timestamp': timestamp,
      };
    }).where((media) {
      var mediaName = media['name'] as String;
      return _searchQuery.isEmpty ||
          mediaName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Widget _buildMediaCard(Map<String, dynamic> mediaData) {
    DateTime timestamp = (mediaData['timestamp'] != null)
        ? (mediaData['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    bool isSelected =
        _selectedItems.any((item) => item['url'] == mediaData['url']);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          if (!isSelected) {
            _selectedItems.add(mediaData);
          }
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedItems.add(mediaData);
                      } else {
                        _selectedItems.removeWhere(
                            (item) => item['url'] == mediaData['url']);
                      }
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                )
              : CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: _getMediaIcon(),
                ),
          title: Text(
            mediaData['name'] ?? 'Sans titre',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle:
              Text(formattedDate, style: const TextStyle(color: Colors.grey)),
          trailing: _isSelectionMode
              ? null
              : const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
          onTap: !_isSelectionMode
              ? () => _openMedia(mediaData['url'] ?? '')
              : null,
        ),
      ),
    );
  }

  Icon _getMediaIcon() {
    switch (_selectedMediaType) {
      case 'video':
        return const Icon(Icons.video_library, color: Colors.white);
      case 'audio':
        return const Icon(Icons.audiotrack, color: Colors.white);
      default:
        return const Icon(Icons.description, color: Colors.white);
    }
  }

  void _openMedia(String url) {
    _updateOpenedLessons(url).then((_) {
      setState(() {});

      if (_selectedMediaType == 'documents' && url.contains('.pdf')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PdfViewPage(pdfUrl: url)),
        );
      } else if (_selectedMediaType == 'video') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VideoPlayerPage(videoUrl: url)),
        );
      } else if (_selectedMediaType == 'audio') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AudioPlayerPage(audioUrl: url)),
        );
      } else {
        launch(url);
      }
    });
  }

  Future<void> _updateOpenedLessons(String url) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('userProgress')
            .doc(userId)
            .collection('courses')
            .doc(widget.courseId)
            .set({
          'openedLessons': FieldValue.arrayUnion([url]),
        }, SetOptions(merge: true));
        print('Opened Lessons Updated: $url');
      } catch (e) {
        print('Error updating opened lessons: $e');
      }
    } else {
      print('User not logged in');
    }
  }
}
