// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import '../services/drive_service.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _trySilent();
  }

  Future<void> _trySilent() async {
    setState(() => _loading = true);
    final ok = await DriveService.instance.trySilentSignIn();
    if (ok && mounted) {
      await AppState.instance.fetchAll();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await DriveService.instance.signIn();
      if (!ok) {
        setState(() { _loading = false; _error = 'Sign-in cancelled.'; });
        return;
      }
      await AppState.instance.fetchAll();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('ApiException: 10')) {
      return 'Configuration error (code 10). The SHA-1 fingerprint or '
             'package name registered on Google Cloud Console does not '
             'match this build. Check Project Settings → Credentials.';
    }
    if (raw.contains('ApiException: 7')) {
      return 'Network error. Check your internet connection.';
    }
    if (raw.contains('ApiException: 12500')) {
      return 'Google Play Services issue. Make sure the emulator/device '
             'has Google Play Services installed and updated.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.book_rounded,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('Ledger',
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: AppTheme.text, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text('Personal expense tracker',
                  style: TextStyle(fontSize: 14, color: AppTheme.text2)),
              const SizedBox(height: 48),

              if (_loading)
                const Column(children: [
                  CircularProgressIndicator(color: AppTheme.accent),
                  SizedBox(height: 16),
                  Text('Connecting to Google Drive...',
                      style: TextStyle(fontSize: 13, color: AppTheme.text2)),
                ])
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _signIn,
                    icon: const Text('G',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: AppTheme.accent)),
                    label: const Text('Sign in with Google',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: AppTheme.text)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.border, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.red),
                      textAlign: TextAlign.center),
                ),
              ],

              const SizedBox(height: 48),
              const Text(
                'Your data stays in your own Google Drive.\nNo external servers.',
                style: TextStyle(fontSize: 11, color: AppTheme.text3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
