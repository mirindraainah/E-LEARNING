import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfViewPage extends StatefulWidget {
  final String pdfUrl;

  const PdfViewPage({super.key, required this.pdfUrl});

  @override
  _PdfViewPageState createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  late Future<File> _pdfFile;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pdfFile = _downloadAndSavePdf(widget.pdfUrl);
  }

  Future<File> _downloadAndSavePdf(String url) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp.pdf');
    await file.writeAsBytes(bytes);

    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voir le fichier'),
        // Supprimer le bouton d'action dans l'AppBar
      ),
      body: FutureBuilder<File>(
        future: _pdfFile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erreur lors du téléchargement du fichier'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('Aucun fichier disponible'));
          }

          final filePath = snapshot.data!.path;

          return Stack(
            children: [
              PDFView(
                filePath: filePath,
                onPageChanged: (int? currentPage, int? totalPages) {
                  setState(() {
                    _currentPage = currentPage ?? 0;
                    _totalPages = totalPages ?? 0;
                  });
                },
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Text(
                  'Page ${_currentPage + 1} / ${_totalPages}',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
