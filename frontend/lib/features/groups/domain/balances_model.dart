class BalancesModel {
  const BalancesModel({
    required this.userBalance,
    required this.totalGroupBalance,
  });

  final double userBalance;
  final double totalGroupBalance;

  factory BalancesModel.fromJson(Map<String, dynamic> json) {
    return BalancesModel(
      userBalance: (json['user_balance'] as num?)?.toDouble() ?? 0.0,
      totalGroupBalance:
          (json['total_group_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_balance': userBalance,
    'total_group_balance': totalGroupBalance,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalancesModel &&
          runtimeType == other.runtimeType &&
          userBalance == other.userBalance &&
          totalGroupBalance == other.totalGroupBalance;

  @override
  int get hashCode => userBalance.hashCode ^ totalGroupBalance.hashCode;
}
