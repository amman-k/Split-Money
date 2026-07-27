import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/expenses/data/expense_repository.dart';
import 'package:split_frontend/features/expenses/domain/expense_models.dart';

final settleUpControllerProvider = FutureProvider.autoDispose
    .family<List<SettlementModel>, String>((ref, groupId) async {
      final repository = ref.read(expenseRepositoryProvider);
      return await repository.getSettlements(groupId);
    });
