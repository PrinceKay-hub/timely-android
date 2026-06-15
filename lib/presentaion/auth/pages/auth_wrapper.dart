import 'package:booking/presentaion/auth/pages/auth_login.dart';
import 'package:booking/presentaion/auth/pages/auth_signup.dart';
import 'package:flutter/material.dart';

// Authentication Wrapper Screen
class AuthWrapper extends StatefulWidget {
  final String? from;
  const AuthWrapper({super.key, this.from});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLogin = true;

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLogin
            ? AuthLogin(onToggle: _toggleAuthMode, from: widget.from,)
            : AuthSignup(onToggle: _toggleAuthMode),
      ),
    );
  }
}
