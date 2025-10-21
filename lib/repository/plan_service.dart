import 'package:flutter/material.dart';
import '../../model/plan_model.dart';

class PlanViewModel extends ChangeNotifier {
  bool isMonthly = false; // Default to Annual
  int selectedIndex = 0;

  // Getter to fetch the correct plans based on toggle
  List<PlanModel> get plans => isMonthly ? monthlyPlans : yearlyPlans;

  // Monthly Plans
  final List<PlanModel> monthlyPlans = [
    PlanModel(
      name: "Free",
      description:
      "14 events & reminders per week\n3 personal notes per week\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nNo credit card required",
      price: "\$0.00",
      period: "/Monthly",
      titleColor: Colors.black,
      isPopular: false,
      isBestValue: false,
    ),
    PlanModel(
      name: "Premium",
      description:
      "56 events & reminders per week\n20 personal notes per week\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nCancel anytime",
      price: "\$8.99",
      period: "/Monthly",
      titleColor: const Color(0xFF00A86B),
      isPopular: true,
      isBestValue: false,
    ),
    PlanModel(
      name: "Unlimited",
      description:
      "Unlimited events & reminders\nUnlimited personal notes\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nCancel anytime",
      price: "\$19.99",
      period: "/Monthly",
      titleColor: const Color(0xFFFF9800),
      isPopular: false,
      isBestValue: true,
    ),
  ];

  // Yearly Plans
  final List<PlanModel> yearlyPlans = [
    PlanModel(
      name: "Free",
      description:
      "14 events & reminders per week\n3 personal notes per week\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nNo credit card required",
      price: "\$0.00",
      period: "/Annually",
      titleColor: Colors.black,
      isPopular: false,
      isBestValue: false,
    ),
    PlanModel(
      name: "Premium",
      description:
      "56 events & reminders per week\n20 personal notes per week\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nCancel anytime",
      price: "\$6.99",
      period: "/Annually",
      titleColor: const Color(0xFF00A86B),
      isPopular: true,
      isBestValue: false,
    ),
    PlanModel(
      name: "Unlimited",
      description:
      "Unlimited events & reminders\nUnlimited personal notes\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nCancel anytime",
      price: "\$14.99",
      period: "/Annually",
      titleColor: const Color(0xFFFF9800),
      isPopular: false,
      isBestValue: true,
    ),
  ];

  // Toggle Monthly/Annual
  void togglePlanType(bool monthly) {
    isMonthly = monthly;
    selectedIndex = 0; // Reset selection on toggle
    notifyListeners();
  }

  // Select a specific plan card
  void selectPlan(int index) {
    selectedIndex = index;
    notifyListeners();
  }
}
