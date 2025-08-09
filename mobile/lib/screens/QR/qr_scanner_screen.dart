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
        const SnackBar(
          content: Text('Please paste QR code data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final dynamic jsonData = jsonDecode(qrData);

      // Ensure jsonData is a Map before accessing keys
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
      // If parsing fails, treat as regular text
      _showRegularQRData(qrData);
    }
  }

  void _showRegularQRData(String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code Content'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scanned Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(data),
              ),
              const SizedBox(height: 16),
              if (data.startsWith('http'))
                const Text(
                  'This appears to be a URL. You can open it in a browser.',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (data.startsWith('http'))
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Would open URL in browser')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Open URL'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF6A1B9A), // Purple color
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
                color: const Color(0xFFE1BEE7), // Light purple background
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Color(0xFF6A1B9A)), // Dark purple icon
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'In a real app, this would use the camera to scan QR codes. For demo purposes, paste the QR data below.',
                      style: TextStyle(color: Color(0xFF6A1B9A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paste QR Code Data:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qrDataController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Paste QR code data here...',
                prefixIcon:
                    const Icon(Icons.qr_code_scanner, color: Color(0xFF6A1B9A)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
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
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How to test:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Go to Menu page\n'
              '2. Select some menu items\n'
              '3. Generate QR code\n'
              '4. Copy the data\n'
              '5. Come back here and paste it\n'
              '6. Click "Process QR Data"',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
