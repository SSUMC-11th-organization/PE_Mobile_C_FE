import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/movie_rating_input.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double rating = 0;
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    // return Dialog(
    //   child: Padding(
    //     padding: const EdgeInsets.all(24),
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: submitted ? _buildSubmittedView() : _buildSelectingView(),
    //     ),
    //   ),
    // );
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: submitted ? _buildSubmittedView() : _buildSelectingView(),
        ),
      ),
    );
  }

  ButtonStyle get _confirmButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 48),
    shape: const StadiumBorder(),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );

  ButtonStyle get _textButtonStyle => TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  List<Widget> _buildSelectingView() {
    return [
      const Text(
        '영화는 어떠셨나요?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      const SizedBox(height: 24),
      MovieRatingInput(
        rating: rating,
        onChanged: (value) {
          setState(() => rating = value);
        },
      ),
      const SizedBox(height: 16),
      // Row(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: [
      //     TextButton(
      //       onPressed: rating == 0 ? null : () => setState(() => rating = 0),
      //       child: const Text('초기화'),
      //     ),
      //     const SizedBox(width: 8),
      //     ElevatedButton(
      //       onPressed: rating == 0
      //           ? null
      //           : () => setState(() => submitted = true),
      //       child: const Text('확인'),
      //     ),
      //   ],
      // ),
      TextButton(
        style: _textButtonStyle,
        onPressed: rating == 0 ? null : () => setState(() => rating = 0),
        child: const Text('다시 선택하기'),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        style: _confirmButtonStyle,
        onPressed: rating == 0 ? null : () => setState(() => submitted = true),
        child: const Text('확인'),
      ),
    ];
  }

  List<Widget> _buildSubmittedView() {
    return [
      // const Icon(Icons.check_circle, color: Colors.amber, size: 40),
      const Icon(Icons.check_circle, color: AppColors.primary, size: 40),
      const SizedBox(height: 16),
      Text(
        '$rating점을 저장했습니다',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      const SizedBox(height: 16),
      // Row(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: [
      //     TextButton(
      //       onPressed: () => setState(() => submitted = false),
      //       child: const Text('다시 선택하기'),
      //     ),
      //     const SizedBox(width: 8),
      //     ElevatedButton(
      //       onPressed: () => Navigator.pop(context, rating),
      //       child: const Text('닫기'),
      //     ),
      //   ],
      // ),
      TextButton(
        style: _textButtonStyle,
        onPressed: () => setState(() => submitted = false),
        child: const Text('다시 선택하기'),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        style: _confirmButtonStyle,
        onPressed: () => Navigator.pop(context, rating),
        child: const Text('닫기'),
      ),
    ];
  }
}
