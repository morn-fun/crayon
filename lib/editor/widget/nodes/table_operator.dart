import 'package:flutter/material.dart';

class TableOperator extends StatelessWidget {
  final List<double> heights;
  final List<double> widths;
  final int? selectedRow;
  final int? selectedColumn;
  final double iconSize;
  final ValueChanged<int>? onRowSelected;
  final ValueChanged<int>? onRowAdd;
  final ValueChanged<int>? onRowDelete;
  final ValueChanged<int>? onColumnSelected;
  final ValueChanged<int>? onColumnAdd;
  final ValueChanged<int>? onColumnDelete;

  const TableOperator({
    super.key,
    required this.heights,
    this.selectedRow,
    this.onRowSelected,
    this.onColumnSelected,
    this.onRowAdd,
    this.onColumnAdd,
    required this.iconSize,
    required this.widths,
    this.selectedColumn,
    this.onRowDelete,
    this.onColumnDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor.withOpacity(0.2);
    final yList = [0.0];
    final xList = [0.0];
    for (var h in heights) {
      yList.add(yList.last + h);
    }
    for (var w in widths) {
      xList.add(xList.last + w);
    }
    return Stack(
      fit: StackFit.loose,
      children: [
        Container(
          width: iconSize,
          margin: EdgeInsets.only(left: xList.last, top: iconSize),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(heights.length, (index) {
              final height = heights[index];
              final selected = selectedRow == index;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (selected) return;
                    onRowSelected?.call(index);
                  },
                  child: Container(
                    height: height,
                    color: selected ? Colors.blue : dividerColor,
                    child: Center(
                        child: GestureDetector(
                      onTap: () => onRowDelete?.call(index),
                      child:
                          Icon(Icons.remove_rounded, size: iconSize, color: Colors.red),
                    )),
                  ),
                ),
              );
            }),
          ),
        ),
        ...List.generate(yList.length, (index) {
          final h = yList[index];
          bool isFirst = index == 0;
          bool isLast = index == yList.length - 1;
          return Positioned(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  onRowAdd?.call(index);
                },
                child: Icon(
                  Icons.add,
                  size: iconSize,
                  color: Colors.blue,
                ),
              ),
            ),
            left: xList.last,
            top: isFirst ? iconSize : (isLast ? h : h + iconSize / 2),
          );
        }),
        SizedBox(
          height: iconSize,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widths.length, (index) {
              final w = widths[index];
              final selected = selectedColumn == index;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (selected) return;
                    onColumnSelected?.call(index);
                  },
                  child: Container(
                    width: w,
                    height: iconSize,
                    color: selected ? Colors.blue : dividerColor,
                    child: Center(
                        child: GestureDetector(
                      onTap: () => onColumnDelete?.call(index),
                      child:
                          Icon(Icons.remove_rounded, size: iconSize, color: Colors.red),
                    )),
                  ),
                ),
              );
            }),
          ),
        ),
        ...List.generate(xList.length, (index) {
          final w = xList[index];
          bool isFirst = index == 0;
          bool isLast = index == xList.length - 1;
          return Positioned(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  onColumnAdd?.call(index);
                },
                child: Icon(
                  Icons.add,
                  size: iconSize,
                  color: Colors.blue,
                ),
              ),
            ),
            left: isFirst ? 0 : (isLast ? w - iconSize : w - iconSize / 2),
            top: 0,
          );
        }),
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
