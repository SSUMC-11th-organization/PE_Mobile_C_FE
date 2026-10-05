import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../widgets/sign_up/email_field.dart';
import '../../widgets/sign_up/nickname_field.dart';
import '../../widgets/sign_up/password_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();

  bool agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final canSubmit =
        nicknameController.text.trim().length >= 2 &&
        emailPattern.hasMatch(emailController.text.trim()) &&
        passwordController.text.length >= 8 &&
        agreedToTerms;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 700;

            if (isWideScreen) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: _buildForm(
                      context,
                      canSubmit: canSubmit,
                      isWideScreen: true,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Center(
                    child: Text(
                      '회원가입',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, bodyConstraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: bodyConstraints.maxHeight - 48,
                          ),
                          child: IntrinsicHeight(
                            child: _buildForm(
                              context,
                              canSubmit: canSubmit,
                              isWideScreen: false,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required bool canSubmit,
    required bool isWideScreen,
  }) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWideScreen)
            Text(
              '회원가입',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(color: AppColors.primary),
            ),
          if (isWideScreen) const SizedBox(height: 8),
          Text(
            isWideScreen
                ? 'MovieLog에 오신 것을 환영합니다!'
                : '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          NicknameField(
            controller: nicknameController,
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          EmailField(
            controller: emailController,
            passwordFocusNode: passwordFocusNode,
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            onChanged: (_) {
              setState(() {});
            },
          ),
          if (!isWideScreen) const Spacer(),
          if (isWideScreen) const SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: agreedToTerms,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppColors.outlineVariant),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return Colors.transparent;
                }),
                onChanged: (value) {
                  setState(() {
                    agreedToTerms = value ?? false;
                  });
                },
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text('필수 약관에 동의합니다')),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: const Color(0xFFCCC2DC),
                disabledForegroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: canSubmit
                  ? () {
                      final isValid = formKey.currentState?.validate() ?? false;

                      if (!isValid) {
                        return;
                      }

                      FocusScope.of(context).unfocus();
                      context.go('/home');
                    }
                  : null,
              child: const Text('가입하기'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '이미 계정이 있나요?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(onPressed: () {}, child: const Text('로그인')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
