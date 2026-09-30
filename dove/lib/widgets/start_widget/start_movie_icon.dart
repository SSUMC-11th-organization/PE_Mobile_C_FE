import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StartMovieIcon extends StatelessWidget {
  const StartMovieIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      child: Icon(Icons.movie_outlined, size: 64, color: AppColors.primary),
    );
  }
}
