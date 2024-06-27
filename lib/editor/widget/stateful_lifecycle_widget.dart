import 'dart:collection';

import 'package:flutter/material.dart';


class StatefulLifecycleWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<BoxDelegator>? onInit;
  final ValueChanged<BoxDelegator>? onDispose;

  const StatefulLifecycleWidget(
      {super.key, required this.child, this.onInit, this.onDispose});

  @override
  State<StatefulLifecycleWidget> createState() =>
      _StatefulLifecycleWidgetState();
}

class _StatefulLifecycleWidgetState extends State<StatefulLifecycleWidget>
    implements BoxDelegator {
  final key = GlobalKey();

  @override
  void initState() {
    widget.onInit?.call(this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.onDispose?.call(this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: key, child: widget.child);
  }

  @override
  Offset? get globalPosition {
    if (!mounted) return null;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero);
  }
}

abstract class BoxDelegator {
  Offset? get globalPosition;
}

class BoxDelegators {
  final delegators = SplayTreeMap<int, Set<BoxDelegator>>();

  void dispose() => delegators.clear();

  void addBoxDelegator(int index, BoxDelegator delegate) {
    final set = delegators[index] ?? <BoxDelegator>{};
    set.add(delegate);
    delegators[index] = set;
  }

  void removeBoxDelegator(int index, BoxDelegator delegate) {
    final set = delegators[index] ?? <BoxDelegator>{};
    set.remove(delegate);
    delegators[index] = set;
    if (set.isEmpty) delegators.remove(index);
  }

  bool isIndexAlive(int index) => delegators[index]?.isNotEmpty ?? false;

  Iterable<int> get keys => delegators.keys;

  int? getIndex(Offset offset) {
    final keys = delegators.keys.toList();
    double y = offset.dy;
    int left = keys.first, right = keys.last;
    int? nearestIndex = left;
    while (left <= right) {
      final mid = (right + left) ~/ 2;
      final delegator = delegators[mid];
      if (delegator == null || delegator.isEmpty) return null;
      final globalY = delegator.first.globalPosition?.dy;
      if (globalY == null) return null;
      if (globalY <= y) {
        left = mid + 1;
        nearestIndex = mid;
      } else {
        right = mid - 1;
      }
    }
    return nearestIndex;
  }
}
