// 영화 목록 화면의 로딩·빈 목록·오류 상태 위젯
import 'package:flutter/material.dart';

import 'empty_view.dart';
import 'error_view.dart';
import 'loading_view.dart';

class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) => const LoadingView();
}

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) =>
      const EmptyView(message: '표시할 영화가 없습니다.');
}

class MovieListError extends StatelessWidget {
  const MovieListError({super.key, this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      ErrorView(message: message ?? '알 수 없는 오류가 발생했습니다.', onRetry: onRetry);
}
