import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _language = 'English'; // Default language, will be overridden by SharedPreferences

  // Localization map for English and Khmer
  final Map<String, Map<String, String>> localization = {
    'English': {
      'app_bar_title': 'Create QR Code',
      'input_label': 'Enter link or data',
      'input_hint': 'https://example.com',
      'generate_button': 'Generate QR Code',
      'clear_button': 'Clear QR Code',
      'scan_button': 'Open QR Scanner',
      'empty_input_error': 'Please enter text or link',
      'qr_label': 'Your QR Code',
      'qr_data_label': 'Data in QR Code:',
      'qr_info': 'Additional Info: You can scan this QR code using a QR scanner app or your camera.',
    },
    'Khmer': {
      'app_bar_title': 'បង្កើត QR Code',
      'input_label': 'បញ្ចូលតំណភ្ជាប់ ឬទិន្នន័យ',
      'input_hint': 'https://example.com',
      'generate_button': 'បង្កើត QR Code',
      'clear_button': 'លុប QR Code',
      'scan_button': 'បើកម៉ាស៊ីនស្កេន QR',
      'empty_input_error': 'សូមបញ្ចូលអត្ថបទ ឬតំណភ្ជាប់',
      'qr_label': 'QR Code របស់អ្នក',
      'qr_data_label': 'ទិន្នន័យក្នុង QR Code:',
      'qr_info': 'ព័ត៌មានបន្ថែម៖ អ្នកអាចស្កេន QR Code នេះ ដោយប្រើកម្មវិធីស្កេន QR ឬកាមេរ៉ារបស់អ្នក។',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage(); // Load saved language on initialization
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      _language = savedLanguage;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization[_language]!['empty_input_error']!),
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
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final primaryColor = isDarkMode ? Colors.deepPurple.shade300 : Colors.deepPurple.shade600;
    final Color inputBorderColor = isDarkMode ? Colors.grey[600]! : Colors.deepPurple.shade200;
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
              Text(
                localization[_language]!['app_bar_title']!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: localization[_language]!['scan_button'],
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
              tooltip: localization[_language]!['clear_button'],
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
                labelText: localization[_language]!['input_label'],
                hintText: localization[_language]!['input_hint'],
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
                labelStyle: TextStyle(
                  color: primaryColor,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                hintStyle: TextStyle(
                  color: secondaryTextColor,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 16.0),
              ),
              style: TextStyle(
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
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
                label: Text(
                  localization[_language]!['generate_button']!,
                  style: TextStyle(
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
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
                localization[_language]!['qr_label']!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
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
                      localization[_language]!['qr_data_label']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      qrText,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localization[_language]!['qr_info']!,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
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