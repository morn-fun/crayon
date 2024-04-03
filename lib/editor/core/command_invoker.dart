
import '../command/basic_command.dart';
import '../exception/command_exception.dart';
import 'controller.dart';
import 'logger.dart';

class CommandInvoker {
  final List<UpdateControllerCommand> _undoCommands = [];
  final List<UpdateControllerCommand> _redoCommands = [];

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
      _redoCommands.clear();
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$_tag, execute', e);
    }
  }

  void undo(RichEditorController controller) {
    if (_undoCommands.isEmpty) throw NoCommandException('undo');
    final command = _undoCommands.removeLast();
    logger.i('undo 【${command.runtimeType}】');
    try {
      _addToRedoCommands(command.update(controller));
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$_tag, undo', e);
    }
  }

  void redo(RichEditorController controller) {
    if (_redoCommands.isEmpty) throw NoCommandException('undo');
    final command = _redoCommands.removeLast();
    logger.i('redo 【${command.runtimeType}】');
    try {
      _addToUndoCommands(command.update(controller));
    } catch (e) {
      throw PerformCommandException(command.runtimeType, '$_tag, redo', e);
    }
  }

  void insertUndoCommand(
      UpdateControllerCommand c, bool record, RichEditorController controller) {
    final command = c.update(controller);
    if (record) _addToUndoCommands(command);
  }

  void _addToUndoCommands(UpdateControllerCommand? command) {
    if (command == null) return;
    if (_undoCommands.length >= 100) {
      _undoCommands.removeAt(0);
    }
    _undoCommands.add(command);
  }

  void _addToRedoCommands(UpdateControllerCommand? command) {
    if (command == null) return;
    if (_redoCommands.length >= 100) {
      _redoCommands.removeAt(0);
    }
    _redoCommands.add(command);
  }

  void dispose() {
    _redoCommands.clear();
    _undoCommands.clear();
  }
}

abstract class UpdateControllerCommand {
  UpdateControllerCommand update(RichEditorController controller);

  bool get enableThrottle => true;
}

class Throttle {
  static final _tagMap = <String, int>{};

  static const _t = 'Throttle';

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
    logger.i('$_t,  diff mill:${now.difference(oldTime).inMilliseconds}');
    if (now.isAfter(oldTime)) {
      _tagMap[tag] = now.millisecondsSinceEpoch;
      callBack.call();
      return;
    }
  }
}