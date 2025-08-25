class PaymentMethod {
  final int id;
  final DateTime createdAt;
  final String methodName;
  final String accountDetails;
  final String? instructions;
  final bool isActive;

  PaymentMethod({
    required this.id,
    required this.createdAt,
    required this.methodName,
    required this.accountDetails,
    this.instructions,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      methodName: json['method_name'],
      accountDetails: json['account_details'],
      instructions: json['instructions'],
      isActive: json['is_active'],
    );
  }
}
