import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:split_frontend/features/expenses/presentation/providers/add_expense_provider.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';
import 'package:split_frontend/features/expenses/presentation/widgets/expense_split_method_selector.dart';
import 'package:split_frontend/features/expenses/presentation/widgets/expense_items_list.dart';
import 'package:split_frontend/features/expenses/presentation/widgets/expense_adjustments_card.dart';
import 'package:split_frontend/features/expenses/presentation/widgets/expense_treat_card.dart';
import 'package:split_frontend/features/expenses/presentation/widgets/expense_payers_card.dart';
import 'package:split_frontend/features/groups/presentation/controllers/group_details_controller.dart';
import 'package:split_frontend/features/expenses/data/expense_repository.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final GroupModel group;
  final String currentUserId;
  final String? expenseId;

  const AddExpenseScreen({
    super.key,
    required this.group,
    required this.currentUserId,
    this.expenseId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(addExpenseProvider.notifier)
          .setGroupMemberModels(widget.group.members, widget.currentUserId);

      if (widget.expenseId != null) {
        _loadExpenseDetails();
      }
    });
  }

  Future<void> _loadExpenseDetails() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(expenseRepositoryProvider);
      final details = await repository.getExpenseDetails(
        widget.group.id,
        widget.expenseId!,
      );
      ref
          .read(addExpenseProvider.notifier)
          .initFromExpense(details, widget.group.members, widget.currentUserId);
      _titleController.text = details.title;
      _amountController.text = details.amount > 0
          ? details.amount.toString()
          : '';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load expense: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    final success = await ref
        .read(addExpenseProvider.notifier)
        .submitExpense(widget.group.id);
    if (success) {
      if (!mounted) return;
      ref.invalidate(groupDetailsControllerProvider(widget.group.id));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addExpenseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.expenseId != null ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (widget.expenseId != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Expense'),
                          content: const Text(
                            'Are you sure you want to delete this expense? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final success = await ref
                            .read(addExpenseProvider.notifier)
                            .deleteExpense(widget.group.id);
                        if (success) {
                          if (!context.mounted) return;
                          ref.invalidate(
                            groupDetailsControllerProvider(widget.group.id),
                          );
                          context.pop();
                        }
                      }
                    },
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: state.isSubmitting || _isLoading ? null : _submit,
          ),
        ],
      ),
      body: state.isSubmitting || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),

                  // Title Input
                  TextField(
                    controller: _titleController,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Expense Title',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) =>
                        ref.read(addExpenseProvider.notifier).updateTitle(val),
                  ),
                  const SizedBox(height: 8),

                  // Description (Location)
                  TextField(
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Description (Optional)',
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => ref
                        .read(addExpenseProvider.notifier)
                        .updateDescription(val),
                  ),
                  const SizedBox(height: 24),

                  // Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            final amount = double.tryParse(val) ?? 0.0;
                            ref
                                .read(addExpenseProvider.notifier)
                                .updateAmount(amount);
                          },
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      'Total Amount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Payers Section
                  ExpensePayersCard(
                    isMultiplePayers: state.isMultiplePayers,
                    paidById: state.paidById,
                    multiplePayers: state.multiplePayers,
                    members: state.groupMembers,
                    onMultiplePayersToggled: (val) => ref
                        .read(addExpenseProvider.notifier)
                        .setMultiplePayersEnabled(val),
                    onSinglePayerChanged: (val) =>
                        ref.read(addExpenseProvider.notifier).setPaidBy(val),
                    onMultiplePayerAmountChanged: (memberId, amount) => ref
                        .read(addExpenseProvider.notifier)
                        .updateMultiplePayer(memberId, amount),
                  ),
                  const SizedBox(height: 24),

                  // Split Method Selector
                  ExpenseSplitMethodSelector(
                    selectedMethod: state.splitMethod,
                    onMethodChanged: (method) => ref
                        .read(addExpenseProvider.notifier)
                        .setSplitMethod(method),
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Section based on Split Method
                  if (state.splitMethod == SplitMethod.byItems)
                    ExpenseItemsList(
                      items: state.items,
                      groupMembers: state.groupMembers,
                    )
                  else if (state.splitMethod == SplitMethod.unequally)
                    // Simplified unequal split UI for brevity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unequal Split',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...state.groupMembers.map((m) {
                          return ListTile(
                            title: Text(m.name),
                            trailing: SizedBox(
                              width: 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    prefixText: '₹ ',
                                    hintText: '0.00',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    ref
                                        .read(addExpenseProvider.notifier)
                                        .updateUnequalSplit(
                                          m.id,
                                          double.tryParse(val) ?? 0.0,
                                        );
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                  const SizedBox(height: 24),
                  Text(
                    'Adjustments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Adjustments
                  ExpenseAdjustmentsCard(
                    taxAmount: state.taxAmount,
                    discountAmount: state.discountAmount,
                    onTaxChanged: (val) =>
                        ref.read(addExpenseProvider.notifier).updateTax(val),
                    onDiscountChanged: (val) => ref
                        .read(addExpenseProvider.notifier)
                        .updateDiscount(val),
                  ),

                  const SizedBox(height: 16),

                  // Treat Section
                  ExpenseTreatCard(
                    isEnabled: state.isTreatEnabled,
                    treatAmounts: state.treatAmounts,
                    members: state.groupMembers,
                    onToggle: (val) => ref
                        .read(addExpenseProvider.notifier)
                        .setTreatEnabled(val, widget.currentUserId),
                    onAmountChanged: (memberId, amount) => ref
                        .read(addExpenseProvider.notifier)
                        .updateTreatAmountForMember(memberId, amount),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }
}
