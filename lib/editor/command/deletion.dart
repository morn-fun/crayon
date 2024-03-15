import 'package:pre_editor/editor/core/controller.dart';

import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../node/basic_node.dart';
import 'basic_command.dart';

class DeleteWhileEditing implements BasicCommand{

  final EditingCursor cursor;

  DeleteWhileEditing(this.cursor);


  @override
  void run(RichEditorController controller) {
    try {

    } on DeleteRequiresNewLineException{

    }
  }

}

class Deletion implements BasicCommand{


  @override
  void run(RichEditorController controller) {
    // TODO: implement execute
  }

  @override
  void undo(RichEditorController controller) {
    // TODO: implement undo
  }

}