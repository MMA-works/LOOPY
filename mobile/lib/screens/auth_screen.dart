import 'package:flutter/material.dart';

import '../app.dart';
import '../core/app_services.dart';
import '../core/api_client.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AppServices.instance.session.authenticate(
        username: _identity.text,
        password: _password.text,
        name: _name.text,
        register: _registering,
      );
      if (mounted) openHome(context);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Backend is unavailable. Check that Looply server is running.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            Theme.of(context).scaffoldBackgroundColor
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(children: [
                              BrandMark(size: 56),
                              SizedBox(width: 14),
                              Text('looply',
                                  style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.8))
                            ]),
                            const SizedBox(height: 28),
                            Text(
                                _registering
                                    ? 'Create your account'
                                    : 'Welcome back',
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1)),
                            const SizedBox(height: 8),
                            Text(
                                _registering
                                    ? 'Join Looply and start a conversation.'
                                    : 'Sign in to continue your conversations.',
                                style: const TextStyle(
                                    color: Color(0xFF77758A), fontSize: 16)),
                            const SizedBox(height: 30),
                            if (_registering) ...[
                              TextFormField(
                                key: const Key('nameField'),
                                controller: _name,
                                decoration: const InputDecoration(
                                    labelText: 'Name',
                                    prefixIcon:
                                        Icon(Icons.person_outline_rounded)),
                                validator: (value) =>
                                    (value ?? '').trim().length < 2
                                        ? 'Please enter your name'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              key: const Key('identityField'),
                              controller: _identity,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: 'Email or username',
                                  prefixIcon:
                                      Icon(Icons.alternate_email_rounded)),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Email or username is required'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const Key('passwordField'),
                              controller: _password,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                              validator: (value) => (value ?? '').length < 8
                                  ? 'Password must be at least 8 characters'
                                  : null,
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              key: const Key('authSubmit'),
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18))),
                              child: _loading
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white))
                                  : Text(
                                      _registering
                                          ? 'Create account'
                                          : 'Sign in',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => setState(
                                      () => _registering = !_registering),
                              child: Text(_registering
                                  ? 'Already have an account? Sign in'
                                  : 'New here? Create an account'),
                            ),
                            const SizedBox(height: 18),
                            const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline_rounded,
                                      size: 14, color: Color(0xFF19A89D)),
                                  SizedBox(width: 5),
                                  Text('Secure connection to Looply',
                                      style: TextStyle(
                                          color: Color(0xFF888395),
                                          fontSize: 12))
                                ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
