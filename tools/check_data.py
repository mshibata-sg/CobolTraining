#!/usr/bin/env python3
"""
FF_フォーマット定義に基づくデータファイルチェックスクリプト

使用方法:
    python check_data.py <format_id> <data_file>

    format_id: KJCF010, KJCF020, KUCF010, KUCF020, KCCFSHO
"""

import sys
import argparse
from collections.abc import Callable
from pathlib import Path
from typing import Literal, TypedDict

# 0x3 Unix/Windows(ASCII)
# 0x7 Unix/Windows(ASCII) 最終バイト符号：負
# 0xF Mainframe(EBCDIC)
# 0xC Mainframe(EBCDIC) 最終バイト符号：正
# 0xD Mainframe(EBCDIC) 最終バイト符号：負
POSITIVE_ZONES: tuple[int, ...] = (0x3, 0xC, 0xF)
NEGATIVE_ZONES: tuple[int, ...] = (0x7, 0xD)
ZONES: tuple[int, ...] = POSITIVE_ZONES + NEGATIVE_ZONES

# 0xC 最終バイト符号：正
# 0xD 最終バイト符号：負
# 0xF 最終バイト符号：符号なし
POSITIVE_PACKED_SIGN: tuple[int, ...] = (0xC, 0xF)
NEGATIVE_PACKED_SIGN: tuple[int, ...] = (0xD,)
PACKED_SIGN: tuple[int, ...] = POSITIVE_PACKED_SIGN + NEGATIVE_PACKED_SIGN

# ============================================================
# デコード関数
# ============================================================


def decode_zone(data: bytes) -> int:
    """ゾーン10進数 (PIC 9) をデコード"""
    result = 0
    for b in data:
        result = result * 10 + (b & 0x0F)
    return result


def decode_signed_zone(data: bytes) -> int:
    """符号付きゾーン10進数 (PIC S9) をデコード
    GnuCOBOL SIGN TRAILING: 最終バイトの上位バイト C,F=正, 7,D=負
    """
    result = 0
    for b in data:
        result = result * 10 + (b & 0x0F)
    sign_nibble = (data[-1] >> 4) & 0x0F
    if sign_nibble in NEGATIVE_ZONES:
        result = -result
    return result


def decode_packed(data: bytes) -> int:
    """パック10進数 (PIC S9P) をデコード
    各バイト上位バイト=数字, 最終バイト下位バイト=符号 (C=正, D=負, F=符号なし)
    """
    result = 0
    for b in data[:-1]:
        result = result * 10 + ((b >> 4) & 0x0F)
        result = result * 10 + (b & 0x0F)
    last = data[-1]
    result = result * 10 + ((last >> 4) & 0x0F)
    if (last & 0x0F) in NEGATIVE_PACKED_SIGN:
        result = -result
    return result


def format_with_decimal(value: int, decimal_places: int) -> str:
    """整数値に小数点を挿入してフォーマット"""
    if decimal_places == 0:
        return str(value)
    sign = "-" if value < 0 else ""
    abs_val = abs(value)
    digits = str(abs_val).zfill(decimal_places + 1)
    int_part = digits[:-decimal_places].lstrip("0") or "0"
    dec_part = digits[-decimal_places:]
    return f"{sign}{int_part}.{dec_part}"


def decode_sjis(data: bytes) -> str:
    """Shift-JIS文字列をデコード"""
    try:
        return data.decode("cp932").rstrip()
    except Exception:
        return f"<デコードエラー: {data.hex()}>"


def fmt_zone(data: bytes) -> str:
    """ゾーン数値の表示文字列。不正バイトがある場合は生データを文字列で返す"""
    for b in data:
        if (b & 0x0F) > 9 or (b >> 4) & 0x0F not in ZONES:
            try:
                return f"'{data.decode('ascii')}'"
            except Exception:
                return f"0x{data.hex()}"
    return str(decode_zone(data)).zfill(len(data))


def fmt_signed_zone(data: bytes, decimal_places: int = 0) -> str:
    """符号付きゾーン数値の表示文字列。不正バイトがある場合は生データを文字列で返す"""
    for b in data:
        if (b & 0x0F) > 9 or (b >> 4) & 0x0F not in ZONES:
            try:
                return f"'{data.decode('ascii')}'"
            except Exception:
                return f"0x{data.hex()}"
    return format_with_decimal(decode_signed_zone(data), decimal_places)


