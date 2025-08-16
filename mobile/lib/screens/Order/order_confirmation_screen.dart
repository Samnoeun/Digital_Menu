import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Preview/menu_preview_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final total = orderItems.fold(0.0, (sum, item) {
      return sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1));
    });

    // Color definitions

    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final successColor = isDarkMode ? Colors.green[600] : Colors.green;
    final infoCardColor = isDarkMode ? Colors.blue[900] : Colors.blue.shade50;
    final Color infoBorderColor = isDarkMode
        ? Colors.blue[800]!
        : Colors.blue.shade100;
    final infoTextColor = isDarkMode ? Colors.blue[100] : Colors.blue.shade800;
    final Color primaryColor = isDarkMode
        ? Colors.deepPurple[600]!
        : Colors.deepPurple;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                isDarkMode
                    ? Colors.deepPurple.shade500
                    : Colors.deepPurple.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            SizedBox(width: 30),
            Text(
              'Order Confirmation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
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
                              'Order Submitted Successfully!',
                              style: TextStyle(
                                fontSize: 22,
                                color: successColor,
                                fontWeight: FontWeight.bold,
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
                                'Your Table Number is',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: infoTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$tableNumber',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.blue[100]
                                      : Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please remember this number',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: infoTextColor,
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
                                  'Order Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  DateFormat('hh:mm a').format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...orderItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${item['quantity']}x',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item['name'] ?? 'Unknown Item',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(
                                        (item['price'] ?? 0.0) *
                                            (item['quantity'] ?? 1),
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textColor,
                                      ),
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
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(total),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: successColor,
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
              // Back to menu button
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.blue[800]
                          : Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      onClearCart();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MenuPreviewScreen(),
                        ),
                        (route) =>
                            route.settings?.name == '/menu' || route.isFirst,
                      );
                    },
                    child: const Text(
                      'Back to Menu',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
