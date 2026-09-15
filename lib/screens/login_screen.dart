import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_strings.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegistering = false;

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showErrorSnackBar(AppStrings.emptyCredentialsError);
      return;
    }

    final email = identifier.contains('@')
        ? identifier
        : '${identifier.toLowerCase().replaceAll(' ', '')}@labred.app';

    setState(() => _isLoading = true);

    try {
      if (_isRegistering) {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        String uid = userCredential.user!.uid;
        String username = identifier.contains('@')
            ? identifier.split('@')[0]
            : identifier;

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'username': username,
          'isAnonymous': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _saveSessionAndNavigate(username, uid, false);
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        String uid = userCredential.user!.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        String actualUsername = userDoc.exists && userDoc.data() != null
            ? (userDoc.data() as Map<String, dynamic>)['username'] ?? identifier
            : identifier;

        bool isAnon = userDoc.exists && userDoc.data() != null
            ? (userDoc.data() as Map<String, dynamic>)['isAnonymous'] ?? false
            : false;

        await _saveSessionAndNavigate(actualUsername, uid, isAnon);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message ?? AppStrings.serverError);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('${AppStrings.connectionError}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAnonymously() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInAnonymously();
      String uid = userCredential.user!.uid;
      String anonUsername =
          '${AppStrings.anonymousUser}_${uid.substring(0, 5)}';

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'username': anonUsername,
        'isAnonymous': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _saveSessionAndNavigate(anonUsername, uid, true);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('${AppStrings.anonymousError}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSessionAndNavigate(
    String username,
    String uid,
    bool isAnon,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', username);
    await prefs.setString('current_uid', uid);
    await prefs.setBool('is_anonymous', isAnon);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HomeScreen(currentUserId: username, isAnonymous: isAnon),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _identifierController,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: AppStrings.usernameLabel,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: AppStrings.passwordLabel,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
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
                  : () => setState(() => _isRegistering = !_isRegistering),
              child: Text(
                _isRegistering
                    ? AppStrings.hasAccountQuestion
                    : AppStrings.noAccountQuestion,
              ),
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.no_accounts),
              label: const Text(AppStrings.anonymousGuestButton),
              onPressed: _isLoading ? null : _loginAnonymously,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
