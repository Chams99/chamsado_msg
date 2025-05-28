import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'home.dart';
import 'sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  void _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _message = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // First, try to sign in
      final user = await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user == null) {
        setState(() {
          _isLoading = false;
          _message = 'Failed to sign in. Please try again.';
        });
        return;
      }

      try {
        // Then update the user's status
        await UserService().updateUserStatus(user.uid, true);

        if (!mounted) return;

        setState(() {
          _message = "Signed in as: ${user.email}";
          _isLoading = false;
        });

        // Navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user.email!)),
        );
      } catch (e) {
        print('Error updating user status: $e');
        // Even if status update fails, still navigate to home
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user.email!)),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error Code: ${e.code}');
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'invalid-email':
            _message = 'Invalid email format.';
            break;
          case 'user-disabled':
            _message = 'This account has been disabled.';
            break;
          case 'user-not-found':
            _message = 'No user found with this email.';
            break;
          case 'wrong-password':
            _message = 'Password is incorrect.';
            break;
          default:
            _message = 'Password is incorrect.';
        }
      });
    } catch (e) {
      print('Unexpected error during sign in: $e');
      setState(() {
        _isLoading = false;
        _message = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              onSubmitted: (_) => _signIn(),
            ),
            SizedBox(height: 32),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _signIn,
                  child: Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
            SizedBox(height: 24),
            Text(_message, style: TextStyle(color: Colors.red)),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text('Don\'t have an account? Sign Up'),
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
