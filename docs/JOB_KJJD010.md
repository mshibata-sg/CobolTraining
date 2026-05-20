# KJJD010 JOBフロースクリプト設計書

## 1. 基本情報

| 項目 | 内容 |
| ---- | ---- |
| ジョブID | KJJD010 |
| ジョブ名 | 受注データ更新 |
| スクリプトパス | `programs/KJJD010.sh` |
| 前提条件 | 各プログラム（KJBM010〜KUBM030）がビルド済みであること |

---

## 2. スクリプト構造

スクリプトは `set -Eeuo pipefail` により、いずれかのステップが異常終了（0以外の終了コード）した場合は後続処理を即座に中断する。

### Step 1: 受注チェックファイル作成（KJBM010）

- 初期入力ファイル（`data/KJJD010I.txt`）を `ITF` に設定する
- 出力先（`data/KJBM010O.dat`）を `OTF` に設定する
- KJBM010 を実行する。

### Step 2: 受注データ形式チェック（KJBM020）

- Step 1 の出力ファイル（`data/KJBM010O.dat`）を `ITF` に設定する
- 出力先（`data/KJBM020O.dat`）を `OTF` に設定する
- KJBM020 を実行する。

### Step 3: ソート（受注チェックファイル　商品番号昇順）

- GCSORT を使用して `data/KJBM020O.dat` を商品番号（ゾーン10進数、5桁）の昇順にソートする
  - ソートキー: KJCF020 の第14バイト目から5バイト（JF020-SHOHIN-NO）
- ソート結果を `data/SORT1O.dat` に出力する（LRECL=100）

### Step 4: 商品番号チェック（KJBM030）

- Step 3 のソート済みファイル（`data/SORT1O.dat`）を `ITF` に設定する
- 商品マスタファイル（`data/KCCFSHO.dat`）を `IMF` に設定する
- 出力先（`data/KJBM030O.dat`）を `OTF` に設定する
- KJBM030 を実行する。

### Step 5: 受注データ振り分け（KJBM050）

- Step 4 の出力ファイル（`data/KJBM030O.dat`）を `ITF` に設定する
- 正常分の出力先（`data/KJBM050O1.dat`）を `OTF1` に設定する
- エラー分の出力先（`data/KJBM050O2.dat`）を `OTF2` に設定する
- KJBM050 を実行する。

### Step 6: 売上ファイル作成（KUBM010）

- Step 5 の正常分ファイル（`data/KJBM050O1.dat`）を `ITF` に設定する
- 出力先（`data/KUBM010O.dat`）を `OTF` に設定する
- KUBM010 を実行する。

### Step 7: ソート（売上ファイル　商品番号・受注年月昇順）

- GCSORT を使用して `data/KUBM010O.dat` を商品番号の昇順、同一商品内は受注年月の昇順にソートする
  - 第1ソートキー: KUCF010 の第14バイト目から5バイト（UF010-SHOHIN-NO）、ゾーン10進数、昇順
  - 第2ソートキー: KUCF010 の第2バイト目から6バイト（UF010-JUCHU-YY+MM）、ゾーン10進数、昇順
- ソート結果を `data/SORT2O.dat` に出力する（LRECL=100）

### Step 8: 売上集計（KUBM020）

- Step 7 のソート済みファイル（`data/SORT2O.dat`）を `ITF` に設定する
- 出力先（`data/KUBM020O.dat`）を `OTF` に設定する
- KUBM020 を実行する。

### Step 9: 売上更新（KUBM030）

- Step 8 の出力ファイル（`data/KUBM020O.dat`）を `ITF` に設定する
- KUBM030 を実行する。

---

## 3. 使用ファイル一覧

