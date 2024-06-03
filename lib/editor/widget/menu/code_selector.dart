import 'package:flutter/material.dart';

class LanguageSelectMenu extends StatefulWidget {
  final List<String> languages;
  final ValueChanged<String> onSelect;
  final VoidCallback onHide;

  const LanguageSelectMenu(
      {super.key,
      required this.languages,
      required this.onSelect,
      required this.onHide});

  @override
  State<LanguageSelectMenu> createState() => _LanguageSelectMenuState();
}

class _LanguageSelectMenuState extends State<LanguageSelectMenu> {
  void hide() => widget.onHide.call();

  late List<String> languages = List.of(widget.languages);

  final ValueNotifier<int> currentIndex = ValueNotifier(1);

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => hide(),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Card(
              elevation: 2,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Container(
                width: 200,
                child: Column(
                  children: [
                    SizedBox(
                      child: TextField(
                        onChanged: (s) {
                          languages.clear();
                          languages.addAll(fuzzySearch(widget.languages, s));
                          currentIndex.value = 0;
                          refresh();
                        },
                        autofocus: true,
                      ),
                    ),
                    Expanded(
                        child: ValueListenableBuilder(
                            valueListenable: currentIndex,
                            builder: (context, v, c) {
                              return ListView.builder(
                                itemBuilder: (ctx, index) {
                                  final isCurrent = index == v;
                                  final l = languages[index];
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    onEnter: (e) {
                                      currentIndex.value = index;
                                    },
                                    child: GestureDetector(
                                      onTap: () {
                                        widget.onSelect.call(l);
                                        hide();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: isCurrent
                                              ? theme.hoverColor
                                              : null,
                                        ),
                                        child: Text(
                                          l,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                itemCount: languages.length,
                              );
                            }))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> fuzzySearch(List<String> items, String searchTerm) {
    List<String> results = [];
    for (String item in items) {
      if (item.contains(searchTerm)) {
        results.add(item);
      }
    }
    return results;
  }
}
