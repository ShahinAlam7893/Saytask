// lib/model/user_model.dart
class UserModel {
  final String userId;
  final String fullName;
  final String email;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
  });

  factory UserModel.fromJwt(Map<String, dynamic> decoded) {
    return UserModel(
      userId: decoded['user_id']?.toString() ?? decoded['id']?.toString() ?? '',
      fullName: decoded['full_name'] ?? decoded['fullName'] ?? decoded['name'] ?? '',
      email: decoded['email'] ?? '',
    );
  }
}
