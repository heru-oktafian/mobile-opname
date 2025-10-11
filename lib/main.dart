import 'package:flutter/material.dart';
import 'package:viopname/ui/pages/branches_page.dart';
import 'package:viopname/ui/pages/home_page.dart';
import 'package:viopname/ui/pages/opnames_page.dart';
import 'package:viopname/ui/pages/profile_page.dart';
import 'package:viopname/ui/pages/sign_in_page.dart';
import 'package:viopname/ui/pages/splash_page.dart';

void main() => runApp(const OpVimedika());

class OpVimedika extends StatelessWidget {
  const OpVimedika({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => SplashPage(),
        '/sign-in': (context) => SignInPage(),
        '/branches': (context) => BranchesPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
        '/opnames': (context) => OpnamePages(),
      },
    );
  }
}
