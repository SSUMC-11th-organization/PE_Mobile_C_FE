import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';

class SignupTextField extends StatelessWidget {
  const SignupTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    final isEmpty = text.isEmpty;
    final hasError = !isEmpty && validator(text) != null;
    final isValid = !isEmpty && validator(text) == null;

    Widget? suffixIcon;
    if (hasError) {
      suffixIcon = const Icon(Icons.error_outline, color: AppColors.error);
    } else if (isValid) {
      suffixIcon = const Icon(Icons.check_circle, color: AppColors.primary);
    }

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    );

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: hasError ? AppColors.errorFill : AppColors.inputFill,
              suffixIcon: suffixIcon,
              errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
              errorBorder: errorBorder,
              focusedErrorBorder: errorBorder,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.inputBorder,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.inputBorder,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
