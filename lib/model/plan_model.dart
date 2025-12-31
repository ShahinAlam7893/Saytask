// model/plan_model.dart

class Plan {
  final String id;
  final String name;
  final double monthlyPrice;
  final double annualPrice;
  final String? currentPlan;

  Plan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.annualPrice,
    this.currentPlan,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      monthlyPrice: _parsePrice(json['monthly_price']),
      annualPrice: _parsePrice(json['annual_price']),
      currentPlan: json['current_plan'] as String?,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  @override
  String toString() {
    return 'Plan(id: $id, name: $name, monthly: $monthlyPrice, annual: $annualPrice, currentPlan: $currentPlan)';
  }
}