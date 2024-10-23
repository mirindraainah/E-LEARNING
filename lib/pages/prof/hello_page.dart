import 'package:flutter/material.dart';

class HelloPage extends StatelessWidget {
  const HelloPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello Page', style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Hello',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
