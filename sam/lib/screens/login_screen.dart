// 로그인 화면 (Required — 이메일 저장 체크박스는 Challenge에서만 추가)
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_showSessionExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;
    return Scaffold(
      appBar: const CommonAppBar(title: '로그인', centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 64),
              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 84,
                height: 84,
              ),
              const SizedBox(height: 24),
              Text(
                'MovieLog에 로그인',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
              LabeledTextField(
                label: '이메일',
                controller: _email,
                enabled: enabled,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null,
              ),
              const SizedBox(height: 24),
              LabeledTextField(
                label: '비밀번호',
                controller: _password,
                enabled: enabled,
                obscureText: true,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
              ),
              if (auth.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    auth.message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 48),
              MovieLogButton(
                label: '로그인',
                width: double.infinity,
                isLoading: loading,
                onPressed: enabled
                    ? () {
                        if (_formKey.currentState!.validate()) {
                          _auth.login(_email.text.trim(), _password.text);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('계정이 없나요?', style: AppTextStyles.bodySmall),
                  TextButton(
                    onPressed: enabled ? () => context.push('/register') : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.violet,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
