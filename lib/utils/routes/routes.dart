import 'package:go_router/go_router.dart';
import 'package:saytask/view/onboarding/splash_screen.dart';
import 'package:saytask/view/home/home_screen.dart';

import '../../view/auth_view/login_screen.dart';
import '../../view/auth_view/signup_screen.dart';
import '../../view/onboarding/onboarding_one.dart';
import '../../view/onboarding/onboarding_three.dart';
import '../../view/onboarding/onboarding_two.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
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
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
