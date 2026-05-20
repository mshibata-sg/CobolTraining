# KCCMURIAGE

## 1. 基本情報

| **システム名** | **サブシステム名** | **物理テーブル名** | **論理テーブル名** |
| -------------- | ------------------ | ------------------ | ------------------ |
| 研修 (ID: K) | 共通 (ID: KC) | KCCMURIAGE | 売上マスタ |

## 2. テーブルレイアウト

| 項目名               | 項目日本語名 | 属性    | 桁数 | 小数 | 制約 | 備考 |
| -------------------- | ------------ | :-----: | :--: | :--: | ---- | ---- |
| CMURIAGE_SHOHIN_NO   | 商品番号     | NUMERIC | 5    |      | PK   |      |
| CMURIAGE_SHOHIN_MEI  | 商品名       | CHAR    | 20   |      | N    |      |
| CMURIAGE_URIAGE_YM   | 売上年月     | CHAR    | 6    |      | PK   |      |
| CMURIAGE_URIKAKE_ZAN | 売掛現在残高 | NUMERIC | 9    | 0    | N    |      |
| CMURIAGE_URIAGE_GAKU | 売上金額     | NUMERIC | 9    | 0    | N    |      |
| CMURIAGE_NYUKIN_GAKU | 入金金額     | NUMERIC | 9    | 0    | N    |      |

**制約凡例**

* **PK**: プライマリキー
* **U**: ユニークキー
* **N**: NOT NULL

## 3. インデックス・制約情報

* **PK以外のインデックス**: なし
* **外部参照キー**: なし
