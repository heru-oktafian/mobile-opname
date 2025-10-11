import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viopname/shared/shared_methods.dart';
import 'package:viopname/ui/pages/sign_in_page.dart';

/// Clear saved session (jwt_token) and navigate to SignInPage.
Future<void> clearSessionAndGoToLogin(
  BuildContext context, {
  String? message,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  } catch (e) {
    // ignore
  }

  if (message != null && message.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCustomSnackBar(context, message, isError: true);
    });
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
      (route) => false,
    );
  });
}

/// Call API logout if needed then clear session and navigate to login.
/// This is a convenience wrapper; projects may want to call their own
/// server-side logout endpoint first.
Future<void> logoutAndClearSession(
  BuildContext context, {
  String? message,
}) async {
  // For now we simply clear session and go to login. If you want to
  // call an API before clearing, implement it here.
  await clearSessionAndGoToLogin(context, message: message);
}
