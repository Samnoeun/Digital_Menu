import 'package:flutter/material.dart';
import 'dart:convert';
import 'qr_menu_view_screen.dart';
import '../../models/menu_item.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final TextEditingController _qrDataController = TextEditingController();

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
          content: const Text('Please paste QR code data'),
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
            'QR Code Content',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scanned Data:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black),
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
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(height: 16),
              if (data.startsWith('http'))
                Text(
                  'This appears to be a URL. You can open it in a browser.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple.shade600),
              ),
            ),
            if (data.startsWith('http'))
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Would open URL in browser'),
                      backgroundColor: isDarkMode ? Colors.grey[800] : null,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple.shade600,
                ),
                child: Text(
                  'Open URL',
                  style: TextStyle(
                    color: isDarkMode ? Colors.black : Colors.white),
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
    final primaryColor = isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple.shade600;
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
              const Text(
                'QR Scanner Demo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
                      'In a real app, this would use the camera to scan QR codes. For demo purposes, paste the QR data below.',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Paste QR Code Data:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
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
                hintText: 'Paste QR code data here...',
                prefixIcon: Icon(Icons.qr_code_scanner, color: primaryColor),
                filled: true,
                fillColor: inputFillColor,
                hintStyle: TextStyle(color: hintColor),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0, horizontal: 16.0),
              ),
              style: TextStyle(color: textColor),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Process QR Data'),
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
              'How to test:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Go to Menu page\n'
              '2. Select some menu items\n'
              '3. Generate QR code\n'
              '4. Copy the data\n'
              '5. Come back here and paste it\n'
              '6. Click "Process QR Data"',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600),
            ),
          ],
        ),
      ),
    );
  }
}