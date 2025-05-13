import 'package:flutter/material.dart';
import 'package:resilience/features/products/presentation/pages/wishlist_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import 'product_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;

  final List<String> _categories = [
    'all',
    't_shirts',
    'jeans',
    'shorts',
    'hoodies',
    'jackets',
  ];

  late AnimationController _categoryAnimationController;
  late Animation<double> _categoryAnimation;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _categoryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _categoryAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _categoryAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _categoryAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _filteredProducts = _products;
      });
      for (var product in _products) {
        print('Product: ${product['name']}, image_url: ${product['image_url']}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading products')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String category) {
    _categoryAnimationController.forward(from: 0);
    setState(() {
      _selectedCategory = category;
      if (category == 'all') {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products
            .where((product) => product['category'] == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Image.asset(
            'assets/Logo.png',
            height: 80,
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Logo.png',
                    height: 60,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.white),
              title: const Text('Wish List', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WishListPage()),
                );
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _supabase.auth.signOut();
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign out failed: \\${error.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large image below the logo
          Image.asset(
            'assets/design.jpg',
            height: 240,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsPage(product: product),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (() {
                                final imageUrl = product['image_url'];
                                String? displayUrl;
                                if (imageUrl is String) {
                                  displayUrl = imageUrl;
                                } else if (imageUrl is List && imageUrl.isNotEmpty && imageUrl[0] is String) {
                                  displayUrl = imageUrl[0];
                                }
                                if (displayUrl != null && displayUrl.isNotEmpty) {
                                  return Image.network(
                                    displayUrl,
                                    fit: BoxFit.cover,
                                  );
                                } else {
                                  return Container(color: Colors.grey[200]);
                                }
                              })(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product['price'] != null ? '\$${product['price']}' : '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}