| ステップ | 区分 | 環境変数 | ファイルパス | フォーマット | LRECL |
| -------- | ---- | -------- | ------------ | ------------ | ----- |
| Step 1 | 入力 | `ITF` | `data/KJJD010I.txt` | KJCF010 行順編成 | 50 |
| Step 1 | 出力 | `OTF` | `data/KJBM010O.dat` | KJCF020 順編成 | 100 |
| Step 2 | 入力 | `ITF` | `data/KJBM010O.dat` | KJCF020 順編成 | 100 |
| Step 2 | 出力 | `OTF` | `data/KJBM020O.dat` | KJCF020 順編成 | 100 |
| Step 3 | 入力 | - | `data/KJBM020O.dat` | KJCF020 順編成 | 100 |
| Step 3 | 出力 | - | `data/SORT1O.dat` | KJCF020 順編成 | 100 |
| Step 4 | 入力 | `ITF` | `data/SORT1O.dat` | KJCF020 順編成 | 100 |
| Step 4 | 入力 | `IMF` | `data/KCCFSHO.dat` | KCCFSHO 順編成 | 50 |
| Step 4 | 出力 | `OTF` | `data/KJBM030O.dat` | KJCF020 順編成 | 100 |
| Step 5 | 入力 | `ITF` | `data/KJBM030O.dat` | KJCF020 順編成 | 100 |
| Step 5 | 出力 | `OTF1` | `data/KJBM050O1.dat` | KJCF020 順編成 | 100 |
| Step 5 | 出力 | `OTF2` | `data/KJBM050O2.dat` | KJCF020 順編成 | 100 |
| Step 6 | 入力 | `ITF` | `data/KJBM050O1.dat` | KJCF020 順編成 | 100 |
| Step 6 | 出力 | `OTF` | `data/KUBM010O.dat` | KUCF010 順編成 | 100 |
| Step 7 | 入力 | - | `data/KUBM010O.dat` | KUCF010 順編成 | 100 |
| Step 7 | 出力 | - | `data/SORT2O.dat` | KUCF010 順編成 | 100 |
| Step 8 | 入力 | `ITF` | `data/SORT2O.dat` | KUCF010 順編成 | 100 |
| Step 8 | 出力 | `OTF` | `data/KUBM020O.dat` | KUCF020 順編成 | 30 |
| Step 9 | 入力 | `ITF` | `data/KUBM020O.dat` | KUCF020 順編成 | 30 |
| Step 9 | 出力 | - | DB: KCCMURIAGE | テーブル更新 | - |

---

## 4. 実行方法

プロジェクトルートから以下のコマンドで実行する。

```bash
bash programs/KJJD010.sh
```

---

## 5. テストデータ

### 5.1 KJJD010I.txt（受注データ　初期入力）

フォーマット: KJCF010（行順編成、LRECL=50、cp932 エンコーディング）

**テストデータ一覧（5レコード）**

| # | データ区分 | 受注番号 | 受注年(下2桁) | 受注月 | 受注日 | 商品番号 | 数量 | 備考 |
| - | ---------- | -------- | ------------- | ------ | ------ | -------- | ---- | ---- |
| 1 | 1 | 0001 | 26 | 01 | 15 | 10001 | 00100 | 正常 |
| 2 | 1 | 0002 | 26 | 01 | 15 | 10003 | 00200 | 正常 |
| 3 | 1 | 0003 | 26 | 01 | 15 | 10005 | 00050 | 正常 |
| 4 | 1 | 0004 | 26 | 01 | 15 | 99999 | 00100 | エラー（商品番号が商品マスタに存在しない） |
| 5 | 1 | 0005 | 26 | 01 | 15 | 10001 | 01000 | エラー（数量が有効範囲 1〜999 を超過） |

**CSV内容（`tools/make_data.py` 用）**

```csv
DATA_KBN,JUCHU_NO,JUCHU_YY,JUCHU_MM,JUCHU_DD,SHOHIN_NO,SURYO
1,0001,26,01,15,10001,00100
1,0002,26,01,15,10003,00200
1,0003,26,01,15,10005,00050
1,0004,26,01,15,99999,00100
1,0005,26,01,15,10001,01000
```

**ファイル作成コマンド**

```bash
tools/make_data.py --template KJCF010 > /tmp/kjjd010i.csv
# 上記 CSV 内容（ヘッダ行以降）を /tmp/kjjd010i.csv に追記する
tools/make_data.py KJCF010 /tmp/kjjd010i.csv data/KJJD010I.txt
```

---

### 5.2 KCCFSHO.dat（商品マスタ）

フォーマット: KCCFSHO（順編成、LRECL=50、cp932 エンコーディング）
**注意**: 商品番号の昇順でソートされていること（KJBM030 の動作要件）

