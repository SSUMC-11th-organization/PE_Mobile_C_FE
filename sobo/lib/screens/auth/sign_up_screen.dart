import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/create_member_request.dart';
import '../../theme/app_colors.dart';
import '../../view_models/learning_member_session.dart';
import '../../widgets/sign_up/password_field.dart';

import '../../view_models/sign_up_view_model.dart';
import '../../widgets/movielog_button.dart';

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

  InputDecoration _inputDecoration({
    required String hintText,
    String? errorText,
    bool available = false,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF8E8798)),
      errorText: errorText,
      errorMaxLines: 3,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      filled: true,
      fillColor: const Color(0xFFFFFDFC),
      border: border(const Color(0xFFDCD5E5)),
      enabledBorder: border(const Color(0xFFDCD5E5)),
      focusedBorder: border(AppColors.primary, width: 1.5),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, width: 1.5),
      suffixIcon: available
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
          : null,
    );
  }

  Future<void> onSubmitPressed(BuildContext context) async {
    final viewModel = context.read<SignUpViewModel>();

    if (viewModel.submitStatus == SubmitStatus.submitting) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!agreedToTerms ||
        viewModel.nicknameCheckStatus != CheckStatus.available ||
        viewModel.emailCheckStatus != CheckStatus.available) {
      return;
    }

    FocusScope.of(context).unfocus();

    await viewModel.submit(
      CreateMemberRequest(
        email: emailController.text,
        password: passwordController.text,
        nickname: nicknameController.text,
      ),
    );

    if (!context.mounted) return;

    if (viewModel.submitStatus == SubmitStatus.success &&
        viewModel.createdMemberId != null) {
      context
          .read<LearningMemberSession>()
          .setMemberId(viewModel.createdMemberId!);

      context.go('/movies');
      return;
    }

    final message = viewModel.snackbarMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final canSubmit =
        nicknameController.text.trim().length >= 2 &&
        nicknameController.text.trim().length <= 12 &&
        emailPattern.hasMatch(emailController.text.trim()) &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*]).{8,}$').hasMatch(passwordController.text) &&
        agreedToTerms;

    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) => PopScope(
        canPop: viewModel.submitStatus != SubmitStatus.submitting,
        child: child!,
      ),
      child: Scaffold(
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

          Consumer<SignUpViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '닉네임',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: nicknameController,
                          decoration: _inputDecoration(
                            hintText: '닉네임을 입력해 주세요',
                            errorText: viewModel.nicknameErrorText,
                            available:
                                viewModel.nicknameCheckStatus ==
                                CheckStatus.available,
                          ),
                          validator: (value) {
                            final nickname = value?.trim() ?? '';

                            if (nickname.isEmpty) {
                              return '닉네임을 입력해 주세요.';
                            }
                            if (nickname.length < 2) {
                              return '닉네임은 두 글자 이상 입력해 주세요.';
                            }

                            if (nickname.length > 12) return '닉네임은 12자 이하로 입력해 주세요.';
                            return null;
                          },
                          onChanged: (value) {
                            viewModel.onNicknameChanged(value);

                            // 기존 가입하기 버튼의 활성 조건도 다시 계산합니다.
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      MovieLogButton(
                        label: '중복 확인',
                        isLoading:
                            viewModel.nicknameCheckStatus ==
                            CheckStatus.checking,
                        onPressed: viewModel.canCheckNickname
                            ? () => viewModel.checkNickname(
                                nicknameController.text,
                              )
                            : null,
                      ),
                    ],
                  ),
                  if (viewModel.nicknameCheckStatus == CheckStatus.checking)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '닉네임 사용 가능 여부를 확인 중입니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (viewModel.nicknameCheckStatus == CheckStatus.available)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '사용 가능한 닉네임입니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          Consumer<SignUpViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이메일',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: _inputDecoration(
                            hintText: 'movie@umc.com',
                            errorText: viewModel.emailErrorText,
                            available:
                                viewModel.emailCheckStatus ==
                                CheckStatus.available,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return '이메일을 입력해 주세요.';
                            }

                            final pattern = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!pattern.hasMatch(email)) {
                              return '올바른 이메일 형식을 입력해 주세요.';
                            }

                            return null;
                          },
                          onChanged: (value) {
                            viewModel.onEmailChanged(value);
                            setState(() {});
                          },
                          onFieldSubmitted: (_) {
                            passwordFocusNode.requestFocus();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      MovieLogButton(
                        label: '중복 확인',
                        isLoading: viewModel.emailCheckStatus == CheckStatus.checking,
                        onPressed: viewModel.canCheckEmail
                            ? () => viewModel.checkEmail(emailController.text)
                            : null,
                      ),
                    ],
                  ),
                  if (viewModel.emailCheckStatus == CheckStatus.checking)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '이메일 사용 가능 여부를 확인 중입니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (viewModel.emailCheckStatus == CheckStatus.available)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '사용 가능한 이메일입니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          Consumer<SignUpViewModel>(
            builder: (context, viewModel, child) {
              return PasswordField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                errorText: viewModel.passwordErrorText,
                onChanged: (_) {
                  viewModel.onPasswordChanged();
                  setState(() {});
                },
              );
            },
          ),

          const SizedBox(height: 24),

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

          Consumer<SignUpViewModel>(
            builder: (context, viewModel, child) {
              final isSubmitting = viewModel.submitStatus == SubmitStatus.submitting;
              final enabled = canSubmit &&
                  viewModel.nicknameCheckStatus == CheckStatus.available &&
                  viewModel.emailCheckStatus == CheckStatus.available &&
                  !isSubmitting;
              return MovieLogButton(
                label: '가입하기',
                width: double.infinity,
                isLoading: isSubmitting,
                onPressed: enabled ? () => onSubmitPressed(context) : null,
              );
            },
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
