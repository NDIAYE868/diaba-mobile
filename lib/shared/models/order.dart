import '../../core/constants/app_config.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  atDepot,
  readyForPickup,
  delivered,
  cancelled;

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending': return OrderStatus.pending;
      case 'confirmed': return OrderStatus.confirmed;
      case 'processing': return OrderStatus.processing;
      case 'shipped': return OrderStatus.shipped;
      case 'at_depot': return OrderStatus.atDepot;
      case 'ready_for_pickup': return OrderStatus.readyForPickup;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending: return 'En attente';
      case OrderStatus.confirmed: return 'Confirmée';
      case OrderStatus.processing: return 'En traitement';
      case OrderStatus.shipped: return 'Expédiée';
      case OrderStatus.atDepot: return 'Au dépôt';
      case OrderStatus.readyForPickup: return 'Prête à récupérer';
      case OrderStatus.delivered: return 'Livrée / Récupérée';
      case OrderStatus.cancelled: return 'Annulée';
    }
  }
}

class OrderItem {
  final int id;
  final int product;
  final String productName;
  final String? productImage;
  final String supplierName;
  final int quantity;
  final String unitPrice;
  final String totalPrice;

  const OrderItem({
    required this.id,
    required this.product,
    required this.productName,
    this.productImage,
    required this.supplierName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['product_image'] as String?;
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = '${AppConfig.apiBaseUrl}$imageUrl';
    }
    return OrderItem(
      id: json['id'] as int,
      product: json['product'] as int,
      productName: json['product_name'] as String,
      productImage: imageUrl,
      supplierName: json['supplier_name'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: json['unit_price'] as String,
      totalPrice: json['total_price'] as String,
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final String statusDisplay;
  final String paymentTimingDisplay;
  final String totalAmount;
  final String shippingAddress;
  final String? phone;
  final String? notes;
  final List<OrderItem> items;
  final int itemsCount;
  final String? shipmentDepotName;
  final String? shipmentDepotAddress;
  final String? shipmentDepotLocation;
  final String? recipientFirstName;
  final String? recipientLastName;
  final String createdAt;
  final String updatedAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusDisplay,
    required this.paymentTimingDisplay,
    required this.totalAmount,
    required this.shippingAddress,
    this.phone,
    this.notes,
    required this.items,
    required this.itemsCount,
    this.shipmentDepotName,
    this.shipmentDepotAddress,
    this.shipmentDepotLocation,
    this.recipientFirstName,
    this.recipientLastName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    // shipping_address peut être string ou Map
    final rawAddr = json['shipping_address'];
    String addr = '';
    if (rawAddr is String) {
      addr = rawAddr;
    } else if (rawAddr is Map) {
      addr = rawAddr.values.join('\n');
    }

    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      statusDisplay: json['status_display'] as String? ?? '',
      paymentTimingDisplay: json['payment_timing_display'] as String? ?? '',
      totalAmount: json['total_amount'] as String,
      shippingAddress: addr,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      items: rawItems.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      itemsCount: json['items_count'] as int? ?? 0,
      shipmentDepotName: json['shipment_depot_name'] as String?,
      shipmentDepotAddress: json['shipment_depot_address'] as String?,
      shipmentDepotLocation: json['shipment_depot_location'] as String?,
      recipientFirstName: json['recipient_first_name'] as String?,
      recipientLastName: json['recipient_last_name'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  double get totalAmountDouble => double.tryParse(totalAmount) ?? 0;
}

class Depot {
  final int id;
  final String name;
  final String address;
  final String communeName;
  final String departementName;
  final String regionName;
  final String city;
  final bool isActive;
  final double? distanceKm;
  final String? latitude;
  final String? longitude;
  final String managerName;
  final String managerPhone;

  const Depot({
    required this.id,
    required this.name,
    required this.address,
    required this.communeName,
    required this.departementName,
    required this.regionName,
    required this.city,
    required this.isActive,
    this.distanceKm,
    this.latitude,
    this.longitude,
    required this.managerName,
    required this.managerPhone,
  });

  factory Depot.fromJson(Map<String, dynamic> json) => Depot(
    id: json['id'] as int,
    name: json['name'] as String,
    address: json['address'] as String? ?? '',
    communeName: json['commune_name'] as String? ?? '',
    departementName: json['departement_name'] as String? ?? '',
    regionName: json['region_name'] as String? ?? '',
    city: json['city'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    latitude: json['latitude'] as String?,
    longitude: json['longitude'] as String?,
    managerName: json['manager_name'] as String? ?? '',
    managerPhone: json['manager_phone'] as String? ?? '',
  );

  String get fullAddress => [address, communeName, departementName]
      .where((s) => s.isNotEmpty)
      .join(', ');
}
