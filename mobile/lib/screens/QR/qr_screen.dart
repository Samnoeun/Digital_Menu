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
      backgroundColor: Colors.deepPurple.shade50, // Added background color
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple.shade600, // Changed to deep purple
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
              ),
              const Text(
                'Generate QR Code',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Open QR Scanner',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
            },
          ),
          if (showQR)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear QR Code',
              onPressed: _clearQR,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Enter link or data',
                hintText: 'https://example.com',
                prefixIcon: const Icon(Icons.link, color: Colors.deepPurple), // Added icon color
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple.shade200), // Added border color
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Colors.deepPurple.shade600), // Label color
                hintStyle: TextStyle(color: Colors.deepPurple.shade400), // Hint color
              ),
              maxLines: 3,
              onChanged: (val) {
                if (showQR && val.trim() != qrText) {
                  setState(() => showQR = false);
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
                  backgroundColor: Colors.deepPurple.shade600, // Changed to deep purple
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (showQR) ...[
              Text(
                'Your QR Code',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade600, // Added text color
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1), // Changed shadow color
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.deepPurple.shade100), // Added border
                ),
                child: QrImageView(
                  data: qrText,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple.shade800, // Changed QR color
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade100), // Added border
                ),
                child: Column(
                  children: [
                    Text(
                      'QR Code Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade600, // Added text color
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      qrText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.deepPurple.shade600, // Added text color
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tip: You can scan this QR code with any QR scanner app or your camera.',
                style: TextStyle(
                  color: Colors.deepPurple.shade400, // Changed text color
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}