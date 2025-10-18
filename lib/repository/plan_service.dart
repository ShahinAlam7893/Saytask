import 'package:flutter/material.dart';
import '../../model/plan_model.dart';

class PlanViewModel extends ChangeNotifier {
  bool isMonthly = true;
  int selectedIndex = 0;

  List<PlanModel> get plans => isMonthly ? monthlyPlans : yearlyPlans;

  final List<PlanModel> monthlyPlans = [
    PlanModel(
      name: "Free Plan",
      description: "14 tasks/week",
      price: "\$0.00/Monthly",
      period: "Monthly",
    ),
    PlanModel(
      name: "Premium Plan",
      description: "56 tasks/week",
      price: "\$9.99/Monthly",
      period: "Monthly",
    ),
  ];

  final List<PlanModel> yearlyPlans = [
    PlanModel(
      name: "Unlimited",
      description: "Unlimited tasks/week",
      price: "\$99.99/Yearly",
      period: "Yearly",
    ),
  ];

  void togglePlanType(bool monthly) {
    isMonthly = monthly;
    selectedIndex = 0;
    notifyListeners();
  }

  void selectPlan(int index) {
    selectedIndex = index;
    notifyListeners();
  }
}
