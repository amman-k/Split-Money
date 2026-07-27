class ExpenseSplitModel {
  const ExpenseSplitModel({required this.memberId, required this.amount});

  final String memberId;
  final double amount;

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitModel(
      memberId: json['member_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'member_id': memberId, 'amount': amount};
}

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidById,
    required this.paidByName,
    required this.date,
    required this.userAmount,
    this.splits = const [],
  });

  final String id;
  final String title;
  final double amount;
  final String paidById;
  final String paidByName;
  final DateTime date;
  final double userAmount;
  final List<ExpenseSplitModel> splits;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final paidBy = json['paid_by'] as Map<String, dynamic>? ?? {};
    final splitsJson = json['splits'] as List<dynamic>? ?? [];

    return ExpenseModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidById: paidBy['id'] as String? ?? '',
      paidByName: paidBy['name'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userAmount: (json['user_amount'] as num?)?.toDouble() ?? 0.0,
      splits: splitsJson
          .map((e) => ExpenseSplitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'paid_by': {'id': paidById, 'name': paidByName},
    'date': date.toIso8601String(),
    'user_amount': userAmount,
    'splits': splits.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          amount == other.amount &&
          paidById == other.paidById &&
          paidByName == other.paidByName &&
          date == other.date &&
          userAmount == other.userAmount;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      amount.hashCode ^
      paidById.hashCode ^
      paidByName.hashCode ^
      date.hashCode ^
      userAmount.hashCode;
}
