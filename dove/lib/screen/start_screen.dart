import 'package:flutter/material.dart';

import '../widgets/start_widget/start_appbar.dart';
import '../widgets/start_widget/start_movie_icon.dart';
import '../widgets/start_widget/start_middleline.dart';
import '../widgets/start_widget/start_button.dart';
import '../theme/app_colors.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: StartAppbar(),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 32, 16, 32),
          child: Column(
            children: [
              SizedBox(height: 24),
              StartMovieIcon(),
              StartMiddleLine(),
              Spacer(),
              StartButton(),
            ],
          ),
        ),
      ),
    );
  }
}
