#!/bin/bash
# コンパイル実行
# -x: 実行可能ファイルを作成
# -o: 出力ファイル名を指定
# -I: コピー句の検索ディレクトリを指定
cobc -x -o KJBM010 -I ../../copylib KJBM010.COB
