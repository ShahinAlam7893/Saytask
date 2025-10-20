import 'package:flutter/material.dart';
import '../../model/plan_model.dart';

class PlanViewModel extends ChangeNotifier {
  bool isMonthly = true;
  int selectedIndex = 0;

  List<PlanModel> get plans => isMonthly ? monthlyPlans : yearlyPlans;

  final List<PlanModel> monthlyPlans = [
    PlanModel(
      name: "Free",
      description: "14 tasks/week",
      price: "\$0.00/Monthly",
      period: "Monthly",
    ),
    PlanModel(
      name: "Premium",
      description: "56 tasks/week",
      price: "\$x.xx/Monthly",
      period: "Monthly",
    ),
    PlanModel(
      name: "Unlimited",
      description: "Unlimited tasks/week",
      price: "\$xx.xx/Monthly",
      period: "Monthly",
    ),
  ];

  final List<PlanModel> yearlyPlans = [
    PlanModel(
      name: "Free",
      description: "14 tasks/week",
      price: "\$0.00",
      period: "yearly",
    ),
    PlanModel(
      name: "Premium",
      description: "56 tasks/week",
      price: "\$xx.xx",
      period: "yearly",
    ),
    PlanModel(
      name: "Unlimited",
      description: "Unlimited tasks/week",
      price: "\$xx.xx",
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
