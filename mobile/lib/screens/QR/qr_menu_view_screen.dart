import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/order_history_model.dart';
import '../../models/menu_item.dart';

class QRMenuViewScreen extends StatefulWidget {
  final List<MenuItem> menuItems;

  const QRMenuViewScreen({super.key, required this.menuItems});

  @override
  State<QRMenuViewScreen> createState() => _QRMenuViewScreenState();
}

class _QRMenuViewScreenState extends State<QRMenuViewScreen> {
  String _language = 'English'; // Default language, will be overridden by SharedPreferences

  // Localization map for English and Khmer
  final Map<String, Map<String, String>> localization = {
    'English': {
      'app_bar_title': 'Generate QR Code',
      'info_text': 'Selected {count} item(s) for QR code generation',
      'generate_button': 'Generate QR Code',
      'refresh_tooltip': 'Refresh QR Code',
      'dialog_title': 'Scan QR Code to View Menu',
      'dialog_subtitle': 'Menu contains {count} item(s)',
      'close_button': 'Close',
      'copy_button': 'Copy Data',
      'preview_button': 'Preview',
      'copy_snackbar': 'Menu data copied to clipboard!',
    },
    'Khmer': {
      'app_bar_title': 'បង្កើត QR Code',
      'info_text': 'បានជ្រើសរើស {count} មុខទំនិញសម្រាប់បង្កើត QR Code',
      'generate_button': 'បង្កើត QR Code',
      'refresh_tooltip': 'ធ្វើឱ្យ QR Code ស្រស់',
      'dialog_title': 'ស្កេន QR Code ដើម្បីមើលម៉ឺនុយ',
      'dialog_subtitle': 'ម៉ឺនុយមាន {count} មុខទំនិញ',
      'close_button': 'បិទ',
      'copy_button': 'ចម្លងទិន្នន័យ',
      'preview_button': 'មើលជាមុន',
      'copy_snackbar': 'ទិន្នន័យម៉ឺនុយត្រូវបានចម្លងទៅក្តារតម្បៀតខ្ទប់!',
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

  String _generateMenuJson() {
    // Create a JSON structure for the menu
    final menuData = {
      'restaurant': localization[_language]!['app_bar_title']!.replaceAll(' QR Code', ''),
      'timestamp': DateTime.now().toIso8601String(),
      'menu_items': widget.menuItems
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'description': item.description,
              'category': item.category,
              'image_url': item.imageUrl,
            },
          )
          .toList(),
    };

    return jsonEncode(menuData);
  }

  void _generateQRCode(BuildContext context) {
    final menuJson = _generateMenuJson();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localization[_language]!['dialog_title']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Real QR Code generation
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: menuJson,
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localization[_language]!['dialog_subtitle']!.replaceAll('{count}', widget.menuItems.length.toString()),
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        localization[_language]!['close_button']!,
                        style: TextStyle(
                          fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: menuJson));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(localization[_language]!['copy_snackbar']!),
                          ),
                        );
                      },
                      child: Text(
                        localization[_language]!['copy_button']!,
                        style: TextStyle(
                          fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PublicMenuViewScreen(menuItems: widget.menuItems),
                          ),
                        );
                      },
                      child: Text(
                        localization[_language]!['preview_button']!,
                        style: TextStyle(
                          fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.deepPurple.shade700;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.deepPurple.shade50;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Color(0xFF6A1B9A),
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              localization[_language]!['app_bar_title']!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6A1B9A),
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6A1B9A)),
            onPressed: () => _generateQRCode(context),
            tooltip: localization[_language]!['refresh_tooltip']!,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: textColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localization[_language]!['info_text']!.replaceAll('{count}', widget.menuItems.length.toString()),
                    style: TextStyle(
                      color: textColor,
                      fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.menuItems.length,
              itemBuilder: (context, index) {
                final item = widget.menuItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.fastfood),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                    subtitle: Text(
                      item.category,
                      style: TextStyle(
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                    trailing: Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: Text(
                  localization[_language]!['generate_button']!,
                  style: TextStyle(
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
                onPressed: () => _generateQRCode(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PublicMenuViewScreen extends StatefulWidget {
  final List<MenuItem> menuItems;

  const PublicMenuViewScreen({super.key, required this.menuItems});

  @override
  State<PublicMenuViewScreen> createState() => _PublicMenuViewScreenState();
}

class _PublicMenuViewScreenState extends State<PublicMenuViewScreen> {
  String _language = 'English'; // Default language, will be overridden by SharedPreferences

  // Localization map for English and Khmer
  final Map<String, Map<String, String>> localization = {
    'English': {
      'app_bar_title': 'Digital Menu',
      'welcome_text': 'Welcome to Our Restaurant',
      'subtitle': 'Scan & Order Menu',
    },
    'Khmer': {
      'app_bar_title': 'ម៉ឺនុយឌីជីថល',
      'welcome_text': 'សូមស្វាគមន៍មកកាន់ភោជនីយដ្ឋានរបស់យើង',
      'subtitle': 'ស្កេន និងកម្ម៉ង់ម៉ឺនុយ',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localization[_language]!['app_bar_title']!,
          style: TextStyle(
            fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.restaurant_menu, size: 50, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  localization[_language]!['welcome_text']!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
                Text(
                  localization[_language]!['subtitle']!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.menuItems.length,
              itemBuilder: (context, index) {
                final item = widget.menuItems[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.fastfood),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.category,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}