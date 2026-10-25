// ============================================================
// FIKAGO - USER MODEL
// ============================================================

class User {
  final int id;
  final String phoneNumber;
  final String fullName;
  final String? email;
  final String role;
  final String? profileImageUrl;
  final String languagePref;
  final bool isVerified;

  User({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.email,
    required this.role,
    this.profileImageUrl,
    this.languagePref = 'sw',
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'customer',
      profileImageUrl: json['profile_image_url'],
      languagePref: json['language_pref'] ?? 'sw',
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'email': email,
      'role': role,
      'profile_image_url': profileImageUrl,
      'language_pref': languagePref,
      'is_verified': isVerified,
    };
  }
}
