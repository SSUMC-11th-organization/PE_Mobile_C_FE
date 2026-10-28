import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 45),
            const WeekGreeting(),
            const SizedBox(height: 65),
            const StartIcon(),
            const SizedBox(height: 65),
            const StartTitle(),
            const Spacer(),
            const StartButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class WeekGreeting extends StatelessWidget {
  const WeekGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'FLUTTER 0주차',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
    );
  }
}

class StartTitle extends StatelessWidget {
  const StartTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '영화의 순간을\n기록하세요',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.normal),
        ),
        SizedBox(height: 10),
        Text(
          '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
        ),
      ],
    );
  }
}

class StartIcon extends StatelessWidget {
  const StartIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/movie.svg',
      // 'assets/logos/movielog_logo.svg',
      width: 72,
      height: 72,
      colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
      semanticsLabel: 'MovieLog 로고',
    );
  }
}

class StartButton extends StatelessWidget {
  const StartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: ElevatedButton(
        onPressed: () {
          context.go('/register');
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('시작하기'),
      ),
    );
  }
}