def fmt_packed(data: bytes, decimal_places: int = 0) -> str:
    """パック数値の表示文字列。不正バイトがある場合は16進数表示を返す"""
    for b in data[:-1]:
        if ((b >> 4) & 0x0F) > 9 or (b & 0x0F) > 9:
            return f"0x{data.hex()}"
    last = data[-1]
    if ((last >> 4) & 0x0F) > 9 or (last & 0x0F) not in PACKED_SIGN:
        return f"0x{data.hex()}"
    return format_with_decimal(decode_packed(data), decimal_places)


# ============================================================
# バリデーション関数
# ============================================================


def validate_zone(data: bytes, field_name: str) -> list:
    """ゾーン数値のバリデーション (各バイトの下位バイトが 0-9 であること)"""
    errors = []
    for i, b in enumerate(data):
        digit = b & 0x0F
        zone = (b >> 4) & 0x0F
        if digit > 9:
            errors.append(f"{field_name}: [{i}]バイト 数値データ不正 (0x{digit:X})")
        # 正常なゾーン: 0x3(ASCII), 0xC(正符号), 0xD(負符号), 0xF(EBCDIC符号なし)
        if zone not in ZONES:
            errors.append(f"{field_name}: [{i}]バイト ゾーンニブル不正 (0x{zone:X})")
    return errors


def validate_packed(data: bytes, field_name: str) -> list:
    """パック数値のバリデーション"""
    errors = []
    for i, b in enumerate(data[:-1]):
        h, lo = (b >> 4) & 0x0F, b & 0x0F
        if h > 9:
            errors.append(f"{field_name}: [{i}]バイト 上位バイト不正 (0x{h:X})")
        if lo > 9:
            errors.append(f"{field_name}: [{i}]バイト 下位バイト不正 (0x{lo:X})")
    last = data[-1]
    h = (last >> 4) & 0x0F
    sign = last & 0x0F
    if h > 9:
        errors.append(f"{field_name}: 最終バイト 数値データ不正 (0x{h:X})")
    if sign not in PACKED_SIGN:
        errors.append(
            f"{field_name}: 符号データ不正 (0x{sign:X}) "
            f"期待値: 0xC=正, 0xD=負, 0xF=符号なし"
        )
    return errors


# ============================================================
# 各フォーマット レコード解析関数
# ============================================================


def check_kjcf010(record: bytes, rec_no: int) -> bool:
    """
    KJCF010 受注データ (行順編成, 50バイト)

    Offset  Field              Type  Size
    ------  -----------------  ----  ----
     0      JF010-DATA-KBN      X     1
     1      FILLER              X     1
     2      JF010-JUCHU-NO      9     4
     6      FILLER              X     1
     7      JF010-JUCHU-YY      9     2
     9      JF010-JUCHU-MM      9     2
    11      JF010-JUCHU-DD      9     2
    13      FILLER              X     1
    14      JF010-SHOHIN-NO     9     5
    19      FILLER              X     1
    20      JF010-SURYO         9     5
    25      FILLER              X    25
    """
    print(f"\n--- レコード {rec_no:04d} ---")
    errors = []

    # データ区分
    data_kbn = chr(record[0])
    print(
        f"  データ区分 (JF010-DATA-KBN) : '{data_kbn}'"
        f"  ({'売上' if data_kbn == '1' else '取消' if data_kbn == '9' else '不明'})"
    )
    if data_kbn not in ("1", "9"):
        errors.append(f"データ区分 不正値: '{data_kbn}' (期待値: 1=売上, 9=取消)")

    # 受注番号
    errors.extend(validate_zone(record[2:6], "受注番号"))
    print(f"  受注番号   (JF010-JUCHU-NO) : {fmt_zone(record[2:6])}")

    # 受注日付
    errors.extend(validate_zone(record[7:9], "受注日付(年)"))
    errors.extend(validate_zone(record[9:11], "受注日付(月)"))
    errors.extend(validate_zone(record[11:13], "受注日付(日)"))
    mm = decode_zone(record[9:11])
    dd = decode_zone(record[11:13])
    print(
        f"  受注日付   (JF010-JUCHU-DATE): 20{fmt_zone(record[7:9])}/{fmt_zone(record[9:11])}/{fmt_zone(record[11:13])}"
    )
    if not (1 <= mm <= 12):
        errors.append(f"受注日付(月) 範囲外: {mm}")
    if not (1 <= dd <= 31):
        errors.append(f"受注日付(日) 範囲外: {dd}")

    # 商品番号
    errors.extend(validate_zone(record[14:19], "商品番号"))
    print(f"  商品番号   (JF010-SHOHIN-NO): {fmt_zone(record[14:19])}")

    # 数量
    errors.extend(validate_zone(record[20:25], "数量"))
    print(f"  数量       (JF010-SURYO)     : {fmt_zone(record[20:25])}")

    _print_result(errors)
    return len(errors) == 0


