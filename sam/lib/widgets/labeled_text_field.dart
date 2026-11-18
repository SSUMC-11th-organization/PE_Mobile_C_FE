// 위에 회색 라벨이 붙은 입력 칸 (로그인·프로필 수정 디자인)
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const _fieldBorder = Color(0xFFE4E0EC);
const _disabledFill = Color(0xFFEFEDF4);

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.errorText,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  // 지정하면 입력 칸 오른쪽 아래에 '4 / 12'처럼 글자 수를 표시
  final int? maxLength;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          buildCounter: maxLength == null
              ? null
              : (_, {required currentLength, required isFocused, maxLength}) =>
                    Text(
                      '$currentLength / $maxLength',
                      style: AppTextStyles.bodySmall,
                    ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: enabled ? AppColors.black : AppColors.gray,
          ),
          decoration: InputDecoration(
            errorText: errorText,
            filled: true,
            fillColor: enabled ? AppColors.white : _disabledFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _border(_fieldBorder),
            enabledBorder: _border(_fieldBorder),
            disabledBorder: _border(_fieldBorder),
            focusedBorder: _border(AppColors.violet, 1.5),
            errorBorder: _border(error),
            focusedErrorBorder: _border(error, 1.5),
          ),
        ),
      ],
    );
  }
}
