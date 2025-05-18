import 'package:firebase_core/firebase_core.dart';
import 'package:fitness/components/main_screen.dart';
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
    GoRoute(path: '/startup', builder: (context, state) => StartupPage()),
    GoRoute(path: '/login', builder: (context, state) => LoginPage()),
    GoRoute(path: '/register', builder: (context, state) => RegisterPage()),
    GoRoute(path: '/forgetpassword', builder: (context, state) => ForgetpasswordPage()),
    GoRoute(path: '/preference1', builder: (context, state) => Userpreference1()),
    GoRoute(path: '/preference2', builder: (context, state) => Userpreference2()),
    GoRoute(path: '/preference3', builder: (context, state) => Userpreference3()),
    GoRoute(path: '/preference4', builder: (context, state) => Userpreference4()),
    GoRoute(path: '/preference5', builder: (context, state) => Userpreference5()),
    GoRoute(path: '/preference6', builder: (context, state) => Userpreference6()),

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
