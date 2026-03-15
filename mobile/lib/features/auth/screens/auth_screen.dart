import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

enum _Mode { login, signUp }

/// Email + password auth screen (login and sign-up).
///
/// Sign-up flow:
///   1. supabase.auth.signUp()  — creates Supabase identity
///   2. POST /api/v1/auth/register — creates the DB user row with macro targets
///
/// Login flow:
///   1. supabase.auth.signInWithPassword()
///   → [AuthGate] detects the new session and navigates to DashboardScreen.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _Mode _mode = _Mode.login;

  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _loading     = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      if (_mode == _Mode.login) {
        await _login();
      } else {
        await _signUp();
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } on DioException catch (e) {
      final detail = (e.response?.data as Map?)?['detail'] as String?
          ?? 'Could not create your profile. Please try again.';
      _showError(detail);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    await Supabase.instance.client.auth.signInWithPassword(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    // AuthGate will react to onAuthStateChange and redirect automatically.
  }

  Future<void> _signUp() async {
    final response = await Supabase.instance.client.auth.signUp(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (response.session == null) {
      // Email confirmation required — Supabase sent a confirmation link.
      if (mounted) {
        _showInfo('Check your email to confirm your account, then log in.');
        setState(() => _mode = _Mode.login);
      }
      return;
    }

    // Email confirmation disabled (common in dev) — session is live immediately.
    // Create the DB user row now.
    await _registerProfile();
    // AuthGate will redirect on its own once the session stream fires.
  }

  Future<void> _registerProfile() async {
    final dio = ref.read(apiClientProvider);
    await dio.post<void>(
      '/api/v1/auth/register',
      data: {
        'name':  _nameCtrl.text.trim().isEmpty
            ? _emailCtrl.text.split('@').first
            : _nameCtrl.text.trim(),
        'email':    _emailCtrl.text.trim(),
        'timezone': DateTime.now().timeZoneName,
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final isSignUp = _mode == _Mode.signUp;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo / headline ──────────────────────────────────────
                    Icon(
                      Icons.local_fire_department_rounded,
                      size:  64,
                      color: AppColors.primaryLime,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FitBuddy',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color:      cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSignUp ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Name field (sign-up only) ─────────────────────────────
                    if (isSignUp) ...[
                      _Field(
                        controller: _nameCtrl,
                        label:      'Full name',
                        icon:       Icons.person_outline_rounded,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Email ─────────────────────────────────────────────────
                    _Field(
                      controller:  _emailCtrl,
                      label:       'Email',
                      icon:        Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Password ──────────────────────────────────────────────
                    TextFormField(
                      controller:  _passCtrl,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _inputDecoration(
                        context,
                        label: 'Password',
                        icon:  Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.onSurfaceMuted,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your password';
                        if (isSignUp && v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── Submit button ─────────────────────────────────────────
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryLime,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.black,
                                ),
                              )
                            : Text(
                                isSignUp ? 'Create Account' : 'Log In',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize:   16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Toggle mode ───────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSignUp
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _mode = isSignUp ? _Mode.login : _Mode.signUp;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            isSignUp ? 'Log In' : 'Sign Up',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:      AppColors.primaryLime,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable text field ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String                label;
  final IconData              icon;
  final TextInputType?        keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:      controller,
      keyboardType:    keyboardType,
      textInputAction: TextInputAction.next,
      decoration:      _inputDecoration(context, label: label, icon: icon),
      validator:       validator,
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String  label,
  required IconData icon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText:  label,
    prefixIcon: Icon(icon, color: AppColors.onSurfaceMuted),
    filled:     true,
    fillColor:  cs.surfaceContainer,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:   BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:   BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.primaryLime, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
  );
}
