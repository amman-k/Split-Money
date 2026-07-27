import 'package:split_frontend/features/expenses/domain/expense_models.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/expenses/data/expense_repository.dart';

enum SplitMethod { equally, unequally, byItems }

class AddExpenseState {
  final String? expenseId;
  final String title;
  final String description;
  final double amount;
  final SplitMethod splitMethod;
  final double taxAmount;
  final double discountAmount;
  final List<GroupMemberModel> groupMembers;
  final String? paidById;
  final bool isMultiplePayers;
  final Map<String, double> multiplePayers;
  final bool isTreatEnabled;
  final Map<String, double> treatAmounts;
  final List<ExpenseItemInput> items;
  final Map<String, double> unequalSplits;
  final bool isSubmitting;
  final String? error;

  const AddExpenseState({
    this.expenseId,
    this.title = '',
    this.description = '',
    this.amount = 0.0,
    this.splitMethod = SplitMethod.equally,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.groupMembers = const [],
    this.paidById,
    this.isMultiplePayers = false,
    this.multiplePayers = const {},
    this.isTreatEnabled = false,
    this.treatAmounts = const {},
    this.items = const [],
    this.unequalSplits = const {},
    this.isSubmitting = false,
    this.error,
  });

  AddExpenseState copyWith({
    String? expenseId,
    String? title,
    String? description,
    double? amount,
    SplitMethod? splitMethod,
    double? taxAmount,
    double? discountAmount,
    List<GroupMemberModel>? groupMembers,
    String? paidById,
    bool? isMultiplePayers,
    Map<String, double>? multiplePayers,
    bool? isTreatEnabled,
    Map<String, double>? treatAmounts,
    List<ExpenseItemInput>? items,
    Map<String, double>? unequalSplits,
    bool? isSubmitting,
    String? error,
  }) {
    return AddExpenseState(
      expenseId: expenseId ?? this.expenseId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      splitMethod: splitMethod ?? this.splitMethod,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      groupMembers: groupMembers ?? this.groupMembers,
      paidById: paidById ?? this.paidById,
      isMultiplePayers: isMultiplePayers ?? this.isMultiplePayers,
      multiplePayers: multiplePayers ?? this.multiplePayers,
      isTreatEnabled: isTreatEnabled ?? this.isTreatEnabled,
      treatAmounts: treatAmounts ?? this.treatAmounts,
      items: items ?? this.items,
      unequalSplits: unequalSplits ?? this.unequalSplits,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error:
          error, // Error is cleared unless provided? Usually we just want to replace or clear it. We'll leave it as `error ?? this.error` but often we want `error: error`.
      // Actually the original had `error: error,` which means it clears error unless provided explicitly. Wait, let me check the original.
    );
  }
}

class AddExpenseNotifier extends Notifier<AddExpenseState> {
  @override
  AddExpenseState build() {
    return const AddExpenseState();
  }

  void setGroupMemberModels(
    List<GroupMemberModel> members,
    String currentUserId,
  ) {
    // Find the member ID corresponding to the current user.
    // The backend marks the logged-in user's member model with isOwner = true.
    String? currentMemberId;
    try {
      currentMemberId = members.firstWhere((m) => m.isOwner).id;
    } catch (_) {
      // If none found, fallback to the first member or leave null
      currentMemberId = members.isNotEmpty ? members.first.id : null;
    }

    state = state.copyWith(
      groupMembers: members,
      paidById: currentMemberId,
      isTreatEnabled: false,
      treatAmounts: currentMemberId != null ? {currentMemberId: 0.0} : {},
      multiplePayers: currentMemberId != null ? {currentMemberId: 0.0} : {},
    );
  }

