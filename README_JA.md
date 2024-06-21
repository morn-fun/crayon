# Crayon

![Crayon](https://github.com/asjqkkkk/asjqkkkk.github.io/assets/30992818/797cd31a-208d-4f1f-9490-fac02b84e35b)

Flutterで実装されたリッチテキストエディタです。

Languages : [中文](https://github.com/morn-fun/crayon/blob/main/README.md) | [English](https://github.com/morn-fun/crayon/blob/main/README_EN.md) | [한국어](https://github.com/morn-fun/crayon/blob/main/README_KO.md)

[![Coverage Status](https://coveralls.io/repos/github/morn-fun/crayon/badge.svg?branch=main)](https://coveralls.io/github/morn-fun/crayon?branch=main)

## [☞☞☞ オンラインで体験する](https://morn-fun.github.io/crayon/)

![screenshot](https://github.com/asjqkkkk/asjqkkkk.github.io/assets/30992818/c952af3d-a5d6-4fa7-a625-d0ea0a0451da)

## 現在サポートされている機能

- 実装されたテキストタイプ：
    - リッチテキスト：太字、下線、取り消し線、斜体、リンク、コードブロック
        - タスクリスト
        - 順序付きリスト、順不同リスト
        - 引用
        - 1〜3レベルの見出し
    - コードブロック：異なるコード言語の切り替えをサポート
    - 水平線
    - テーブル：上記のコンテンツのネストをサポート
- キーボードショートカット：
    - 元に戻す、やり直す
    - コピー、貼り付け（アプリケーション外からの貼り付けは改善中）
    - 改行
    - 削除
    - 全選択
    - インデント、逆インデント
    - 矢印キー、矢印キー+コピー、矢印キー+単語ジャンプ

## 将来の計画

- v0.7.0 は画像をサポートしています
- v0.8.0 は外部コンテンツからエディターへの変換とその逆の変換を改善します
- v0.9.0 はコアユニットテストを完了し、ハイレベルのバグを修正します
- v1.0.0 はモバイルデバイスをサポートしています, Dart Packageとして公開する