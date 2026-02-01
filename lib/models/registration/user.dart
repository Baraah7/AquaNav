class User {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? userName;
  final String? password;
  final bool isGuest;
  final String? phone;
  final String? location;
  final double sellerRating;
  final int totalSales;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.userName,
    required this.password,
    this.isGuest = false,
    this.phone,
    this.location,
    this.sellerRating = 0.0,
    this.totalSales = 0,
  });

  /// Creates a guest user with only an id
  User.guest({required this.id})
      : email = null,
        firstName = null,
        lastName = null,
        userName = null,
        password = null,
        isGuest = true,
        phone = null,
        location = null,
        sellerRating = 0.0,
        totalSales = 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_name': userName,
      'is_guest': isGuest,
      'phone': phone,
      'location': location,
      'seller_rating': sellerRating,
      'total_sales': totalSales,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    final isGuest = map['is_guest'] ?? false;

    if (isGuest) {
      return User.guest(id: map['id']);
    }

    return User(
      id: map['id'],
      email: map['email'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      userName: map['user_name'],
      password: null,
      isGuest: false,
      phone: map['phone'],
      location: map['location'],
      sellerRating: (map['seller_rating'] ?? 0.0).toDouble(),
      totalSales: map['total_sales'] ?? 0,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? userName,
    String? password,
    bool? isGuest,
    String? phone,
    String? location,
    double? sellerRating,
    int? totalSales,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userName: userName ?? this.userName,
      password: password ?? this.password,
      isGuest: isGuest ?? this.isGuest,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      sellerRating: sellerRating ?? this.sellerRating,
      totalSales: totalSales ?? this.totalSales,
    );
  }
}