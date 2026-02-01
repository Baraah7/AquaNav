import 'package:cloud_firestore/cloud_firestore.dart';

enum FishType {
  hamour,
  shaari,
  safi,
  kingfish,
  shrimp,
  crab,
  other;

  String get displayName {
    switch (this) {
      case FishType.hamour:
        return 'Hamour (Grouper)';
      case FishType.shaari:
        return 'Shaari (Emperor)';
      case FishType.safi:
        return 'Safi (Rabbitfish)';
      case FishType.kingfish:
        return 'Kingfish';
      case FishType.shrimp:
        return 'Shrimp';
      case FishType.crab:
        return 'Crab';
      case FishType.other:
        return 'Other';
    }
  }

  String get arabicName {
    switch (this) {
      case FishType.hamour:
        return 'هامور';
      case FishType.shaari:
        return 'شعري';
      case FishType.safi:
        return 'صافي';
      case FishType.kingfish:
        return 'كنعد';
      case FishType.shrimp:
        return 'ربيان';
      case FishType.crab:
        return 'قبقب';
      case FishType.other:
        return 'أخرى';
    }
  }
}

enum FishCondition {
  fresh,
  frozen,
  cleaned,
  filleted;

  String get displayName {
    switch (this) {
      case FishCondition.fresh:
        return 'Fresh';
      case FishCondition.frozen:
        return 'Frozen';
      case FishCondition.cleaned:
        return 'Cleaned';
      case FishCondition.filleted:
        return 'Filleted';
    }
  }
}

enum PaymentMethod {
  cash,
  benefitPay;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.benefitPay:
        return 'Benefit Pay';
    }
  }
}

enum ListingStatus {
  available,
  reserved,
  sold;

  String get displayName {
    switch (this) {
      case ListingStatus.available:
        return 'Available';
      case ListingStatus.reserved:
        return 'Reserved';
      case ListingStatus.sold:
        return 'Sold';
    }
  }
}

class FishListing {
  final String id;
  final FishType fishType;
  final String? customFishName;
  final double weight;
  final double pricePerKg;
  final FishCondition condition;
  final List<PaymentMethod> acceptedPayments;
  final String? description;
  final List<String> imageUrls;
  final String? benefitPayImageUrl;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String? sellerLocation;
  final DateTime listedAt;
  final ListingStatus status;
  final String? catchLocation;
  final DateTime? catchDate;

  FishListing({
    required this.id,
    required this.fishType,
    this.customFishName,
    required this.weight,
    required this.pricePerKg,
    required this.condition,
    required this.acceptedPayments,
    this.description,
    this.imageUrls = const [],
    this.benefitPayImageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    this.sellerLocation,
    required this.listedAt,
    this.status = ListingStatus.available,
    this.catchLocation,
    this.catchDate,
  });

  String? get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  double get totalPrice => weight * pricePerKg;

  String get displayName =>
      fishType == FishType.other && customFishName != null
          ? customFishName!
          : fishType.displayName;

  /// Creates a FishListing from a Firestore document
  factory FishListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FishListing(
      id: doc.id,
      fishType: FishType.values.firstWhere(
        (e) => e.name == data['fishType'],
        orElse: () => FishType.other,
      ),
      customFishName: data['customFishName'] as String?,
      weight: (data['weight'] as num).toDouble(),
      pricePerKg: (data['pricePerKg'] as num).toDouble(),
      condition: FishCondition.values.firstWhere(
        (e) => e.name == data['condition'],
        orElse: () => FishCondition.fresh,
      ),
      acceptedPayments: (data['acceptedPayments'] as List<dynamic>)
          .map((e) => PaymentMethod.values.firstWhere(
                (p) => p.name == e,
                orElse: () => PaymentMethod.cash,
              ))
          .toList(),
      description: data['description'] as String?,
      imageUrls: (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      benefitPayImageUrl: data['benefitPayImageUrl'] as String?,
      sellerId: data['sellerId'] as String,
      sellerName: data['sellerName'] as String,
      sellerPhone: data['sellerPhone'] as String,
      sellerLocation: data['sellerLocation'] as String?,
      listedAt: (data['listedAt'] as Timestamp).toDate(),
      status: ListingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ListingStatus.available,
      ),
      catchLocation: data['catchLocation'] as String?,
      catchDate: data['catchDate'] != null
          ? (data['catchDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts this FishListing to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fishType': fishType.name,
      'customFishName': customFishName,
      'weight': weight,
      'pricePerKg': pricePerKg,
      'condition': condition.name,
      'acceptedPayments': acceptedPayments.map((e) => e.name).toList(),
      'description': description,
      'imageUrls': imageUrls,
      'benefitPayImageUrl': benefitPayImageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'sellerLocation': sellerLocation,
      'listedAt': Timestamp.fromDate(listedAt),
      'status': status.name,
      'catchLocation': catchLocation,
      'catchDate': catchDate != null ? Timestamp.fromDate(catchDate!) : null,
    };
  }

  FishListing copyWith({
    String? id,
    FishType? fishType,
    String? customFishName,
    double? weight,
    double? pricePerKg,
    FishCondition? condition,
    List<PaymentMethod>? acceptedPayments,
    String? description,
    List<String>? imageUrls,
    String? benefitPayImageUrl,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerLocation,
    DateTime? listedAt,
    ListingStatus? status,
    String? catchLocation,
    DateTime? catchDate,
  }) {
    return FishListing(
      id: id ?? this.id,
      fishType: fishType ?? this.fishType,
      customFishName: customFishName ?? this.customFishName,
      weight: weight ?? this.weight,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      condition: condition ?? this.condition,
      acceptedPayments: acceptedPayments ?? this.acceptedPayments,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      benefitPayImageUrl: benefitPayImageUrl ?? this.benefitPayImageUrl,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerLocation: sellerLocation ?? this.sellerLocation,
      listedAt: listedAt ?? this.listedAt,
      status: status ?? this.status,
      catchLocation: catchLocation ?? this.catchLocation,
      catchDate: catchDate ?? this.catchDate,
    );
  }
}
