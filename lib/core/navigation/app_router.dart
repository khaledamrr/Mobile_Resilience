import 'package:flutter/material.dart';
import 'package:resilience/features/admin/presentation/pages/admin_dashboard.dart';
import 'package:resilience/features/auth/presentation/pages/login_page.dart';
import 'package:resilience/features/auth/presentation/pages/signup_page.dart';
import 'package:resilience/features/cart/presentation/pages/cart_page.dart';
import 'package:resilience/features/products/presentation/pages/home_page.dart';
import 'package:resilience/features/products/presentation/pages/product_details_page.dart';
import 'package:resilience/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final Session? session = snapshot.data!.session;
                if (session != null) {
                  // Check if user is admin
                  return FutureBuilder(
                    future: Supabase.instance.client
                        .from('admin')
                        .select()
                        .eq('id', session.user.id)
                        .maybeSingle(),
                    builder: (context, adminSnapshot) {
                      if (adminSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }
                      if (adminSnapshot.hasData && adminSnapshot.data != null) {
                        // User is admin
                        return const AdminDashboard();
                      } else {
                        // Not admin
                        return const HomePage();
                      }
                    },
                  );
                } else {
                  return const LoginPage();
                }
              }
              return const LoginPage();
            },
          ),
        );
      case '/home':
        return MaterialPageRoute(
          builder: (_) => StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final Session? session = snapshot.data!.session;
                if (session != null) {
                  // Check if user is admin
                  return FutureBuilder(
                    future: Supabase.instance.client
                        .from('admin')
                        .select()
                        .eq('id', session.user.id)
                        .maybeSingle(),
                    builder: (context, adminSnapshot) {
                      if (adminSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }
                      if (adminSnapshot.hasData && adminSnapshot.data != null) {
                        // User is admin
                        return const AdminDashboard();
                      } else {
                        // Not admin
                        return const HomePage();
                      }
                    },
                  );
                } else {
                  return const LoginPage();
                }
              }
              return const LoginPage();
            },
          ),
        );
      case '/home':
        return MaterialPageRoute(
          builder: (_) => StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final AuthChangeEvent event = snapshot.data!.event;
                final Session? session = snapshot.data!.session;
                if (event == AuthChangeEvent.signedIn && session != null) {
                  // Check if user is admin
                  return FutureBuilder(
                    future: Supabase.instance.client
                        .from('admin')
                        .select()
                        .eq('id', session.user.id)
                        .maybeSingle(),
                    builder: (context, adminSnapshot) {
                      if (adminSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }
                      if (adminSnapshot.hasData && adminSnapshot.data != null) {
                        // User is admin
                        return const AdminDashboard();
                      } else {
                        // Not admin
                        return const HomePage();
                      }
                    },
                  );
                } else {
                  return const LoginPage();
                }
              }
              return const LoginPage();
            },
          ),
        );
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case '/cart':
        return MaterialPageRoute(builder: (_) => const CartPage());
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case '/product':
        final product = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ProductDetailsPage(product: product),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 