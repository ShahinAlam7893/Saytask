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

// Custom page transition for smooth navigation
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

// Slide transition for detail pages
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

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// 🧭 Centralized GoRouter configuration with smooth transitions
final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // --- Onboarding & Auth routes (NO NAVBAR) ---
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
        child: const ForgotPassMailScreen(),
      ),
    ),
    GoRoute(
      path: '/otp_verification',
      pageBuilder: (context, state) => buildPageWithFadeTransition(
        context: context,
        state: state,
        child: const OtpVerificationScreen(email: ''),
      ),
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

    // --- Settings (NO NAVBAR) ---
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

    // --- Chat (NO NAVBAR) ---
    GoRoute(
      path: '/chat',
      pageBuilder: (context, state) => buildPageWithSlideTransition(
        context: context,
        state: state,
        child: ChatPage(),
      ),
    ),

    // --- Global Navbar Tabs (FADE TRANSITION) ---
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

    // --- Detail Pages (WITH NAVBAR, SLIDE TRANSITION) ---
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
        final note = state.extra as Note;
        return buildPageWithSlideTransition(
          context: context,
          state: state,
          child: SmoothNavigationWrapper(
            initialIndex: 3,
            child: NoteDetailsScreen(note: note),
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

// // lib/config/router/go_router.dart
// import 'package:go_router/go_router.dart';
// import 'package:saytask/model/note_model.dart';
// import 'package:saytask/model/today_task_model.dart';
// import 'package:saytask/model/event_model.dart';
//
// import 'package:saytask/view/chat/chat_screen.dart';
// import 'package:saytask/view/event/edit_event_screen.dart';
// import 'package:saytask/view/event/event_details_screen.dart';
// import 'package:saytask/view/note/create_note_screen.dart';
// import 'package:saytask/view/note/note_details_screen.dart';
// import 'package:saytask/view/onboarding/plan_screen.dart';
// import 'package:saytask/view/onboarding/splash_screen.dart';
// import 'package:saytask/view/onboarding/onboarding_one.dart';
// import 'package:saytask/view/onboarding/onboarding_two.dart';
// import 'package:saytask/view/onboarding/onboarding_three.dart';
// import 'package:saytask/view/today/task_details_screen.dart';
//
// import '../../res/components/nab_bar.dart';
// import '../../view/auth_view/create_new_password_screen.dart';
// import '../../view/auth_view/forgot_pass_mail_screen.dart';
// import '../../view/auth_view/login_screen.dart';
// import '../../view/auth_view/otp_verification_screen.dart';
// import '../../view/auth_view/signup_screen.dart';
// import '../../view/auth_view/success_screen.dart';
// import '../../view/settings/about_us_screen.dart';
// import '../../view/settings/account_management.dart';
// import '../../view/settings/delete_account_screen.dart';
// import '../../view/settings/privacy_policy_screen.dart';
// import '../../view/settings/profile_screen.dart';
// import '../../view/settings/settings_screen.dart';
// import '../../view/settings/terms_and_condition.dart';
// import '../../view/settings/update_password.dart';
//
// /// 🧭 Centralized GoRouter configuration with GlobalLayout (SmoothNavigationWrapper)
// final GoRouter router = GoRouter(
//   initialLocation: '/home',
//   routes: [
//     // --- Onboarding & Auth routes ---
//     GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
//     GoRoute(path: '/onboarding_one', builder: (context, state) => const OnboardingOne()),
//     GoRoute(path: '/onboarding_two', builder: (context, state) => const OnboardingTwo()),
//     GoRoute(path: '/onboarding_three', builder: (context, state) => const OnboardingThree()),
//     GoRoute(path: '/plan_screen', builder: (context, state) => const PlanScreen()),
//     GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
//     GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
//     GoRoute(path: '/forgot_password_mail', builder: (context, state) => const ForgotPassMailScreen()),
//     GoRoute(path: '/otp_verification', builder: (context, state) => const OtpVerificationScreen(email: '')),
//     GoRoute(path: '/create_new_password', builder: (context, state) => const CreateNewPasswordScreen()),
//     GoRoute(path: '/success', builder: (context, state) => const SuccessScreen()),
//
//     // --- Global Navbar Tabs ---
//     GoRoute(
//       path: '/home',
//       builder: (context, state) => const SmoothNavigationWrapper(initialIndex: 0),
//     ),
//     GoRoute(
//       path: '/today',
//       builder: (context, state) => const SmoothNavigationWrapper(initialIndex: 1),
//     ),
//     GoRoute(
//       path: '/speak',
//       builder: (context, state) => const SmoothNavigationWrapper(initialIndex: 2),
//     ),
//     GoRoute(
//       path: '/calendar',
//       builder: (context, state) => const SmoothNavigationWrapper(initialIndex: 3),
//     ),
//     GoRoute(
//       path: '/notes',
//       builder: (context, state) => const SmoothNavigationWrapper(initialIndex: 4),
//     ),
//
//     // --- Chat & Settings ---
//     GoRoute(path: '/chat', builder: (context, state) => ChatPage()),
//     GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
//     GoRoute(path: '/account_management', builder: (context, state) => const AccountManagementScreen()),
//     GoRoute(path: '/update_password', builder: (context, state) => const UpdatePassword()),
//     GoRoute(path: '/delete_account', builder: (context, state) => const DeleteAccountPage()),
//     GoRoute(path: '/terms_and_conditions', builder: (context, state) => const TermsAndCondition()),
//     GoRoute(path: '/privacy_policy', builder: (context, state) => const PrivacyPolicyScreen()),
//     GoRoute(path: '/about_us', builder: (context, state) => const AboutUsScreen()),
//     GoRoute(path: '/profile_screen', builder: (context, state) => const ProfileScreen()),
//
//     // --- Notes ---
//     GoRoute(
//       path: '/create_note',
//       builder: (context, state) => const CreateNoteScreen(),
//     ),
//     GoRoute(
//       path: '/note_details',
//       builder: (context, state) {
//         final note = state.extra as Note;
//         return SmoothNavigationWrapper(
//           initialIndex: 4, // Notes tab stays active
//           child: NoteDetailsScreen(note: note),
//         );
//       },
//     ),
//
//     // --- Today (Tasks) ---
//     GoRoute(
//       path: '/task-details',
//       name: 'taskDetails',
//       builder: (context, state) {
//         final task = state.extra as Task?;
//         return SmoothNavigationWrapper(
//           initialIndex: 1, // Today tab stays active
//           child: TaskDetailsScreen(task: task!),
//         );
//       },
//     ),
//
//     // --- Events (Calendar) ---
//     GoRoute(
//       path: '/event_details',
//       builder: (context, state) {
//         final event = state.extra as Event?;
//         return SmoothNavigationWrapper(
//           initialIndex: 3, // Calendar tab stays active
//           child: EventDetailsScreen(event: event),
//         );
//       },
//     ),
//     GoRoute(
//       path: '/edit_event',
//       name: 'editEvent',
//       builder: (context, state) {
//         final event = state.extra as Event;
//         return SmoothNavigationWrapper(
//           initialIndex: 3, // Calendar tab stays active
//           child: EventEditScreen(event: event),
//         );
//       },
//     ),
//   ],
// );








// import 'package:go_router/go_router.dart';
// import 'package:saytask/model/note_model.dart';
// import 'package:saytask/model/today_task_model.dart';
// import 'package:saytask/model/event_model.dart';
// import 'package:saytask/res/components/nab_bar.dart';
// import 'package:saytask/view/chat/chat_screen.dart';
// import 'package:saytask/view/event/edit_event_screen.dart';
// import 'package:saytask/view/note/create_note_screen.dart';
// import 'package:saytask/view/note/note_details_screen.dart';
// import 'package:saytask/view/onboarding/plan_screen.dart';
// import 'package:saytask/view/onboarding/splash_screen.dart';
// import 'package:saytask/view/today/task_details_screen.dart';
// import 'package:saytask/view/auth_view/create_new_password_screen.dart';
// import 'package:saytask/view/auth_view/forgot_pass_mail_screen.dart';
// import 'package:saytask/view/auth_view/login_screen.dart';
// import 'package:saytask/view/auth_view/otp_verification_screen.dart';
// import 'package:saytask/view/auth_view/signup_screen.dart';
// import 'package:saytask/view/auth_view/success_screen.dart';
// import 'package:saytask/view/event/event_details_screen.dart';
// import 'package:saytask/view/onboarding/onboarding_one.dart';
// import 'package:saytask/view/onboarding/onboarding_two.dart';
// import 'package:saytask/view/onboarding/onboarding_three.dart';
// import 'package:saytask/view/settings/about_us_screen.dart';
// import 'package:saytask/view/settings/account_management.dart';
// import 'package:saytask/view/settings/delete_account_screen.dart';
// import 'package:saytask/view/settings/privacy_policy_screen.dart';
// import 'package:saytask/view/settings/profile_screen.dart';
// import 'package:saytask/view/settings/settings_screen.dart';
// import 'package:saytask/view/settings/terms_and_condition.dart';
// import 'package:saytask/view/settings/update_password.dart';
// import 'package:saytask/view/home/home_screen.dart';
// import 'package:saytask/view/today/today_screen.dart';
// import 'package:saytask/view/speak_screen/speak_screen.dart';
// import 'package:saytask/view/calendar/calendar_screen.dart';
// import 'package:saytask/view/note/notes_screen.dart';
//
// final GoRouter router = GoRouter(
//   initialLocation: '/home',
//   routes: [
//     // ---------------- AUTH / ONBOARDING ROUTES ----------------
//     GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
//     GoRoute(path: '/onboarding_one', builder: (_, __) => const OnboardingOne()),
//     GoRoute(path: '/onboarding_two', builder: (_, __) => const OnboardingTwo()),
//     GoRoute(path: '/onboarding_three', builder: (_, __) => const OnboardingThree()),
//     GoRoute(path: '/plan_screen', builder: (_, __) => const PlanScreen()),
//     GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
//     GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
//     GoRoute(path: '/forgot_password_mail', builder: (_, __) => const ForgotPassMailScreen()),
//     GoRoute(path: '/otp_verification', builder: (_, __) => const OtpVerificationScreen(email: '')),
//     GoRoute(path: '/create_new_password', builder: (_, __) => const CreateNewPasswordScreen()),
//     GoRoute(path: '/success', builder: (_, __) => const SuccessScreen()),
//
//     // ---------------- SETTINGS ROUTES ----------------
//     GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
//     GoRoute(path: '/account_management', builder: (_, __) => const AccountManagementScreen()),
//     GoRoute(path: '/update_password', builder: (_, __) => const UpdatePassword()),
//     GoRoute(path: '/delete_account', builder: (_, __) => const DeleteAccountPage()),
//     GoRoute(path: '/terms_and_conditions', builder: (_, __) => const TermsAndCondition()),
//     GoRoute(path: '/privacy_policy', builder: (_, __) => const PrivacyPolicyScreen()),
//     GoRoute(path: '/about_us', builder: (_, __) => const AboutUsScreen()),
//     GoRoute(path: '/profile_screen', builder: (_, __) => const ProfileScreen()),
//
//     // ---------------- MAIN SCREENS (WITH NAVBAR) ----------------
//     GoRoute(
//       path: '/home',
//       builder: (_, __) => const SmoothNavigationWrapper(child: HomeScreen()),
//     ),
//     GoRoute(
//       path: '/today',
//       builder: (_, __) => const SmoothNavigationWrapper(child: TodayScreen()),
//     ),
//     GoRoute(
//       path: '/speak',
//       builder: (_, __) => const SmoothNavigationWrapper(child: SpeakHomeScreen()),
//     ),
//     GoRoute(
//       path: '/calendar',
//       builder: (_, __) => const SmoothNavigationWrapper(child: CalendarScreen()),
//     ),
//     GoRoute(
//       path: '/notes',
//       builder: (_, __) => const SmoothNavigationWrapper(child: NotesScreen()),
//     ),
//     GoRoute(
//       path: '/create_note',
//       builder: (_, __) => const SmoothNavigationWrapper(child: CreateNoteScreen()),
//     ),
//
//     // ---------------- DETAIL / OTHER PAGES (ALSO WITH NAVBAR) ----------------
//     GoRoute(
//       path: '/task-details',
//       name: 'taskDetails',
//       builder: (context, state) {
//         final task = state.extra as Task?;
//         return SmoothNavigationWrapper(child: TaskDetailsScreen(task: task!));
//       },
//     ),
//     GoRoute(
//       path: '/event_details',
//       builder: (context, state) {
//         final event = state.extra as Event?;
//         return SmoothNavigationWrapper(child: EventDetailsScreen(event: event));
//       },
//     ),
//     GoRoute(
//       path: '/edit_event',
//       name: 'editEvent',
//       builder: (context, state) {
//         final event = state.extra as Event;
//         return SmoothNavigationWrapper(child: EventEditScreen(event: event));
//       },
//     ),
//     GoRoute(
//       path: '/note_details',
//       builder: (context, state) {
//         final note = state.extra as Note;
//         return SmoothNavigationWrapper(child: NoteDetailsScreen(note: note));
//       },
//     ),
//
//     // ---------------- CHAT ----------------
//     GoRoute(
//       path: '/chat',
//       builder: (_, __) => const SmoothNavigationWrapper(child: ChatPage()),
//     ),
//   ],
// );
//





// import 'package:go_router/go_router.dart';
// import 'package:saytask/model/note_model.dart';
// import 'package:saytask/model/today_task_model.dart';
// import 'package:saytask/view/chat/chat_screen.dart';
// import 'package:saytask/view/event/edit_event_screen.dart';
// import 'package:saytask/view/note/create_note_screen.dart';
// import 'package:saytask/view/note/note_details_screen.dart';
// import 'package:saytask/view/onboarding/plan_screen.dart';
// import 'package:saytask/view/onboarding/splash_screen.dart';
// import 'package:saytask/view/today/task_details_screen.dart';
// import '../../model/event_model.dart';
// import '../../res/components/nab_bar.dart';
// import '../../view/auth_view/create_new_password_screen.dart';
// import '../../view/auth_view/forgot_pass_mail_screen.dart';
// import '../../view/auth_view/login_screen.dart';
// import '../../view/auth_view/otp_verification_screen.dart';
// import '../../view/auth_view/signup_screen.dart';
// import '../../view/auth_view/success_screen.dart';
// import '../../view/event/event_details_screen.dart';
// import '../../view/onboarding/onboarding_one.dart';
// import '../../view/onboarding/onboarding_two.dart';
// import '../../view/onboarding/onboarding_three.dart';
// import '../../view/settings/about_us_screen.dart';
// import '../../view/settings/account_management.dart';
// import '../../view/settings/delete_account_screen.dart';
// import '../../view/settings/privacy_policy_screen.dart';
// import '../../view/settings/profile_screen.dart';
// import '../../view/settings/settings_screen.dart';
// import '../../view/settings/terms_and_condition.dart';
// import '../../view/settings/update_password.dart';
// import '../../view/home/home_screen.dart';
// import '../../view/today/today_screen.dart';
// import '../../view/note/notes_screen.dart';
// import '../../view/calendar/calendar_screen.dart';
// import '../../view/speak_screen/speak_screen.dart';
//
// final GoRouter router = GoRouter(
//   initialLocation: '/splash',
//   routes: [
//     // ======== WITHOUT NAV BAR ======== //
//     GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
//     GoRoute(path: '/onboarding_one', builder: (_, __) => const OnboardingOne()),
//     GoRoute(path: '/onboarding_two', builder: (_, __) => const OnboardingTwo()),
//     GoRoute(path: '/onboarding_three', builder: (_, __) => const OnboardingThree()),
//     GoRoute(path: '/plan_screen', builder: (_, __) => const PlanScreen()),
//     GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
//     GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
//     GoRoute(path: '/forgot_password_mail', builder: (_, __) => const ForgotPassMailScreen()),
//     GoRoute(path: '/otp_verification', builder: (_, __) => const OtpVerificationScreen(email: '')),
//     GoRoute(path: '/create_new_password', builder: (_, __) => const CreateNewPasswordScreen()),
//     GoRoute(path: '/success', builder: (_, __) => const SuccessScreen()),
//
//     // ======== SETTINGS (WITHOUT NAV BAR) ======== //
//     GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
//     GoRoute(path: '/account_management', builder: (_, __) => const AccountManagementScreen()),
//     GoRoute(path: '/update_password', builder: (_, __) => const UpdatePassword()),
//     GoRoute(path: '/delete_account', builder: (_, __) => const DeleteAccountPage()),
//     GoRoute(path: '/terms_and_conditions', builder: (_, __) => const TermsAndCondition()),
//     GoRoute(path: '/privacy_policy', builder: (_, __) => const PrivacyPolicyScreen()),
//     GoRoute(path: '/about_us', builder: (_, __) => const AboutUsScreen()),
//     GoRoute(path: '/profile_screen', builder: (_, __) => const ProfileScreen()),
//
// // ======== CHAT SCREEN (WITHOUT NAV BAR) ======== //
//     GoRoute(
//       path: '/chat',
//       builder: (_, __) => ChatPage(),
//     ),
//
//
//     // ======== MAIN APP WITH NAV BAR ======== //
//     ShellRoute(
//       builder: (context, state, child) => SmoothNavigationWrapper(
//         // child will change according to selected tab
//         initialIndex: 0,
//         key: state.pageKey,
//       ),
//       routes: [
//         GoRoute(
//           path: '/home',
//           builder: (_, __) => const HomeScreen(),
//         ),
//         GoRoute(
//           path: '/today',
//           builder: (_, __) => const TodayScreen(),
//         ),
//         GoRoute(
//           path: '/speak',
//           builder: (_, __) => const SpeakHomeScreen(),
//         ),
//         GoRoute(
//           path: '/calendar',
//           builder: (_, __) => const CalendarScreen(),
//         ),
//         GoRoute(
//           path: '/notes',
//           builder: (_, __) => const NotesScreen(),
//         ),
//         GoRoute(
//           path: '/create_note',
//           builder: (_, __) => const CreateNoteScreen(),
//         ),
//
//         GoRoute(
//           path: '/task-details',
//           name: 'taskDetails',
//           builder: (context, state) {
//             final task = state.extra as Task;
//             return TaskDetailsScreen(task: task);
//           },
//         ),
//         GoRoute(
//           path: '/event_details',
//           builder: (context, state) {
//             final event = state.extra as Event?;
//             return EventDetailsScreen(event: event);
//           },
//         ),
//         GoRoute(
//           path: '/edit_event',
//           name: 'editEvent',
//           builder: (context, state) {
//             final event = state.extra as Event;
//             return EventEditScreen(event: event);
//           },
//         ),
//         GoRoute(
//           path: '/note_details',
//           builder: (context, state) {
//             final note = state.extra as Note;
//             return NoteDetailsScreen();
//           },
//         ),
//       ],
//     ),
//   ],
// );
