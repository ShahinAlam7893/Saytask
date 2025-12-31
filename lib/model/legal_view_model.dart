// viewmodel/legal_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:saytask/repository/legal_service.dart';

class LegalViewModel extends ChangeNotifier {
  final LegalService _service = LegalService();

  String termsContent = "";
  String privacyContent = "";
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadLegalContent() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getTerms(),
        _service.getPrivacyPolicy(),
      ]);

      termsContent = results[0] as String;
      privacyContent = results[1] as String;
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print("Legal load error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}