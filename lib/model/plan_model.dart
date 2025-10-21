import 'package:flutter/material.dart';

class PlanModel {
  final String name;
  final String description;
  final String price;
  final String period;
  final Color titleColor;   // For plan title color
  final bool isPopular;     // For "Most Popular" badge
  final bool isBestValue;   // For best value plan styling

  PlanModel({
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    this.titleColor = Colors.black,
    this.isPopular = false,
    this.isBestValue = false,
  });
}
