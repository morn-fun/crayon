
import '../command/basic.dart';
import '../exception/command.dart';
import 'context.dart';
import 'editor_controller.dart';
import 'logger.dart';

class CommandInvoker {
  final List<UpdateControllerOperation> _undoOperations = [];
  final List<UpdateControllerOperation> _redoOperations = [];

  final tag = 'RichEditorController';

  void execute(BasicCommand command, NodesOperator operator,
      {bool noThrottle = false}) {
    try {
      logger.i('$tag, execute 【$command】');
      final c = command.run(operator);
      final enableThrottle = c?.enableThrottle ?? true;
      if (noThrottle || !enableThrottle) {
        _addToUndoCommands(c);
      } else {
        Throttle.execute(() {
          _addToUndoCommands(c);
        }, tag: tag);
      }
      _redoOperations.clear();
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$tag, execute', e);
    }
  }

  void undo(RichEditorController controller) {
    if (_undoOperations.isEmpty) throw NoCommandException('undo');
    final command = _undoOperations.removeLast();
    logger.i('undo 【${command.runtimeType}】');
    try {
      _addToRedoCommands(command.update(controller));
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$tag, undo', e);
    }
  }

  void redo(RichEditorController controller) {
    if (_redoOperations.isEmpty) throw NoCommandException('undo');
    final command = _redoOperations.removeLast();
    logger.i('redo 【${command.runtimeType}】');
    try {
      _addToUndoCommands(command.update(controller));
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$tag, redo', e);
    }
  }

  void insertUndoCommand(UpdateControllerOperation c, bool record,
      RichEditorController controller) {
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
