import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:viopname/shared/theme.dart';

void showCustomSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  Flushbar(
    message: message,
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: isError ? AppColors.error : AppColors.primary,
    duration: const Duration(seconds: 2),
  ).show(context);
}
