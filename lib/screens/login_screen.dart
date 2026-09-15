import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_strings.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;

  Future<bool> _authenticateWithServer(String username, bool isRegister) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      // Cambiar a 'true' cuando el servidor esté en línea
      bool isServerOnline = false;
      return isServerOnline;
    } catch (e) {
      return false;
    }
  }

  void _submit() async {
    final username = _userController.text.trim();
    if (username.isEmpty) return;

    setState(() => _isLoading = true);

    final bool success = await _authenticateWithServer(
      username,
      _isRegistering,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', username);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(currentUserId: username),
        ),
      );
    } else {
      final actionText = _isRegistering
          ? AppStrings.actionErrorRegister
          : AppStrings.actionErrorLogin;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.serverError}: No se pudo $actionText'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _userController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: AppStrings.usernameLabel,
                hintText: _isRegistering
                    ? AppStrings.registerHint
                    : AppStrings.loginHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isRegistering
                          ? AppStrings.createAccountButton
                          : AppStrings.loginButton,
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                      });
                    },
              child: Text(
                _isRegistering
                    ? AppStrings.hasAccountQuestion
                    : AppStrings.noAccountQuestion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
