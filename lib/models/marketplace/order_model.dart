import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'fish_listing_model.dart';

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

class Order {
  final String id;
  final String listingId;
  final String sellerId;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String? buyerLocation;
  final PaymentMethod paymentMethod;
  final String? paymentProofImageUrl;
  final DateTime orderedAt;
  final OrderStatus status;
  final String? sellerNote;
  final String? rejectionReason;
  final DateTime? respondedAt;

  Order({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerLocation,
    required this.paymentMethod,
    this.paymentProofImageUrl,
    required this.orderedAt,
    this.status = OrderStatus.pending,
    this.sellerNote,
    this.rejectionReason,
    this.respondedAt,
  });

  /// Creates an Order from a Firestore document
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      listingId: data['listingId'] as String,
      sellerId: data['sellerId'] as String,
      buyerId: data['buyerId'] as String,
      buyerName: data['buyerName'] as String,
      buyerPhone: data['buyerPhone'] as String,
      buyerLocation: data['buyerLocation'] as String?,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == data['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentProofImageUrl: data['paymentProofImageUrl'] as String?,
      orderedAt: (data['orderedAt'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      sellerNote: data['sellerNote'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts this Order to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerLocation': buyerLocation,
      'paymentMethod': paymentMethod.name,
      'paymentProofImageUrl': paymentProofImageUrl,
      'orderedAt': Timestamp.fromDate(orderedAt),
      'status': status.name,
      'sellerNote': sellerNote,
      'rejectionReason': rejectionReason,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  Order copyWith({
    String? id,
    String? listingId,
    String? sellerId,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    String? buyerLocation,
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
      listingId: listingId ?? this.listingId,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerLocation: buyerLocation ?? this.buyerLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProofImageUrl: paymentProofImageUrl ?? this.paymentProofImageUrl,
      orderedAt: orderedAt ?? this.orderedAt,
      status: status ?? this.status,
      sellerNote: sellerNote ?? this.sellerNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
