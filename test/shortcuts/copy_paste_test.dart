import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/divider.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/node/divider/divider.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/shortcuts/copy_paste.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';

void main() {
  test('copy', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 100)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 100)]),
      RichTextNode.from([RichTextSpan(text: 'c' * 100)]),
    ]);
    var text = await CopyAction(ActionOperator(ctx)).invoke(CopyIntent());
    assert(text.isEmpty);

    ctx.onCursor(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition(0, 50)));
    text = await CopyAction(ActionOperator(ctx)).invoke(CopyIntent());
    print(text);
    assert(text == 'a' * 50);

    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(1, RichTextNodePosition.zero()),
        EditingCursor(2, RichTextNodePosition(0, 50))));
    text = await CopyAction(ActionOperator(ctx)).invoke(CopyIntent());
    print(text);
    assert(text == '${'b' * 100}\n${'c' * 50}');
  });

  testWidgets('paste', (tester) async {
    String copyText = 'a' * 100;
    TestWidgetsFlutterBinding.ensureInitialized();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (message) {
      if (message.method == 'Clipboard.getData') {
        return Future.value({'text': copyText});
      }
      return null;
    });
    var ctx = buildEditorContext(basicNodes());
    ctx.onCursor(EditingCursor(0, RichTextNodePosition.zero()));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());
    final c1 = (ctx.cursor as EditingCursor).as<RichTextNodePosition>();
    assert(c1.index == 0);
    assert(c1.position == RichTextNodePosition(0, copyText.length));

    copyText = '- aaa\n1. bbb\n# ccc\n## ddd\n### eee';
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());
    final c2 = (ctx.cursor as EditingCursor).as<RichTextNodePosition>();
    assert(c2.index == 4);

    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'b' * 100)])
    ]);
    copyText = 'a' * 100;
    ctx.onCursor(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition(0, 50)));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());
    final c3 = (ctx.cursor as EditingCursor).as<RichTextNodePosition>();
    assert(c3.index == 0);
    assert(c3.position == RichTextNodePosition(0, 100));
    assert(ctx.nodes.first.text == copyText + 'b' * 50);

    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 100)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 100)]),
      RichTextNode.from([RichTextSpan(text: 'c' * 100)])
    ]);
    copyText = 'd' * 100;
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, RichTextNodePosition.zero()),
        EditingCursor(1, RichTextNodePosition(0, 50))));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());
    final c4 = (ctx.cursor as EditingCursor).as<RichTextNodePosition>();
    assert(c4.index == 0);
    assert(c3.position == RichTextNodePosition(0, 100));
    assert(ctx.nodes.first.text == copyText + 'b' * 50);

    ctx = buildEditorContext(basicNodes());
    copyText = '';
    ctx.onCursor(EditingCursor(0, RichTextNodePosition.zero()));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    ctx = buildEditorContext(basicNodes());
    copyText = '';
    ctx.onCursor(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition(0, 50)));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 100)]),
    ]);
    copyText = '- aaa\n1. bbb\n# ccc\n## ddd\n### eee';
    ctx.onCursor(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition(0, 10)));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 100)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 100)]),
      RichTextNode.from([RichTextSpan(text: 'c' * 100)])
    ]);
    copyText = '';
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, RichTextNodePosition.zero()),
        EditingCursor(1, RichTextNodePosition(0, 50))));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 100)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 100)]),
      RichTextNode.from([RichTextSpan(text: 'c' * 100)])
    ]);
    copyText = '$specialEdge$specialEdge';
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, RichTextNodePosition.zero()),
        EditingCursor(1, RichTextNodePosition.zero())));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    copyText = '---';
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, RichTextNodePosition.zero()),
        EditingCursor(1, RichTextNodePosition(0, 50))));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    ctx = buildEditorContext([DividerNode()]);
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    ctx = buildEditorContext([DividerNode(), DividerNode(), DividerNode()]);
    copyText = '- aaa\n1. bbb\n# ccc\n## ddd\n### eee';
    ctx.onCursor(SelectingNodesCursor(EditingCursor(0, DividerPosition()),
        EditingCursor(1, DividerPosition())));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());

    ctx = buildEditorContext([DividerNode(), DividerNode(), DividerNode()]);
    copyText = '- aaa\n1. bbb\n# ccc\n## ddd\n### eee';
    ctx.onCursor(SelectingNodeCursor(0, DividerPosition(), DividerPosition()));
    await PasteAction(ActionOperator(ctx)).invoke(PasteIntent());
  });
}
