import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './openai_service.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final OpenAIService openAIService = OpenAIService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  void _sendMessage() async {
    final text = _controller.text;
    if (text.isNotEmpty) {
      setState(() {
        messages.add({'sender': 'user', 'text': text});
      });
      _controller.clear();

      try {
        // Attendre la réponse du service OpenAI
        final response = await openAIService.generateResponse(text);

        setState(() {
          messages.add({'sender': 'bot', 'text': response.trim()});
        });
      } catch (error) {
        // Gestion des erreurs (affichez l'erreur dans l'interface utilisateur ou dans la console)
        print('Erreur lors de l\'envoi du message : $error');
        setState(() {
          messages.add(
              {'sender': 'bot', 'text': 'Désolé, une erreur est survenue.'});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chatbot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Column(
                    crossAxisAlignment: message['sender'] == 'user'
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: message['sender'] == 'user'
                              ? Colors.blue[200]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(message['text'] ?? ''),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
