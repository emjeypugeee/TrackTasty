import 'package:firebase_core/firebase_core.dart';
import 'package:fitness/animations/fade_out_page_transition.dart';
import 'package:fitness/main_screen_widgets/main_screen.dart';
import 'package:fitness/firebase_options.dart';
import 'package:fitness/pages/login/forgetpassword_page.dart';
import 'package:fitness/pages/login/startup_page.dart';
import 'package:fitness/pages/login/login_page.dart';
import 'package:fitness/pages/login/register_page.dart';
import 'package:fitness/pages/main_pages/analytics_page.dart';
import 'package:fitness/pages/main_pages/chat_bot.dart';
import 'package:fitness/pages/main_pages/forecasting_page.dart';
import 'package:fitness/pages/main_pages/home_page.dart';
import 'package:fitness/pages/main_pages/profile_page.dart';
import 'package:fitness/pages/preference/userpreference_2.dart';
import 'package:fitness/pages/preference/userpreference_1.dart';
import 'package:fitness/pages/preference/userpreference_3.dart';
import 'package:fitness/pages/preference/userpreference_4.dart';
import 'package:fitness/pages/preference/userpreference_5.dart';
import 'package:fitness/pages/preference/userpreference_6.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/startup',

  // routes of the pages
  routes: [
    GoRoute(
      path: '/startup',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: StartupPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: LoginPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: RegisterPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/forgetpassword',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ForgetpasswordPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference1',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference1(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference2',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference2(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference3',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference3(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference4',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference4(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference5',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference5(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference6',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference6(),
        key: state.pageKey,
      ),
    ),

    //shell route for main screen
    ShellRoute(builder: (context, state, child) => MainScreen(child: child), routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const ChatBot(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfilePage(),
      ),
      GoRoute(
        path: '/forecasting',
        builder: (context, state) => ForecastingPage(),
      ),
    ])
  ],
);

const _authPaths = ['/startup', '/login', '/register'];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF121212), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212))),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
