import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              // Header / Brand Area
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bubble_chart,
                      color: colorScheme.primary,
                      size: AppSpacing.xl,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('SplitEase', style: textTheme.displaySmall),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Illustration Card (flexible and constrained to prevent overflow)
              Flexible(
                flex: 8,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 280,
                    maxHeight: 280,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1B1B),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDbm5QIGK2A0TTTOnqg3yEKZylHYsVAtSSTj2Mj6MGyiZD1FfgL4rPvWcJwHP1IBJWDqp4Mp69e-bb8QsVPqH9bXfXbVkt8dJQF2xcAcbj73brMyQ6CuNZpdwVqpVP4jnX4maoxAr-VZH60fi4mCXga41z_n1MFMKO87yFgzFCjizjPXBNHa_Gc4Ti9zOeznaXA46gYGtQ8DeX-kX_hJl0sql7KPoKLYUdVSx0DOKM_S-5baDg_aTXeaAfdro416_dwmvA9a9-0-2r-',
                            fit: BoxFit.cover,
                            opacity: const AlwaysStoppedAnimation(0.9),
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Icon(
                                    Icons.group_outlined,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.sm,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Headline & Description
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Split expenses without the awkwardness',
                      style: textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Track shared expenses, split bills fairly, and settle balances with friends, family, roommates, or travel groups—all in one place.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Action Stack with more rounded (pill-shaped) buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: l10n?.getStarted ?? 'Get Started',
                    child: ElevatedButton(
                      onPressed: () => context.push('/signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n?.getStarted ?? 'Get Started',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    button: true,
                    label: l10n?.signIn ?? 'Sign In',
                    child: ElevatedButton(
                      onPressed: () => context.push('/signin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n?.signIn ?? 'Sign In',
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
        ),
      ),
    );
  }
}
