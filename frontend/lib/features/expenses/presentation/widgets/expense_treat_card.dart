import 'package:flutter/material.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';

class ExpenseTreatCard extends StatelessWidget {
  final bool isEnabled;
  final Map<String, double> treatAmounts;
  final List<GroupMemberModel> members;
  final ValueChanged<bool> onToggle;
  final void Function(String, double) onAmountChanged;

  const ExpenseTreatCard({
    super.key,
    required this.isEnabled,
    required this.treatAmounts,
    required this.members,
    required this.onToggle,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Someone treated the group?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Subtract a set amount before splitting',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 16),
            Column(
              children: members.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(m.name)),
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: TextFormField(
                            initialValue:
                                treatAmounts[m.id] != null &&
                                    treatAmounts[m.id]! > 0
                                ? treatAmounts[m.id].toString()
                                : '',
                            keyboardType: const TextInputType.numberWithOptions(
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
                              onAmountChanged(
                                m.id,
                                double.tryParse(val) ?? 0.0,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
