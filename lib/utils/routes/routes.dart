import 'package:go_router/go_router.dart';
import 'package:saytask/model/note_model.dart';
import 'package:saytask/view/note/create_note_screen.dart';
import 'package:saytask/view/note/note_details_screen.dart';
import 'package:saytask/view/onboarding/splash_screen.dart';
import '../../model/event_model.dart';
import '../../res/components/nab_bar.dart';
import '../../view/auth_view/create_new_password_screen.dart';
import '../../view/auth_view/forgot_pass_mail_screen.dart';
import '../../view/auth_view/login_screen.dart';
import '../../view/auth_view/otp_verification_screen.dart';
import '../../view/auth_view/signup_screen.dart';
import '../../view/auth_view/success_screen.dart';
import '../../view/event/event_details_screen.dart';
import '../../view/onboarding/onboarding_one.dart';
import '../../view/onboarding/onboarding_two.dart';
import '../../view/onboarding/onboarding_three.dart';
import '../../view/settings/about_us_screen.dart';
import '../../view/settings/account_management.dart';
import '../../view/settings/delete_account_screen.dart';
import '../../view/settings/privacy_policy_screen.dart';
import '../../view/settings/profile_screen.dart';
import '../../view/settings/settings_screen.dart';
import '../../view/settings/terms_and_condition.dart';
import '../../view/settings/update_password.dart';

final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding_one',
      builder: (context, state) => const OnboardingOne(),
    ),
    GoRoute(
      path: '/onboarding_two',
      builder: (context, state) => const OnboardingTwo(),
    ),
    GoRoute(
      path: '/onboarding_three',
      builder: (context, state) => const OnboardingThree(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot_password_mail',
      builder: (context, state) => const ForgotPassMailScreen(),
    ),
    GoRoute(
      path: '/otp_verification',
      builder: (context, state) => const OtpVerificationScreen(email: ''),
    ),
    GoRoute(
      path: '/create_new_password',
      builder: (context, state) => const CreateNewPasswordScreen(),
    ),
    GoRoute(
      path: '/success',
      builder: (context, state) => const SuccessScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const SmoothNavigationWrapper(initialIndex: 0),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/account_management',
      builder: (context, state) => const AccountManagementScreen(),
    ),
    GoRoute(
      path: '/update_password',
      builder: (context, state) => const UpdatePassword(),
    ),
    GoRoute(
      path: '/delete_account',
      builder: (context, state) => const DeleteAccountPage(),
    ),
    GoRoute(
      path: '/terms_and_conditions',
      builder: (context, state) => const TermsAndCondition(),
    ),
    GoRoute(
      path: '/privacy_policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/about_us',
      builder: (context, state) => const AboutUsScreen(),
    ),
    GoRoute(
      path: '/profile_screen',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/create_note',
      builder: (context, state) => const CreateNoteScreen(),
    ),
    GoRoute(
      path: '/event_details',
      builder: (context, state) {
        final event = state.extra as Event?;
        return EventDetailsScreen(event: event);
      },
    ),
    GoRoute(
      path: '/note_details',
      builder: (context, state) {
        final note = state.extra as Note;
        return NoteDetailsScreen();
      },
    ),
  ],
);