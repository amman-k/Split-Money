import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/features/dashboard/presentation/widgets/group_summary_card.dart';
import 'package:split_frontend/features/groups/domain/group_model.dart';
import 'package:split_frontend/features/groups/presentation/controllers/groups_list_controller.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';

class GroupsSliverList extends ConsumerWidget {
  final ValueChanged<GroupModel>? onGroupTap;

  const GroupsSliverList({super.key, this.onGroupTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsListControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return groupsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 36),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.failedToLoadGroups,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                onPressed: () => ref.refresh(groupsListControllerProvider),
                child: Text(l10n.retryAction),
              ),
            ],
          ),
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.noGroupsFoundTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.noGroupsFoundSubtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
          ),
          sliver: SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return GroupSummaryCard.fromGroupModel(
                group: group,
                opacity: 1.0,
                onTap: () {
                  if (onGroupTap != null) onGroupTap!(group);
                },
              );
            },
          ),
        );
      },
    );
  }
}
