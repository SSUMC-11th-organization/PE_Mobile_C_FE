import 'package:flutter/material.dart';

import '../../models/movie_sort.dart';
import '../../theme/app_colors.dart';

class MovieSortButton extends StatelessWidget {
  const MovieSortButton({
    super.key,
    required this.selectedSort,
    required this.onSelected,
  });

  final MovieSort selectedSort;
  final ValueChanged<MovieSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MovieSort>(
      icon: const Icon(Icons.sort, color: AppColors.primary),
      tooltip: '정렬',
      initialValue: selectedSort,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final sort in MovieSort.values)
          PopupMenuItem(value: sort, child: Text(sort.label)),
      ],
    );
  }
}
