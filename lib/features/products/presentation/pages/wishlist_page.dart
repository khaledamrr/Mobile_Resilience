import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'product_details_page.dart';

class WishListPage extends StatefulWidget {
  const WishListPage({super.key});

  @override
  State<WishListPage> createState() => _WishListPageState();
}

class _WishListPageState extends State<WishListPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _wishlistProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlistProducts();
  }

  Future<void> _loadWishlistProducts() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to view wishlist')),
          );
        }
        return;
      }

      final response = await _supabase
          .from('wishlist')
          .select('product:products(*)') // Join with products table
          .eq('user_id', user.id);

      setState(() {
        _wishlistProducts = List<Map<String, dynamic>>.from(response)
            .map((item) => item['product'] as Map<String, dynamic>)
            .toList();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wishlist: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Image.asset(
            'assets/Logo.png',
            height: 56,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
              onPressed: () {},
              tooltip: 'Wishlist',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlistProducts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.favorite_border, color: Colors.grey, size: 60),
            SizedBox(height: 16),
            Text(
              'No items in your wishlist',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _wishlistProducts.length,
        itemBuilder: (context, index) {
          final product = _wishlistProducts[index];
          final imageUrls = product['image_url'] != null &&
              product['image_url'] is List &&
              product['image_url'].isNotEmpty
              ? List<String>.from(product['image_url'])
              : product['image_url'] is String && product['image_url'].isNotEmpty
              ? [product['image_url']]
              : [];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(product: product),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: imageUrls.isNotEmpty
                          ? Image.network(
                        imageUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 40),
                          );
                        },
                      )
                          : const Center(
                        child: Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    child: Column(
                      children: [
                        Text(
                          product['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product['price'] != null
                              ? '\$${product['price'].toStringAsFixed(2)}'
                              : '\$0.00',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}