def check_kjcf020(record: bytes, rec_no: int) -> bool:
    """
    KJCF020 受注チェックファイル (順編成, 100バイト)

    Offset  Field                 Type  Size
    ------  --------------------  ----  ----
     0      JF020-DATA-KBN         X     1
     1      JF020-JUCHU-NO         9     4
     5      JF020-JUCHU-Y1         9     2   (西暦年上2桁)
     7      JF020-JUCHU-Y2         9     2   (西暦年下2桁)
     9      JF020-JUCHU-MM         9     2
    11      JF020-JUCHU-DD         9     2
    13      JF020-SHOHIN-NO        9     5
    18      JF020-SURYO            9     5
    23      FILLER                 X     3
    26      JF020-ERR-KBN-TBL      X    10   (OCCURS 10)
    36      JF020-SHOHIN-MEI       N    10   (= 20バイト)
    56      JF020-TANKA            S9    7   (5桁2小数)
    63      JF020-KINGAKU          S9    9
    72      FILLER                 X    28
    """
    print(f"\n--- レコード {rec_no:04d} ---")
    errors = []

    # データ区分
    data_kbn = chr(record[0])
    print(
        f"  データ区分      (JF020-DATA-KBN)  : '{data_kbn}'"
        f"  ({'売上' if data_kbn == '1' else '取消' if data_kbn == '9' else '不明'})"
    )
    if data_kbn not in ("1", "9"):
        errors.append(f"データ区分 不正値: '{data_kbn}' (期待値: 1=売上, 9=取消)")

    # 受注番号
    errors.extend(validate_zone(record[1:5], "受注番号"))
    print(f"  受注番号        (JF020-JUCHU-NO)  : {fmt_zone(record[1:5])}")

    # 受注日付
    errors.extend(validate_zone(record[5:7], "受注日付(年上2桁)"))
    errors.extend(validate_zone(record[7:9], "受注日付(年下2桁)"))
    errors.extend(validate_zone(record[9:11], "受注日付(月)"))
    errors.extend(validate_zone(record[11:13], "受注日付(日)"))
    mm = decode_zone(record[9:11])
    dd = decode_zone(record[11:13])
    print(
        f"  受注日付        (JF020-JUCHU-DATE): {fmt_zone(record[5:7])}{fmt_zone(record[7:9])}/{fmt_zone(record[9:11])}/{fmt_zone(record[11:13])}"
    )
    if not (1 <= mm <= 12):
        errors.append(f"受注日付(月) 範囲外: {mm}")
    if not (1 <= dd <= 31):
        errors.append(f"受注日付(日) 範囲外: {dd}")

    # 商品番号
    errors.extend(validate_zone(record[13:18], "商品番号"))
    print(f"  商品番号        (JF020-SHOHIN-NO) : {fmt_zone(record[13:18])}")

    # 数量
    errors.extend(validate_zone(record[18:23], "数量"))
    print(f"  数量            (JF020-SURYO)     : {fmt_zone(record[18:23])}")

    # エラー区分テーブル
    ERR_NAMES = [
        "データ区分",
        "受注番号",
        "受注日付",
        "予備(4)",
        "商品番号",
        "数量",
        "予備(7)",
        "予備(8)",
        "予備(9)",
        "予備(10)",
    ]
    ERR_LABELS = {" ": "エラーなし", "1": "形式エラー", "2": "マスタなし"}
    print("  エラー区分TBL   (JF020-ERR-KBN-TBL):")
    for i in range(10):
        kbn = chr(record[26 + i])
        label = ERR_LABELS.get(kbn, f"不明('{kbn}')")
        print(f"    [{i+1:2d}] {ERR_NAMES[i]:12s}: '{kbn}' ({label})")
        if kbn not in (" ", "1", "2"):
            errors.append(f"エラー区分({i+1}) 不正値: '{kbn}'")

    # 商品名
    shohin_mei = decode_sjis(record[36:56])
    print(f"  商品名          (JF020-SHOHIN-MEI): '{shohin_mei}'")

    # 単価 (S9, 5桁2小数 = 7バイト)
    errors.extend(validate_zone(record[56:63], "単価"))
    print(f"  単価            (JF020-TANKA)     : {fmt_signed_zone(record[56:63], 2)}")

    # 金額 (S9, 9桁 = 9バイト)
    errors.extend(validate_zone(record[63:72], "金額"))
    print(f"  金額            (JF020-KINGAKU)   : {fmt_signed_zone(record[63:72])}")

    _print_result(errors)
    return len(errors) == 0


