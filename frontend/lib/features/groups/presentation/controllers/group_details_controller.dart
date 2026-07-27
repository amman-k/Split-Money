import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/groups/data/group_repository.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';
import 'package:split_frontend/features/groups/domain/expense_model.dart';
import 'package:split_frontend/features/groups/domain/balances_model.dart';

class GroupDetailsState {
  const GroupDetailsState({
    required this.group,
    required this.expenses,
    required this.balances,
  });

  final GroupModel group;
  final List<ExpenseModel> expenses;
  final BalancesModel balances;
}

final groupDetailsControllerProvider = FutureProvider.autoDispose
    .family<GroupDetailsState, String>((ref, groupId) async {
      final repository = ref.read(groupRepositoryProvider);

      // Fetch all required data concurrently
      final results = await Future.wait([
        repository.getGroupDetails(groupId),
        repository.getGroupExpenses(groupId),
        repository.getGroupBalances(groupId),
      ]);

      return GroupDetailsState(
        group: results[0] as GroupModel,
        expenses: results[1] as List<ExpenseModel>,
        balances: results[2] as BalancesModel,
      );
    });
