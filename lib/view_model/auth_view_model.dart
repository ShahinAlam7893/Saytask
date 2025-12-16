import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:saytask/core/jwt_helper.dart';
import 'package:saytask/model/user_model.dart';
import 'package:saytask/repository/auth_repository.dart';
import 'package:saytask/repository/notification_service.dart';
import 'package:saytask/service/local_storage_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  UserModel? currentUser;
  String? _accessToken;

  String? resetEmailToken;
  String? verifiedResetToken;

  bool isLoading = false;

  bool isUpdatingProfile = false;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;
  String? _changePasswordError;
  String? get changePasswordError => _changePasswordError;

  bool get isLoggedIn {
    final token = _accessToken ?? LocalStorageService.token;
    if (token == null) return false;
    return !_isTokenExpired(token);
  }

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

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _repository.login(email, password);

      final token = LocalStorageService.token;
      if (token != null) {
        _accessToken = token;
        currentUser = user;
        await NotificationService.sendFcmTokenToBackend();
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

  Future<bool> updateProfile(UserModel updatedUser) async {
    isUpdatingProfile = true;
    notifyListeners();

    try {
      await _repository.updateProfile(updatedUser);
      currentUser = updatedUser;
      notifyListeners();

      return true;
    } catch (e) {
      if (kDebugMode) print('Update profile error: $e');
      return false;
    } finally {
      isUpdatingProfile = false;
      notifyListeners();
    }
  }

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();



  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Google Sign-In cancelled by user.");
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final String? idToken = await userCredential.user?.getIdToken();

      print("🔥 Google Firebase ID Token: $idToken");

      // send to your backend
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      return;
    }
  }

  Future<void> googleSignOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> appleLogin() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      oauthCredential,
    );

    print(credential.identityToken);
  }
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isChangingPassword = true;
    _changePasswordError = null;
    notifyListeners();

    debugPrint("AuthViewModel.changePassword() → Starting...");

    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      debugPrint("AuthViewModel → Password changed successfully!");
      return true;
    } catch (e) {
      _changePasswordError = e.toString().replaceFirst('Exception: ', '');
      debugPrint("AuthViewModel → Error: $_changePasswordError");
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }
}
