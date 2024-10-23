//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
import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenAIService {
  final String apiKey = ''; // Remplacez par votre clé API

  Future<String> generateResponse(String prompt) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo", // Utilisation du modèle GPT-3.5 Turbo
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a helpful assistant." // Facultatif : Contexte du chatbot
            },
            {"role": "user", "content": prompt}
          ],
          "max_tokens":
              150, // Limitez les tokens pour éviter des réponses trop longues
          "temperature": 0.7, // Ajuste la créativité des réponses
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('Erreur API : ${response.statusCode} ${response.body}');
        return 'Erreur : Impossible de générer une réponse';
      }
    } catch (error) {
      print('Erreur réseau : $error');
      return 'Erreur de connexion';
    }
  }
}