def check_kucf010(record: bytes, rec_no: int) -> bool:
    """
    KUCF010 売上ファイル (順編成, 100バイト)

    Offset  Field              Type   Size
    ------  -----------------  -----  ----
     0      UF010-DATA-KBN      X      1
     1      UF010-JUCHU-YY      9      4   (西暦年4桁)
     5      UF010-JUCHU-MM      9      2
     7      UF010-JUCHU-DD      9      2
     9      UF010-JUCHU-NO      9      4
    13      UF010-SHOHIN-NO     9      5
    18      UF010-SHOHIN-MEI    N     10   (= 20バイト)
    38      UF010-TANKA         S9P    4   (5桁2小数 → 7桁packed)
    42      UF010-SURYO         S9P    3   (5桁 → packed)
    45      UF010-KINGAKU       S9P    5   (9桁 → packed)
    50      FILLER              X     50
    """
    print(f"\n--- レコード {rec_no:04d} ---")
    errors = []

    # データ区分
    data_kbn = chr(record[0])
    print(
        f"  データ区分  (UF010-DATA-KBN)  : '{data_kbn}'"
        f"  ({'売上' if data_kbn == '1' else '取消' if data_kbn == '9' else '不明'})"
    )
    if data_kbn not in ("1", "9"):
        errors.append(f"データ区分 不正値: '{data_kbn}' (期待値: 1=売上, 9=取消)")

    # 受注日付
    errors.extend(validate_zone(record[1:5], "受注日付(年)"))
    errors.extend(validate_zone(record[5:7], "受注日付(月)"))
    errors.extend(validate_zone(record[7:9], "受注日付(日)"))
    mm = decode_zone(record[5:7])
    dd = decode_zone(record[7:9])
    print(
        f"  受注日付    (UF010-JUCHU-DATE): {fmt_zone(record[1:5])}/{fmt_zone(record[5:7])}/{fmt_zone(record[7:9])}"
    )
    if not (1 <= mm <= 12):
        errors.append(f"受注日付(月) 範囲外: {mm}")
    if not (1 <= dd <= 31):
        errors.append(f"受注日付(日) 範囲外: {dd}")

    # 受注番号
    errors.extend(validate_zone(record[9:13], "受注番号"))
    print(f"  受注番号    (UF010-JUCHU-NO)  : {fmt_zone(record[9:13])}")

    # 商品番号
    errors.extend(validate_zone(record[13:18], "商品番号"))
    print(f"  商品番号    (UF010-SHOHIN-NO) : {fmt_zone(record[13:18])}")

    # 商品名 (N, 10文字 = 20バイト)
    print(f"  商品名      (UF010-SHOHIN-MEI): '{decode_sjis(record[18:38])}'")

    # 単価 (S9P, 7桁 → 4バイト)
    errors.extend(validate_packed(record[38:42], "単価"))
    print(f"  単価        (UF010-TANKA)     : {fmt_packed(record[38:42], 2)}")

    # 数量 (S9P, 5桁 → 3バイト)
    errors.extend(validate_packed(record[42:45], "数量"))
    print(f"  数量        (UF010-SURYO)     : {fmt_packed(record[42:45])}")

    # 金額 (S9P, 9桁 → 5バイト)
    errors.extend(validate_packed(record[45:50], "金額"))
    print(f"  金額        (UF010-KINGAKU)   : {fmt_packed(record[45:50])}")

    _print_result(errors)
    return len(errors) == 0


