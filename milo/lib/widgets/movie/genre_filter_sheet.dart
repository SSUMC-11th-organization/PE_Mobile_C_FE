import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.allGenres,
    required this.initialSelected,
  });

  final List<String> allGenres;
  final Set<String> initialSelected;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late Set<String> selected = {...widget.initialSelected};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '장르 선택',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.allGenres.length,
                itemBuilder: (context, index) {
                  final genre = widget.allGenres[index];
                  final isChecked = selected.contains(genre);

                  return CheckboxListTile(
                    value: isChecked,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selected.add(genre);
                        } else {
                          selected.remove(genre);
                        }
                      });
                    },
                    title: Text(genre),
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
