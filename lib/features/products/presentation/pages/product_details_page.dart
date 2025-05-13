import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  int _quantity = 1;
  bool _isLoading = false;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  late PageController _pageController;
  late AnimationController _favoriteController;
  late Animation<double> _favoriteAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _favoriteAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.easeInOut),
    );
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isCheckingFavorite = false);
      return;
    }

    try {
      final response = await _supabase
          .from('wishlist')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', widget.product['id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isFavorite = response != null;
          _isCheckingFavorite = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isCheckingFavorite = false);
        debugPrint('Favorite check error: $error');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (!mounted) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to manage favorites')),
      );
      return;
    }

    // Store previous state in case we need to revert
    final previousState = _isFavorite;

    // Optimistic UI update
    setState(() => _isFavorite = !_isFavorite);
    _favoriteController.forward(from: 0);

    try {
      if (_isFavorite) {
        // Upsert instead of insert to handle conflicts gracefully
        final response = await _supabase
            .from('wishlist')
            .upsert(
          {
            'user_id': user.id,
            'product_id': widget.product['id'],
            'created_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id,product_id',
        )
            .select()
            .single();

        if (response == null) throw Exception('Upsert failed');
      } else {
        final response = await _supabase
            .from('wishlist')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', widget.product['id']);

        if (response.isEmpty) throw Exception('Delete failed');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (error) {
      // Revert UI on error
      if (mounted) {
        setState(() => _isFavorite = previousState);

        debugPrint('Favorite error details: $error');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().contains('23505')
                  ? 'Already in your favorites'
                  : 'Failed to update favorites. Please try again.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to add items to cart')),
          );
        }
        return;
      }

      final existingCartItem = await _supabase
          .from('cart')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', widget.product['id'])
          .maybeSingle();

      if (existingCartItem != null) {
        await _supabase.from('cart').update({
          'quantity': existingCartItem['quantity'] + _quantity,
        }).eq('id', existingCartItem['id']);
      } else {
        await _supabase.from('cart').insert({
          'user_id': user.id,
          'product_id': widget.product['id'],
          'quantity': _quantity,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding to cart')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.product['image_url'] != null &&
        widget.product['image_url'] is List &&
        widget.product['image_url'].isNotEmpty
        ? List<String>.from(widget.product['image_url'])
        : [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isCheckingFavorite)
            AnimatedBuilder(
              animation: _favoriteAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _favoriteAnimation.value,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF5F5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Description
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product['description'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Image Carousel
              if (imageUrls.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[100],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(imageUrls[index]),
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        },
                      ),
                      if (imageUrls.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              count: imageUrls.length,
                              effect: const WormEffect(
                                activeDotColor: Colors.black,
                                dotColor: Colors.grey,
                                dotHeight: 8,
                                dotWidth: 8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                  ),
                ),

              // Price and Quantity
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${widget.product['price'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Only ${widget.product['stock']} left in stock - order soon.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Quantity:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black54),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                  ),
                                  Text(_quantity.toString(),
                                      style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: _quantity < widget.product['stock']
                                        ? () => setState(() => _quantity++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                              : const Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
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
