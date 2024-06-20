import 'package:flutter/material.dart';
import 'editor/node/rich_text/rich_text.dart';
import 'editor/node/rich_text/rich_text_span.dart';
import 'editor/widget/editor/rich_editor.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

List<RichTextNode> _nodes =
    texts.map((e) => RichTextNode.from([RichTextSpan(text: e)])).toList();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Crayon')),
        body: RichEditor(nodes: _nodes),
      ),
    );
  }
}

const texts = [
  'Thank you - 谢谢',
  'How are you? - 你好吗？',
  'I love you - 我爱你',
  'What\'s your name? - 你叫什么名字？',
  'Where are you from? - 你从哪里来？',
  'Excuse me - 对不起 / 不好意思',
  'How much is it? - 多少钱？',
  'I\'m sorry - 对不起',
  'Good morning - 早上好',
  'I don\'t understand - 我不懂',
];
