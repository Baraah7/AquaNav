class BuyerInfo {
  final String id;
  final String name;
  final String phone;
  final String? location;

  BuyerInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.location,
  });

  factory BuyerInfo.fromJson(Map<String, dynamic> json) {
    return BuyerInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'location': location,
    };
  }
}