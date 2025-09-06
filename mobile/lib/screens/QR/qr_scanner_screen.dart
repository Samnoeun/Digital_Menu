import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _brandNameController = TextEditingController();
  String _language = 'English'; // Default language
  String qrText = ''; // QR code data for generation
  bool showQR = false; // Whether to show generated QR code
  String customBrandName = ''; // Custom brand name
  Color _qrColor = Colors.purple; // Default QR code color
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Localization map for English and Khmer
  final Map<String, Map<String, String>> localization = {
    'English': {
      'app_bar_title': 'QR Code Generator',
      'url_label': 'Enter URL for QR Code:',
      'url_hint': 'Enter a URL (e.g., https://example.com)',
      'brand_name_label': 'Custom Brand Name:',
      'brand_name_hint': 'Enter your brand name or message',
      'generate_button': 'Generate QR Code',
      'how_to_test': 'How to generate a QR code:',
      'test_instructions': '1. Enter a URL in the text field below.\n'
          '2. Optionally, enter a brand name to display below the QR code.\n'
          '3. Select a color for the QR code.\n'
          '4. Click "Generate QR Code" to create and display it.\n'
          '5. Use the download button in the top bar to save the QR code as an image.',
      'empty_input_error': 'Please enter a URL',
      'download_button': 'Download QR Code',
      'download_success': 'QR code saved to downloads!',
      'download_failed': 'Failed to save QR code.',
      'download_web_only': 'Download is only supported on web.',
      'color_picker_label': 'QR Code Color',
    },
    'Khmer': {
      'app_bar_title': 'បង្កើត QR Code',
      'url_label': 'បញ្ចូល URL សម្រាប់ QR Code:',
      'url_hint': 'បញ្ចូល URL (ឧ. https://example.com)',
      'brand_name_label': 'ឈ្មោះម៉ាកផ្ទាល់ខ្លួន:',
      'brand_name_hint': 'បញ្ចូលឈ្មោះម៉ាក ឬសាររបស់អ្នក',
      'generate_button': 'បង្កើត QR Code',
      'how_to_test': 'វិធីបង្កើត QR Code:',
      'test_instructions': '1. បញ្ចូល URL នៅក្នុងប្រអប់អត្ថបទខាងក្រោម។\n'
          '2. ស្រេចចិត្ត បញ្ចូលឈ្មោះម៉ាកដើម្បីបង្ហាញនៅខាងក្រោម QR Code។\n'
          '3. ជ្រើសរើសពណ៌សម្រាប់ QR Code។\n'
          '4. ចុច "បង្កើត QR Code" ដើម្បីបង្កើតនិងបង្ហាញវា។\n'
          '5. ប្រើប៊ូតុងទាញយកនៅរបារខាងលើដើម្បីរក្សាទុក QR Code ជារូបភាព។',
      'empty_input_error': 'សូមបញ្ចូល URL',
      'download_button': 'ទាញយក QR Code',
      'download_success': 'QR Code ត្រូវបានរក្សាទុកទៅក្នុងផ្នែកទាញយក!',
      'download_failed': 'បរាជ័យក្នុងការរក្សាទុក QR Code។',
      'download_web_only': 'ការទាញយកគាំទ្រតែនៅលើវេបសាយប៉ុណ្ណោះ។',
      'color_picker_label': 'ពណ៌ QR Code',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _loadCustomBrandName();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      _language = savedLanguage;
    });
  }

  // Load saved brand name from SharedPreferences
  Future<void> _loadCustomBrandName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBrandName = prefs.getString('qr_brand_name') ?? '';
    setState(() {
      customBrandName = savedBrandName;
      _brandNameController.text = savedBrandName;
    });
  }

  // Save brand name to SharedPreferences
  Future<void> _saveCustomBrandName(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qr_brand_name', text);
  }

  // Generate QR code from URL
  void _generateQRCode() {
    final String url = _urlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization[_language]!['empty_input_error']!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      qrText = url;
      showQR = true;
      _animationController.forward(from: 0.0);
    });
  }

  // Download QR code as image with white border and brand name
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

      // Create a canvas to draw QR code and brand name
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const qrSize = 250.0;
      const borderSize = 20.0; // White border width
      const textMarginTop = 20.0; // Extra margin top for text
      final textHeight = customBrandName.isNotEmpty ? 50.0 : 0.0; // Space for text
      final totalWidth = qrSize + 2 * borderSize;
      final totalHeight = qrSize + 2 * borderSize + textHeight + (customBrandName.isNotEmpty ? textMarginTop : 0.0);

      // Draw white background for border
      canvas.drawRect(
        Rect.fromLTWH(0, 0, totalWidth, totalHeight),
        Paint()..color = Colors.white,
      );

      // Draw QR code with offset for border
      final qrImage = await qrPainter.toImage(qrSize);
      canvas.drawImage(qrImage, Offset(borderSize, borderSize), Paint());

      // Draw brand name below QR code
      if (customBrandName.isNotEmpty) {
        final textSpan = TextSpan(
          text: customBrandName,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
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

      // For web, trigger download
      final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
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
    _urlController.dispose();
    _brandNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.grey[100]!;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800]!;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final primaryColor = Colors.deepPurple; // Updated to deepPurple
    final hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey[500]!;
    final inputFillColor = isDarkMode ? Colors.grey[800]! : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor, // Uses deepPurple
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
        actions: [
          if (showQR)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: localization[_language]!['download_button'],
              onPressed: _downloadQRCode,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL input for QR code generation
            Text(
              localization[_language]!['url_label']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                hintText: localization[_language]!['url_hint']!,
                prefixIcon: Icon(Icons.link, color: primaryColor),
                filled: true,
                fillColor: inputFillColor,
                hintStyle: TextStyle(
                  color: hintColor,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
              ),
              style: TextStyle(
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 20),
            // Brand name input
            Text(
              localization[_language]!['brand_name_label']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _brandNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                hintText: localization[_language]!['brand_name_hint']!,
                prefixIcon: Icon(Icons.edit, color: primaryColor),
                filled: true,
                fillColor: inputFillColor,
                hintStyle: TextStyle(
                  color: hintColor,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
              ),
              style: TextStyle(
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
              maxLines: 1,
              onChanged: (value) {
                setState(() {
                  customBrandName = value;
                });
                _saveCustomBrandName(value);
              },
            ),
            const SizedBox(height: 20),
            // Color picker
            GestureDetector(
              onTap: () async {
                final Color? pickedColor = await showDialog<Color>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      localization[_language]!['color_picker_label']!,
                      style: TextStyle(
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _qrColor == color ? Colors.white : Colors.grey,
                                  width: _qrColor == color ? 3 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                );
                if (pickedColor != null) {
                  setState(() {
                    _qrColor = pickedColor;
                    if (showQR) _animationController.forward(from: 0.0);
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localization[_language]!['color_picker_label']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _qrColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: Text(
                  localization[_language]!['generate_button']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
                onPressed: _generateQRCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // Uses deepPurple
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Generated QR code
            if (showQR)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: QrImageView(
                              data: qrText,
                              version: QrVersions.auto,
                              size: 250.0,
                              backgroundColor: Colors.white,
                              foregroundColor: _qrColor,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                          ),
                          if (customBrandName.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              customBrandName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (showQR) ...[
              const SizedBox(height: 20),
              Text(
                qrText,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            // Test instructions
            Text(
              localization[_language]!['how_to_test']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localization[_language]!['test_instructions']!,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}