**テストデータ一覧（3レコード）**

| # | 商品番号 | 商品名 | 単価 | 前月末在庫数 | 当月入庫数 | 当月出庫数 |
| - | -------- | ------ | ---- | ------------ | ---------- | ---------- |
| 1 | 10001 | 商品００００１ | 1000.00 | 0 | 0 | 0 |
| 2 | 10003 | 商品００００３ | 500.00 | 0 | 0 | 0 |
| 3 | 10005 | 商品００００５ | 200.00 | 0 | 0 | 0 |

> 単価（CFSHO-TANKA）は PIC S9(05)V9(2) のパック10進数で格納される。
> CSV では小数点以下を含む実数値（例: 1000.00）または内部整数値（100000）で指定する（`tools/make_data.py --template KCCFSHO` で確認すること）。

**CSV内容（`tools/make_data.py` 用）**

```csv
SHOHIN_NO,SHOHIN_MEI,TANKA,ZENGETU_ZAIKO,TOUGETU_NYUKO,TOUGETU_SYUKO
10001,商品００００１,1000.00,0,0,0
10003,商品００００３,500.00,0,0,0
10005,商品００００５,200.00,0,0,0
```

**ファイル作成コマンド**

```bash
tools/make_data.py --template KCCFSHO > /tmp/kccfsho.csv
# 上記 CSV 内容（ヘッダ行以降）を /tmp/kccfsho.csv に追記する
tools/make_data.py KCCFSHO /tmp/kccfsho.csv data/KCCFSHO.dat
```

---

### 5.3 KCCMURIAGE テーブル初期データ

`docs/TBL_KCCMURIAGE.md` の初期データと同じ内容を使用する。

**テーブル初期状態**

| 商品番号 | 商品名 | 売上年月 | 売掛現在残高 | 売上金額 | 入金金額 |
| -------- | ------ | -------- | ------------ | -------- | -------- |
| 10001 | 商品００００１ | 202601 | 50,000 | 100,000 | 80,000 |
| 10003 | 商品００００３ | 202601 | 30,000 | 60,000 | 40,000 |
| 10005 | 商品００００５ | 202601 | 10,000 | 20,000 | 15,000 |

**SQL（テーブル再作成 + 初期データ投入）**

```sql
DROP TABLE IF EXISTS KCCMURIAGE;
CREATE TABLE KCCMURIAGE (
    CMURIAGE_SHOHIN_NO   NUMERIC(5)   NOT NULL,
    CMURIAGE_SHOHIN_MEI  CHAR(20)     NOT NULL,
    CMURIAGE_URIAGE_YM   CHAR(6)      NOT NULL,
    CMURIAGE_URIKAKE_ZAN NUMERIC(9,0) NOT NULL,
    CMURIAGE_URIAGE_GAKU NUMERIC(9,0) NOT NULL,
    CMURIAGE_NYUKIN_GAKU NUMERIC(9,0) NOT NULL,
    PRIMARY KEY (CMURIAGE_SHOHIN_NO, CMURIAGE_URIAGE_YM)
);

INSERT INTO KCCMURIAGE
    (CMURIAGE_SHOHIN_NO, CMURIAGE_SHOHIN_MEI, CMURIAGE_URIAGE_YM,
     CMURIAGE_URIKAKE_ZAN, CMURIAGE_URIAGE_GAKU, CMURIAGE_NYUKIN_GAKU)
VALUES
    (10001, '商品００００１', '202601',  50000, 100000, 80000),
    (10003, '商品００００３', '202601',  30000,  60000, 40000),
    (10005, '商品００００５', '202601',  10000,  20000, 15000);
```

**初期化コマンド**

