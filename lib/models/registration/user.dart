class User {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? userName;
  final String? password;
  final bool isGuest;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.userName,
    required this.password,
    this.isGuest = false,
  });

  /// Creates a guest user with only an id
  User.guest({required this.id})
      : email = null,
        firstName = null,
        lastName = null,
        userName = null,
        password = null,
        isGuest = true;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
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
      firstName: map['first_name'],
      lastName: map['last_name'],
      userName: map['user_name'],
      password: null,
      isGuest: false,
    );
  }
}