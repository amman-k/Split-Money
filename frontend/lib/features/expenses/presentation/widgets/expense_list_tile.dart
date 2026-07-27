import 'package:flutter/material.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';

class ExpenseListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String payerName;
  final double amountPaid;
  final String date;
  final double userAmount; // Positive for lent, negative for owed

  const ExpenseListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.payerName,
    required this.amountPaid,
    required this.date,
    required this.userAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    final isLent = userAmount > 0;
    // Format currency
    final formattedUserAmount = '₹${userAmount.abs().toStringAsFixed(2)}';
    final sign = isLent ? '+' : '-';

    // In a full app, you might want to use a semantic color extension instead of hardcoded colors
    final amountColor = isLent ? colorScheme.primary : const Color(0xFFD6735A);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.transparent, // Background is transparent in the mock
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.paidBy(
                    payerName,
                    '₹${amountPaid.toStringAsFixed(2)}',
                    date,
                  ),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Amount and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign$formattedUserAmount',
                style: textTheme.labelLarge?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLent ? l10n.youLent : l10n.youOweLower,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
