# GCSORT ソートユーティリティ

## 1. 基本情報

| 項目 | 内容 |
| ---- | ---- |
| ツール名 | GCSORT |
| 概要 | Micro Focus MFSORT のサブセット機能を実装した OSS ソートユーティリティ |
| ライセンス | GNU General Public License |
| 対応操作 | SORT / MERGE / COPY / JOIN |

**戻り値**

| 値 | 意味 |
| :--: | ---- |
| 0 | 正常終了 |
| 4 | 警告あり |
| 16 | エラー終了 |

---

## 2. 実行方法

```bash
# コントロールファイル経由（推奨）
gcsort TAKE <コントロールファイルパス>
```

コントロールファイルにソート条件を記述し、`gcsort TAKE` で実行します。
`mktemp` で一時ファイルを作成し、終了時に削除するのが一般的な使用パターンです。

```bash
CTRLFILE=$(mktemp)
trap "rm -f $CTRLFILE" EXIT

cat <<_EOF_ >> $CTRLFILE
SORT FIELDS=(...)
    USE  /path/to/input.dat  RECORD F,100 ORG SQ
    GIVE /path/to/output.dat RECORD F,100 ORG SQ
_EOF_

gcsort TAKE $CTRLFILE
```

---

## 3. コントロールステートメント

### SORT文

```
SORT FIELDS=(<開始位置>, <桁数>, <形式>, <順序> [, <開始位置>, <桁数>, <形式>, <順序>, ...])
    USE  <入力ファイルパス> RECORD F,<レコード長> ORG SQ
    GIVE <出力ファイルパス> RECORD F,<レコード長> ORG SQ
```

**FIELDS パラメータ**

| パラメータ | 説明 |
| ---------- | ---- |
| 開始位置 | ソートキーの開始バイト位置（**1始まり**） |
| 桁数 | ソートキーのバイト数 |
| 形式 | データ形式（下記「フィールド形式一覧」参照） |
| 順序 | `A`: 昇順 / `D`: 降順 |

複数キーを指定する場合は、第1キーから順に `,` で区切って並べます。

**RECORD句**

| 指定 | 意味 |
| ---- | ---- |
| `F,<n>` | 固定長レコード、1レコード n バイト |

**ORG句**

| 指定 | 意味 |
| ---- | ---- |
| `SQ` | 順編成（Sequential）ファイル |

---

## 4. フィールド形式一覧

| 形式 | 名称 | 説明 | COBOL対応 |
| :--: | ---- | ---- | --------- |
| CH | Character | 文字（英数字） | PIC X |
| ZD | Zoned Decimal | ゾーン10進数 | PIC 9 |
| PD | Packed Decimal | パック10進数 | USAGE PACKED-DECIMAL |
| BI | Binary (unsigned) | 符号なし2進数 | USAGE BINARY |
| FI | Binary (signed) | 符号付き2進数 | USAGE BINARY |
| FL | Floating Point | 浮動小数点数 | — |

---

## 5. 使用例

### 例1: 商品番号順ソート（KJCF020 受注チェックファイル）

KJJD010 フロー内、KJBM020 → KJBM030 の間で行うソート。
KJCF020 フォーマット（LRECL=100）を商品番号の昇順でソートします。

**ソートキーのバイト位置（KJCF020）**

| フィールド | 開始位置 | バイト数 | 形式 |
| ---------- | :------: | :------: | :--: |
| JF020-DATA-KBN | 1 | 1 | CH |
| JF020-JUCHU-NO | 2 | 4 | ZD |
| JF020-JUCHU-DATE | 6 | 8 | ZD |
| **JF020-SHOHIN-NO** | **14** | **5** | **ZD** |

```bash
CTRLFILE=$(mktemp)
trap "rm -f $CTRLFILE" EXIT

cat <<_EOF_ >> $CTRLFILE
SORT FIELDS=(14, 5, ZD, A)
    USE  ${SCRIPTDIR}/../../data/KJBM020O.dat RECORD F,100 ORG SQ
    GIVE ${SCRIPTDIR}/../../data/SORT1O.dat   RECORD F,100 ORG SQ
_EOF_

gcsort TAKE $CTRLFILE
```

---

### 例2: 商品番号・日付順ソート（KUCF010 売上ファイル）

KJJD010 フロー内、KUBM010 → KUBM020 の間で行うソート。
KUCF010 フォーマット（LRECL=100）を商品番号の昇順、同一商品内は受注年月の昇順でソートします。

**ソートキーのバイト位置（KUCF010）**

| フィールド | 開始位置 | バイト数 | 形式 |
| ---------- | :------: | :------: | :--: |
| UF010-DATA-KBN | 1 | 1 | CH |
| UF010-JUCHU-DATE（YY+MM+DD） | 2 | 8 | ZD |
| UF010-JUCHU-NO | 10 | 4 | ZD |
| **UF010-SHOHIN-NO** | **14** | **5** | **ZD** |
| **UF010-JUCHU-YY+MM（年月）** | **2** | **6** | **ZD** |

```bash
CTRLFILE=$(mktemp)
trap "rm -f $CTRLFILE" EXIT

cat <<_EOF_ >> $CTRLFILE
SORT FIELDS=(14, 5, ZD, A, 2, 6, ZD, A)
    USE  ${SCRIPTDIR}/../../data/KUBM010O.dat RECORD F,100 ORG SQ
    GIVE ${SCRIPTDIR}/../../data/SORT2O.dat   RECORD F,100 ORG SQ
_EOF_

gcsort TAKE $CTRLFILE
```

---

## 6. 参考

- GnuCOBOL contrib リポジトリ: https://sourceforge.net/p/gnucobol/contrib/HEAD/tree/trunk/tools/GCSORT/
- サンプルスクリプト: [`sample/gcsort/sort.sh`](../sample/gcsort/sort.sh)
