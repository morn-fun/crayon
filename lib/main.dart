import 'package:flutter/material.dart';
import 'package:pre_editor/editor/node/rich_text_node/rich_text_span.dart';

import 'editor/node/rich_text_node/rich_text_node.dart';
import 'editor/widget/rich_editor.dart';

void main() {
  runApp(const MyApp());
}

RichTextNode _node = RichTextNode.from([RichTextSpan(text: 'aaabbb')]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Pre Editor')),
        body: RichEditor(nodes: [_node]),
      ),
    );
  }
}
