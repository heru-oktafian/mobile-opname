import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viopname/shared/jwt_utils.dart';
import 'package:viopname/ui/pages/sign_in_page.dart';
import 'package:viopname/ui/pages/home_page.dart';
import 'package:viopname/ui/pages/branches_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token != null && token.isNotEmpty) {
        // Jika token kadaluarsa, hapus dan arahkan ke SignIn
        if (isTokenExpired(token)) {
          await prefs.remove('jwt_token');
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SignInPage()),
            (route) => false,
          );
          return;
        }

        // Token valid: cek apakah ada branch_id di payload
        final branchId = getBranchIdFromToken(token);
        if (branchId != null && branchId.isNotEmpty) {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => BranchesPage(authToken: token),
            ),
            (route) => false,
          );
        }
        return;
      }

      // Tidak ada token -> tampilkan splash singkat lalu ke SignIn
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    } catch (e) {
      // Jika error saat cek sesi, fallback ke SignIn setelah delay
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.10; // 10% kiri dan kanan

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 56, 69, 85),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            height: 175,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img_logo_dark.png'),
                fit: BoxFit.contain, // jaga proporsi gambar
              ),
            ),
          ),
        ),
      ),
    );
  }
}
