import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      print('Fetching cart items for user: ${user.id}');

      final response = await _supabase
          .from('cart')
          .select('*, products(*)')
          .eq('user_id', user.id);

      print('Received response: $response');

      if (response != null && response is List && response.isNotEmpty) {
        print('First cart item structure: ${response.first}');

        // If products exists, log its structure too
        if (response.first['products'] != null) {
          print('First product structure: ${response.first['products']}');

          // Check if image_url exists and log its type
          final product = response.first['products'];
          if (product is Map && product['image_url'] != null) {
            print('image_url type: ${product['image_url'].runtimeType}');
            print('image_url value: ${product['image_url']}');
          }
        }
      }

      setState(() {
        // Fixed conversion from response to properly typed list
        _cartItems = (response as List).map((item) =>
        Map<String, dynamic>.from(item as Map<dynamic, dynamic>)
        ).toList();
        _calculateTotal();
      });
    } catch (error) {
      print('Error loading cart items: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart items: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotal() {
    _totalAmount = _cartItems.fold(0, (sum, item) {
      // Safely extract the product data with proper type checking
      final productData = item['products'];
      if (productData == null) return sum;

      // Handle both cases where product might be a Map or need conversion
      final product = productData is Map ?
      Map<String, dynamic>.from(productData as Map) :
      <String, dynamic>{};

      if (product.isEmpty) return sum;

      final price = product['price'];
      final quantity = item['quantity'];

      if (price is num && quantity is num) {
        return sum + (price * quantity);
      }
      return sum;
    });
  }

  Future<void> _updateQuantity(String cartId, int currentQuantity, bool isIncrement) async {
    try {
      // Convert cartId to String if it's not already
      final String id = cartId.toString();

      // Get the current cart item and its product
      final cartItem = await _supabase
          .from('cart')
          .select('*, products(*)')
          .eq('id', id)
          .single();

      if (cartItem == null) {
        return;
      }

      // Get the product stock
      final product = cartItem['products'] as Map<String, dynamic>?;
      final stock = product?['stock'] as int? ?? 0;

      // Calculate new quantity
      final newQuantity = isIncrement ? (currentQuantity + 1) : (currentQuantity - 1);

      // Check if new quantity exceeds stock
      if (isIncrement && newQuantity > stock) {
        return;
      }

      // Update the quantity
      await _supabase
          .from('cart')
          .update({'quantity': newQuantity})
          .eq('id', id);

      // Reload the cart items
      await _loadCartItems();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $error')),
        );
      }
    }
  }

  Future<void> _removeItem(String cartId) async {
    try {
      print('Attempting to remove item with cart ID: $cartId');

      // Convert cartId to String if it's not already
      final String id = cartId.toString();

      final response = await _supabase
          .from('cart')
          .delete()
          .eq('id', id)
          .select();

      print('Delete response: $response');

      if (response != null && response.isNotEmpty) {
        print('Item removed successfully');
        await _loadCartItems();
      } else {
        print('Delete failed - no response received');
      }
    } catch (error) {
      print('Error removing item: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Create order
      final orderResponse = await _supabase.from('orders').insert({
        'user_id': user.id,
        'total_amount': _totalAmount,
        'status': 'pending',
      }).select();

      if (orderResponse.isEmpty) {
        throw Exception('Failed to create order');
      }

      final orderId = orderResponse[0]['id'];

      // Create order items
      for (final item in _cartItems) {
        final productData = item['products'];
        if (productData == null) continue;

        final product = productData is Map ?
        Map<String, dynamic>.from(productData as Map) :
        <String, dynamic>{};

        if (product.isEmpty || product['id'] == null) continue;

        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': product['id'],
          'quantity': item['quantity'] is num ? item['quantity'] : 1,
          'price_at_time': product['price'] is num ? product['price'] : 0,
        });
      }

      // Clear cart
      await _supabase.from('cart').delete().eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Utility method to safely get the first image URL from a product
  String? getFirstImageUrl(Map<String, dynamic> product) {
    try {
      if (product.containsKey('image_url')) {
        final imageData = product['image_url'];

        if (imageData is List && imageData.isNotEmpty) {
          return imageData.first.toString();
        } else if (imageData is String) {
          return imageData;
        }
      }
    } catch (e) {
      print('Error getting first image URL: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 3,
          centerTitle: true,
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Logo.png',
                height: 70,
              ),
              const SizedBox(height: 8),
              const Text(
                'Shopping Cart',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          actions: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black, size: 30),
                  onPressed: () {},
                  tooltip: 'Cart',
                ),
                if (_cartItems.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${_cartItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 60),
                SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cartItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                final productData = item['products'];
                if (productData == null) {
                  return const SizedBox.shrink();
                }
                final product = productData is Map
                    ? Map<String, dynamic>.from(productData as Map)
                    : <String, dynamic>{};
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _getProductImage(product),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name']?.toString() ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '\$${((product['price'] is num ? product['price'] : 0) * (item['quantity'] is num ? item['quantity'] : 1)).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                                    onPressed: () {
                                      final currentQuantity = item['quantity'] as int? ?? 1;
                                      if (currentQuantity > 1) {
                                        final String id = item['id'].toString();
                                        _updateQuantity(id, currentQuantity, false);
                                      }
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      item['quantity']?.toString() ?? '1',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 22),
                                    onPressed: () {
                                      final currentQuantity = item['quantity'] as int? ?? 1;
                                      final String id = item['id'].toString();
                                      final product = item['products'] as Map<String, dynamic>?;
                                      final stock = product?['stock'] as int? ?? 0;
                                      if (currentQuantity >= stock) {
                                        return;
                                      }
                                      _updateQuantity(id, currentQuantity, true);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                        onPressed: () {
                          final String id = item['id'].toString();
                          _removeItem(id);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          // Sticky checkout bar
          if (!_isLoading && _cartItems.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.10),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '\$${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 160,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _checkout,
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'Checkout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _getProductImage(Map<String, dynamic> product) {
    final imageUrl = getFirstImageUrl(product);

    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.broken_image, size: 40),
      );
    }

    return const Icon(Icons.image_not_supported, size: 40);
  }
}