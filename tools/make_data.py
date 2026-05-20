#!/usr/bin/env python3
"""
CSVからCOBOL用データファイルを生成するスクリプト

使用方法:
    python make_data.py <format_id> <csv_file> [output_file]
    python make_data.py --template <format_id>
"""

import sys
import csv
import argparse
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Literal, NotRequired, TypedDict


class FieldDef(TypedDict):
    col: str | None
    type: Literal["X", "9", "S9", "S9P", "N"]
    size: int
    digits: NotRequired[int]
    decimals: NotRequired[int]
    chars: NotRequired[int]
    fill: NotRequired[str]
    sample: NotRequired[str]


class FormatMeta(TypedDict):
    name: str
    file_type: Literal["line_sequential", "sequential"]
    record_len: int
    default_ext: str


# ============================================================
# エンコード関数  (check_data.py の decode_* の逆)
# ============================================================


def encode_zone(val_str: str, n_digits: int) -> bytes:
    """ゾーン10進数 (PIC 9) にエンコード
    非数字文字が含まれる場合はASCII生データとして格納 (エラーデータ用)
    """
    s = str(val_str).strip()
    if not s:
        s = "0"
    if all(c.isdigit() for c in s):
        return s.zfill(n_digits)[-n_digits:].encode("ascii")
    else:
        # 非数字を含む: 生ASCIIとして格納 (COBOLのGROUP転送と同等)
        return s[:n_digits].ljust(n_digits).encode("ascii", errors="replace")


def encode_signed_zone(val_str: str, n_total_digits: int, decimal_places: int) -> bytes:
    """符号付きゾーン10進数 (PIC S9) にエンコード
    GnuCOBOL SIGN TRAILING: 最終バイト 0xC0|digit (正) / 0xD0|digit (負)
    """
    s = str(val_str).strip() or "0"
    try:
        d = Decimal(s)
    except InvalidOperation:
        return (
            s[:n_total_digits].ljust(n_total_digits).encode("ascii", errors="replace")
        )

    sign_nibble = 0x7 if d < 0 else 0x3
    int_val = abs(int(d * (10**decimal_places)))
    digits = [int(c) for c in str(int_val).zfill(n_total_digits)[-n_total_digits:]]

    result = bytearray(n_total_digits)
    for i, dg in enumerate(digits[:-1]):
        result[i] = 0x30 | dg
    result[-1] = (sign_nibble << 4) | digits[-1]
    return bytes(result)


def encode_packed(val_str: str, n_total_digits: int, decimal_places: int) -> bytes:
    """パック10進数 (PIC S9P) にエンコード"""
    s = str(val_str).strip() or "0"
    n_bytes = (n_total_digits + 2) // 2
    try:
        d = Decimal(s)
    except InvalidOperation:
        return bytes(n_bytes)

    sign_nibble = 0xD if d < 0 else 0xC
    int_val = abs(int(d * (10**decimal_places)))
    digits = [int(c) for c in str(int_val).zfill(n_total_digits)[-n_total_digits:]]

    result = bytearray(n_bytes)
    for i in range(n_bytes - 1):
        result[i] = (digits[i * 2] << 4) | digits[i * 2 + 1]
    result[-1] = (digits[-1] << 4) | sign_nibble
    return bytes(result)


def encode_national(val_str: str, n_chars: int) -> bytes:
    """日本語項目 (PIC N) にエンコード (Shift-JIS, 全角スペースで右パディング)"""
    ZENKAKU_SPACE = "\u3000"  # 全角スペース
    s = str(val_str)
    padded = s[:n_chars].ljust(n_chars, ZENKAKU_SPACE)
    return padded.encode("cp932", errors="replace")


def encode_alpha(val_str: str, n_bytes: int) -> bytes:
    """英数字項目 (PIC X) にエンコード (半角スペースで右パディング)"""
    encoded = str(val_str).encode("cp932", errors="replace")
    if len(encoded) >= n_bytes:
        return encoded[:n_bytes]
    return encoded + b" " * (n_bytes - len(encoded))


# ============================================================
# フィールド定義
# ============================================================
# 各フィールド:
#   col      : CSV列名 (None = FILLER)
#   type     : X / 9 / S9 / S9P / N
#   size     : バイト数
#   digits   : 総桁数 (9/S9/S9P)
#   decimals : 小数桁数 (S9/S9P, 省略時0)
#   chars    : 文字数 (N: size = chars * 2)
#   fill     : FILLER固定値 (省略時 ' ')
#   sample   : --template用サンプル値
# ============================================================

