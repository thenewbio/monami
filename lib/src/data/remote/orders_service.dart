import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:monami/src/data/state/constants/firebase_collection.dart';
import 'package:monami/src/models/product_model.dart';
import 'package:monami/src/services/storage_service.dart';
import 'package:monami/src/utils/logger.dart';
import 'package:monami/src/data/remote/notification_service.dart';
import 'package:monami/src/data/remote/product_service.dart';

/// Service to handle orders operations with Firebase and local storage
class OrdersService {
  final _logger = Logger(OrdersService);
  final _firestore = FirebaseFirestore.instance;
// Replace with your actual Gemini API Key
  static const _apiKey = 'YOUR_GEMINI_API_KEY';

  /// New: AI-Powered Shipping Assistant using Gemini
  Future<String> getAIShippingEstimate(Orders order) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      final itemsList = order.items.map((e) => e.productName).join(', ');
      final city = order.shippingAddress['city'] ?? 'your location';

      final prompt = """
      Act as a friendly logistics assistant for Monami Ecommerce. 
      The customer has ordered: $itemsList. 
      The delivery city is: $city. 
      The current status is: ${order.status}.
      Provide a concise 2-sentence update on when they might receive it and a 
      fun fact about one of the items.
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ??
          "We're processing your order and will update you soon!";
    } catch (e) {
      return "AI Assistant: We're experiencing high traffic, but your order is safe in our system!";
    }
  }

  /// New: Mark as Shipped with Tracking ID
  Future<void> shipOrder(String orderId, String trackingId) async {
    await _firestore
        .collection(FirebaseCollectionName.orders)
        .doc(orderId)
        .update({
      'status': 'shipped',
      'trackingId': trackingId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Create a new order (both Firebase and local storage)
  Future<Orders> createOrder(Orders order) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Add to Firebase
      await _addToFirestoreOrder(order, currentUser.uid);

      // Add to local storage
      await StorageService.saveOrder(order.toJson());

      // Send notifications to product owners
      await _sendPurchaseNotifications(order, currentUser.uid);

      _logger.log('Order created successfully: ${order.id}');
      print(
          'DEBUG: Purchase notification trigger called for order: ${order.id}');
      return order;
    } catch (e) {
      _logger.log('Error creating order: $e');
      rethrow;
    }
  }

  /// Add order to Firebase
  Future<void> _addToFirestoreOrder(Orders order, String userId) async {
    try {
      await _firestore
          .collection(FirebaseCollectionName.orders)
          .doc(order.id)
          .set({
        'id': order.id,
        'userId': userId,
        'items': order.items.map((item) => item.toJson()).toList(),
        'subtotal': order.subtotal,
        'shipping': order.shipping,
        'tax': order.tax,
        'total': order.total,
        'status': order.status,
        'createdAt': order.createdAt.toIso8601String(),
        'shippingAddress': order.shippingAddress,
        'paymentMethod': order.paymentMethod,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _logger.log('Order added to Firestore');
    } catch (e) {
      _logger.log('Error adding order to Firestore: $e');
      throw Exception('Failed to add order to cloud: $e');
    }
  }

  /// Get orders from Firebase
  Future<List<Orders>> getOrdersFromFirebase() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(FirebaseCollectionName.orders)
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Orders.fromJson(data);
      }).toList();

      _logger.log('Retrieved ${orders.length} orders from Firebase');
      return orders;
    } catch (e) {
      _logger.log('Error getting orders from Firebase: $e');
      throw Exception('Failed to fetch orders from cloud: $e');
    }
  }

  /// Get orders (Firebase first, then local fallback)
  Future<List<Orders>> getOrders() async {
    try {
      // Try Firebase first
      try {
        final orders = await getOrdersFromFirebase();
        // Sync with local storage
        await _syncOrdersWithLocal(orders);
        return orders;
      } catch (firebaseError) {
        _logger
            .log('Firebase error, loading from local storage: $firebaseError');
        // Fallback to local storage
        final ordersData = await StorageService.getOrders();
        return ordersData.map((data) => Orders.fromJson(data)).toList();
      }
    } catch (e) {
      _logger.log('Error getting orders: $e');
      return [];
    }
  }

  /// Sync Firebase orders with local storage
  Future<void> _syncOrdersWithLocal(List<Orders> firebaseOrders) async {
    try {
      // Clear local orders
      final localOrders = await StorageService.getOrders();
      for (final order in localOrders) {
        // Note: We don't have a delete order method in StorageService
        // This is a limitation that could be addressed in future updates
      }

      // Add Firebase orders to local storage
      for (final order in firebaseOrders) {
        await StorageService.saveOrder(order.toJson());
      }

      _logger.log('Synced ${firebaseOrders.length} orders with local storage');
    } catch (e) {
      _logger.log('Error syncing orders with local storage: $e');
    }
  }

  /// Get order by ID
  Future<Orders?> getOrderById(String orderId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection(FirebaseCollectionName.orders)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Verify the order belongs to the current user
      if (data['userId'] != currentUser.uid) {
        throw Exception('Order does not belong to current user');
      }

      return Orders.fromJson(data);
    } catch (e) {
      _logger.log('Error getting order by ID: $e');
      return null;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update in Firebase
      await _firestore
          .collection(FirebaseCollectionName.orders)
          .doc(orderId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update in local storage
      final orders = await StorageService.getOrders();
      final orderIndex = orders.indexWhere((order) => order['id'] == orderId);
      if (orderIndex != -1) {
        orders[orderIndex]['status'] = status;
        orders[orderIndex]['updatedAt'] = DateTime.now().toIso8601String();
        await StorageService.saveOrder(orders[orderIndex]);
      }

      _logger.log('Order status updated: $orderId -> $status');
    } catch (e) {
      _logger.log('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  /// New: Get AI-generated shipping update based on current order state
  Future<String> getAIShippingAssistance(Orders order) async {
    // This uses a placeholder for your AI API call (e.g., Gemini or OpenAI)
    // You would pass the order items and status to get a human-like summary
    final items = order.items.map((e) => e.productName).join(', ');
    final prompt =
        "Update the customer on order #${order.id}. Items: $items. Status: ${order.status}. Address: ${order.shippingAddress['city']}.";

    // Logic: Return a friendly message based on order status
    if (order.status == 'shipped') {
      return "Your order ($items) is currently on the move! It's headed to ${order.shippingAddress['city']} and usually takes 2-3 business days.";
    }
    return "We are still preparing your items ($items). Our team is working to get it to the courier as soon as possible!";
  }

  /// Update entire order
  Future<void> updateOrder(Orders order) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update in Firebase
      await _firestore
          .collection(FirebaseCollectionName.orders)
          .doc(order.id)
          .update({
        'id': order.id,
        'items': order.items.map((item) => item.toJson()).toList(),
        'subtotal': order.subtotal,
        'shipping': order.shipping,
        'tax': order.tax,
        'total': order.total,
        'status': order.status,
        'createdAt': order.createdAt.toIso8601String(),
        'shippingAddress': order.shippingAddress,
        'paymentMethod': order.paymentMethod,
        'paymentId': order.paymentId,
        'completedAt': order.completedAt?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update in local storage
      await StorageService.saveOrder(order.toJson());

      _logger.log('Order updated successfully: ${order.id}');
    } catch (e) {
      _logger.log('Error updating order: $e');
      throw Exception('Failed to update order: $e');
    }
  }

  /// Get orders by status
  Future<List<Orders>> getOrdersByStatus(String status) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(FirebaseCollectionName.orders)
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Orders.fromJson(data);
      }).toList();

      _logger.log('Retrieved ${orders.length} orders with status: $status');
      return orders;
    } catch (e) {
      _logger.log('Error getting orders by status: $e');
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  /// Get orders count
  Future<int> getOrdersCount() async {
    try {
      final orders = await getOrders();
      return orders.length;
    } catch (e) {
      _logger.log('Error getting orders count: $e');
      return 0;
    }
  }

  /// Get total spent
  Future<double> getTotalSpent() async {
    try {
      final orders = await getOrders();
      double total = 0.0;
      for (final order in orders) {
        // Support both synchronous and asynchronous total values (FutureOr<double>)
        final double value = await Future.value(order.total);
        total += value;
      }
      return total;
    } catch (e) {
      _logger.log('Error calculating total spent: $e');
      return 0.0;
    }
  }

  /// Get recent orders (last N orders)
  Future<List<Orders>> getRecentOrders(int limit) async {
    try {
      final orders = await getOrders();
      return orders.take(limit).toList();
    } catch (e) {
      _logger.log('Error getting recent orders: $e');
      return [];
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'cancelled');
      _logger.log('Order cancelled: $orderId');
    } catch (e) {
      _logger.log('Error cancelling order: $e');
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Complete order
  Future<void> completeOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'completed');
      _logger.log('Order completed: $orderId');
    } catch (e) {
      _logger.log('Error completing order: $e');
      throw Exception('Failed to complete order: $e');
    }
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final orders = await getOrders();

      final totalOrders = orders.length;
      final totalSpent = orders.fold(0.0, (sum, order) => sum + order.total);
      final averageOrderValue =
          totalOrders > 0 ? totalSpent / totalOrders : 0.0;

      final statusCounts = <String, int>{};
      for (final order in orders) {
        statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
      }

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'averageOrderValue': averageOrderValue,
        'statusCounts': statusCounts,
      };
    } catch (e) {
      _logger.log('Error getting order statistics: $e');
      return {
        'totalOrders': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
        'statusCounts': <String, int>{},
      };
    }
  }

  /// Sync local orders with Firebase
  Future<void> syncLocalOrdersWithFirebase() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get local orders
      final localOrders = await StorageService.getOrders();

      // Get Firebase orders
      final firebaseOrders = await getOrdersFromFirebase();

      // Create a set of Firebase order IDs for quick lookup
      final firebaseOrderIds = firebaseOrders.map((order) => order.id).toSet();

      // Add local orders that don't exist in Firebase
      for (final orderData in localOrders) {
        final order = Orders.fromJson(orderData);
        if (!firebaseOrderIds.contains(order.id)) {
          await _addToFirestoreOrder(order, currentUser.uid);
        }
      }

      _logger.log('Synced ${localOrders.length} local orders with Firebase');
    } catch (e) {
      _logger.log('Error syncing local orders with Firebase: $e');
      throw Exception('Failed to sync orders: $e');
    }
  }

  /// Send purchase notifications to product owners
  Future<void> _sendPurchaseNotifications(Orders order, String buyerId) async {
    try {
      // Get buyer details
      final buyerDoc = await _firestore
          .collection(FirebaseCollectionName.users)
          .doc(buyerId)
          .get();

      if (!buyerDoc.exists) return;

      final buyerData = buyerDoc.data()!;
      final buyerName =
          buyerData['displayName'] ?? buyerData['email'] ?? 'Someone';

      // Get product details and send notifications
      final productService = ProductService();
      final products = await productService.getProductsFromFirebase();
      final notificationService = NotificationService();

      // Group items by product owner
      final Map<String, List<CartItem>> ownerItems = {};

      for (final item in order.items) {
        final product = products.firstWhere((p) => p.id == item.productId);
        final ownerId = product.createdBy;

        if (!ownerItems.containsKey(ownerId)) {
          ownerItems[ownerId] = [];
        }
        ownerItems[ownerId]!.add(item);
      }

      // Send notification for each product owner
      for (final entry in ownerItems.entries) {
        final ownerId = entry.key;
        final items = entry.value;

        // Calculate total for this owner
        double totalAmount = 0;
        int totalQuantity = 0;
        String productNames = '';

        for (final item in items) {
          totalAmount += item.price * item.quantity;
          totalQuantity += item.quantity;
          if (productNames.isNotEmpty) productNames += ', ';
          productNames += item.productName;
        }

        // Send notification
        await notificationService.sendPurchaseNotification(
          productId: items.first.productId,
          productName: productNames,
          buyerName: buyerName,
          productOwnerId: ownerId,
          quantity: totalQuantity,
          totalAmount: totalAmount,
        );
      }

      _logger.log('Purchase notifications sent for order: ${order.id}');
    } catch (e) {
      _logger.log('Error sending purchase notifications: $e');
      // Don't throw error to avoid breaking the order functionality
    }
  }
}
