
import 'package:flutter/material.dart';
import 'package:moegyishop/screens/auth/signup_screen_with_map.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupScreenWithMap()),
            );
          },
          child: Text('Go to Sign Up with Map'),
        ),
      ),
    );
  }
}
