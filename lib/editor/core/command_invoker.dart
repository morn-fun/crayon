import '../command/basic_command.dart';
import '../exception/command_exception.dart';
import 'controller.dart';
import 'logger.dart';

class CommandInvoker {
  final List<BasicCommand> _undoCommands = [];
  final List<BasicCommand> _redoCommands = [];
  final _maxLength = 500;

  void execute(
    BasicCommand command,
    RichEditorController controller, {
    bool record = true,
  }) {
    try {
      logger.i('execute 【${command.runtimeType}】');
      command.execute(controller);
      if (record) _addCommand(command, _undoCommands);
    } catch (e) {
      throw PerformCommandException(command.runtimeType, e);
    }
  }

  void undo(RichEditorController controller) {
    if (_undoCommands.isEmpty) throw NoCommandException('undo');
    final command = _undoCommands.removeLast();
    try {
      command.undo(controller);
      _addCommand(command, _redoCommands);
    } on Exception catch (e) {
      throw PerformCommandException(command.runtimeType, e);
    }
  }

  void redo(RichEditorController controller) {
    if (_redoCommands.isEmpty) throw NoCommandException('redo');
    final command = _redoCommands.removeLast();
    try {
      command.execute(controller);
      _addCommand(command, _undoCommands);
    } on Exception catch (e) {
      throw PerformCommandException(command.runtimeType, e);
    }
  }

  void _addCommand(BasicCommand command, List<BasicCommand> list) {
    if (list.length >= _maxLength) list.removeAt(0);
    list.add(command);
  }

  void dispose() {
    _undoCommands.clear();
    _redoCommands.clear();
  }
}
