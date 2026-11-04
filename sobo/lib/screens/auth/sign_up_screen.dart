import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/member/member_api_service.dart';
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
  bool checkingAvailability = false;
  String nicknameResult = '';
  String emailResult = '';

  Future<void> _checkAvailability({
    required bool isNickname,
  }) async {
    final controller =
    isNickname ? nicknameController : emailController;
    final value = controller.text.trim();

    if (value.isEmpty) {
      setState(() {
        if (isNickname) {
          nicknameResult = '닉네임을 입력해주세요.';
        } else {
          emailResult = '이메일을 입력해주세요.';
        }
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      checkingAvailability = true;

      if (isNickname) {
        nicknameResult = '확인 중...';
      } else {
        emailResult = '확인 중...';
      }
    });

    String result;

    try {
      final available = isNickname
          ? await MemberApiService.checkNickname(value)
          : await MemberApiService.checkEmail(value);

      result =
      '$value 검사 결과\n'
          '{"available": $available}\n'
          '${available ? "사용 가능합니다." : "이미 사용 중입니다."}';
    } catch (error) {
      result = '요청 실패: $error';
    }

    if (!mounted) return;

    setState(() {
      checkingAvailability = false;

      // 요청 중 입력이 바뀌었다면 이전 값의 결과는 표시하지 않습니다.
      final currentValue = controller.text.trim();
      final message = currentValue == value ? result : '';

      if (isNickname) {
        nicknameResult = message;
      } else {
        emailResult = message;
      }
    });
  }

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
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    child: _buildForm(
                      context,
                      canSubmit: canSubmit,
                      isWideScreen: false,
                    ),
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
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
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
              setState(() {
                nicknameResult = '';
              });
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: checkingAvailability
                  ? null
                  : () => _checkAvailability(isNickname: true),
              child: const Text('닉네임 중복 확인'),
            ),
          ),
          if (nicknameResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(nicknameResult),
            ),

          const SizedBox(height: 16),

          EmailField(
            controller: emailController,
            passwordFocusNode: passwordFocusNode,
            onChanged: (_) {
              setState(() {
                emailResult = '';
              });
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: checkingAvailability
                  ? null
                  : () => _checkAvailability(isNickname: false),
              child: const Text('이메일 중복 확인'),
            ),
          ),
          if (emailResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(emailResult),
            ),

          const SizedBox(height: 16),

          PasswordField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Checkbox(
                value: agreedToTerms,
                materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(
                  color: AppColors.outlineVariant,
                ),
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
              const Expanded(
                child: Text('필수 약관에 동의합니다'),
              ),
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
              onPressed: canSubmit && !checkingAvailability
                  ? () {
                final isValid =
                    formKey.currentState?.validate() ?? false;

                if (!isValid) return;

                FocusScope.of(context).unfocus();

                // 실제 회원가입 API 연결 전의 기존 임시 이동
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
              TextButton(
                onPressed: () {},
                child: const Text('로그인'),
              ),
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