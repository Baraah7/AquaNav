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

  // Seller information from backend JSON
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

  // Convert Seller information to JSON for storage or API calls
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