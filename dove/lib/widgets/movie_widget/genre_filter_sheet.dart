import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
Future<Set<String>?> showGenreFilterSheet(
  BuildContext context, {
  required List<String> genres,
  required Set<String> selectedGenres,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        GenreFilterSheet(genres: genres, initialSelected: selectedGenres),
  );
}

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelected,
  });

  final List<String> genres;
  final Set<String> initialSelected;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> _selected = {...widget.initialSelected};

  void _toggle(String genre, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(genre);
      } else {
        _selected.remove(genre);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Material(
          color: AppColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '장르 필터',
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
                    ),
                    Text(
                      '여러 장르를 선택할 수 있어요',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    for (final genre in widget.genres)
                      CheckboxListTile(
                        value: _selected.contains(genre),
                        onChanged: (checked) =>
                            _toggle(genre, checked ?? false),
                        title: Text(genre),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop({..._selected}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
