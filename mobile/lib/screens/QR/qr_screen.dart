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
        SnackBar(
          content: const Text('Please enter some text or URL'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBackgroundColor = isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50;
    // final cardBackgroundColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final primaryColor = isDarkMode ? Colors.deepPurple.shade300 : Colors.deepPurple.shade600;
    // final inputBorderColor = isDarkMode ? Colors.grey[600] : Colors.deepPurple.shade200;
    final Color inputBorderColor = isDarkMode ? Colors.grey[600]! : Colors.deepPurple.shade200;
    // Change from Color? to Color by providing a default value
final Color cardBackgroundColor = isDarkMode ? Colors.grey[800]! : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
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
                prefixIcon: Icon(Icons.link, color: primaryColor),
              border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: inputBorderColor),
),
enabledBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: inputBorderColor),
),

                filled: true,
                fillColor: cardBackgroundColor,
                labelStyle: TextStyle(color: primaryColor),
                hintStyle: TextStyle(color: secondaryTextColor),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0, horizontal: 16.0),
              ),
              style: TextStyle(color: textColor),
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
                  backgroundColor: primaryColor,
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
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
               boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.1),
    blurRadius: 8,
    offset: const Offset(0, 3),
  ),
],
// border: Border.all(...)
                  border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.deepPurple.shade100),
                ),
                child: QrImageView(
                  data: qrText,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: cardBackgroundColor,
                  foregroundColor: isDarkMode ? Colors.white : Colors.deepPurple.shade800,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.deepPurple.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      'QR Code Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      qrText,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
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
                  color: secondaryTextColor,
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