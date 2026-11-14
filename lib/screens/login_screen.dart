import '../widgets/app_logo.dart';
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
final _optionalEmailController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmPasswordController = TextEditingController();

bool _isLoading = false;
bool _isRegistering = false;

@override
void dispose() {
_identifierController.dispose();
_optionalEmailController.dispose();
_passwordController.dispose();
_confirmPasswordController.dispose();
super.dispose();
}

Future<void> _submit() async {
final identifier = _identifierController.text.trim();
final password = _passwordController.text.trim();

if (_isRegistering) {
final optionalEmail = _optionalEmailController.text.trim();
final confirmPassword = _confirmPasswordController.text.trim();

if (identifier.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
_showErrorSnackBar(AppStrings.emptyNameOrPasswordError);
return;
}

if (optionalEmail.isNotEmpty &&
(!optionalEmail.contains('@') || !optionalEmail.contains('.'))) {
_showErrorSnackBar(AppStrings.invalidOptionalEmailError);
return;
}

if (password != confirmPassword) {
_showErrorSnackBar(AppStrings.passwordsDoNotMatchError);
return;
}

final username = identifier;
final authEmail = optionalEmail.isNotEmpty
? optionalEmail
: '${username.toLowerCase().replaceAll(' ', '')}@labred.app';

setState(() => _isLoading = true);

try {
final existingUser = await FirebaseFirestore.instance
.collection('users')
.doc(username)
.get();
if (existingUser.exists) {
if (!mounted) return;
_showErrorSnackBar(AppStrings.usernameAlreadyExistsError);
setState(() => _isLoading = false);
return;
}

UserCredential userCredential = await FirebaseAuth.instance
.createUserWithEmailAndPassword(email: authEmail, password: password);

String uid = userCredential.user!.uid;

await FirebaseFirestore.instance.collection('users').doc(username).set({
'uid': uid,
'email': authEmail,
'username': username,
'isAnonymous': false,
'workoutStreak': 0,
'dietStreak': 0,
'createdAt': FieldValue.serverTimestamp(),
});

await _saveSessionAndNavigate(username, uid, false);
} on FirebaseAuthException catch (e) {
if (!mounted) return;
_showErrorSnackBar(e.message ?? AppStrings.serverError);
} catch (e) {
if (!mounted) return;
_showErrorSnackBar('${AppStrings.connectionError}:$e');
} finally {
if (mounted) setState(() => _isLoading = false);
}
return;
}

// Modo Iniciar Sesión
if (identifier.isEmpty || password.isEmpty) {
_showErrorSnackBar(AppStrings.emptyCredentialsError);
return;
}

setState(() => _isLoading = true);

try {
String emailToSignIn = identifier.contains('@')
? identifier
: '${identifier.toLowerCase().replaceAll(' ', '')}@labred.app';

// Si inició sesión con nombre de usuario y registró un correo real opcional, buscar su email en Firestore
if (!identifier.contains('@')) {
final userDoc = await FirebaseFirestore.instance
.collection('users')
.doc(identifier)
.get();
if (userDoc.exists && userDoc.data() != null) {
final storedEmail = (userDoc.data()!['email'] ?? '').toString();
if (storedEmail.isNotEmpty) {
emailToSignIn = storedEmail;
}
}
}

UserCredential userCredential = await FirebaseAuth.instance
.signInWithEmailAndPassword(email: emailToSignIn, password: password);

String uid = userCredential.user!.uid;

final queryByUid = await FirebaseFirestore.instance
.collection('users')
.where('uid', isEqualTo: uid)
.limit(1)
.get();

String actualUsername = identifier.contains('@')
? identifier.split('@')[0]
: identifier;
bool isAnon = false;

if (queryByUid.docs.isNotEmpty) {
final data = queryByUid.docs.first.data();
actualUsername = data['username'] ?? actualUsername;
isAnon = data['isAnonymous'] ?? false;
} else {
DocumentSnapshot userDoc = await FirebaseFirestore.instance
.collection('users')
.doc(actualUsername)
.get();

if (userDoc.exists && userDoc.data() != null) {
final data = userDoc.data() as Map<String, dynamic>;
actualUsername = data['username'] ?? actualUsername;
isAnon = data['isAnonymous'] ?? false;
}
}

await _saveSessionAndNavigate(actualUsername, uid, isAnon);
} on FirebaseAuthException catch (e) {
if (!mounted) return;
_showErrorSnackBar(e.message ?? AppStrings.serverError);
} catch (e) {
if (!mounted) return;
_showErrorSnackBar('${AppStrings.connectionError}:$e');
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

await FirebaseFirestore.instance
.collection('users')
.doc(anonUsername)
.set({
'uid': uid,
'username': anonUsername,
'isAnonymous': true,
'createdAt': FieldValue.serverTimestamp(),
});

await _saveSessionAndNavigate(anonUsername, uid, true);
} catch (e) {
if (!mounted) return;
_showErrorSnackBar('${AppStrings.anonymousError}:$e');
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
const SizedBox(height: 64),
const AppLogo(size: 96, borderRadius: 18),
const SizedBox(height: 16),
const Text(
AppStrings.appName,
style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
),
const SizedBox(height: 32),
TextField(
controller: _identifierController,
enabled: !_isLoading,
decoration: InputDecoration(
labelText: _isRegistering
? AppStrings.registerNameLabel
: AppStrings.usernameLabel,
border: const OutlineInputBorder(),
prefixIcon: const Icon(Icons.person),
),
),
if (_isRegistering) ...[
const SizedBox(height: 16),
TextField(
controller: _optionalEmailController,
enabled: !_isLoading,
keyboardType: TextInputType.emailAddress,
decoration: const InputDecoration(
labelText: AppStrings.optionalEmailLabel,
border: OutlineInputBorder(),
prefixIcon: Icon(Icons.email_outlined),
),
),
],
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
if (_isRegistering) ...[
const SizedBox(height: 16),
TextField(
controller: _confirmPasswordController,
enabled: !_isLoading,
obscureText: true,
decoration: const InputDecoration(
labelText: AppStrings.confirmPasswordLabel,
border: OutlineInputBorder(),
prefixIcon: Icon(Icons.lock_outline),
),
),
],
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
: () {
setState(() {
_isRegistering = !_isRegistering;
_confirmPasswordController.clear();
});
},
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
