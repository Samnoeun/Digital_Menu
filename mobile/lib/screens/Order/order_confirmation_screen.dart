import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Preview/menu_preview_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final int tableNumber;
  final List<Map<String, dynamic>> orderItems;
  final VoidCallback onClearCart;

  const OrderConfirmationScreen({
    super.key,
    required this.tableNumber,
    required this.orderItems,
    required this.onClearCart,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  String selectedLanguage = 'English';
  
  final Map<String, Map<String, String>> localization = {
    'English': {
      'order_confirmation': 'Order Confirmation',
      'order_submitted': 'Order Submitted Successfully!',
      'table_number': 'Your Table Number is',
      'remember_number': 'Please remember this number',
      'order_summary': 'Order Summary',
      'total': 'Total:',
      'back_to_menu': 'Back to Menu',
      'unknown_item': 'Unknown Item',
    },
    'Khmer': {
      'order_confirmation': 'ការបញ្ជាក់ការកម្មង',
      'order_submitted': 'ការកម្មងត្រូវបានដាក់ស្នើដោយជោគជ័យ!',
      'table_number': 'លេខតុរបស់អ្នកគឺ',
      'remember_number': 'សូមចងចាំលេខនេះ',
      'order_summary': 'សេចក្តីសង្ខេបការកម្មង',
      'total': 'សរុប៖',
      'back_to_menu': 'ត្រឡប់ទៅម៉ឺនុយ',
      'unknown_item': 'ធាតុមិនស្គាល់',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }

  TextStyle getTextStyle({bool isBold = false, bool isSecondary = false, double? fontSize}) {
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: fontSize ?? (isSecondary ? 16 : 18),
      color: isSecondary 
          ? Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)
          : Theme.of(context).textTheme.bodyLarge!.color,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final lang = localization[selectedLanguage]!;

    final total = widget.orderItems.fold(0.0, (sum, item) {
      return sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1));
    });

    // Color definitions
    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final successColor = isDarkMode ? Colors.green[300] : Colors.green;
    final infoCardColor = isDarkMode ? Colors.blue[900] : Colors.blue.shade50;
    final Color infoBorderColor = isDarkMode ? Colors.blue[800]! : Colors.blue.shade100;
    final infoTextColor = isDarkMode ? Colors.blue[100] : Colors.blue.shade800;
    final Color primaryColor = isDarkMode ? Colors.deepPurple[300]! : Colors.deepPurple;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, isDarkMode ? Colors.deepPurple.shade500 : Colors.deepPurple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 30),
            Text(
              lang['order_confirmation']!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Success icon and message
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: successColor,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              lang['order_submitted']!,
                              style: TextStyle(
                                fontSize: 22,
                                color: successColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table number highlight
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: infoCardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: infoBorderColor, width: 2),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                lang['table_number']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: infoTextColor,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.tableNumber}',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.blue[100] : Colors.blue.shade900,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lang['remember_number']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: infoTextColor,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Order details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang['order_summary']!,
                                  style: getTextStyle(isBold: true),
                                ),
                                Text(
                                  DateFormat('hh:mm a').format(DateTime.now()),
                                  style: getTextStyle(isSecondary: true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...widget.orderItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      '${item['quantity']}x',
                                      style: getTextStyle(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item['name'] ?? lang['unknown_item']!,
                                        style: getTextStyle(),
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
                                      style: getTextStyle(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang['total']!,
                                  style: getTextStyle(isBold: true, fontSize: 18),
                                ),
                                Text(
                                  currencyFormat.format(total),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: successColor,
                                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Back to menu button
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      widget.onClearCart();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MenuPreviewScreen(),
                        ),
                      );
                    },
                    child: Text(
                      lang['back_to_menu']!,
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.white,
                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
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