import 'package:flutter/material.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';

class GroupBalanceCard extends StatelessWidget {
  final double userBalance; // Positive means owed, negative means owes
  final double totalGroupBalance;
  final VoidCallback onAddExpense;
  final VoidCallback onSettleUp;

  const GroupBalanceCard({
    super.key,
    required this.userBalance,
    required this.totalGroupBalance,
    required this.onAddExpense,
    required this.onSettleUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    // Formatting for display
    final isOwed = userBalance >= 0;
    // Format currency (assuming $ for now, ideally format properly based on locale)
    final formattedUserBalance = '₹${userBalance.abs().toStringAsFixed(2)}';
    final formattedGroupBalance = '₹${totalGroupBalance.toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFF191919), // Match the mock dark card color
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.currentStanding,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isOwed ? l10n.youAreOwedTitleCase : l10n.youOweLower,
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.primary, // Using primary color for owed text
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            formattedUserBalance,
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.primary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFC39352), // Goldish dot color from mock
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.totalGroupBalance(formattedGroupBalance).toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddExpense,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    l10n.addExpenseAction,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSettleUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF2C2C2C,
                    ), // Darker button bg
                    foregroundColor: colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.payments_outlined, size: 20),
                  label: Text(
                    l10n.settleUpAction,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
