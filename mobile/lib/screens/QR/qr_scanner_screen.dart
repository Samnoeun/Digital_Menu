import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_menu_view_screen.dart';
import '../../models/menu_item.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final TextEditingController _qrDataController = TextEditingController();
  String _language = 'English'; // Default language, will be overridden by SharedPreferences

  // Localization map for English and Khmer
  final Map<String, Map<String, String>> localization = {
    'English': {
      'app_bar_title': 'QR Scanner Demo',
      'info_text': 'In a real app, this would use the camera to scan QR codes. For demo purposes, paste the QR data below.',
      'paste_label': 'Paste QR Code Data:',
      'hint_text': 'Paste QR code data here...',
      'process_button': 'Process QR Data',
      'how_to_test': 'How to test:',
      'test_instructions': '1. Go to Menu page\n'
          '2. Select some menu items\n'
          '3. Generate QR code\n'
          '4. Copy the data\n'
          '5. Come back here and paste it\n'
          '6. Click "Process QR Data"',
      'empty_input_error': 'Please paste QR code data',
      'dialog_title': 'QR Code Content',
      'scanned_data_label': 'Scanned Data:',
      'url_message': 'This appears to be a URL. You can open it in a browser.',
      'close_button': 'Close',
      'open_url_button': 'Open URL',
      'url_snackbar': 'Would open URL in browser',
    },
    'Khmer': {
      'app_bar_title': 'ស្កេន QR Code',
      'info_text': 'នៅក្នុងកម្មវិធីពិតប្រាកដ វានឹងប្រើកាមេរ៉ាដើម្បីស្កេន QR Code។ សម្រាប់គោលបំណងសាកល្បង សូមបិទភ្ជាប់ទិន្នន័យ QR ខាងក្រោម។',
      'paste_label': 'បិទភ្ជាប់ទិន្នន័យ QR Code:',
      'hint_text': 'បិទភ្ជាប់ទិន្នន័យ QR Code នៅទីនេះ...',
      'process_button': 'ដំណើរការទិន្នន័យ QR',
      'how_to_test': 'វិធីសាកល្បង:',
      'test_instructions': '1. ចូលទៅកាន់ទំព័រម៉ឺនុយ\n'
          '2. ជ្រើសរើសមុខម្ហូបមួយចំនួន\n'
          '3. បង្កើត QR Code\n'
          '4. ចម្លងទិន្នន័យ\n'
          '5. ត្រលប់មកទីនេះ ហើយបិទភ្ជាប់វា\n'
          '6. ចុច "ដំណើរការទិន្នន័យ QR"',
      'empty_input_error': 'សូមបិទភ្ជាប់ទិន្នន័យ QR Code',
      'dialog_title': 'ខ្លឹមសារនៃ QR Code',
      'scanned_data_label': 'ទិន្នន័យស្កេន:',
      'url_message': 'នេះហាក់ដូចជា URL។ អ្នកអាចបើកវានៅក្នុងកម្មវិធីរុករក។',
      'close_button': 'បិទ',
      'open_url_button': 'បើក URL',
      'url_snackbar': 'នឹងបើក URL នៅក្នុងកម្មវិធីរុករក',
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
    _qrDataController.dispose();
    super.dispose();
  }

  void _processQRData() {
    final String qrData = _qrDataController.text.trim();

    if (qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization[_language]!['empty_input_error']!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final dynamic jsonData = jsonDecode(qrData);

      if (jsonData is Map && jsonData['menu_items'] != null) {
        final List<MenuItem> menuItems = (jsonData['menu_items'] as List)
            .map(
              (item) => MenuItem(
                id: item['id'],
                name: item['name'],
                price: item['price'].toDouble(),
                description: item['description'],
                category: item['category'],
                imageUrl: item['image_url'],
              ),
            )
            .toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicMenuViewScreen(menuItems: menuItems),
          ),
        );
      } else {
        _showRegularQRData(qrData);
      }
    } catch (e) {
      _showRegularQRData(qrData);
    }
  }

  void _showRegularQRData(String data) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.deepPurple.shade50;
    final textColor = isDarkMode ? Colors.white : Colors.deepPurple.shade800;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.deepPurple.shade100;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            localization[_language]!['dialog_title']!,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization[_language]!['scanned_data_label']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  data,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (data.startsWith('http'))
                Text(
                  localization[_language]!['url_message']!,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localization[_language]!['close_button']!,
                style: TextStyle(
                  color: isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple.shade600,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
            if (data.startsWith('http'))
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localization[_language]!['url_snackbar']!),
                      backgroundColor: isDarkMode ? Colors.grey[800] : null,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple.shade600,
                ),
                child: Text(
                  localization[_language]!['open_url_button']!,
                  style: TextStyle(
                    color: isDarkMode ? Colors.black : Colors.white,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.deepPurple.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.deepPurple.shade800;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.deepPurple.shade200;
    final primaryColor = isDarkMode ? Colors.deepPurple[600] : Colors.deepPurple.shade600;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade400;
    final inputFillColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
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
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: textColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localization[_language]!['info_text']!,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localization[_language]!['paste_label']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qrDataController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                hintText: localization[_language]!['hint_text']!,
                prefixIcon: Icon(Icons.qr_code_scanner, color: primaryColor),
                filled: true,
                fillColor: inputFillColor,
                hintStyle: TextStyle(
                  color: hintColor,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0, horizontal: 16.0),
              ),
              style: TextStyle(
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: Text(
                  localization[_language]!['process_button']!,
                  style: TextStyle(
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
                onPressed: _processQRData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localization[_language]!['how_to_test']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localization[_language]!['test_instructions']!,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}