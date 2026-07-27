import 'package:flutter/material.dart';
import 'package:split_frontend/features/expenses/presentation/providers/add_expense_provider.dart';

class ExpenseSplitMethodSelector extends StatelessWidget {
  final SplitMethod selectedMethod;
  final ValueChanged<SplitMethod> onMethodChanged;

  const ExpenseSplitMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: SplitMethod.values.map((method) {
          final isSelected = selectedMethod == method;
          final label = _getLabel(method);

          return Expanded(
            child: GestureDetector(
              onTap: () => onMethodChanged(method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getLabel(SplitMethod method) {
    switch (method) {
      case SplitMethod.equally:
        return 'Equally';
      case SplitMethod.unequally:
        return 'Unequally';
      case SplitMethod.byItems:
        return 'By Items';
    }
  }
}
