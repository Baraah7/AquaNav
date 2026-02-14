
import 'package:Bahaar/models/marketplace/listing_model.dart';
import 'package:Bahaar/models/marketplace/seller_information.dart';

// Represents a single fish listing in the marketplace
class FishListing {
  final String id;
  final FishType fishType;
  // Custom fish name (used only when fishType == FishType.other)
  final String? customFishName;
  // In kilograms
  final double weight;
  final double pricePerKg;
  // Condition of the fish (fresh, frozen, cleaned, filleted)
  final FishCondition condition;
  final List<PaymentMethod> acceptedPayments;
  final String? description;
  final List<String> imageUrls;
  final String? benefitPayImageUrl;
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
    this.imageUrls = const [],
    this.benefitPayImageUrl,
    required this.seller,
    required this.listedAt,
    this.status = ListingStatus.available,
    this.catchLocation,
    this.catchDate,
  });

  // Returns the first image to be used as a thumbnail
  String? get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  double get totalPrice => weight * pricePerKg;

  // Name shown in the UI - Uses custom name if fish type is "other"
  String get displayName =>
      fishType == FishType.other && customFishName != null
          ? customFishName!
          : fishType.displayName;

  // Creates a FishListing object from JSON data
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
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      benefitPayImageUrl: json['benefitPayImageUrl'] as String?,
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
  
  // Converts the FishListing object to JSON
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
      'imageUrls': imageUrls,
      'benefitPayImageUrl': benefitPayImageUrl,
      'seller': seller.toJson(),
      'listedAt': listedAt.toIso8601String(),
      'status': status.name,
      'catchLocation': catchLocation,
      'catchDate': catchDate?.toIso8601String(),
    };
  }
  
  // Creates a new FishListing with updated values
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
      imageUrls: imageUrls ?? this.imageUrls,
      benefitPayImageUrl: benefitPayImageUrl ?? this.benefitPayImageUrl,
      seller: seller ?? this.seller,
      listedAt: listedAt ?? this.listedAt,
      status: status ?? this.status,
      catchLocation: catchLocation ?? this.catchLocation,
      catchDate: catchDate ?? this.catchDate,
    );
  }
}