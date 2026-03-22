// lib/service_report/pages/signature_page.dart
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';

class SignaturePage extends StatefulWidget {
  final Function(Uint8List) onSave; // Kirim bytes langsung
  
  const SignaturePage({super.key, required this.onSave});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Signature"),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _controller.undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _controller.redo,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _controller.clear,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveSignature,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Signature(
              controller: _controller,
              height: 400,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Tanda tangani dengan stylus atau jari Anda",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please draw a signature first")),
      );
      return;
    }

    try {
      // Export signature sebagai PNG bytes
      final signatureData = await _controller.toPngBytes();
      
      if (signatureData == null) return;

      // Kirim bytes langsung ke halaman sebelumnya
      widget.onSave(signatureData);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}