import 'package:flutter/material.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/user/user_home_screen.dart';

class NavigationUtils {
  static void navigateToHome(BuildContext context, String role) {
    if (role == 'ADMIN') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserHomeScreen()),
        (route) => false,
      );
    }
  }
}

