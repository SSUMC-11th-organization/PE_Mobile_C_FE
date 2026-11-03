import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/signup_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SignUpViewModel>(
      create: (context) => SignUpViewModel(context.read<MemberCheckService>()),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          toolbarHeight: 64,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/arrow_back.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  AppColors.onSurfaceVariant,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {}, // 아직 기능 없음
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                shape: const CircleBorder(),
              ),
            ),
          ),
          title: Text(
            '회원가입',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontSize: 24,
            ),
          ),
        ),
        body: const SafeArea(child: SignBody()),
      ),
    );
  }
}

class SignBody extends StatelessWidget {
  const SignBody({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxFormWidth = constraints.maxWidth >= 700
            ? 560.0
            : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxFormWidth),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: const SignUpForm(),
            ),
          ),
        );
      },
    );
  }
}

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

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

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

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.go('/home');
    }
  }

  Widget _checkMessage({
    required CheckStatus status,
    required String? errorText,
    required String availableText,
  }) {
    if (status == CheckStatus.available) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          availableText,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: AppColors.primary,
          ),
        ),
      );
    }
    if (status == CheckStatus.error && errorText != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          errorText,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: Colors.red,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

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

            // 닉네임
            Consumer<SignUpViewModel>(
              builder: (context, viewModel, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MovieLogTextFormField(
                            label: '닉네임',
                            hint: '닉네임을 입력해주세요',
                            controller: nicknameController,
                            needsVerification: true,
                            isVerified:
                                viewModel.nicknameCheckStatus ==
                                CheckStatus.available,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final nickname = value?.trim() ?? '';
                              if (nickname.isEmpty) return '닉네임을 입력해주세요.';
                              if (nickname.length < 2) {
                                return '닉네임은 두 글자 이상 입력해주세요.';
                              }
                              if (viewModel.nicknameCheckStatus ==
                                  CheckStatus.duplicated) {
                                return viewModel.nicknameErrorText;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              viewModel.onNicknameChanged(value);
                              _updateFormValidity();
                            },
                            onFieldSubmitted: (_) =>
                                emailFocusNode.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          // 라벨 높이만큼 내려서 입력창과 맞춥니다. 어긋나면 값만 조절하세요.
                          padding: const EdgeInsets.only(top: 24),
                          child: MovieLogButton(
                            label: '중복 확인',
                            isLoading:
                                viewModel.nicknameCheckStatus ==
                                CheckStatus.checking,
                            onPressed:
                                viewModel.canCheckNickname &&
                                    nicknameController.text.trim().length >= 2
                                ? () async {
                                    await viewModel.checkNickname(
                                      nicknameController.text,
                                    );
                                    if (!mounted) return;
                                    _updateFormValidity();
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    _checkMessage(
                      status: viewModel.nicknameCheckStatus,
                      errorText: viewModel.nicknameErrorText,
                      availableText: '사용할 수 있는 닉네임입니다.',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // 이메일
            Consumer<SignUpViewModel>(
              builder: (context, viewModel, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MovieLogTextFormField(
                            label: '이메일',
                            hint: '이메일 주소를 입력해주세요',
                            controller: emailController,
                            focusNode: emailFocusNode,
                            needsVerification: true,
                            isVerified:
                                viewModel.emailCheckStatus ==
                                CheckStatus.available,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return '이메일을 입력해주세요.';
                              if (!_emailRegex.hasMatch(email)) {
                                return '올바른 이메일 형식이 아닙니다.';
                              }
                              if (viewModel.emailCheckStatus ==
                                  CheckStatus.duplicated) {
                                return viewModel.emailErrorText;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              viewModel.onEmailChanged(value);
                              _updateFormValidity();
                            },
                            onFieldSubmitted: (_) =>
                                passwordFocusNode.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: MovieLogButton(
                            label: '중복 확인',
                            isLoading:
                                viewModel.emailCheckStatus ==
                                CheckStatus.checking,
                            onPressed:
                                viewModel.canCheckEmail &&
                                    emailController.text.trim().length >= 2
                                ? () async {
                                    await viewModel.checkEmail(
                                      emailController.text,
                                    );
                                    if (!mounted) return;
                                    _updateFormValidity();
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    _checkMessage(
                      status: viewModel.emailCheckStatus,
                      errorText: viewModel.emailErrorText,
                      availableText: '사용할 수 있는 이메일입니다.',
                    ),
                  ],
                );
              },
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
            Consumer<SignUpViewModel>(
              builder: (context, viewModel, child) {
                final canSubmit =
                    _agreedToTerms && _isFormValid && viewModel.isReadyToSubmit;
                return MovieLogButton(
                  label: '가입하기',
                  width: double.infinity,
                  onPressed: canSubmit ? _onSubmit : null,
                );
              },
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

class MovieLogTextFormField extends StatefulWidget {
  const MovieLogTextFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.needsVerification = false,
    this.isVerified = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool needsVerification;
  final bool isVerified;

  @override
  State<MovieLogTextFormField> createState() => _MovieLogTextFormFieldState();
}

class _MovieLogTextFormFieldState extends State<MovieLogTextFormField> {
  bool _hasError = false;
  bool _hasValue = false;
  late bool _obscure = widget.obscureText; // 비밀번호 가림 여부 (토글 가능)

  void _updateState(String? value) {
    final error = widget.validator?.call(value);
    final hasError = error != null;
    final hasValue = (value ?? '').trim().isNotEmpty;

    if (hasError != _hasError || hasValue != _hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = hasError;
            _hasValue = hasValue;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? suffixIcon;

    if (widget.obscureText) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off : Icons.visibility,
          color: AppColors.onSurfaceVariant,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    } else if (_hasError) {
      suffixIcon = const Icon(Icons.error_outline, color: Colors.red);
    } else if (widget.needsVerification ? widget.isVerified : _hasValue) {
      suffixIcon = const Icon(Icons.check_circle, color: AppColors.primary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1B20),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: (value) {
            widget.onChanged?.call(value);
          },
          onFieldSubmitted: widget.onFieldSubmitted,
          validator: (value) {
            final error = widget.validator?.call(value);
            _updateState(value);
            return error;
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.hintText,
            ),
            filled: true,
            fillColor: _hasError
                ? Colors.red.withValues(alpha: 0.08)
                : AppColors.surfaceContainer,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 9,
            ),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
