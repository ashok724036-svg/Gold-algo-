import 'package:flutter/material.dart';

import '../app.dart';
import '../core/config.dart';
import '../core/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isSignUp = false;
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final client = AppConfig.supabase;
      if (client == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ShellScreen()),
          );
        }
        return;
      }
      if (isSignUp) {
        await client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ShellScreen()),
        );
      }
    } catch (e) {
      setState(() => error = 'Unable to sign in. Check your details and try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_graph_rounded, color: AppTheme.gold, size: 42),
                const SizedBox(height: 28),
                Text('GoldScalper Pro', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 10),
                Text(
                  'Paper trade XAUUSD with disciplined bots. No broker connection. No real money.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: AppTheme.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : submit,
                    child: Text(loading ? 'Connecting…' : isSignUp ? 'Create account' : 'Sign in'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => isSignUp = !isSignUp),
                  child: Text(isSignUp ? 'Already have an account? Sign in' : 'New here? Create an account'),
                ),
                const SizedBox(height: 22),
                const Text('LOCAL PAPER MODE', style: TextStyle(color: AppTheme.gold, letterSpacing: 1.4, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  'Without Supabase build settings, you can explore the paper dashboard locally. Live sync becomes available once the project is configured.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}