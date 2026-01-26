class User {
  final String id;
  final String? email;
  final String? userName;
  final String? password;
  final bool isGuest;

  User({
    required this.id,
    required this.email,
    required this.userName,
    required this.password,
    this.isGuest = false,
  });

  /// Creates a guest user with only an id
  User.guest({required this.id})
      : email = null,
        userName = null,
        password = null,
        isGuest = true;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'user_name': userName,
      'is_guest': isGuest,
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
      userName: map['user_name'],
      password: null,
      isGuest: false,
    );
  }
}