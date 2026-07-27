import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:split_frontend/features/groups/presentation/screens/create_group_screen.dart';
import 'package:split_frontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:split_frontend/features/groups/presentation/screens/group_details_screen.dart';
import 'package:split_frontend/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:split_frontend/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:split_frontend/features/auth/presentation/screens/welcome_screen.dart';

CustomTransitionPage<void> _buildSmoothTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.03),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _buildSmoothTransitionPage(
        context: context,
        state: state,
        child: const SignUpScreen(),
      ),
    ),
    GoRoute(
      path: '/signin',
      pageBuilder: (context, state) => _buildSmoothTransitionPage(
        context: context,
        state: state,
        child: const SignInScreen(),
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => _buildSmoothTransitionPage(
        context: context,
        state: state,
        child: const DashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/groups/create',
      pageBuilder: (context, state) => _buildSmoothTransitionPage(
        context: context,
        state: state,
        child: const CreateGroupScreen(),
      ),
    ),
    GoRoute(
      path: '/groups/:id',
      pageBuilder: (context, state) {
        final groupId = state.pathParameters['id']!;
        return _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: GroupDetailsScreen(groupId: groupId),
        );
      },
    ),
  ],
);
