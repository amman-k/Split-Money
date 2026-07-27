import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';
import 'package:split_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:split_frontend/features/auth/domain/user.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';
import 'package:split_frontend/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:split_frontend/features/auth/presentation/widgets/auth_header_section.dart';
import 'package:split_frontend/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:split_frontend/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:split_frontend/features/auth/presentation/widgets/auth_top_app_bar.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final controller = ref.read(authControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() {
      _emailError = controller.validateEmail(email)
          ? null
          : (l10n?.invalidEmailError ?? 'Please enter a valid email address');
      _passwordError = controller.validatePassword(password)
          ? null
          : (l10n?.passwordTooShortError ??
                'Password must be at least 8 characters');
    });

    if (_emailError == null && _passwordError == null) {
      controller.signIn(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context);

    ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (!next.isLoading && next.hasValue && next.value != null) {
        if (context.mounted) {
          context.go('/dashboard');
        }
      }
    });

    return Scaffold(
      appBar: AuthTopAppBar(onBack: () => context.pop()),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
                vertical: AppSpacing.md,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AuthHeaderSection(
                    title: l10n?.signInHeaderTitle ?? 'Welcome back',
                    subtitle:
                        l10n?.signInHeaderSubtitle ??
                        'Sign in to continue splitting expenses with your friends.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthTextField(
                    label: l10n?.emailLabel ?? 'Email Address',
                    placeholder: l10n?.emailPlaceholder ?? 'john@example.com',
                    controller: _emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    label: l10n?.passwordLabel ?? 'Password',
                    placeholder: l10n?.passwordPlaceholder ?? '••••••••',
                    controller: _passwordController,
                    enabled: !isLoading,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    errorText: _passwordError,
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    onSubmitted: (_) => _validateAndSubmit(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthSubmitButton(
                    label: l10n?.signInButton ?? 'Sign In',
                    isLoading: isLoading,
                    onPressed: _validateAndSubmit,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: AuthFooterLink(
                      promptText:
                          l10n?.dontHaveAccount ?? "Don't have an account?",
                      actionText: l10n?.signUp ?? 'Sign Up',
                      onPressed: () => context.pushReplacement('/signup'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
