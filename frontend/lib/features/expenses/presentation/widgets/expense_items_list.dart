import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/expenses/domain/expense_models.dart';
import 'package:split_frontend/features/expenses/presentation/providers/add_expense_provider.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';

class ExpenseItemsList extends ConsumerWidget {
  final List<ExpenseItemInput> items;
  final List<GroupMemberModel> groupMembers;

  const ExpenseItemsList({
    super.key,
    required this.items,
    required this.groupMembers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ref
                    .read(addExpenseProvider.notifier)
                    .addItem(
                      const ExpenseItemInput(
                        name: '',
                        amount: 0.0,
                        members: [],
                      ),
                    );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _ItemCard(
            item: item,
            groupMembers: groupMembers,
            onChanged: (newItem) => ref
                .read(addExpenseProvider.notifier)
                .updateItem(index, newItem),
            onDeleted: () =>
                ref.read(addExpenseProvider.notifier).removeItem(index),
          );
        }),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ExpenseItemInput item;
  final List<GroupMemberModel> groupMembers;
  final ValueChanged<ExpenseItemInput> onChanged;
  final VoidCallback onDeleted;

  const _ItemCard({
    required this.item,
    required this.groupMembers,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.name,
                  decoration: InputDecoration(
                    hintText: 'Item Name',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (val) => onChanged(item.copyWith(name: val)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: item.amount > 0 ? item.amount.toString() : '',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    hintText: '0.00',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (val) {
                    final amount = double.tryParse(val) ?? 0.0;
                    onChanged(item.copyWith(amount: amount));
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDeleted,
                color: theme.colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Shared by:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...groupMembers.map((m) {
                final isSelected = item.members.contains(m.id);
                return InkWell(
                  onTap: () {
                    final newMembers = List<String>.from(item.members);
                    if (isSelected) {
                      newMembers.remove(m.id);
                    } else {
                      newMembers.add(m.id);
                    }
                    onChanged(item.copyWith(members: newMembers));
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      m.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
