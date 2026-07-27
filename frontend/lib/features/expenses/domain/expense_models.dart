class ExpenseSplitInput {
  final String memberId;
  final double amount;

  const ExpenseSplitInput({required this.memberId, required this.amount});

  Map<String, dynamic> toJson() => {'member_id': memberId, 'amount': amount};
}

class ExpenseItemInput {
  final String name;
  final double amount;
  final List<String> members;

  const ExpenseItemInput({
    required this.name,
    required this.amount,
    this.members = const [],
  });

  ExpenseItemInput copyWith({
    String? name,
    double? amount,
    List<String>? members,
  }) {
    return ExpenseItemInput(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'members': members,
  };
}

class ExpensePaymentInput {
  final String memberId;
  final double amount;

  const ExpensePaymentInput({required this.memberId, required this.amount});

  Map<String, dynamic> toJson() => {'member_id': memberId, 'amount': amount};
}

class CreateExpenseRequest {
  final String title;
  final String description;
  final double amount;
  final String splitType;
  final double taxAmount;
  final double discountAmount;
  final Map<String, dynamic> metadata;
  final List<ExpensePaymentInput> payments;
  final List<ExpenseSplitInput> splits;
  final List<ExpenseItemInput> items;

  const CreateExpenseRequest({
    required this.title,
    required this.description,
    required this.amount,
    required this.splitType,
    required this.taxAmount,
    required this.discountAmount,
    this.metadata = const {},
    this.payments = const [],
    this.splits = const [],
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'amount': amount,
    'split_type': splitType,
    'tax_amount': taxAmount,
    'discount_amount': discountAmount,
    'metadata': metadata,
    'payments': payments.map((e) => e.toJson()).toList(),
    'splits': splits.map((e) => e.toJson()).toList(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class ExpenseDetailModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String splitType;
  final double taxAmount;
  final double discountAmount;
  final DateTime date;
  final Map<String, dynamic> metadata;
  final List<ExpensePaymentInput> payments;
  final List<ExpenseSplitInput> splits;
  final List<ExpenseItemInput> items;

  const ExpenseDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.splitType,
    required this.taxAmount,
    required this.discountAmount,
    required this.date,
    this.metadata = const {},
    this.payments = const [],
    this.splits = const [],
    this.items = const [],
  });

  factory ExpenseDetailModel.fromJson(Map<String, dynamic> json) {
    return ExpenseDetailModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      splitType: json['split_type'] as String? ?? 'EQUALLY',
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      payments:
          (json['payments'] as List<dynamic>?)
              ?.map(
                (e) => ExpensePaymentInput(
                  memberId: e['member_id'] as String? ?? '',
                  amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
                ),
              )
              .toList() ??
          [],
      splits:
          (json['splits'] as List<dynamic>?)
              ?.map(
                (e) => ExpenseSplitInput(
                  memberId: e['member_id'] as String? ?? '',
                  amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
                ),
              )
              .toList() ??
          [],
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => ExpenseItemInput(
                  name: e['name'] as String? ?? '',
                  amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
                  members:
                      (e['members'] as List<dynamic>?)
                          ?.map((m) => m as String)
                          .toList() ??
                      [],
                ),
              )
              .toList() ??
          [],
    );
  }
}

class SettlementModel {
  final String fromMemberId;
  final String fromMemberName;
  final String toMemberId;
  final String toMemberName;
  final double amount;

  const SettlementModel({
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amount,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      fromMemberId: json['from_member_id'] as String? ?? '',
      fromMemberName: json['from_member_name'] as String? ?? '',
      toMemberId: json['to_member_id'] as String? ?? '',
      toMemberName: json['to_member_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
