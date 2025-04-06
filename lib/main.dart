import 'package:firebase_core/firebase_core.dart';
import 'package:fitness/components/main_screen.dart';
import 'package:fitness/firebase_options.dart';
import 'package:fitness/pages/login/forgetpassword_page.dart';
import 'package:fitness/pages/login/startup_page.dart';
import 'package:fitness/pages/login/login_page.dart';
import 'package:fitness/pages/login/register_page.dart';
import 'package:fitness/pages/preference/userpreference_2.dart';
import 'package:fitness/pages/preference/userpreference_1.dart';
import 'package:fitness/pages/preference/userpreference_3.dart';
import 'package:fitness/pages/preference/userpreference_4.dart';
import 'package:fitness/pages/preference/userpreference_5.dart';
import 'package:fitness/pages/preference/userpreference_6.dart';
import 'package:fitness/pages/preference/userpreference_7.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212))),
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
      routes: <String, WidgetBuilder>{
        '/LoginPage': (context) => LoginPage(),
        '/RegisterPage': (context) => RegisterPage(),
        '/StartupPage': (context) => StartupPage(),
        '/ForgetpasswordPage': (context) => ForgetpasswordPage(),
        '/Userpreference1Page': (context) => Userpreference1(),
        '/Userpreference2Page': (context) => Userpreference2(),
        '/Userpreference3Page': (context) => Userpreference3(),
        '/Userpreference4Page': (context) => Userpreference4(),
        '/Userpreference5Page': (context) => Userpreference5(),
        '/Userpreference6Page': (context) => Userpreference6(),
        '/Userpreference7Page': (context) => Userpreference7(),
        '/MainScreenPage': (context) => MainScreen(),
      },
    );
  }
}
