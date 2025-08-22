import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import 'Order/order_confirmation_screen.dart';

class TableNumberScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final Function() onClearCart;

  const TableNumberScreen({
    Key? key,
    required this.orderItems,
    required this.onClearCart,
  }) : super(key: key);

  @override
  State<TableNumberScreen> createState() => _TableNumberScreenState();
}

class _TableNumberScreenState extends State<TableNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'table_number_title': 'Table Number',
      'enter_table_number': 'Please enter your table number:',
      'label_table_number': 'Table Number',
      'submit_order': 'Submit Order',
      'enter_table_number_error': 'Please enter a table number',
      'valid_number_error': 'Please enter a valid number',
      'table_occupied_error': 'This table is already occupied. '
                             'Please choose another table or ask staff for assistance.',
      'general_error': 'Error: {error}',
    },
    'Khmer': {
      'table_number_title': 'លេខតុ',
      'enter_table_number': 'សូមបញ្ចូលលេខតុរបស់អ្នក៖',
      'label_table_number': 'លេខតុ',
      'submit_order': 'ដាក់បញ្ជាទិញ',
      'enter_table_number_error': 'សូមបញ្ចូលលេខតុ',
      'valid_number_error': 'សូមបញ្ចូលលេខដែលត្រឹមត្រូវ',
      'table_occupied_error': 'តុនេះត្រូវបានកាន់កាប់រួចហើយ។ '
                            'សូមជ្រើសរើសតុផ្សេងទៀត ឬសុំជំនួយពីបុគ្គលិក។',
      'general_error': 'កំហុស៖ {error}',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final tableNumber = int.parse(_tableNumberController.text);

      await ApiService.submitOrder(
        tableNumber: tableNumber,
        items: widget.orderItems,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(
              tableNumber: tableNumber,
              orderItems: widget.orderItems,
              onClearCart: widget.onClearCart,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          if (e.toString().contains('Duplicate entry') && 
              e.toString().contains('orders_restaurant_id_table_number_unique')) {
            _errorMessage = localization[selectedLanguage]!['table_occupied_error']!;
          } else {
            _errorMessage = localization[selectedLanguage]!['general_error']!.replaceFirst('{error}', e.toString().replaceAll('Exception: ', ''));
          }
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final inputBackground = isDarkMode ? Colors.grey[800] : Colors.white;
    final borderColor = isDarkMode ? Colors.deepPurple.shade300 : Colors.deepPurple;
    final lang = localization[selectedLanguage]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              lang['table_number_title']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: null, // No font family change here for consistency with original
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang['enter_table_number']!,
                style: TextStyle(
                  fontSize: 18,
                  color: textColor,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tableNumberController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: textColor,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                decoration: InputDecoration(
                  labelText: lang['label_table_number']!,
                  labelStyle: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                  filled: true,
                  fillColor: inputBackground,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                  errorText: _errorMessage,
                  errorStyle: const TextStyle(color: Colors.red),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang['enter_table_number_error']!;
                  }
                  if (int.tryParse(value) == null) {
                    return lang['valid_number_error']!;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          lang['submit_order']!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}