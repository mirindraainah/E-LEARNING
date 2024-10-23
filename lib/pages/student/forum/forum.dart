import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ForumPage extends StatefulWidget {
  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  String? _replyingToMessageId;
  String? _replyingToMessageText;
  List<DocumentSnapshot> _messages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!_hasMore) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Query query = _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      final QuerySnapshot querySnapshot = await query.get();
      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _messages.addAll(querySnapshot.docs);
        _lastDocument = querySnapshot.docs.last;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forum de discussion'),
        backgroundColor: Colors.white10,
        foregroundColor: Color.fromARGB(216, 136, 135, 135),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent) {
                    _loadMessages();
                  }
                  return true;
                },
                child: ListView.builder(
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _hasMore
                          ? Center(child: CircularProgressIndicator())
                          : SizedBox.shrink();
                    }

                    DocumentSnapshot doc =
                        _messages[_messages.length - 1 - index];
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    bool isCurrentUser =
                        data['userId'] == _auth.currentUser?.uid;

                    return GestureDetector(
                      onLongPress: isCurrentUser
                          ? () => _showMessageOptions(doc.id, data['text'])
                          : null,
                      child: MessageBubble(
                        message: data['text'],
                        email: data['email'],
                        isCurrentUser: isCurrentUser,
                        reactions: List<String>.from(data['reactions'] ?? []),
                        replyTo: data['replyTo'],
                        onReply: () => _replyToMessage(doc.id, data['text']),
                        timestamp: (data['timestamp'] as Timestamp).toDate(),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_replyingToMessageId != null) _buildReplyingTo(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyingTo() {
    return Container(
      padding: EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Réponse à: "${_replyingToMessageText}"',
              style: TextStyle(fontStyle: FontStyle.italic),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => setState(() {
              _replyingToMessageId = null;
              _replyingToMessageText = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Écrivez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          ElevatedButton(
            child: Icon(Icons.send, color: Colors.white),
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(16),
              backgroundColor: Colors.blue.shade400, // bouton d'envoi
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final newMessage = {
        'text': _messageController.text,
        'userId': _auth.currentUser?.uid,
        'email': _auth.currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'replyTo': _replyingToMessageId,
        'reactions': [],
      };

      final docRef = await _firestore.collection('messages').add(newMessage);
      final updatedDoc = await docRef.get();

      setState(() {
        _messages.insert(0, updatedDoc);
      });

      _messageController.clear();
      setState(() {
        _replyingToMessageId = null;
        _replyingToMessageText = null;
      });
    }
  }

  void _replyToMessage(String messageId, String messageText) {
    setState(() {
      _replyingToMessageId = messageId;
      _replyingToMessageText = messageText;
    });
  }

  void _showMessageOptions(String messageId, String currentText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Options'),
          content: Text('Que voulez-vous faire ?'),
          actions: [
            TextButton(
              child: Text('Modifier'),
              onPressed: () {
                Navigator.of(context).pop();
                _editMessage(messageId, currentText);
              },
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage(messageId);
              },
            ),
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _editMessage(String messageId, String currentText) async {
    TextEditingController editController =
        TextEditingController(text: currentText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le message'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(hintText: 'Nouveau message'),
          maxLines: null,
        ),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Enregistrer'),
            onPressed: () => Navigator.of(context).pop(editController.text),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentText) {
      final docRef = _firestore.collection('messages').doc(messageId);
      await docRef.update({
        'text': result,
        'edited': true,
      });

      final updatedDoc = await docRef.get();
      setState(() {
        int index = _messages.indexWhere((doc) => doc.id == messageId);
        if (index != -1) {
          _messages[index] = updatedDoc;
        }
      });
    }
  }

  void _deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).delete();
    setState(() {
      _messages.removeWhere((doc) => doc.id == messageId);
    });
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final String email;
  final bool isCurrentUser;
  final List<String> reactions;
  final String? replyTo;
  final VoidCallback onReply;
  final DateTime timestamp;

  MessageBubble({
    required this.message,
    required this.email,
    required this.isCurrentUser,
    required this.reactions,
    this.replyTo,
    required this.onReply,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(email,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontSize: 11)),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue.shade100 : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(fontSize: 14),
                ),
                if (replyTo != null) _buildReplyTo(),
                SizedBox(height: 5),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.reply, size: 20),
                onPressed: onReply,
                color: Colors.grey[600],
              ),
              // autre
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyTo() {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('messages').doc(replyTo).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          String replyText = snapshot.data!.get('text') as String;
          return Container(
            margin: EdgeInsets.only(top: 5),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Répond à: "$replyText"',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11),
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
