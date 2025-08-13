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
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Text(
                  data,
                  style: TextStyle(color: Colors.deepPurple.shade800),
                ),
              ),
              const SizedBox(height: 16),
              if (data.startsWith('http'))
                Text(
                  'This appears to be a URL. You can open it in a browser.',
                  style: TextStyle(color: Colors.deepPurple.shade600),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.deepPurple.shade600),
              ),
            ),
            if (data.startsWith('http'))
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Would open URL in browser')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade600,
                ),
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
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple.shade600,
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
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.deepPurple.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'In a real app, this would use the camera to scan QR codes. For demo purposes, paste the QR data below.',
                      style: TextStyle(color: Colors.deepPurple.shade800),
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
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qrDataController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple.shade200),
                ),
                hintText: 'Paste QR code data here...',
                prefixIcon: Icon(Icons.qr_code_scanner, 
                    color: Colors.deepPurple.shade600),
                filled: true,
                fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.deepPurple.shade400),
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
                  backgroundColor: Colors.deepPurple.shade600,
                  foregroundColor: Colors.white,
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
                color: Colors.deepPurple.shade800,
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
              style: TextStyle(color: Colors.deepPurple.shade600),
            ),
          ],
        ),
      ),
    );
  }
}