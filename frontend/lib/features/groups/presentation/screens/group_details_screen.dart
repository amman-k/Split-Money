import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';
import 'package:split_frontend/features/groups/presentation/widgets/group_balance_card.dart';
import 'package:split_frontend/features/expenses/presentation/widgets/expense_list_tile.dart';
import 'package:split_frontend/shared/widgets/section_header.dart';
import 'package:split_frontend/features/groups/presentation/widgets/participant_card.dart';
import 'package:split_frontend/features/groups/presentation/controllers/group_details_controller.dart';
import 'package:split_frontend/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:split_frontend/features/groups/presentation/screens/group_expenses_screen.dart';
import 'package:split_frontend/features/groups/presentation/screens/settle_up_screen.dart';
import 'package:split_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:split_frontend/features/groups/presentation/screens/add_members_screen.dart';
import 'package:split_frontend/features/groups/presentation/controllers/delete_group_controller.dart';
import 'package:intl/intl.dart';

class GroupDetailsScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final asyncState = ref.watch(groupDetailsControllerProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: asyncState.maybeWhen(
          data: (state) => Text(
            state.group.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          orElse: () => const Text(''),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'add_members') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMembersScreen(groupId: groupId),
                  ),
                );
              } else if (value == 'delete_group') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Group'),
                    content: const Text(
                      'Are you sure you want to delete this group? All expenses will be lost.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final success = await ref
                      .read(deleteGroupControllerProvider.notifier)
                      .deleteGroup(groupId);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Group deleted successfully'),
                      ),
                    );
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } else if (context.mounted) {
                    final error = ref.read(deleteGroupControllerProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error?.toString() ?? 'Failed to delete group',
                        ),
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_members',
                child: Text('Add Members'),
              ),
              const PopupMenuItem(
                value: 'delete_group',
                child: Text(
                  'Delete Group',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load group: $error'),
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
          final balances = state.balances;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.sm),
                    GroupBalanceCard(
                      userBalance: balances.userBalance,
                      totalGroupBalance: balances.totalGroupBalance,
                      onAddExpense: () {
                        final currentUserId =
                            ref.read(authControllerProvider).value?.user.id ??
                            "";
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddExpenseScreen(
                              group: group,
                              currentUserId: currentUserId,
                            ),
                          ),
                        );
                      },
                      onSettleUp: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SettleUpScreen(groupId: group.id),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: l10n.recentExpenses,
                      actionLabel: expenses.isNotEmpty ? l10n.viewAll : null,
                      onActionPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GroupExpensesScreen(groupId: group.id),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (expenses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: Text('No expenses yet. Add one!')),
                      )
                    else
                      ...expenses.take(3).map((expense) {
                        return GestureDetector(
                          onTap: () {
                            final currentUserId =
                                ref
                                    .read(authControllerProvider)
                                    .value
                                    ?.user
                                    .id ??
                                "";
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
                        );
                      }),

                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      title: l10n.participantsCount(group.members.length),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 3.5,
                  ),
                  delegate: SliverChildListDelegate(
                    group.members.map((member) {
                      return ParticipantCard(name: member.name);
                    }).toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          );
        },
      ),
    );
  }
}
