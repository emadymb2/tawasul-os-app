import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/session.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _errorCode;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = L10n.of(context);
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _errorCode = 'empty');
      return;
    }
    setState(() {
      _busy = true;
      _errorCode = null;
    });
    final error = await widget.session.signIn(username: _username.text, password: _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _errorCode = error;
    });
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message(strings, error))));
  }

  String _message(L10n strings, String code) {
    switch (code) {
      case 'empty':
        return strings.fillBothFields;
      case 'wrong-credentials':
        return strings.wrongCredentials;
      case 'login-disabled':
        return strings.loginDisabled;
      case 'too-many-attempts':
        return strings.tooManyAttempts;
      case 'connection-failed':
        return strings.networkError;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final scope = LocaleScope.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pine hero with decorative circles
              ClipRect(
                child: Container(
                  color: AppColors.pine,
                  child: Stack(
                    children: [
                      PositionedDirectional(top: -70, end: -60, child: _circle(220, AppColors.red)),
                      PositionedDirectional(bottom: -50, end: 90, child: _circle(120, AppColors.gold)),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 44),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.cream,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(Icons.school_rounded, color: AppColors.pine, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(strings.appName,
                                          style: const TextStyle(
                                              color: AppColors.cream, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
                                      Text(strings.appTagline.toUpperCase(),
                                          style: const TextStyle(
                                              color: AppColors.mintText,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 3)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 56),
                              Text(strings.loginHeadline,
                                  style: const TextStyle(
                                      color: AppColors.cream, fontSize: 38, fontWeight: FontWeight.w900, height: 1.12)),
                              const SizedBox(height: 18),
                              Text(strings.loginSubhead,
                                  style: const TextStyle(color: AppColors.mintText, fontSize: 16, height: 1.5)),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cream sign-in section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(strings.signIn,
                              style: const TextStyle(color: AppColors.pine, fontSize: 34, fontWeight: FontWeight.w900)),
                        ),
                        InkWell(
                          onTap: scope.toggle,
                          borderRadius: BorderRadius.circular(26),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.line, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(strings.language,
                                style: const TextStyle(color: AppColors.pine, fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(strings.signInSubtitle, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                    const SizedBox(height: 26),
                    LabeledField(label: strings.username, controller: _username),
                    LabeledField(label: strings.password, controller: _password, obscure: true),
                    if (_errorCode != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child:
                            Text(_message(strings, _errorCode!), style: const TextStyle(color: AppColors.red, fontSize: 13)),
                      ),
                    PrimaryButton(label: _busy ? strings.signingIn : strings.signIn, onPressed: _submit, busy: _busy),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(30)),
                      child: Text(strings.signInHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.pine, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _circle(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
