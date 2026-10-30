import 'package:flutter/material.dart';

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.selectedGenres,
  });

  final List<String> genres;
  final List<String> selectedGenres;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> temporarySelectedGenres;

  @override
  void initState() {
    super.initState();
    temporarySelectedGenres = widget.selectedGenres.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '장르 선택',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.genres.length,
                  itemBuilder: (context, index) {
                    final genre = widget.genres[index];

                    return CheckboxListTile(
                      title: Text(genre),
                      value: temporarySelectedGenres.contains(genre),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            temporarySelectedGenres.add(genre);
                          } else {
                            temporarySelectedGenres.remove(genre);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, temporarySelectedGenres.toList());
                    },
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
