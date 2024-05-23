import 'dart:collection';
import '../../../../editor/extension/unmodifiable.dart';
import '../../core/copier.dart';
import 'table_cell.dart';

class TableCellList {
  final UnmodifiableListView<TableCell> cells;

  TableCellList(List<TableCell> cells, {int initNum = 3})
      : cells = _initCells(cells, initNum);

  TableCellList.empty({int initNum = 3}) : cells = _initCells([], initNum);

  static UnmodifiableListView<TableCell> _initCells(
      List<TableCell> cells, int initNum) {
    if (cells.isEmpty) {
      return UnmodifiableListView(
          List.generate(initNum, (i) => TableCell.empty()));
    }
    return UnmodifiableListView(cells);
  }

  int get length => cells.length;

  TableCell get last => cells.last;

  TableCell get first => cells.first;

  TableCell getCell(int index) => cells[index];

  Map<String, dynamic> toJson() =>
      {'type': '$runtimeType', 'cells': cells.map((e) => e.toJson()).toList()};

  String get text => cells.map((e) => e.text).join(' | ');

  TableCellList insert(int index, List<TableCell> cellList) =>
      TableCellList(cells.insertMore(index, cellList));

  TableCellList replace(int begin, int end, Iterable<TableCell> iterable,
          {int initNum = 3}) =>
      TableCellList(cells.replaceMore(begin, end, iterable), initNum: initNum);

  TableCellList update(int index, ValueCopier<TableCell> copier) =>
      TableCellList(cells.update(index, copier));

  TableCellList updateMore(
          int begin, int end, ValueCopier<List<TableCell>> copier,
          {int initNum = 3}) =>
      TableCellList(cells.updateMore(begin, end, copier), initNum: initNum);
}
