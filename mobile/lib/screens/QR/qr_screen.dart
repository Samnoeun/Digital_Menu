import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_scanner_screen.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final TextEditingController _textController = TextEditingController();
  String qrText = '';
  bool showQR = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text or URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      qrText = _textController.text.trim();
      showQR = true;
    });
  }

  void _clearQR() {
    setState(() {
      qrText = '';
      showQR = false;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable default back button
        backgroundColor: const Color(0xFFF3E5F5), // Light purple background
        elevation: 0,
        titleSpacing: 0, // Remove default spacing
        title: Padding(
          padding: const EdgeInsets.only(left: 10, right: 2),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Color(0xFF6A1B9A),
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 0),
              const Text(
                'Generate QR',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF6A1B9A), // Apply purple to all icons if needed
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
            },
            tooltip: 'QR Scanner Demo',
          ),
          if (showQR)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearQR,
              tooltip: 'Clear QR Code',
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter link or data',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                hintText: 'https://example.com or any text',
              ),
              maxLines: 3,
              onChanged: (val) {
                if (showQR && val.trim() != qrText) {
                  setState(() {
                    showQR = false;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text('Generate QR Code'),
                onPressed: _generateQR,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (showQR) ...[
              const Text(
                'Your QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrText,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  // Add logo in the center (optional)
                  embeddedImage:
                      null, // You can add AssetImage('assets/logo.png') here
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(40, 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'QR Code Data:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      qrText,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan this QR code with any QR scanner app',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
