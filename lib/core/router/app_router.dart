import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      // Routes nécessitant une connexion
      final protectedRoutes = [
        '/orders',
        '/profile',
        '/checkout',
      ];
      final isProtected = protectedRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      if (isProtected && !isLoggedIn) {
        return '/auth/login?redirect=${state.matchedLocation}';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      // ─── Main Shell (Bottom Nav) ─────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (ctx, state) => _noTransition(const ShopScreen(), state),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (ctx, state) => _noTransition(const FavoritesScreen(), state),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (ctx, state) => _noTransition(const CartScreen(), state),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (ctx, state) => _noTransition(const OrdersScreen(), state),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (ctx, state) => _noTransition(const ProfileScreen(), state),
          ),
        ],
      ),

      // ─── Product Detail ──────────────────────────────────────────────────
      GoRoute(
        path: '/product/:slug',
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ProductDetailScreen(slug: state.pathParameters['slug']!),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // ─── Checkout ────────────────────────────────────────────────────────
      GoRoute(
        path: '/checkout',
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CheckoutScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // ─── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: LoginScreen(
            redirectTo: state.uri.queryParameters['redirect'],
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/auth/register',
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable : ${state.uri}'),
      ),
    ),
  );
});

NoTransitionPage _noTransition(Widget child, GoRouterState state) {
  return NoTransitionPage(key: state.pageKey, child: child);
}

Widget _slideTransition(context, animation, secondaryAnimation, child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}

Widget _fadeTransition(context, animation, secondaryAnimation, child) {
  return FadeTransition(opacity: animation, child: child);
}
