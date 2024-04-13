
import '../command/basic_command.dart';
import '../exception/command_exception.dart';
import 'controller.dart';
import 'logger.dart';

class CommandInvoker {
  final List<UpdateControllerOperation> _undoOperations = [];
  final List<UpdateControllerOperation> _redoOperations = [];

  final _tag = 'RichEditorController';

  void execute(BasicCommand command, RichEditorController controller,
      {bool noThrottle = false}) {
    try {
      logger.i('$_tag, execute 【$command】');
      final c = command.run(controller);
      final enableThrottle = c?.enableThrottle ?? true;
      if (noThrottle || !enableThrottle) {
        _addToUndoCommands(c);
      } else {
        Throttle.execute(() {
          _addToUndoCommands(c);
        }, tag: _tag);
      }
      _redoOperations.clear();
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$_tag, execute', e);
    }
  }

  void undo(RichEditorController controller) {
    if (_undoOperations.isEmpty) throw NoCommandException('undo');
    final command = _undoOperations.removeLast();
    logger.i('undo 【${command.runtimeType}】');
    try {
      _addToRedoCommands(command.update(controller));
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$_tag, undo', e);
    }
  }

  void redo(RichEditorController controller) {
    if (_redoOperations.isEmpty) throw NoCommandException('undo');
    final command = _redoOperations.removeLast();
    logger.i('redo 【${command.runtimeType}】');
    try {
      _addToUndoCommands(command.update(controller));
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$_tag, redo', e);
    }
  }

  void insertUndoCommand(
      UpdateControllerOperation c, bool record, RichEditorController controller) {
    final command = c.update(controller);
    if (record) _addToUndoCommands(command);
  }

  void _addToUndoCommands(UpdateControllerOperation? command) {
    if (command == null) return;
    if (_undoOperations.length >= 100) {
      _undoOperations.removeAt(0);
    }
    _undoOperations.add(command);
  }

  void _addToRedoCommands(UpdateControllerOperation? command) {
    if (command == null) return;
    if (_redoOperations.length >= 100) {
      _redoOperations.removeAt(0);
    }
    _redoOperations.add(command);
  }

  void dispose() {
    _redoOperations.clear();
    _undoOperations.clear();
  }
}

abstract class UpdateControllerOperation {
  UpdateControllerOperation update(RichEditorController controller);

  bool get enableThrottle => true;
}

class Throttle {
  static final _tagMap = <String, int>{};

  static void execute(Function callBack,
      {Duration duration = const Duration(milliseconds: 500),
      String tag = 'default'}) {
    final time = _tagMap[tag];
    if (time == null) {
      _tagMap[tag] = DateTime.now().millisecondsSinceEpoch;
      callBack.call();
      return;
    }
    final now = DateTime.now();
    final oldTime = DateTime.fromMillisecondsSinceEpoch(time).add(duration);
    if (now.isAfter(oldTime)) {
      _tagMap[tag] = now.millisecondsSinceEpoch;
      callBack.call();
      return;
    }
  }
}
