// 회원가입 화면 구현
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const _background = AppColors.warmWhite;
const _primary = AppColors.violet;
const _primaryDark = AppColors.violet;
const _titleColor = AppColors.black;
const _bodyColor = Color(0xFF49454F);
const _hintColor = Color(0xFF9C9691);
const _fieldBackground = Color(0xFFF4F2EF);
const _fieldBorder = Color(0xFFDCD6CD);
const _errorBackground = Color(0xFFFAD9D9);
const _errorColor = Color(0xFFB3261E);
const _buttonDisabled = Color(0xFFCABEDD);

final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[A-Za-z]{2,}$');

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nicknameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nicknameController,
      _emailController,
      _passwordController,
    ]) {
      controller.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateNickname(String? value) {
    final text = value ?? '';
    if (text.isEmpty || text.length >= 2) return null;
    return '닉네임은 2자 이상이어야 합니다.';
  }

  String? _validateEmail(String? value) {
    final text = value ?? '';
    if (text.isEmpty || _emailRegex.hasMatch(text)) return null;
    return '올바른 이메일 형식이 아닙니다.';
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty || text.length >= 8) return null;
    return '비밀번호는 8자 이상이어야 합니다.';
  }

  bool get _isFormValid =>
      _validateNickname(_nicknameController.text) == null &&
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      _nicknameController.text.isNotEmpty &&
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _agreed;

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_agreed) {
      setState(() {});
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin(context),
            vertical: AppSpacing.sm,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SignupHeader(),
                const SizedBox(height: 28),
                const _WelcomeMessage(),
                const SizedBox(height: 32),
                _SignupTextField(
                  label: '닉네임',
                  hintText: '닉네임을 입력해주세요',
                  controller: _nicknameController,
                  focusNode: _nicknameFocus,
                  nextFocusNode: _emailFocus,
                  validator: _validateNickname,
                ),
                const SizedBox(height: 20),
                _SignupTextField(
                  label: '이메일',
                  hintText: '이메일 주소를 입력해주세요',
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocusNode: _passwordFocus,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                _SignupTextField(
                  label: '비밀번호',
                  hintText: '비밀번호를 입력해주세요',
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  isLast: true,
                  validator: _validatePassword,
                  onSubmitted: _submit,
                ),
                const SizedBox(height: 100),
                _AgreementCheckbox(
                  value: _agreed,
                  onChanged: (value) => setState(() => _agreed = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isFormValid ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryDark,
                      disabledBackgroundColor: _buttonDisabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '가입하기',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _LoginPrompt(onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: _titleColor),
            ),
          ),
          const Text(
            '회원가입',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '환영합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: _bodyColor),
        ),
        SizedBox(height: 4),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: _bodyColor),
        ),
      ],
    );
  }
}

class _SignupTextField extends StatelessWidget {
  const _SignupTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.validator,
    this.nextFocusNode,
    this.obscureText = false,
    this.keyboardType,
    this.isLast = false,
    this.onSubmitted,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final String? Function(String?) validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool isLast;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final errorText = validator(controller.text);
    final hasError = errorText != null;
    final isValid = !hasError && controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: (_) {
            if (isLast) {
              onSubmitted?.call();
            } else if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
          validator: validator,
          style: const TextStyle(fontSize: 16, color: _titleColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: _hintColor),
            filled: true,
            fillColor: hasError ? _errorBackground : _fieldBackground,
            suffixIcon: hasError
                ? const Icon(Icons.error_outline, color: _errorColor)
                : isValid
                ? const Icon(Icons.check_circle, color: _primaryDark)
                : null,
            errorStyle: const TextStyle(fontSize: 13, color: _errorColor),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _errorColor : _fieldBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _errorColor : _fieldBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _errorColor : _primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _errorColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _AgreementCheckbox extends StatelessWidget {
  const _AgreementCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? _primaryDark : Colors.transparent,
              border: Border.all(
                color: value ? _primaryDark : _fieldBorder,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          const Text(
            '필수 약관에 동의합니다',
            style: TextStyle(fontSize: 15, color: _titleColor),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '이미 계정이 있나요? ',
          style: TextStyle(fontSize: 15, color: _bodyColor),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            '로그인',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ),
      ],
    );
  }
}
