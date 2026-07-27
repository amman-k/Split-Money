import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';
import 'package:split_frontend/features/expenses/presentation/widgets/expense_list_tile.dart';
import 'package:split_frontend/features/groups/presentation/controllers/group_details_controller.dart';
import 'package:split_frontend/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:split_frontend/features/auth/presentation/controllers/auth_controller.dart';

class GroupExpensesScreen extends ConsumerWidget {
  final String groupId;

  const GroupExpensesScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final asyncState = ref.watch(groupDetailsControllerProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.allExpenses,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load expenses: $error'),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(groupDetailsControllerProvider(groupId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) {
          final group = state.group;
          final expenses = state.expenses;

          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses yet. Add one!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () {
                    final currentUserId =
                        ref.read(authControllerProvider).value?.user.id ?? "";
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExpenseScreen(
                          group: group,
                          currentUserId: currentUserId,
                          expenseId: expense.id,
                        ),
                      ),
                    );
                  },
                  child: ExpenseListTile(
                    icon: Icons.receipt_long_outlined,
                    title: expense.title,
                    payerName: expense.paidByName,
                    amountPaid: expense.amount,
                    date: DateFormat.MMMd().format(expense.date),
                    userAmount: expense.userAmount,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
