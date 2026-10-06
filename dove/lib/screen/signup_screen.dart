import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/widgets/signup_widget/signup_appbar.dart';
import 'package:movielog/widgets/signup_widget/signup_form.dart';
import 'package:movielog/widgets/signup_widget/signup_intro.dart';
import 'package:movielog/widgets/signup_widget/signup_login_link.dart';
import 'package:movielog/widgets/signup_widget/signup_submit_button.dart';
import 'package:movielog/widgets/signup_widget/signup_terms_checkbox.dart';
import 'package:movielog/widgets/signup_widget/signup_validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;
  bool get _canSubmit =>
      validateNickname(_nicknameController.text) == null &&
      validateEmail(_emailController.text) == null &&
      validatePassword(_passwordController.text) == null &&
      _agreedToTerms;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 회원가입 화면에서는 뒤로 가기가 동작하지 않는다
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: SignupAppbar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SignupIntro(),
                SignupForm(
                  nicknameController: _nicknameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                SignupTermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (checked) =>
                      setState(() => _agreedToTerms = checked),
                ),
                const SizedBox(height: 16),
                SignupSubmitButton(
                  onPressed: _canSubmit ? () => context.go('/home') : null,
                ),
                const SizedBox(height: 16),
                SignupLoginLink(onPressed: () => debugPrint('로그인을 눌렀습니다.')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
