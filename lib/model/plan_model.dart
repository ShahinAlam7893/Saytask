class PlanModel {
  final String name;
  final String description;
  final String price;
  final String period;
  final bool isPopular;

  PlanModel({
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    this.isPopular = false,
  });
}
