import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/item_model.dart';
import '../../services/api_services.dart';

class ItemDetailBottomSheet extends StatefulWidget {
  final Item item;

  const ItemDetailBottomSheet({super.key, required this.item});

  @override
  State<ItemDetailBottomSheet> createState() => _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends State<ItemDetailBottomSheet> {
  String _language = 'English'; // Default language, will be overridden by SharedPreferences

  // Localization map for English and Khmer
  final Map<String, Map<String, String>> localization = {
    'English': {
      'description_label': 'Description',
      'no_description': 'No description available.',
    },
    'Khmer': {
      'description_label': 'ការពិពណ៌នា',
      'no_description': 'គ្មានការពិពណ៌នាទេ។',
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
    final currencyFormat = NumberFormat.currency(locale: _language == 'Khmer' ? 'km_KH' : 'en', symbol: _language == 'Khmer' ? '៛' : '\$');
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Image with better loading and aspect ratio
          if (widget.item.imagePath != null && widget.item.imagePath!.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  ApiService.getImageUrl(widget.item.imagePath),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            Center(
              child: Icon(
                Icons.image_not_supported,
                size: 100,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),

          const SizedBox(height: 20),

          // Name, Category and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.item.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade700.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item.category!.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.deepPurple.shade700,
                            fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(widget.item.price),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            localization[_language]!['description_label']!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
              fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                widget.item.description ?? localization[_language]!['no_description']!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}