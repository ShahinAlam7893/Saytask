import 'package:flutter/foundation.dart';
import 'package:saytask/model/plan_model.dart';
import 'package:saytask/repository/plan_repository.dart';


class PlanViewModel extends ChangeNotifier {
  final PlanService _repository = PlanService();

  List<Plan> plans = [];
  bool isLoading = false;
  String? errorMessage;

  bool isMonthly = true;

  void togglePlanType(bool monthly) {
    isMonthly = monthly;
    notifyListeners();
  }

  Future<void> loadPlans() async {
    try {
      isLoading = true;
      notifyListeners();

      plans = await _repository.getPlans();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<String?> createCheckout(String planId) async {
    try {
      final billingInterval = isMonthly ? "month" : "year";
      return await _repository.checkout(planId, billingInterval);
    } catch (e) {
      return null;
    }
  }

  double getPrice(Plan plan) {
    return isMonthly ? plan.monthlyPrice : plan.annualPrice/12;
  }
}
