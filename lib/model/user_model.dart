
class UserModel {
  final String userId;
  final String fullName;
  final String email;

  final String? gender;
  final String? dateOfBirth; 
  final String? country;
  final String? phoneNumber;
  final bool notificationsEnabled;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.gender,
    this.dateOfBirth,
    this.country,
    this.phoneNumber,
    this.notificationsEnabled = true,
  });

  factory UserModel.fromJwt(Map<String, dynamic> decoded) {
    return UserModel(
      userId: decoded['user_id']?.toString() ?? '',
      fullName: decoded['full_name'] ?? decoded['fullName'] ?? '',
      email: decoded['email'] ?? '',
      gender: decoded['gender'],
      dateOfBirth: decoded['birth_date'] ?? decoded['date_of_birth'],
      country: decoded['country'],
      phoneNumber: decoded['phone_number'],
      notificationsEnabled: decoded['notifications_enabled'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "first_name": fullName,
      "gender": gender,
      "birth_date": dateOfBirth,
      "country": country,
      "notifications_enabled": notificationsEnabled.toString(),
      "phone_number": phoneNumber,
    };
  }

  UserModel copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? country,
    String? phoneNumber,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}