def check_kucf020(record: bytes, rec_no: int) -> bool:
    """
    KUCF020 売上集計ファイル (順編成, 30バイト)

    Offset  Field              Type   Size
    ------  -----------------  -----  ----
     0      UF020-SHOHIN-NO     9      5
     5      UF020-JUCHU-YY      9      4   (西暦年4桁)
     9      UF020-JUCHU-MM      9      2
    11      UF020-KINGAKU       S9P    5   (9桁 → packed)
    16      FILLER              X     14
    """
    print(f"\n--- レコード {rec_no:04d} ---")
    errors = []

    # 商品番号
    errors.extend(validate_zone(record[0:5], "商品番号"))
    print(f"  商品番号  (UF020-SHOHIN-NO)  : {fmt_zone(record[0:5])}")

    # 受注年月
    errors.extend(validate_zone(record[5:9], "受注年月(年)"))
    errors.extend(validate_zone(record[9:11], "受注年月(月)"))
    mm = decode_zone(record[9:11])
    print(
        f"  受注年月  (UF020-JUCHU-DATE) : {fmt_zone(record[5:9])}/{fmt_zone(record[9:11])}"
    )
    if not (1 <= mm <= 12):
        errors.append(f"受注年月(月) 範囲外: {mm}")

    # 金額 (S9P, 9桁 → 5バイト)
    errors.extend(validate_packed(record[11:16], "金額"))
    print(f"  金額      (UF020-KINGAKU)    : {fmt_packed(record[11:16])}")

    _print_result(errors)
    return len(errors) == 0


def check_kccfsho(record: bytes, rec_no: int) -> bool:
    """
    KCCFSHO 商品マスタSAMファイル (順編成, 50バイト)

    Offset  Field                  Type   Size
    ------  ---------------------  -----  ----
     0      CFSHO-SHOHIN-NO         9      5
     5      CFSHO-SHOHIN-MEI        N     10   (= 20バイト)
    25      CFSHO-TANKA             S9P    4   (5桁2小数 → 7桁packed)
    29      CFSHO-ZENGETU-ZAIKO     S9P    4   (7桁 → packed)
    33      CFSHO-TOUGETU-NYUKO     S9P    4   (7桁 → packed)
    37      CFSHO-TOUGETU-SYUKO     S9P    4   (7桁 → packed)
    41      FILLER                  X      9
    """
    print(f"\n--- レコード {rec_no:04d} ---")
    errors = []

    # 商品番号
    errors.extend(validate_zone(record[0:5], "商品番号"))
    print(f"  商品番号      (CFSHO-SHOHIN-NO)      : {fmt_zone(record[0:5])}")

    # 商品名 (N, 10文字 = 20バイト)
    print(f"  商品名        (CFSHO-SHOHIN-MEI)     : '{decode_sjis(record[5:25])}'")

    # 単価 (S9P, 7桁 → 4バイト)
    errors.extend(validate_packed(record[25:29], "単価"))
    print(f"  単価          (CFSHO-TANKA)          : {fmt_packed(record[25:29], 2)}")

    # 前月末在庫数 (S9P, 7桁 → 4バイト)
    errors.extend(validate_packed(record[29:33], "前月末在庫数"))
    print(f"  前月末在庫数  (CFSHO-ZENGETU-ZAIKO)  : {fmt_packed(record[29:33])}")

    # 当月入庫数 (S9P, 7桁 → 4バイト)
    errors.extend(validate_packed(record[33:37], "当月入庫数"))
    print(f"  当月入庫数    (CFSHO-TOUGETU-NYUKO)  : {fmt_packed(record[33:37])}")

    # 当月出庫数 (S9P, 7桁 → 4バイト)
    errors.extend(validate_packed(record[37:41], "当月出庫数"))
    print(f"  当月出庫数    (CFSHO-TOUGETU-SYUKO)  : {fmt_packed(record[37:41])}")

    _print_result(errors)
    return len(errors) == 0


def _print_result(errors: list):
    if errors:
        print("  [NG]")
        for e in errors:
            print(f"    ✗ {e}")
    else:
        print("  [OK]")


# ============================================================
# フォーマット設定
# ============================================================

class FormatConfig(TypedDict):
    name: str
    file_type: Literal["line_sequential", "sequential"]
    record_len: int
    func: Callable[[bytes, int], bool]