FIELDS: dict[str, list[FieldDef]] = {
    # ----------------------------------------------------------
    # KJCF010 受注データ (行順編成, 50バイト)
    # ----------------------------------------------------------
    "KJCF010": [
        {"col": "DATA_KBN", "type": "X", "size": 1, "sample": "1"},
        {"col": None, "type": "X", "size": 1, "fill": " "},
        {"col": "JUCHU_NO", "type": "9", "size": 4, "digits": 4, "sample": "0001"},
        {"col": None, "type": "X", "size": 1, "fill": " "},
        {"col": "JUCHU_YY", "type": "9", "size": 2, "digits": 2, "sample": "26"},
        {"col": "JUCHU_MM", "type": "9", "size": 2, "digits": 2, "sample": "01"},
        {"col": "JUCHU_DD", "type": "9", "size": 2, "digits": 2, "sample": "10"},
        {"col": None, "type": "X", "size": 1, "fill": " "},
        {"col": "SHOHIN_NO", "type": "9", "size": 5, "digits": 5, "sample": "10001"},
        {"col": None, "type": "X", "size": 1, "fill": " "},
        {"col": "SURYO", "type": "9", "size": 5, "digits": 5, "sample": "00010"},
        {"col": None, "type": "X", "size": 25, "fill": " "},
    ],
    # ----------------------------------------------------------
    # KJCF020 受注チェックファイル (順編成, 100バイト)
    # ----------------------------------------------------------
    "KJCF020": [
        {"col": "DATA_KBN", "type": "X", "size": 1, "sample": "1"},
        {"col": "JUCHU_NO", "type": "9", "size": 4, "digits": 4, "sample": "0001"},
        {"col": "JUCHU_Y1", "type": "9", "size": 2, "digits": 2, "sample": "20"},
        {"col": "JUCHU_Y2", "type": "9", "size": 2, "digits": 2, "sample": "26"},
        {"col": "JUCHU_MM", "type": "9", "size": 2, "digits": 2, "sample": "01"},
        {"col": "JUCHU_DD", "type": "9", "size": 2, "digits": 2, "sample": "10"},
        {"col": "SHOHIN_NO", "type": "9", "size": 5, "digits": 5, "sample": "10001"},
        {"col": "SURYO", "type": "9", "size": 5, "digits": 5, "sample": "00010"},
        {"col": None, "type": "X", "size": 3, "fill": " "},
        {"col": "ERR_KBN_1", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_2", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_3", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_4", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_5", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_6", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_7", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_8", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_9", "type": "X", "size": 1, "sample": " "},
        {"col": "ERR_KBN_10", "type": "X", "size": 1, "sample": " "},
        {"col": "SHOHIN_MEI", "type": "N", "size": 20, "chars": 10, "sample": ""},
        {
            "col": "TANKA",
            "type": "S9",
            "size": 7,
            "digits": 7,
            "decimals": 2,
            "sample": "0.00",
        },
        {
            "col": "KINGAKU",
            "type": "S9",
            "size": 9,
            "digits": 9,
            "decimals": 0,
            "sample": "0",
        },
        {"col": None, "type": "X", "size": 28, "fill": " "},
    ],
    # ----------------------------------------------------------
    # KUCF010 売上ファイル (順編成, 100バイト)
    # ----------------------------------------------------------
    "KUCF010": [
        {"col": "DATA_KBN", "type": "X", "size": 1, "sample": "1"},
        {"col": "JUCHU_YY", "type": "9", "size": 4, "digits": 4, "sample": "2026"},
        {"col": "JUCHU_MM", "type": "9", "size": 2, "digits": 2, "sample": "01"},
        {"col": "JUCHU_DD", "type": "9", "size": 2, "digits": 2, "sample": "10"},
        {"col": "JUCHU_NO", "type": "9", "size": 4, "digits": 4, "sample": "0001"},
        {"col": "SHOHIN_NO", "type": "9", "size": 5, "digits": 5, "sample": "10001"},
        {
            "col": "SHOHIN_MEI",
            "type": "N",
            "size": 20,
            "chars": 10,
            "sample": "テスト商品Ａ　　　　",
        },
        {
            "col": "TANKA",
            "type": "S9P",
            "size": 4,
            "digits": 7,
            "decimals": 2,
            "sample": "1000.00",
        },
        {
            "col": "SURYO",
            "type": "S9P",
            "size": 3,
            "digits": 5,
            "decimals": 0,
            "sample": "10",
        },
        {
            "col": "KINGAKU",
            "type": "S9P",
            "size": 5,
            "digits": 9,
            "decimals": 0,
            "sample": "10000",
        },
        {"col": None, "type": "X", "size": 50, "fill": " "},
    ],
    # ----------------------------------------------------------
    # KUCF020 売上集計ファイル (順編成, 30バイト)
    # ----------------------------------------------------------
    "KUCF020": [
        {"col": "SHOHIN_NO", "type": "9", "size": 5, "digits": 5, "sample": "10001"},
        {"col": "JUCHU_YY", "type": "9", "size": 4, "digits": 4, "sample": "2026"},
        {"col": "JUCHU_MM", "type": "9", "size": 2, "digits": 2, "sample": "01"},
        {
            "col": "KINGAKU",
            "type": "S9P",
            "size": 5,
            "digits": 9,
            "decimals": 0,
            "sample": "10000",
        },
        {"col": None, "type": "X", "size": 14, "fill": " "},
    ],
    # ----------------------------------------------------------
    # KCCFSHO 商品マスタSAMファイル (順編成, 50バイト)
    # ----------------------------------------------------------
    "KCCFSHO": [
        {"col": "SHOHIN_NO", "type": "9", "size": 5, "digits": 5, "sample": "10001"},
        {
            "col": "SHOHIN_MEI",
            "type": "N",
            "size": 20,
            "chars": 10,
            "sample": "テスト商品Ａ　　　　",
        },
        {
            "col": "TANKA",
            "type": "S9P",
            "size": 4,
            "digits": 7,
            "decimals": 2,
            "sample": "1000.00",
        },
        {
            "col": "ZENGETU_ZAIKO",
            "type": "S9P",
            "size": 4,
            "digits": 7,
            "decimals": 0,
            "sample": "100",
        },
        {
            "col": "TOUGETU_NYUKO",
            "type": "S9P",
            "size": 4,
            "digits": 7,
            "decimals": 0,
            "sample": "50",
        },
        {
            "col": "TOUGETU_SYUKO",
            "type": "S9P",
            "size": 4,
            "digits": 7,
            "decimals": 0,
            "sample": "30",
        },
        {"col": None, "type": "X", "size": 9, "fill": " "},
    ],
}

