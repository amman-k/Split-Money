import 'package:flutter/material.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/features/groups/presentation/widgets/member_tile.dart';

class GroupMembersCard extends StatelessWidget {
  final String headerTitle;
  final String ownerName;
  final String ownerBadgeLabel;
  final List<String> members;
  final ValueChanged<int>? onRemoveMember;

  const GroupMembersCard({
    super.key,
    required this.headerTitle,
    required this.ownerName,
    required this.ownerBadgeLabel,
    required this.members,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerTitle,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          MemberTile(
            name: ownerName,
            isOwner: true,
            ownerBadgeLabel: ownerBadgeLabel,
          ),
          for (int i = 0; i < members.length; i++) ...[
            Divider(
              height: AppSpacing.xl,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            MemberTile(
              name: members[i],
              ownerBadgeLabel: ownerBadgeLabel,
              onRemove: onRemoveMember != null
                  ? () => onRemoveMember!(i)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
