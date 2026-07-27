import 'package:flutter/material.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';

class ParticipantCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isRemainder;
  final int? remainderCount;

  const ParticipantCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.isRemainder = false,
    this.remainderCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF131313), // Dark background
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(theme),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (isRemainder && remainderCount != null) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF232323),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '+$remainderCount',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // For now, use a placeholder icon if no URL is provided
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        shape: BoxShape.circle,
        image: avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: avatarUrl == null
          ? Icon(
              Icons.person,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}