FORMAT_META: dict[str, FormatMeta] = {
    "KJCF010": {
        "name": "受注データ",
        "file_type": "line_sequential",
        "record_len": 50,
        "default_ext": ".txt",
    },
    "KJCF020": {
        "name": "受注チェックファイル",
        "file_type": "sequential",
        "record_len": 100,
        "default_ext": ".dat",
    },
    "KUCF010": {
        "name": "売上ファイル",
        "file_type": "sequential",
        "record_len": 100,
        "default_ext": ".dat",
    },
    "KUCF020": {
        "name": "売上集計ファイル",
        "file_type": "sequential",
        "record_len": 30,
        "default_ext": ".dat",
    },
    "KCCFSHO": {
        "name": "商品マスタSAMファイル",
        "file_type": "sequential",
        "record_len": 50,
        "default_ext": ".dat",
    },
}

TYPE_LABEL: dict[str, str] = {
    "X": "英数字",
    "9": "ゾーン数値",
    "S9": "符号付ゾーン数値",
    "S9P": "パック数値",
    "N": "日本語",
}


# ============================================================
# レコード作成
# ============================================================


def build_record(fmt_id: str, row: dict) -> bytes:
    """CSV行を1レコードのバイト列に変換"""
    rec = bytearray()
    for f in FIELDS[fmt_id]:
        if f["col"] is None:
            rec += f.get("fill", " ").encode("ascii") * f["size"]
            continue
        val = row.get(f["col"], "")
        ftype = f["type"]
        if ftype == "X":
            rec += encode_alpha(val, f["size"])
        elif ftype == "9":
            rec += encode_zone(val, f["digits"])
        elif ftype == "S9":
            rec += encode_signed_zone(val, f["digits"], f.get("decimals", 0))
        elif ftype == "S9P":
            rec += encode_packed(val, f["digits"], f.get("decimals", 0))
        elif ftype == "N":
            rec += encode_national(val, f["chars"])
    return bytes(rec)


def print_record(fmt_id: str, row: dict, rec_no: int):
    """レコードの各項目をコンソールに出力"""
    print(f"\n--- レコード {rec_no:04d} ---")
    for f in FIELDS[fmt_id]:
        if f["col"] is None:
            continue
        val = row.get(f["col"], "")
        label = TYPE_LABEL.get(f["type"], f["type"])
        print(f"  {f['col']:20s} ({label:12s}): {repr(val)}")


# ============================================================
# テンプレート出力
# ============================================================