```bash
psql -h db -U postgres << 'EOF'
DROP TABLE IF EXISTS KCCMURIAGE;
CREATE TABLE KCCMURIAGE (
    CMURIAGE_SHOHIN_NO   NUMERIC(5)   NOT NULL,
    CMURIAGE_SHOHIN_MEI  CHAR(20)     NOT NULL,
    CMURIAGE_URIAGE_YM   CHAR(6)      NOT NULL,
    CMURIAGE_URIKAKE_ZAN NUMERIC(9,0) NOT NULL,
    CMURIAGE_URIAGE_GAKU NUMERIC(9,0) NOT NULL,
    CMURIAGE_NYUKIN_GAKU NUMERIC(9,0) NOT NULL,
    PRIMARY KEY (CMURIAGE_SHOHIN_NO, CMURIAGE_URIAGE_YM)
);
INSERT INTO KCCMURIAGE
    (CMURIAGE_SHOHIN_NO, CMURIAGE_SHOHIN_MEI, CMURIAGE_URIAGE_YM,
     CMURIAGE_URIKAKE_ZAN, CMURIAGE_URIAGE_GAKU, CMURIAGE_NYUKIN_GAKU)
VALUES
    (10001, '商品００００１', '202601',  50000, 100000, 80000),
    (10003, '商品００００３', '202601',  30000,  60000, 40000),
    (10005, '商品００００５', '202601',  10000,  20000, 15000);
EOF
```

---

## 6. 検証項目と期待値

### 6.1 KJBM050O2.dat（エラー分）の期待内容

テストデータのうち、受注番号 0004・0005 の 2 レコードがエラー分として出力される。
出力順は KJBM030O.dat 内での出現順（商品番号ソート順）に従う。

| 出現順 | 受注番号 | 商品番号 | 数量 | 商品名 | 金額 | ERR(5) | ERR(6) | エラー原因 |
| ------ | -------- | -------- | ---- | ------ | ---- | ------ | ------ | ---------- |
| 1 | 0005 | 10001 | 01000 | 商品００００１ | 0 | (空白) | 1 | KJBM020 にて数量エラー（1000 > 999）。KJBM030 でマッチし商品名セット済み。金額はゼロ。 |
| 2 | 0004 | 99999 | 00100 | (空白) | 0 | 2 | (空白) | KJBM030 にて商品番号アンマッチ（マスタに 99999 が存在しない）。 |

> **出現順について**: SORT1O.dat は商品番号昇順のため、10001（受注番号0005）→ 99999（受注番号0004）の順となる。

---

### 6.2 KUBM020O.dat（売上集計）の期待内容

フォーマット: KUCF020（順編成、LRECL=30）

正常分 3 レコード（受注番号 0001・0002・0003）を商品番号・年月単位で集計した結果が出力される。

金額計算:

- 受注番号 0001: 商品10001、数量 100 × 単価 1,000.00 = **100,000**
- 受注番号 0002: 商品10003、数量 200 × 単価 500.00 = **100,000**
- 受注番号 0003: 商品10005、数量 50 × 単価 200.00 = **10,000**

| 商品番号 | 受注年 | 受注月 | 集計金額 |
| -------- | ------ | ------ | -------- |
| 10001 | 2026 | 01 | 100,000 |
| 10003 | 2026 | 01 | 100,000 |
| 10005 | 2026 | 01 | 10,000 |

---

### 6.3 KCCMURIAGE テーブル更新後の期待値

KUBM030 は売上集計ファイルの金額を KCCMURIAGE の `CMURIAGE_URIKAKE_ZAN`（売掛現在残高）と `CMURIAGE_URIAGE_GAKU`（売上金額）に加算する。

**確認コマンド**

```bash
psql -h db -U postgres -c "SELECT * FROM KCCMURIAGE ORDER BY CMURIAGE_SHOHIN_NO"
```

**期待値（初期値 + 集計金額）**

| 商品番号 | 売上年月 | 売掛現在残高 | 売上金額 | 入金金額 |
| -------- | -------- | ------------ | -------- | -------- |
| 10001 | 202601 | **150,000** | **200,000** | 80,000 |
| 10003 | 202601 | **130,000** | **160,000** | 40,000 |
| 10005 | 202601 | **20,000** | **30,000** | 15,000 |

計算根拠:

- 商品10001: 売掛 50,000 + 100,000 = **150,000** / 売上 100,000 + 100,000 = **200,000**
- 商品10003: 売掛 30,000 + 100,000 = **130,000** / 売上 60,000 + 100,000 = **160,000**
- 商品10005: 売掛 10,000 + 10,000 = **20,000** / 売上 20,000 + 10,000 = **30,000**
