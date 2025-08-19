import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'Order/order_confirmation_screen.dart';

class TableNumberScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final Function() onClearCart;
  final int restaurantId; // Added to receive restaurantId

  const TableNumberScreen({
    Key? key,
    required this.orderItems,
    required this.onClearCart,
    required this.restaurantId, // Required parameter
  }) : super(key: key);

  @override
  State<TableNumberScreen> createState() => _TableNumberScreenState();
}

class _TableNumberScreenState extends State<TableNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

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
              restaurantId: widget.restaurantId, // Pass the restaurantId
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // disable default back button
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 0, // remove default padding before title
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
            const SizedBox(width: 0), // small gap between icon and text
            const Text(
              'Table Number',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
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
              const Text(
                'Please enter your table number:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tableNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Table Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a table number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
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
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Submit Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}