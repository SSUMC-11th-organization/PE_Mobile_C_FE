import 'package:flutter/material.dart';

import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import 'movielog_button.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({super.key, required this.vm, this.moreLabel = '더 보기'});

  final PagedMoviesViewModel vm;
  final String moreLabel;

  @override
  Widget build(BuildContext context) {
    if (!vm.hasMore && !vm.isLoadingMore && vm.loadMoreError == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('모든 영화를 확인했습니다.', textAlign: TextAlign.center),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (vm.loadMoreError != null) Text(vm.loadMoreError!),
          MovieLogButton(
            width: double.infinity,
            label: vm.loadMoreError == null ? '더 보기' : '다음 페이지 다시 시도',
            isLoading: vm.isLoadingMore,
            onPressed: vm.phase == LoadPhase.ready ? vm.loadNextPage : null,
          ),
        ],
      ),
    );
  }
}
