import 'listing_model.dart';
import 'fish_listing.dart';
import 'buyer_information.dart';

// Represents the lifecycle status of an order
enum OrderStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.rejected:
        return 'Rejected';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Represents a purchase order made by a buyer for a fish listing
class Order {
  final String id;
  final FishListing listing;
  final BuyerInfo buyer;
  final PaymentMethod paymentMethod;
  final String? paymentProofImageUrl;
  final DateTime orderedAt;
  final OrderStatus status;
  final String? sellerNote;
  final String? rejectionReason;
  final DateTime? respondedAt;

  Order({
    required this.id,
    required this.listing,
    required this.buyer,
    required this.paymentMethod,
    this.paymentProofImageUrl,
    required this.orderedAt,
    this.status = OrderStatus.pending,
    this.sellerNote,
    this.rejectionReason,
    this.respondedAt,
  });

  double get totalPrice => listing.totalPrice;

  // Creates a new Order with modified fields
  Order copyWith({
    String? id,
    FishListing? listing,
    BuyerInfo? buyer,
    PaymentMethod? paymentMethod,
    String? paymentProofImageUrl,
    DateTime? orderedAt,
    OrderStatus? status,
    String? sellerNote,
    String? rejectionReason,
    DateTime? respondedAt,
  }) {
    return Order(
      id: id ?? this.id,
      listing: listing ?? this.listing,
      buyer: buyer ?? this.buyer,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProofImageUrl: paymentProofImageUrl ?? this.paymentProofImageUrl,
      orderedAt: orderedAt ?? this.orderedAt,
      status: status ?? this.status,
      sellerNote: sellerNote ?? this.sellerNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  // Creates an Order object from backend JSON data
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      listing: FishListing.fromJson(json['listing'] as Map<String, dynamic>),
      buyer: BuyerInfo.fromJson(json['buyer'] as Map<String, dynamic>),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentProofImageUrl: json['paymentProofImageUrl'] as String?,
      orderedAt: DateTime.parse(json['orderedAt'] as String),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      sellerNote: json['sellerNote'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  // Converts the Order object to JSON for API or database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing': listing.toJson(),
      'buyer': buyer.toJson(),
      'paymentMethod': paymentMethod.name,
      'paymentProofImageUrl': paymentProofImageUrl,
      'orderedAt': orderedAt.toIso8601String(),
      'status': status.name,
      'sellerNote': sellerNote,
      'rejectionReason': rejectionReason,
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }
}
