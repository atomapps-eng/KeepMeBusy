import 'package:flutter/material.dart';

class ReceiptViewerPage extends StatelessWidget {

  final String imageUrl;

  const ReceiptViewerPage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}