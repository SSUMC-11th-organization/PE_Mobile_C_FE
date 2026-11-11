import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '비밀번호',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: obscureText,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: '영문, 숫자 포함 8자 이상',
            filled: true,
            fillColor: const Color(0xFFFFFDFC),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFFDCD5E5)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            suffixIcon: IconButton(
              tooltip: obscureText ? '비밀번호 보이기' : '비밀번호 숨기기',
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  obscureText = !obscureText;
                });
              },
            ),
          ),
          validator: (value) {
            final password = value ?? '';

            if (password.isEmpty) {
              return '비밀번호를 입력해주세요.';
            }

            if (password.length < 8) {
              return '비밀번호는 8자 이상 입력해주세요.';
            }

            return null;
          },
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) {
            widget.focusNode.unfocus();
          },
        ),
      ],
    );
  }
}
