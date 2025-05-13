import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

import '../../../products/presentation/pages/home_page.dart';

class OrderPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const OrderPage({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOrderConfirmationEmail(String email) async {
    try {
      final emailMessage = await FlutterEmailSender.send(Email(
        body: '''
        Thank you for your order!

        Order Details:
        Total Amount: \$${widget.totalAmount.toStringAsFixed(2)}
        Payment Method: Cash on Delivery
        
        Items Ordered:
        ${widget.cartItems.map((item) => '- ${item['products']['name']} x ${item['quantity']}').join('\n')}
        
        We will contact you soon to confirm your order.
        ''',
        subject: 'Order Confirmation',
        recipients: [email],
        isHTML: false,
      ));
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Ensure all form values are properly initialized
      final fullName = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final email = _emailController.text.trim();

      if (fullName.isEmpty || phoneNumber.isEmpty || email.isEmpty) {
        throw Exception('All fields are required');
      }

      // Create order
      final orderResponse = await _supabase.from('orders').insert({
        'user_id': user.id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'payment_method': 'cash_on_delivery',
        'status': 'pending',
        'total_amount': widget.totalAmount,
        'items': widget.cartItems.map((item) => {
          'product_id': item['products']['id'],
          'quantity': item['quantity'],
          'price': item['products']['price']
        }).toList()
      }).select().catchError((error) {
        print('Error placing order: $error');
        return null;
      });

      if (orderResponse != null && orderResponse is List && orderResponse.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        try {
          await _sendOrderConfirmationEmail(_emailController.text);
          await _supabase.from('cart').delete().eq('user_id', user.id);

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        } catch (e) {
          print('Error sending email: $e');

          await _supabase.from('cart').delete().eq('user_id', user.id);

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        }
      } else {
        throw Exception('Failed to create order');
      }
    } catch (error) {
      print('Error placing order: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your email';
                  if (!value!.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Method: Cash on Delivery',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Total Amount: \$${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
