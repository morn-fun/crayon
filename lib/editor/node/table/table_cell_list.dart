import 'dart:collection';
import '../../../../editor/extension/unmodifiable.dart';
import '../../core/copier.dart';
import 'table_cell.dart';

class TableCellList {
  final UnmodifiableListView<TableCell> cells;

  TableCellList(List<TableCell> cells) : cells = _initCells(cells);

  TableCellList.empty({int initNum = 3})
      : cells = _initCells([], initNum: initNum);

  static UnmodifiableListView<TableCell> _initCells(List<TableCell> cells,
      {int initNum = 3}) {
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

  List<List<Map<String, dynamic>>> toJson() =>
      cells.map((e) => e.toJson()).toList();

  String get text => cells.map((e) => e.text).join(' | ');

  TableCellList insert(int index, List<TableCell> cellList) =>
      TableCellList(cells.insertMore(index, cellList));

  TableCellList replace(int start, int end, Iterable<TableCell> iterable) =>
      TableCellList(cells.replaceMore(start, end, iterable));

  TableCellList update(int index, ValueCopier<TableCell> copier) =>
      TableCellList(cells.update(index, copier));

  TableCellList updateMore(
      int begin, int end, ValueCopier<List<TableCell>> copier) =>
      TableCellList(cells.updateMore(begin, end, copier));
}