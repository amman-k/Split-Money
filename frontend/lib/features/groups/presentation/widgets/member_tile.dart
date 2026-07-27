import 'package:flutter/material.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';

class MemberTile extends StatelessWidget {
  final String name;
  final bool isOwner;
  final String ownerBadgeLabel;
  final VoidCallback? onRemove;

  const MemberTile({
    super.key,
    required this.name,
    this.isOwner = false,
    required this.ownerBadgeLabel,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isOwner
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            isOwner ? 'ME' : initial,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isOwner
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            name,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: isOwner ? FontWeight.bold : FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (isOwner)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              ownerBadgeLabel,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else if (onRemove != null)
          Semantics(
            button: true,
            label: 'Remove $name',
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(AppSpacing.tappableTargetMin),
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.tappableTargetMin,
                  minHeight: AppSpacing.tappableTargetMin,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
