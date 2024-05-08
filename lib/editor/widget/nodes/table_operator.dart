import 'package:flutter/material.dart';

class TableRowOperator extends StatelessWidget {
  final List<double> heights;
  final int? selectedIndex;
  final ValueChanged<int>? onSelect;
  final ValueChanged<int>? onAdd;

  const TableRowOperator({
    super.key,
    required this.heights,
    this.selectedIndex,
    this.onSelect,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;
    final iconPositions = [0.0];
    for (var h in heights) {
      iconPositions.add(iconPositions.last + h);
    }
    return Stack(
      fit: StackFit.loose,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(heights.length, (index) {
            final height = heights[index];
            final selected = selectedIndex == index;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (selected) return;
                  onSelect?.call(index);
                },
                child: Container(
                    width: 10,
                    height: height,
                    color: selected ? Colors.blue : dividerColor),
              ),
            );
          }),
        ),
        ...List.generate(iconPositions.length, (index) {
          final h = iconPositions[index];
          return Positioned(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  onAdd?.call(index);
                },
                child: Icon(
                  Icons.add,
                  size: 10,
                ),
              ),
            ),
            left: 0,
            top: index == 0 ? 0 : h - 10,
          );
        })
      ],
    );
  }
}

class TableColumnOperator extends StatelessWidget {
  final List<double> widths;

  const TableColumnOperator({super.key, required this.widths});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.loose,
      children: [],
    );
  }
}
