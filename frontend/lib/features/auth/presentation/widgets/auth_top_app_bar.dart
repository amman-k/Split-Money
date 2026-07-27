import 'package:flutter/material.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';

class AuthTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;

  const AuthTopAppBar({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      color: colorScheme.surface,
      // Wrap the inner contents in a SafeArea (top only) to push it down dynamically
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                button: true,
                label: 'Go back',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(AppSpacing.xl),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48.0,
                        minHeight: 48.0,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.arrow_back,
                        color: colorScheme.onSurfaceVariant,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                l10n?.appTitle ?? 'SplitEase',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Symmetric placeholder to ensure exact center alignment of title
              const SizedBox(width: 48.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  // Increased from 72.0 to 96.0 to account for the new top spacing safely
  Size get preferredSize => const Size.fromHeight(96.0);
}