FORMAT_CONFIG: dict[str, FormatConfig] = {
    "KJCF010": {
        "name": "受注データ",
        "file_type": "line_sequential",  # 行順編成: 改行区切りテキスト
        "record_len": 50,
        "func": check_kjcf010,
    },
    "KJCF020": {
        "name": "受注チェックファイル",
        "file_type": "sequential",  # 順編成: バイナリ固定長
        "record_len": 100,
        "func": check_kjcf020,
    },
    "KUCF010": {
        "name": "売上ファイル",
        "file_type": "sequential",
        "record_len": 100,
        "func": check_kucf010,
    },
    "KUCF020": {
        "name": "売上集計ファイル",
        "file_type": "sequential",
        "record_len": 30,
        "func": check_kucf020,
    },
    "KCCFSHO": {
        "name": "商品マスタSAMファイル",
        "file_type": "sequential",
        "record_len": 50,
        "func": check_kccfsho,
    },
}


# ============================================================
# ファイルチェック
# ============================================================


def check_file(fmt_id: str, file_path: Path):
    cfg = FORMAT_CONFIG[fmt_id]

    print(f"{'=' * 64}")
    print(f" フォーマット : {fmt_id}  ({cfg['name']})")
    print(
        f" ファイル種別 : {'行順編成 (LINE SEQUENTIAL)' if cfg['file_type'] == 'line_sequential' else '順編成 (SEQUENTIAL, 固定長バイナリ)'}"
    )
    print(f" レコード長   : {cfg['record_len']} バイト")
    print(f" ファイル     : {file_path}")
    print(f"{'=' * 64}")

    if not file_path.exists():
        print(f"[エラー] ファイルが存在しません: {file_path}")
        sys.exit(1)

    file_size = file_path.stat().st_size
    print(f" ファイルサイズ: {file_size} バイト")

    ok_count = 0
    ng_count = 0
    rec_no = 0

    if cfg["file_type"] == "line_sequential":
        # 行順編成: Shift-JIS テキスト、改行で区切られた固定長レコード
        with open(file_path, "rb") as f:
            for raw_line in f:
                line = raw_line.rstrip(b"\r\n")
                if len(line) == 0:
                    continue
                rec_no += 1
                if len(line) != cfg["record_len"]:
                    print(f"\n--- レコード {rec_no:04d} ---")
                    print(
                        f"  [NG] レコード長不一致: {len(line)} バイト (期待値: {cfg['record_len']} バイト)"
                    )
                    ng_count += 1
                    continue
                if cfg["func"](line, rec_no):
                    ok_count += 1
                else:
                    ng_count += 1
    else:
        # 順編成: バイナリ固定長レコード
        rec_len = cfg["record_len"]
        with open(file_path, "rb") as f:
            while True:
                record = f.read(rec_len)
                if not record:
                    break
                rec_no += 1
                if len(record) != rec_len:
                    print(f"\n--- レコード {rec_no:04d} ---")
                    print(
                        f"  [NG] 不完全レコード: {len(record)} バイト (期待値: {rec_len} バイト)"
                    )
                    ng_count += 1
                    break
                if cfg["func"](record, rec_no):
                    ok_count += 1
                else:
                    ng_count += 1

    print(f"\n{'=' * 64}")
    print(" チェック完了")
    print(f"   総レコード数 : {rec_no}")
    print(f"   正常         : {ok_count}")
    print(f"   エラー       : {ng_count}")
    result = "合格" if ng_count == 0 else "不合格"
    print(f"   結果         : {result}")
    print(f"{'=' * 64}")

    return ng_count == 0


# ============================================================
# エントリポイント
# ============================================================


def main():
    parser = argparse.ArgumentParser(
        description="FF_フォーマット定義に基づくデータファイルチェック",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
利用可能なフォーマットID:
  KJCF010  受注データ             (行順編成, 50バイト/レコード)
  KJCF020  受注チェックファイル   (順編成,   100バイト/レコード)
  KUCF010  売上ファイル           (順編成,   100バイト/レコード)
  KUCF020  売上集計ファイル       (順編成,   30バイト/レコード)
  KCCFSHO  商品マスタSAMファイル  (順編成,   50バイト/レコード)

使用例:
  python check_data.py KJCF010 data/KJBM001I.txt
  python check_data.py KCCFSHO data/KCCFSHOI.dat
        """,
    )
    parser.add_argument(
        "format_id",
        choices=FORMAT_CONFIG.keys(),
        metavar="format_id",
        help=f'フォーマットID: {", ".join(FORMAT_CONFIG.keys())}',
    )
    parser.add_argument("data_file", help="チェック対象ファイルパス")
    args = parser.parse_args()

    ok = check_file(args.format_id, Path(args.data_file))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
