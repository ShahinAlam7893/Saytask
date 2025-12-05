// lib/config/router/go_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saytask/model/note_model.dart';
import 'package:saytask/model/today_task_model.dart';
import 'package:saytask/model/event_model.dart';

import 'package:saytask/view/chat/chat_screen.dart';
import 'package:saytask/view/event/edit_event_screen.dart';
import 'package:saytask/view/event/event_details_screen.dart';
import 'package:saytask/view/note/create_note_screen.dart';
import 'package:saytask/view/note/note_details_screen.dart';
import 'package:saytask/view/onboarding/plan_screen.dart';
import 'package:saytask/view/onboarding/splash_screen.dart';
import 'package:saytask/view/onboarding/onboarding_one.dart';
import 'package:saytask/view/onboarding/onboarding_two.dart';
import 'package:saytask/view/onboarding/onboarding_three.dart';
import 'package:saytask/view/today/task_details_screen.dart';

import '../../res/components/nab_bar.dart';
import '../../view/auth_view/create_new_password_screen.dart';
import '../../view/auth_view/forgot_pass_mail_screen.dart';
import '../../view/auth_view/login_screen.dart';
import '../../view/auth_view/otp_verification_screen.dart';
import '../../view/auth_view/signup_screen.dart';
import '../../view/auth_view/success_screen.dart';
import '../../view/settings/about_us_screen.dart';
import '../../view/settings/account_management.dart';
import '../../view/settings/delete_account_screen.dart';
import '../../view/settings/privacy_policy_screen.dart';
import '../../view/settings/profile_screen.dart';
import '../../view/settings/settings_screen.dart';
import '../../view/settings/terms_and_condition.dart';
import '../../view/settings/update_password.dart';

CustomTransitionPage buildPageWithFadeTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}


CustomTransitionPage buildPageWithSlideTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding_one',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const OnboardingOne(),
      ),
    ),
    GoRoute(
      path: '/onboarding_two',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const OnboardingTwo(),
      ),
    ),
    GoRoute(
      path: '/onboarding_three',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const OnboardingThree(),
      ),
    ),
    GoRoute(
      path: '/plan_screen',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const PlanScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const SignupScreen(),
      ),
    ),
    GoRoute(
      path: '/forgot_password_mail',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: ForgotPassMailScreen(),
      ),
    ),
    GoRoute(
      path: '/otp_verification',
      pageBuilder: (context, state) {
        final token = state.extra as String?;
        if (token == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/forgot_password_mail');
          });
          return buildPageWithFadeTransition(
            context: context,
            state: state,
            child: const Scaffold(body: Center(child: Text("Invalid access"))),
          );
        }
        return buildPageWithFadeTransition(
          context: context,
          state: state,
          child: OtpVerificationScreen(resetToken: token),
        );
      },
    ),

    GoRoute(
      path: '/create_new_password',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const CreateNewPasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/success',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const SuccessScreen(),
      ),
    ),

    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/account_management',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const AccountManagementScreen(),
      ),
    ),
    GoRoute(
      path: '/update_password',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const UpdatePassword(),
      ),
    ),
    GoRoute(
      path: '/delete_account',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const DeleteAccountPage(),
      ),
    ),
    GoRoute(
      path: '/terms_and_conditions',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const TermsAndCondition(),
      ),
    ),
    GoRoute(
      path: '/privacy_policy',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const PrivacyPolicyScreen(),
      ),
    ),
    GoRoute(
      path: '/about_us',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const AboutUsScreen(),
      ),
    ),
    GoRoute(
      path: '/profile_screen',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const ProfileScreen(),
      ),
    ),


    GoRoute(
      path: '/chat',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: ChatPage(),
      ),
    ),

    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const SmoothNavigationWrapper(initialIndex: 0),
      ),
    ),
    GoRoute(
      path: '/today',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const SmoothNavigationWrapper(initialIndex: 1),
      ),
    ),
    GoRoute(
      path: '/speak',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const SmoothNavigationWrapper(initialIndex: 2),
      ),
    ),
    GoRoute(
      path: '/calendar',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const SmoothNavigationWrapper(initialIndex: 2),
      ),
    ),
    GoRoute(
      path: '/notes',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const SmoothNavigationWrapper(initialIndex: 3),
      ),
    ),

    GoRoute(
      path: '/create_note',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const SmoothNavigationWrapper(
          initialIndex: 3,
          child: CreateNoteScreen(),
        ),
      ),
    ),
    GoRoute(
  path: '/note_details',
  pageBuilder: (context, state) {
    return buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const SmoothNavigationWrapper(
        initialIndex: 3,
        child: NoteDetailsScreen(),
      ),
    );
  },
),
    GoRoute(
      path: '/task-details',
      name: 'taskDetails',
      pageBuilder: (context, state) {
        final task = state.extra as Task?;
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: SmoothNavigationWrapper(
            initialIndex: 1,
            child: TaskDetailsScreen(task: task!),
          ),
        );
      },
    ),
    GoRoute(
      path: '/event_details',
      pageBuilder: (context, state) {
        final event = state.extra as Event?;
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: SmoothNavigationWrapper(
            initialIndex: 2,
            child: EventDetailsScreen(event: event),
          ),
        );
      },
    ),
    GoRoute(
      path: '/edit_event',
      name: 'editEvent',
      pageBuilder: (context, state) {
        final event = state.extra as Event;
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: SmoothNavigationWrapper(
            initialIndex: 2,
            child: EventEditScreen(event: event),
          ),
        );
      },
    ),
  ],
);
