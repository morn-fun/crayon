import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/shortcuts/optional_menu.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';

void main(){
  test('optional_menu', (){
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    OptionalMenuUpArrowAction(ActionOperator(ctx)).invoke(OptionalMenuUpArrowIntent());
    OptionalMenuDownArrowAction(ActionOperator(ctx)).invoke(OptionalMenuDownArrowIntent());
    OptionalMenuEnterAction(ActionOperator(ctx)).invoke(OptionalMenuEnterIntent());
  });
}