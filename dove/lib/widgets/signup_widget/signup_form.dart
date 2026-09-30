import 'package:flutter/material.dart';
import 'package:movielog/widgets/signup_widget/signup_text_field.dart';
import 'package:movielog/widgets/signup_widget/signup_validators.dart';

class SignupForm extends StatelessWidget {
  const SignupForm({
    super.key,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.onChanged,
  });
  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          SignupTextField(
            label: '닉네임',
            hint: '닉네임을 입력해주세요',
            controller: nicknameController,
            validator: validateNickname,
            onChanged: onChanged,
          ),
          SignupTextField(
            label: '이메일',
            hint: '이메일 주소를 입력해주세요',
            controller: emailController,
            validator: validateEmail,
            onChanged: onChanged,
          ),
          SignupTextField(
            label: '비밀번호',
            hint: '비밀번호를 입력해주세요',
            controller: passwordController,
            validator: validatePassword,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
