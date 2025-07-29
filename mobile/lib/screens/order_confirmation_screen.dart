import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final total = orderItems.fold(0.0, (sum, item) {
      return sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success icon and message
            Center(
              child: Column(
                children: const [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Order Submitted Successfully!',
                    style: TextStyle(
                      fontSize: 22,
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Your Table Number is',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$tableNumber',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please remember this number',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade800,
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...orderItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '${item['quantity']}x',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['name'] ?? 'Unknown Item',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Text(
                              '\$${((item['price'] ?? 0.0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Back to menu button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  onClearCart();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}