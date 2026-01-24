enum FishType {
  hamour,
  shaari,
  safi,
  suboor,
  chanad,
  kingfish,
  tuna,
  shrimp,
  crab,
  lobster,
  squid,
  other;

  String get displayName {
    switch (this) {
      case FishType.hamour:
        return 'Hamour (Grouper)';
      case FishType.shaari:
        return 'Shaari (Emperor)';
      case FishType.safi:
        return 'Safi (Rabbitfish)';
      case FishType.suboor:
        return 'Suboor (Shad)';
      case FishType.chanad:
        return 'Chanad (Mackerel)';
      case FishType.kingfish:
        return 'Kingfish';
      case FishType.tuna:
        return 'Tuna';
      case FishType.shrimp:
        return 'Shrimp';
      case FishType.crab:
        return 'Crab';
      case FishType.lobster:
        return 'Lobster';
      case FishType.squid:
        return 'Squid';
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
      case FishType.suboor:
        return 'صبور';
      case FishType.chanad:
        return 'چناد';
      case FishType.kingfish:
        return 'كنعد';
      case FishType.tuna:
        return 'تونة';
      case FishType.shrimp:
        return 'ربيان';
      case FishType.crab:
        return 'قبقب';
      case FishType.lobster:
        return 'استاكوزا';
      case FishType.squid:
        return 'حبار';
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

class SellerInfo {
  final String id;
  final String name;
  final String phone;
  final String? location;
  final double rating;
  final int totalSales;

  SellerInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.location,
    this.rating = 0.0,
    this.totalSales = 0,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      location: json['location'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalSales: json['totalSales'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'location': location,
      'rating': rating,
      'totalSales': totalSales,
    };
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
  final String? imageUrl;
  final SellerInfo seller;
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
    this.imageUrl,
    required this.seller,
    required this.listedAt,
    this.status = ListingStatus.available,
    this.catchLocation,
    this.catchDate,
  });

  double get totalPrice => weight * pricePerKg;

  String get displayName =>
      fishType == FishType.other && customFishName != null
          ? customFishName!
          : fishType.displayName;

  factory FishListing.fromJson(Map<String, dynamic> json) {
    return FishListing(
      id: json['id'] as String,
      fishType: FishType.values.firstWhere(
        (e) => e.name == json['fishType'],
        orElse: () => FishType.other,
      ),
      customFishName: json['customFishName'] as String?,
      weight: (json['weight'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      condition: FishCondition.values.firstWhere(
        (e) => e.name == json['condition'],
        orElse: () => FishCondition.fresh,
      ),
      acceptedPayments: (json['acceptedPayments'] as List<dynamic>)
          .map((e) => PaymentMethod.values.firstWhere(
                (p) => p.name == e,
                orElse: () => PaymentMethod.cash,
              ))
          .toList(),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      seller: SellerInfo.fromJson(json['seller'] as Map<String, dynamic>),
      listedAt: DateTime.parse(json['listedAt'] as String),
      status: ListingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ListingStatus.available,
      ),
      catchLocation: json['catchLocation'] as String?,
      catchDate: json['catchDate'] != null
          ? DateTime.parse(json['catchDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fishType': fishType.name,
      'customFishName': customFishName,
      'weight': weight,
      'pricePerKg': pricePerKg,
      'condition': condition.name,
      'acceptedPayments': acceptedPayments.map((e) => e.name).toList(),
      'description': description,
      'imageUrl': imageUrl,
      'seller': seller.toJson(),
      'listedAt': listedAt.toIso8601String(),
      'status': status.name,
      'catchLocation': catchLocation,
      'catchDate': catchDate?.toIso8601String(),
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
    String? imageUrl,
    SellerInfo? seller,
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
      imageUrl: imageUrl ?? this.imageUrl,
      seller: seller ?? this.seller,
      listedAt: listedAt ?? this.listedAt,
      status: status ?? this.status,
      catchLocation: catchLocation ?? this.catchLocation,
      catchDate: catchDate ?? this.catchDate,
    );
  }
}
