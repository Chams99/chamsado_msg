import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'home.dart';
import 'sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/translation.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  void _signUp() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });
    try {
      final user = await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          id: user.uid,
          email: user.email!,
          name: _nameController.text.trim(),
          lastSeen: DateTime.now(),
          isOnline: true,
        );
        await UserService().createOrUpdateUser(userModel);

        setState(() {
          _message = AppTranslations.tr('account_created', append: user.email);
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user.email!)),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'email-already-in-use':
            _message = AppTranslations.tr('email_already_in_use');
            break;
          case 'invalid-email':
            _message = AppTranslations.tr('invalid_email');
            break;
          case 'weak-password':
            _message = AppTranslations.tr('weak_password');
            break;
          case 'operation-not-allowed':
            _message = AppTranslations.tr('operation_not_allowed');
            break;
          default:
            _message = AppTranslations.tr('unexpected_error');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = AppTranslations.tr('unexpected_error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
              ),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signUp(),
            ),
            SizedBox(height: 32),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _signUp,
                  child: Text('Sign Up'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
            SizedBox(height: 24),
            Text(_message, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignInPage()),
                );
              },
              child: Text('Already have an account? Sign In'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
