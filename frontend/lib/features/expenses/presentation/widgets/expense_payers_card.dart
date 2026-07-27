import 'package:flutter/material.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';

class ExpensePayersCard extends StatelessWidget {
  final bool isMultiplePayers;
  final String? paidById;
  final Map<String, double> multiplePayers;
  final List<GroupMemberModel> members;
  final ValueChanged<bool> onMultiplePayersToggled;
  final ValueChanged<String> onSinglePayerChanged;
  final void Function(String, double) onMultiplePayerAmountChanged;

  const ExpensePayersCard({
    super.key,
    required this.isMultiplePayers,
    required this.paidById,
    required this.multiplePayers,
    required this.members,
    required this.onMultiplePayersToggled,
    required this.onSinglePayerChanged,
    required this.onMultiplePayerAmountChanged,
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
              Text(
                'Paid By',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Multiple people',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isMultiplePayers,
                    onChanged: onMultiplePayersToggled,
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isMultiplePayers)
            DropdownButtonFormField<String>(
              initialValue: members.any((m) => m.id == paidById)
                  ? paidById
                  : null,
              decoration: InputDecoration(
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
              items: members.map((m) {
                return DropdownMenuItem<String>(
                  value: m.id,
                  child: Text(m.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onSinglePayerChanged(val);
              },
            )
          else
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
                                multiplePayers[m.id] != null &&
                                    multiplePayers[m.id]! > 0
                                ? multiplePayers[m.id].toString()
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
                              onMultiplePayerAmountChanged(
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
      ),
    );
  }
}
