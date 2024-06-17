import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/shortcuts/delete.dart';
import 'package:crayon/editor/shortcuts/redo.dart';
import 'package:crayon/editor/shortcuts/undo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';

void main(){
  test('undo-redo', (){
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(EditingCursor(0, ctx.nodes.last.endPosition));
    int i = 0;
    while(i < 10){
      DeleteAction(ActionOperator(ctx)).invoke(DeleteIntent());
      i++;
    }
    assert(ctx.nodes.first.text.isEmpty);

    while(i > 0){
      UndoAction(ActionOperator(ctx)).invoke(UndoIntent());
      i--;
    }
    assert(ctx.nodes.first.text.length == 10);


    while(i < 10){
      RedoAction(ActionOperator(ctx)).invoke(RedoIntent());
      i++;
    }
    assert(ctx.nodes.first.text.isEmpty);
  });
}