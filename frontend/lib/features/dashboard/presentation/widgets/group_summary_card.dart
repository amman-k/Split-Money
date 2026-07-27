import 'package:flutter/material.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';

class GroupSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusLabel;
  final String? statusValue;
  final bool isPositiveStatus;
  final VoidCallback? onTap;
  final double opacity;

  const GroupSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.statusValue,
    this.isPositiveStatus = true,
    this.onTap,
    this.opacity = 1.0,
  });

  factory GroupSummaryCard.fromGroupModel({
    required GroupModel group,
    required VoidCallback onTap,
    double opacity = 1.0,
  }) {
    final subtitleText = group.description.isNotEmpty
        ? group.description
        : '${group.members.length} members';

    return GroupSummaryCard(
      title: group.name,
      subtitle: subtitleText,
      statusLabel: '${group.members.length} MEMBERS',
      statusValue: null,
      isPositiveStatus: true,
      onTap: onTap,
      opacity: opacity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Semantics(
          button: true,
          label: '$title, $subtitle, $statusLabel ${statusValue ?? ""}',
          child: Material(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap ?? () {},
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.tappableTargetMin,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 18.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          statusLabel,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: isPositiveStatus
                                ? colorScheme.primary
                                : const Color(0xFFFFB4AB),
                          ),
                        ),
                        if (statusValue != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            statusValue!,
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
