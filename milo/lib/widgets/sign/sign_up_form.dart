import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/widgets/sign/movie_log_text_form_field.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;
  bool _isFormValid = false;

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  bool get _canSubmit => _agreedToTerms && _isFormValid;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),

            MovieLogTextFormField(
              label: '닉네임',
              hint: '닉네임을 입력해주세요',
              controller: nicknameController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final nickname = value?.trim() ?? '';
                if (nickname.isEmpty) return '닉네임을 입력해주세요.';
                if (nickname.length < 2) return '닉네임은 두 글자 이상 입력해주세요.';
                return null;
              },
              onChanged: (_) => _updateFormValidity(),
              onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            MovieLogTextFormField(
              label: '이메일',
              hint: '이메일 주소를 입력해주세요',
              controller: emailController,
              focusNode: emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return '이메일을 입력해주세요.';

                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';

                return null;
              },
              onChanged: (_) => _updateFormValidity(),
              onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            MovieLogTextFormField(
              label: '비밀번호',
              hint: '비밀번호를 입력해주세요',
              controller: passwordController,
              focusNode: passwordFocusNode,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return '비밀번호를 입력해주세요.';
                if (password.length < 8) return '비밀번호는 8자 이상 입력해주세요.';
                return null;
              },
              onChanged: (_) => _updateFormValidity(),
            ),
            const SizedBox(height: 144),

            // 약관 동의
            Row(
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '필수 약관에 동의합니다',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 가입하기 버튼
            ElevatedButton(
              onPressed: _canSubmit
                  ? () {
                      if (_formKey.currentState!.validate()) {
                        context.go('/home');
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCCC2DC),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.05),
              ),
              child: const Text(
                '가입하기',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 로그인 링크
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '이미 계정이 있나요?',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF494551),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    debugPrint('로그인 진행');
                  },
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
