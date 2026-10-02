import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';

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
    } else if (_hasValue) {
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