  void initFromExpense(
    ExpenseDetailModel expense,
    List<GroupMemberModel> members,
    String currentUserId,
  ) {
    Map<String, double> multiplePayers = {};
    if (expense.payments.length > 1) {
      for (var p in expense.payments) {
        multiplePayers[p.memberId] = p.amount;
      }
    } else if (expense.payments.isNotEmpty) {
      multiplePayers[expense.payments.first.memberId] =
          expense.payments.first.amount;
    }

    Map<String, double> unequalSplits = {};
    if (expense.splitType == 'UNEQUALLY') {
      for (var s in expense.splits) {
        unequalSplits[s.memberId] = s.amount;
      }
    }

    Map<String, double> treatAmounts = {};
    if (expense.metadata.containsKey('treats')) {
      final t = expense.metadata['treats'] as Map<String, dynamic>;
      t.forEach((k, v) {
        treatAmounts[k] = (v as num).toDouble();
      });
    }

    SplitMethod sm = SplitMethod.equally;
    if (expense.splitType == 'UNEQUALLY') sm = SplitMethod.unequally;
    if (expense.splitType == 'BY_ITEMS') sm = SplitMethod.byItems;

    state = AddExpenseState(
      expenseId: expense.id,
      title: expense.title,
      description: expense.description,
      amount: expense.amount,
      splitMethod: sm,
      taxAmount: expense.taxAmount,
      discountAmount: expense.discountAmount,
      groupMembers: members,
      paidById: expense.payments.length == 1
          ? expense.payments.first.memberId
          : null,
      isMultiplePayers: expense.payments.length > 1,
      multiplePayers: multiplePayers,
      isTreatEnabled: treatAmounts.isNotEmpty,
      treatAmounts: treatAmounts,
      items: expense.items,
      unequalSplits: unequalSplits,
    );
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void updateAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setSplitMethod(SplitMethod method) {
    state = state.copyWith(splitMethod: method);
  }

  void setPaidBy(String memberId) {
    state = state.copyWith(paidById: memberId);
  }

  void setMultiplePayersEnabled(bool enabled) {
    state = state.copyWith(isMultiplePayers: enabled);
  }

  void updateMultiplePayer(String memberId, double amount) {
    final newPayers = Map<String, double>.from(state.multiplePayers);
    newPayers[memberId] = amount;
    state = state.copyWith(multiplePayers: newPayers);
  }

  void updateTax(double tax) {
    state = state.copyWith(taxAmount: tax);
  }

  void updateDiscount(double discount) {
    state = state.copyWith(discountAmount: discount);
  }

  void setTreatEnabled(bool enabled, String currentUserId) {
    state = state.copyWith(
      isTreatEnabled: enabled,
      treatAmounts: enabled ? state.treatAmounts : {},
    );
  }

  void updateTreatAmountForMember(String memberId, double amount) {
    final newTreats = Map<String, double>.from(state.treatAmounts);
    newTreats[memberId] = amount;
    state = state.copyWith(treatAmounts: newTreats);
  }

  void addItem(ExpenseItemInput item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(int index, ExpenseItemInput item) {
    final newItems = List<ExpenseItemInput>.from(state.items);
    newItems[index] = item;
    state = state.copyWith(items: newItems);
  }

  void removeItem(int index) {
    final newItems = List<ExpenseItemInput>.from(state.items);
    newItems.removeAt(index);
    state = state.copyWith(items: newItems);
  }

  void updateUnequalSplit(String memberId, double amount) {
    final newSplits = Map<String, double>.from(state.unequalSplits);
    newSplits[memberId] = amount;
    state = state.copyWith(unequalSplits: newSplits);
  }

  Future<bool> submitExpense(String groupId) async {
    if (state.title.trim().isEmpty) {
      state = state.copyWith(error: "Please enter an expense title.");
      return false;
    }
    if (state.amount <= 0) {
      state = state.copyWith(error: "Please enter a valid expense amount.");
      return false;
    }

    double effectiveAmountToSplit =
        state.amount + state.taxAmount - state.discountAmount;

    if (state.isMultiplePayers) {
      double totalPaid = state.multiplePayers.values.fold(0.0, (a, b) => a + b);
      if ((totalPaid - effectiveAmountToSplit).abs() > 0.01) {
        state = state.copyWith(
          error: "Total amount paid does not match the expense amount.",
        );
        return false;
      }
    } else {
      if (state.paidById == null) {
        state = state.copyWith(
          error: "Please select who paid for the expense.",
        );
        return false;
      }
    }

    double totalTreatAmount = state.isTreatEnabled
        ? state.treatAmounts.values.fold(0.0, (sum, val) => sum + val)
        : 0.0;

    if (state.isTreatEnabled) {
      if (totalTreatAmount <= 0) {
        state = state.copyWith(error: "Please enter a valid treat amount.");
        return false;
      }
      if (totalTreatAmount > effectiveAmountToSplit) {
        state = state.copyWith(
          error: "Treat amount cannot exceed the total expense amount.",
        );
        return false;
      }
    }

    if (state.splitMethod == SplitMethod.unequally) {
      double totalUnequal = state.unequalSplits.values.fold(
        0.0,
        (a, b) => a + b,
      );
      if ((totalUnequal - effectiveAmountToSplit).abs() > 0.01) {
        state = state.copyWith(
          error: "Entered unequal amounts do not sum up to the total amount.",
        );
        return false;
      }
    } else if (state.splitMethod == SplitMethod.byItems) {
      double totalItems = state.items.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );
      if (state.items.isEmpty) {
        state = state.copyWith(error: "Please add at least one item.");
        return false;
      }
      if ((totalItems - state.amount).abs() > 0.01) {
        state = state.copyWith(
          error: "Total item amounts do not match the total expense amount.",
        );
        return false;
      }
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final repository = ref.read(expenseRepositoryProvider);

      double effectiveAmountToSplit =
          state.amount + state.taxAmount - state.discountAmount;
      if (state.isTreatEnabled && totalTreatAmount > 0) {
        effectiveAmountToSplit -= totalTreatAmount;
      }

      List<ExpenseSplitInput> finalSplits = [];

      if (state.splitMethod == SplitMethod.equally) {
        int count = state.groupMembers.length;
        if (count > 0) {
          double perPerson = effectiveAmountToSplit / count;
          for (var m in state.groupMembers) {
            double amountOwed = perPerson;
            if (state.isTreatEnabled) {
              amountOwed += (state.treatAmounts[m.id] ?? 0.0);
            }
            finalSplits.add(
              ExpenseSplitInput(memberId: m.id, amount: amountOwed),
            );
          }
        }
      } else if (state.splitMethod == SplitMethod.unequally) {
        state.unequalSplits.forEach((key, value) {
          double amountOwed = value;
          if (state.isTreatEnabled) {
            amountOwed += (state.treatAmounts[key] ?? 0.0);
          }
          finalSplits.add(ExpenseSplitInput(memberId: key, amount: amountOwed));
        });
      } else if (state.splitMethod == SplitMethod.byItems) {
        Map<String, double> itemSplits = {};
        for (var item in state.items) {
          if (item.members.isNotEmpty) {
            double perPersonItem = item.amount / item.members.length;
            for (var m in item.members) {
              itemSplits[m] = (itemSplits[m] ?? 0.0) + perPersonItem;
            }
          }
        }

        double adjustments = state.taxAmount - state.discountAmount;
        double adjustmentPerPerson = state.groupMembers.isNotEmpty
            ? adjustments / state.groupMembers.length
            : 0.0;

        for (var m in state.groupMembers) {
          double itemAmount = itemSplits[m.id] ?? 0.0;
          double amountOwed = itemAmount + adjustmentPerPerson;
          if (state.isTreatEnabled) {
            amountOwed += (state.treatAmounts[m.id] ?? 0.0);
          }
          finalSplits.add(
            ExpenseSplitInput(memberId: m.id, amount: amountOwed),
          );
        }
      }

      List<ExpensePaymentInput> payments = [];
      if (state.isMultiplePayers) {
        state.multiplePayers.forEach((memberId, amount) {
          if (amount > 0) {
            payments.add(
              ExpensePaymentInput(memberId: memberId, amount: amount),
            );
          }
        });
      } else {
        payments.add(
          ExpensePaymentInput(
            memberId: state.paidById!,
            amount:
                state.amount +
                state.taxAmount -
                state.discountAmount, // effective total including treats
          ),
        );
      }

      final request = CreateExpenseRequest(
        title: state.title,
        description: state.description,
        amount: state.amount,
        splitType: state.splitMethod.name.toUpperCase(),
        taxAmount: state.taxAmount,
        discountAmount: state.discountAmount,
        payments: payments,
        splits: finalSplits,
        items: state.splitMethod == SplitMethod.byItems ? state.items : [],
        metadata: {"treats": state.treatAmounts},
      );

      if (state.expenseId != null) {
        await repository.updateExpense(groupId, state.expenseId!, request);
      } else {
        await repository.createExpense(groupId, request);
      }

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteExpense(String groupId) async {
    if (state.expenseId == null) return false;
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final repository = ref.read(expenseRepositoryProvider);
      await repository.deleteExpense(groupId, state.expenseId!);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final addExpenseProvider =
    NotifierProvider.autoDispose<AddExpenseNotifier, AddExpenseState>(() {
      return AddExpenseNotifier();
    });
