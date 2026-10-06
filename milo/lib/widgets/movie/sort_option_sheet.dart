import 'package:flutter/material.dart';
import 'package:movielog/data/movie_sort_option.dart';

class SortOptionSheet extends StatelessWidget {
  const SortOptionSheet({super.key, required this.selected});

  final MovieSortOption selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in MovieSortOption.values)
            ListTile(
              title: Text(option.label),
              trailing: selected == option ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, option),
            ),
        ],
      ),
    );
  }
}