def print_template(fmt_id: str):
    """CSVテンプレート (ヘッダー行 + サンプル行) を標準出力"""
    cols = [f["col"] for f in FIELDS[fmt_id] if f["col"] is not None]
    samples = [f.get("sample", "") for f in FIELDS[fmt_id] if f["col"] is not None]
    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(cols)
    writer.writerow(samples)


# ============================================================
# ファイル生成
# ============================================================


def make_file(fmt_id: str, csv_path: Path, out_path: Path):
    meta = FORMAT_META[fmt_id]
    expected_len = meta["record_len"]

    print(f"{'=' * 64}")
    print(f" フォーマット : {fmt_id}  ({meta['name']})")
    print(
        f" ファイル種別 : {'行順編成 (LINE SEQUENTIAL)' if meta['file_type'] == 'line_sequential' else '順編成 (SEQUENTIAL, 固定長バイナリ)'}"
    )
    print(f" レコード長   : {expected_len} バイト")
    print(f" 入力CSV     : {csv_path}")
    print(f" 出力ファイル: {out_path}")
    print(f"{'=' * 64}")

    records = []

    with open(csv_path, encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for rec_no, row in enumerate(reader, 1):
            print_record(fmt_id, row, rec_no)
            rec = build_record(fmt_id, row)
            if len(rec) != expected_len:
                print(
                    f"  [エラー] レコード長不一致: {len(rec)} バイト (期待値: {expected_len})",
                    file=sys.stderr,
                )
                sys.exit(1)
            records.append(rec)
            print(f"  → {len(rec)} バイト [作成]")

    out_path.parent.mkdir(parents=True, exist_ok=True)

    if meta["file_type"] == "line_sequential":
        with open(out_path, "wb") as f:
            for rec in records:
                f.write(rec + b"\n")
    else:
        with open(out_path, "wb") as f:
            for rec in records:
                f.write(rec)

    size = out_path.stat().st_size
    print(f"\n{'=' * 64}")
    print(" 生成完了")
    print(f"   総レコード数  : {len(records)}")
    print(f"   ファイルサイズ: {size} バイト")
    print(f"   出力先        : {out_path}")
    print(f"{'=' * 64}")


# ============================================================
# エントリポイント
# ============================================================


def main():
    parser = argparse.ArgumentParser(
        description="CSVからCOBOL用データファイルを生成",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
利用可能なフォーマットID:
  KJCF010  受注データ             (行順編成, 50バイト/レコード)
  KJCF020  受注チェックファイル   (順編成,   100バイト/レコード)
  KUCF010  売上ファイル           (順編成,   100バイト/レコード)
  KUCF020  売上集計ファイル       (順編成,   30バイト/レコード)
  KCCFSHO  商品マスタSAMファイル  (順編成,   50バイト/レコード)

使用例:
  # CSVテンプレートを生成
  python make_data.py --template KJCF010
  python make_data.py --template KCCFSHO > data/kccfsho_template.csv

  # CSVからデータファイルを生成 (出力先省略時: data/<format_id><ext>)
  python make_data.py KJCF010 data/input.csv
  python make_data.py KJCF010 data/input.csv data/KJBM010I.txt
  python make_data.py KCCFSHO data/master.csv data/KCCFSHO.dat

  # check_data.py で内容を確認
  python check_data.py KJCF010 data/KJBM010I.txt
        """,
    )
    parser.add_argument(
        "--template",
        metavar="format_id",
        choices=FIELDS.keys(),
        help="CSVテンプレート(ヘッダー+サンプル行)を標準出力して終了",
    )
    parser.add_argument(
        "format_id",
        nargs="?",
        choices=FIELDS.keys(),
        metavar="format_id",
        help=f'フォーマットID: {", ".join(FIELDS.keys())}',
    )
    parser.add_argument("csv_file", nargs="?", help="入力CSVファイルパス")
    parser.add_argument(
        "output_file",
        nargs="?",
        help="出力ファイルパス (省略時: data/<format_id><ext>)",
    )

    args = parser.parse_args()

    if args.template:
        print_template(args.template)
        return

    if not args.format_id or not args.csv_file:
        parser.print_help()
        sys.exit(1)

    csv_path = Path(args.csv_file)
    if not csv_path.exists():
        print(f"[エラー] CSVファイルが存在しません: {csv_path}", file=sys.stderr)
        sys.exit(1)

    if args.output_file:
        out_path = Path(args.output_file)
    else:
        ext = FORMAT_META[args.format_id]["default_ext"]
        out_path = Path("data") / f"{args.format_id}{ext}"

    make_file(args.format_id, csv_path, out_path)


if __name__ == "__main__":
    main()
