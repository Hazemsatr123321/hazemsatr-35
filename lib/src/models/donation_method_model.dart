class DonationMethod {
  final String id;
  final String methodName;
  final String accountDetails;
  final String? instructions;
  final bool isActive;

  DonationMethod({
    required this.id,
    required this.methodName,
    required this.accountDetails,
    this.instructions,
    required this.isActive,
  });

  factory DonationMethod.fromJson(Map<String, dynamic> json) {
    return DonationMethod(
      id: json['id'],
      methodName: json['method_name'],
      accountDetails: json['account_details'],
      instructions: json['instructions'],
      isActive: json['is_active'],
    );
  }
}
