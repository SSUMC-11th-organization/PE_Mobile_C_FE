import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'movie_rating_input.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.initialRating = 0});

  final double initialRating;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double rating = widget.initialRating;

  int _resetCount = 0;

  void _reset() {
    setState(() {
      rating = 0;
      _resetCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '영화는 어떠셨나요?',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            MovieRatingInput(
              key: ValueKey(_resetCount),
              rating: rating,
              onChanged: (value) => setState(() => rating = value),
            ),
            TextButton(
              onPressed: rating == 0 ? null : _reset,
              child: const Text('다시 선택하기'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: rating == 0
                    ? null
                    : () => Navigator.of(context).pop(rating),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.buttonDisabled,
                  disabledForegroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
