import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  final AuthService _authService = AuthService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = await _authService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        requireEmailVerified: false, // change to true if you want to enforce verification
      );

      // On success navigate to products
      if (user != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/products');
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Authentication error';
      if (e.code == 'user-not-found') message = 'ဤအကောင့်မရှိပါ။';
      if (e.code == 'wrong-password') message = 'စကားဝှက် မှားနေပါသည်။';
      if (e.code == 'email-not-verified') {
        message = 'Email မသိမ်းဆည်းထားသေးပါ။ ကျေးဇူးပြု၍ အီးမေးလ်ကို စစ်ဆေးပြီး verify လုပ်ပါ။';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('အမှားတစ်ခု ဖြစ်ပါသည်: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moegyishop - Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email ထည့်ပါ';
                      if (!v.contains('@')) return 'အမှန်တကယ် Email ဖြင့်ဖြည့်ပါ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password ထည့်ပါ';
                      if (v.length < 6) return 'Password အနည်းဆုံး 6 လုံး';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Log in'),
                        ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text('No account? Sign up'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final email = _emailCtrl.text.trim();
                      if (email.isEmpty) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Email ထည့်ပါ')),
                        );
                        return;
                      }
                      try {
                        await _authService.sendPasswordReset(email: email);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Password reset email ပို့ပြီးပါပြီ')),
                        );
                      } on FirebaseAuthException catch (e) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text(e.message ?? 'Error sending reset email')),
                        );
                      }
                    },
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
