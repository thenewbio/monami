class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final List<String> colors;
  final List<String> sizes;
  final bool isAvailable;
  final int stockQuantity;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final String createdBy;
  final String? brand;
  final Map<String, dynamic>? specifications;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    this.colors = const [],
    this.sizes = const [],
    this.isAvailable = true,
    this.stockQuantity = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.createdBy,
    this.brand,
    this.specifications,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'colors': colors,
      'sizes': sizes,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'brand': brand,
      'specifications': specifications,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      images: List<String>.from(json['images'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      sizes: List<String>.from(json['sizes'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      stockQuantity: json['stockQuantity'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'] ?? '',
      brand: json['brand'],
      specifications: json['specifications'],
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? images,
    List<String>? colors,
    List<String>? sizes,
    bool? isAvailable,
    int? stockQuantity,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    String? createdBy,
    String? brand,
    Map<String, dynamic>? specifications,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      images: images ?? this.images,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      brand: brand ?? this.brand,
      specifications: specifications ?? this.specifications,
    );
  }
}

class CartItem {
  final String productId;
  final String productName;
  final double price;
  final String image;
  int quantity;
  final String? color;
  final String? size;
  final DateTime addedAt;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.image,
    required this.quantity,
    this.color,
    this.size,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'image': image,
      'quantity': quantity,
      'color': color,
      'size': size,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      productName: json['productName'],
      price: (json['price'] as num).toDouble(),
      image: json['image'],
      quantity: json['quantity'],
      color: json['color'],
      size: json['size'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  double get totalPrice => price * quantity;
}

// lib/src/models/product_model.dart

class Orders {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;
  final String status; // 'pending', 'processing', 'shipped', 'delivered'
  final String? trackingId; // New field added
  final DateTime createdAt;
  final Map<String, dynamic> shippingAddress;
  final String paymentMethod;
  final String? paymentId;
  final DateTime? completedAt;

  Orders({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.status,
    this.trackingId, // Optional tracking ID
    required this.createdAt,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentId,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shipping': shipping,
      'tax': tax,
      'total': total,
      'status': status,
      'trackingId': trackingId,
      'createdAt': createdAt.toIso8601String(),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Orders.fromJson(Map<String, dynamic> json) {
    return Orders(
      id: json['id'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'],
      trackingId: json['trackingId'],
      createdAt: DateTime.parse(json['createdAt']),
      shippingAddress: json['shippingAddress'],
      paymentMethod: json['paymentMethod'],
      paymentId: json['paymentId'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  /// Create a copy with updated fields
  Orders copyWith({
    String? id,
    List<CartItem>? items,
    double? subtotal,
    double? shipping,
    double? tax,
    double? total,
    String? status,
    String? trackingId,
    DateTime? createdAt,
    Map<String, dynamic>? shippingAddress,
    String? paymentMethod,
    String? paymentId,
    DateTime? completedAt,
  }) {
    return Orders(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shipping: shipping ?? this.shipping,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      trackingId: trackingId ?? this.trackingId,
      createdAt: createdAt ?? this.createdAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class UserProfile {
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final Map<String, dynamic>? preferences;
  final List<Map<String, dynamic>> addresses;

  UserProfile({
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.preferences,
    this.addresses = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'preferences': preferences,
      'addresses': addresses,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profileImage'],
      preferences: json['preferences'],
      addresses: List<Map<String, dynamic>>.from(json['addresses'] ?? []),
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    Map<String, dynamic>? preferences,
    List<Map<String, dynamic>>? addresses,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      preferences: preferences ?? this.preferences,
      addresses: addresses ?? this.addresses,
    );
  }
}
