import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import '../../services/api_services.dart';
import '../../models/restaurant_model.dart';
import 'qr_scanner_screen.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  String qrText = '';
  bool showQR = false;
  bool isLoading = true;
  String? errorMessage;
  String? restaurantName;
  String customText = '';
  String _language = 'English';
  Color _qrColor = Colors.purple; // Default QR code color
  String _selectedFont = 'Poppins'; // Default font
  final TextEditingController _customTextController = TextEditingController();
  final List<String> _availableFonts = [
    'Poppins',
    'Montserrat',
    'Roboto',
    'Open Sans',
    'Lato',
    'Nunito',
    'Inter',
    'Raleway',
    'Ubuntu',
    'Source Sans Pro',
  ];

  // Localization map for English and Khmer
  final Map<String, Map<String, String>> localization = {
    'English': {
      'app_bar_title': 'Restaurant QR Code',
      'qr_data_label': 'QR Code URL:',
      'qr_info': 'Scan this QR code to view the restaurant menu.',
      'loading': 'Loading restaurant data...',
      'error_no_restaurant': 'No restaurant found. Please create a restaurant first.',
      'error_fetch_failed': 'Failed to fetch restaurant data. Please try again.',
      'scan_button': 'Open QR Scanner',
      'download_button': 'Download QR Code',
      'custom_text_label': 'Custom Brand Name',
      'custom_text_hint': 'Enter your brand name or message',
      'download_success': 'QR code saved to downloads!',
      'download_failed': 'Failed to save QR code.',
      'download_web_only': 'Download is only supported on web.',
      'color_picker_label': 'QR Code Color',
      'font_picker_label': 'Font Style',
    },
    'Khmer': {
      'app_bar_title': 'QR Code ភោជនីយដ្ឋាន',
      'qr_data_label': 'URL នៃ QR Code:',
      'qr_info': 'ស្កេន QR Code នេះដើម្បីមើលម៉ឺនុយភោជនីយដ្ឋាន។',
      'loading': 'កំពុងផ្ទុកទិន្នន័យភោជនីយដ្ឋាន...',
      'error_no_restaurant': 'រកមិនឃើញភោជនីយដ្ឋានទេ�। សូមបង្កើតភោជនីយដ្ឋានជាមុនសិន�।',
      'error_fetch_failed': 'បរាជ័យក្នុងការទៅយកទិន្នន័យភោជនីយដ្ឋាន។ សូមព្យាយាមម្តងទៀត។',
      'scan_button': 'បើកម៉ាស៊ីនស្កេន QR',
      'download_button': 'ទាញយក QR Code',
      'custom_text_label': 'ឈ្មោះម៉ាកផ្ទាល់ខ្លួន',
      'custom_text_hint': 'បញ្ចូលឈ្មោះម៉ាក ឬសាររបស់អ្នក',
      'download_success': 'QR Code ត្រូវបានរក្សាទុកទៅក្នុងផ្នែកទាញយក!',
      'download_failed': 'បរាជ័យក្នុងការរក្សាទុក QR Code�।',
      'download_web_only': 'ការទាញយកគាំទ្រតែនៅលើវេបសាយប៉ុណ្ណោះ�।',
      'color_picker_label': 'ពណ៌ QR Code',
      'font_picker_label': 'រចនាប័ទ្មអក្សរ',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _loadCustomText();
    _fetchRestaurantAndGenerateQR();
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      _language = savedLanguage;
    });
  }

  // Load saved custom text from SharedPreferences
  Future<void> _loadCustomText() async {
    final prefs = await SharedPreferences.getInstance();
    final savedText = prefs.getString('qr_custom_text') ?? '';
    setState(() {
      customText = savedText;
      _customTextController.text = savedText;
    });
  }

  // Save custom text to SharedPreferences
  Future<void> _saveCustomText(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qr_custom_text', text);
  }

  // Fetch restaurant data and generate QR code
  Future<void> _fetchRestaurantAndGenerateQR() async {
    try {
      final restaurant = await ApiService.getRestaurant();
      setState(() {
        qrText = 'http://192.168.108.131:8000/restaurants/${restaurant.id}/menu';
        restaurantName = restaurant.restaurantName;
        showQR = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().contains('No restaurant found')
            ? localization[_language]!['error_no_restaurant']
            : localization[_language]!['error_fetch_failed'];
        isLoading = false;
      });
    }
  }

  // Download QR code as image with white border and custom text
  Future<void> _downloadQRCode() async {
    try {
      if (!kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization[_language]!['download_web_only']!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Generate QR code image data
      final qrValidationResult = QrValidator.validate(
        data: qrText,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      if (!qrValidationResult.isValid) {
        throw Exception('Invalid QR code data');
      }
      final qrCode = qrValidationResult.qrCode;
      final qrPainter = QrPainter.withQr(
        qr: qrCode!,
        emptyColor: Colors.white,
        gapless: true,
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: _qrColor,
        ),
      );

      // Create a canvas to draw QR code and custom text
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const qrSize = 250.0;
      const borderSize = 20.0; // White border width
      const textMarginTop = 20.0; // Extra margin top for text
      final textHeight = customText.isNotEmpty ? 50.0 : 0.0; // Space for text
      final totalWidth = qrSize + 2 * borderSize;
      final totalHeight = qrSize + 2 * borderSize + textHeight + (customText.isNotEmpty ? textMarginTop : 0.0);

      // Draw white background for border
      canvas.drawRect(
        Rect.fromLTWH(0, 0, totalWidth, totalHeight),
        Paint()..color = Colors.white,
      );

      // Draw QR code with offset for border
      final qrImageData = await qrPainter.toImageData(qrSize);
      if (qrImageData == null) {
        throw Exception('Failed to generate QR code image');
      }
      final qrImage = await qrPainter.toImage(qrSize);
      canvas.drawImage(qrImage, Offset(borderSize, borderSize), Paint());

      // Draw custom text below QR code
      if (customText.isNotEmpty) {
        final textSpan = TextSpan(
          text: customText,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : _selectedFont,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: totalWidth);
        final textOffset = Offset(
          (totalWidth - textPainter.width) / 2, // Center horizontally
          qrSize + borderSize + textMarginTop, // Add margin top
        );
        textPainter.paint(canvas, textOffset);
      }

      // Convert canvas to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      // For web, trigger download using universal_html
      final fileName = 'qr_code_${restaurantName?.replaceAll(' ', '_') ?? 'menu'}_${DateTime.now().millisecondsSinceEpoch}.png';
      final bytes = byteData.buffer.asUint8List();
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization[_language]!['download_success']!),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization[_language]!['download_failed']!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBackgroundColor = isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final primaryColor = Colors.deepPurple.shade600;
    final cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final inputBorderColor = isDarkMode ? Colors.grey[600]! : Colors.deepPurple.shade200;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            localization[_language]!['app_bar_title']!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
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
              icon: const Icon(Icons.download),
              tooltip: localization[_language]!['download_button'],
              onPressed: _downloadQRCode,
            ).animate().scale(duration: 300.ms),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isLoading)
              Column(
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    localization[_language]!['loading']!,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms)
            else if (errorMessage != null)
              Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 16,
                      fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms)
            else if (showQR) ...[
              if (restaurantName != null)
                Text(
                  'Menu for $restaurantName',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey[700]! : Colors.deepPurple.shade100,
                      width: 1,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [Colors.grey[800]!, Colors.grey[850]!]
                            : [Colors.white, Colors.deepPurple.shade50],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20), // White border around QR code
                      color: Colors.white,
                      child: QrImageView(
                        data: qrText,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                        foregroundColor: _qrColor,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 20),
              TextField(
                controller: _customTextController,
                decoration: InputDecoration(
                  labelText: localization[_language]!['custom_text_label'],
                  hintText: localization[_language]!['custom_text_hint'],
                  labelStyle: TextStyle(color: primaryColor),
                  prefixIcon: Icon(Icons.edit, color: primaryColor),
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
                  hintStyle: TextStyle(color: secondaryTextColor),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 16.0,
                  ),
                ),
                maxLines: 1,
                onChanged: (value) {
                  setState(() {
                    customText = value;
                  });
                  _saveCustomText(value);
                },
                style: TextStyle(
                  color: textColor,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : _selectedFont,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              // Color Picker
              GestureDetector(
                onTap: () async {
                  final Color? pickedColor = await showDialog<Color>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(localization[_language]!['color_picker_label']!),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Simple color picker with predefined colors
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Colors.purple,
                                Colors.blue,
                                Colors.green,
                                Colors.red,
                                Colors.orange,
                                Colors.black,
                              ].map((color) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop(color);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _qrColor == color ? Colors.white : Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                      ],
                    ),
                  );
                  if (pickedColor != null) {
                    setState(() {
                      _qrColor = pickedColor;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.deepPurple.shade100,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localization[_language]!['color_picker_label']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                          fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _qrColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              // Font Picker
              DropdownButtonFormField<String>(
                value: _selectedFont,
                decoration: InputDecoration(
                  labelText: localization[_language]!['font_picker_label'],
                  labelStyle: TextStyle(color: primaryColor),
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 16.0,
                  ),
                ),
                items: _availableFonts.map((font) {
                  return DropdownMenuItem<String>(
                    value: font,
                    child: Text(
                      font,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : font,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFont = value;
                    });
                  }
                },
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.deepPurple.shade100,
                  ),
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
                      style: TextStyle(fontSize: 13, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Text(
                localization[_language]!['qr_info']!,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 300.ms),
            ],
          ],
        ),
      ),
    );
  }
}