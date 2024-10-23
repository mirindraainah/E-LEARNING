import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewPage extends StatelessWidget {
  final String url;

  const DocumentViewPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Erreur lors de l\'ouverture du document.')),
              );
            }
          },
          child: Text('Ouvrir le Document'),
        ),
      ),
    );
  }
}
