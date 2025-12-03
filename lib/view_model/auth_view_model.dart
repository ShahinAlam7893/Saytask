import 'package:flutter/foundation.dart';
import 'package:saytask/core/jwt_helper.dart';
import 'package:saytask/model/user_model.dart';
import 'package:saytask/repository/auth_repository.dart';
import 'package:saytask/service/local_storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  UserModel? currentUser;
  String? _accessToken;

  // 🔥 Forgot Password Tokens
  String? resetEmailToken; // After sending email
  String? verifiedResetToken; // After OTP verification

  bool isLoading = false;

  // ---------------------------
  //  LOGIN STATUS
  // ---------------------------
  bool get isLoggedIn {
    final token = _accessToken ?? LocalStorageService.token;
    if (token == null) return false;
    return !_isTokenExpired(token);
  }

  // ---------------------------
  //  LOAD USER FROM STORED TOKEN
  // ---------------------------
  Future<void> loadUserFromStoredToken() async {
    final token = LocalStorageService.token;
    if (token == null) {
      _accessToken = null;
      currentUser = null;
      notifyListeners();
      return;
    }

    try {
      final decoded = JwtHelper.decode(token);
      currentUser = UserModel.fromJwt(decoded);
      _accessToken = token;
      notifyListeners();
    } catch (e) {
      await logout();
    }
  }

  // ---------------------------
  //  REGISTER
  // ---------------------------
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      final token = LocalStorageService.token;
      if (token != null) {
        _accessToken = token;
        currentUser = user;
        notifyListeners();
        return true;
      }

      currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------
  //  LOGIN
  // ---------------------------
  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _repository.login(email, password);

      final token = LocalStorageService.token;
      if (token != null) {
        _accessToken = token;
        currentUser = user;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) print('Auth login error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------
  //  LOGOUT
  // ---------------------------
  Future<void> logout() async {
    await _repository.logout();
    await LocalStorageService.clear();
    _accessToken = null;
    currentUser = null;
    notifyListeners();
  }

  String? get accessToken => _accessToken ?? LocalStorageService.token;

  bool _isTokenExpired(String token) {
    try {
      final decoded = JwtHelper.decode(token);
      if (decoded.containsKey('exp')) {
        final expInt = decoded['exp'] is int
            ? decoded['exp']
            : int.tryParse(decoded['exp'].toString());

        if (expInt != null) {
          final expiry = DateTime.fromMillisecondsSinceEpoch(
            expInt * 1000,
            isUtc: true,
          );
          return expiry.isBefore(DateTime.now().toUtc());
        }
      }
    } catch (e) {
      if (kDebugMode) print('Token expiry check error: $e');
      return true;
    }
    return false;
  }

  // ====================================================
  // 🔥🔥🔥 FORGOT PASSWORD LOGIC
  // ====================================================

  /// 1️⃣ SEND OTP TO EMAIL
  Future<bool> forgotPassword(String email) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.forgotPassword(email);

      resetEmailToken = response["reset_token"];
      notifyListeners();

      return true;
    } catch (e) {
      if (kDebugMode) print("Forgot Password error: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 2️⃣ VERIFY OTP
  Future<bool> verifyResetOtp(String otp, String token) async {
    if (resetEmailToken == null) return false;

    isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.verifyResetOtp(
        token: resetEmailToken!,
        otp: otp,
      );

      verifiedResetToken = response["reset_token"];
      notifyListeners();

      return true;
    } catch (e) {
      if (kDebugMode) print("Verify OTP error: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 3️⃣ SET NEW PASSWORD
  Future<bool> setNewPassword(String newPassword) async {
    if (verifiedResetToken == null) return false;

    isLoading = true;
    notifyListeners();

    try {
      await _repository.setNewPassword(
        token: verifiedResetToken!,
        newPassword: newPassword,
      );

      return true;
    } catch (e) {
      if (kDebugMode) print("Set New Password error: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 4️⃣ RESEND OTP
  Future<bool> resendOtp(String email) async {
    if (resetEmailToken == null) return false;

    try {
      final response = await _repository.resendOtp(resetEmailToken!);
      resetEmailToken = response["reset_token"];
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Resend OTP error: $e');
      return false;
    }
  }
}
