import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:monami/src/presentation/views/order/order_view.dart';
import 'package:monami/src/presentation/views/payment/payment_view.dart';
import 'package:monami/src/utils/router/route_name.dart';
import 'package:monami/src/presentation/views/bottomnavigation/bottom_navigation_screen.dart';
import 'package:monami/src/presentation/views/login/login_view.dart';
import 'package:monami/src/presentation/views/onboarding/onboarding_view.dart';
import 'package:monami/src/presentation/views/splash/splash_view.dart';
import 'package:monami/src/presentation/views/profile/profile_view.dart';
import 'package:monami/src/presentation/views/profile/edit_profile_view.dart';
import 'package:monami/src/presentation/views/favorites/favorites_view.dart';
import 'package:monami/src/presentation/views/profile/order_history_view.dart';
import 'package:monami/src/presentation/views/dashboard/user_dashboard_view.dart';
import 'package:monami/src/presentation/views/product/create_product_view.dart';
import 'package:monami/src/presentation/views/product/product_detail_view.dart';
import 'package:monami/src/presentation/views/cart/cart_view.dart';
import 'package:monami/src/presentation/views/checkout/checkout_view.dart';
import 'package:monami/src/presentation/views/payment/payment_selection_view.dart';

import 'package:monami/src/presentation/views/notifications/notifications_view.dart';
import 'package:monami/src/models/product_model.dart';

class RouteGenerator {
  ///Generates routes, extracts and passes navigation arguments.
  static Route<Object?>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashScreenViewRoute:
        return _getPageRoute(const SplashView());
      case Routes.onboardingViewRoute:
      case Routes.onboardingRoute:
        return _getPageRoute(const OnboardingScreen());
      case Routes.homeViewRoute:
        return _getPageRoute(const BottomNavigation());
      case Routes.loginViewRoute:
      case Routes.loginRoute:
        return _getPageRoute(const LoginView());

      // Profile routes
      case Routes.editProfileRoute:
        return _getPageRoute(const EditProfileView());
      case Routes.favoritesRoute:
        return _getPageRoute(const FavoritesView());
      case Routes.orderHistoryRoute:
        return _getPageRoute(const OrderHistoryView());
      case Routes.userDashboardRoute:
        return _getPageRoute(const UserDashboardView());

      // Product routes
      case Routes.createProductRoute:
        return _getPageRoute(const CreateProductView());
      case Routes.productDetailRoute:
        return _getPageRoute(_buildProductDetailView(settings.arguments));

      // Cart and checkout routes
      case Routes.cartRoute:
        return _getPageRoute(const CartView());
      case Routes.checkoutRoute:
        return _getPageRoute(_buildCheckoutView(settings.arguments));
      case Routes.orderSuccessRoute:
        return _getPageRoute(_buildOrderSuccessView(settings.arguments));

      // Payment routes
      case Routes.paymentRoute:
        return _getPageRoute(_buildPaymentView(settings.arguments));
      // Notification routes
      case Routes.notificationsRoute:
        return _getPageRoute(const NotificationsView());

      //order routes
      case Routes.orderTrackingRoute:
        return _getPageRoute(_buildOrderTrackingView(settings.arguments));

      default:
        return _getPageRoute(_errorPage());
    }
  }

  //Wraps widget with a CupertinoPageRoute and adds route settings
  static CupertinoPageRoute<Object> _getPageRoute(
    Widget child, [
    String? routeName,
    dynamic args,
  ]) =>
      CupertinoPageRoute(
        builder: (context) => child,
        settings: RouteSettings(
          name: routeName,
          arguments: args,
        ),
      );

  ///Error page shown when app attempts navigating to an unknown route
  static Widget _errorPage({String message = "Error! Page not found"}) =>
      Scaffold(
        appBar: AppBar(
            title: const Text(
          'Page not found',
          style: TextStyle(color: Colors.red),
        )),
        body: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );

  // New Helper for Order Tracking
  static Widget _buildOrderTrackingView(dynamic arguments) {
    if (arguments is Orders) {
      return OrderTrackingView(order: arguments);
    }
    return _errorPage(message: 'Invalid Order data for tracking');
  }

  // Helper methods for views that require arguments
  static Widget _buildProductDetailView(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      return ProductDetailView(
        image: arguments['image'] ?? 'assets/images/bag_1.png',
        title: arguments['title'] ?? 'Product',
        subtitle: arguments['subtitle'] ?? 'Description',
        price: arguments['price'] ?? '\$0.00',
        rating: arguments['rating'] ?? 0.0,
        reviews: arguments['reviews'] ?? 0,
        productId: arguments['productId'] ?? '',
      );
    }
    return const ProductDetailView(
      image: 'assets/images/bag_1.png',
      title: 'Product',
      subtitle: 'Description',
      price: '\$0.00',
      rating: 0.0,
      reviews: 0,
      productId: '',
    );
  }

  static Widget _buildCheckoutView(dynamic arguments) {
    if (arguments is Map<String, dynamic> && arguments['items'] != null) {
      return CheckoutView(
        items: List<CheckoutItem>.from(arguments['items']),
        subtotal: arguments['subtotal'] ?? 0.0,
        shipping: arguments['shipping'] ?? 0.0,
        tax: arguments['tax'] ?? 0.0,
      );
    }
    return const CheckoutView(
      items: [],
      subtotal: 0.0,
      shipping: 0.0,
      tax: 0.0,
    );
  }

  static Widget _buildOrderSuccessView(dynamic arguments) {
    // This would be a simple success page
    return Scaffold(
      appBar: AppBar(title: const Text('Order Success')),
      body: const Center(
        child: Text('Order placed successfully!'),
      ),
    );
  }

  static Widget _buildPaymentView(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      return PaymentView(
        order: arguments['order'],
        items: arguments['items'],
      );
    }
    // Return an error page when payment arguments are missing to avoid passing null
    // to a non-nullable Orders parameter.
    return _errorPage(message: 'Missing payment arguments');
  }
}
