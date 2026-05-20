#!/usr/bin/env python3
"""
COBOLコピーブックをパースし、データ項目の一覧を出力するスクリプト

使用方法:
    python parse_copybook.py <copybook_path>
    python parse_copybook.py --csv <copybook_path>

対応:
    - PIC X, N, 9, S9, V
    - USAGE DISPLAY, PACKED-DECIMAL, COMP-3
    - OCCURS句, REDEFINES句
"""

import sys
import re
import argparse
import subprocess


def read_copybook(path: str) -> str:
    """コピーブックを読み込む (Shift-JIS → UTF-8変換を試みる)"""
    try:
        result = subprocess.run(
            ["iconv", "-f", "cp932", "-t", "utf8", path],
            capture_output=True,
            check=True,
        )
        return result.stdout.decode("utf-8")
    except (subprocess.CalledProcessError, FileNotFoundError):
        with open(path, encoding="utf-8") as f:
            return f.read()


def extract_source_lines(text: str) -> list[str]:
    """固定形式COBOLソースから有効行を抽出し、継続行を結合する"""
    raw_lines = []
    for line in text.splitlines():
        if len(line) < 7:
            continue
        indicator = line[6] if len(line) > 6 else " "
        if indicator == "*":
            continue
        content = line[7:72] if len(line) > 7 else ""
        raw_lines.append((indicator, content))

    # 継続行 (indicator == '-') を前行に結合
    merged = []
    for indicator, content in raw_lines:
        if indicator == "-" and merged:
            # 継続行: 前行末尾の空白を除去し、現行の先頭空白後から結合
            stripped = content.lstrip()
            merged[-1] = merged[-1].rstrip() + " " + stripped
        else:
            merged.append(content)
    return merged


def tokenize_lines(lines: list[str]) -> list[str]:
    """行群を文(ピリオド区切り)ごとのトークン列に分割"""
    statements = []
    current = ""
    for line in lines:
        current += " " + line
        # ピリオドで文が終わる
        while "." in current:
            idx = current.index(".")
            statements.append(current[:idx].strip())
            current = current[idx + 1 :]
    if current.strip():
        statements.append(current.strip())
    return statements


def parse_pic(pic_str: str) -> dict:
    """PIC句文字列をパースして型情報を返す"""
    s = pic_str.upper().replace(" ", "")

    has_sign = False
    int_digits = 0
    dec_digits = 0
    pic_type = None  # 'X', 'N', '9', 'S9'
    total_chars = 0

    i = 0
    in_decimal = False

    if s.startswith("S"):
        has_sign = True
        i = 1

    while i < len(s):
        ch = s[i]
        # 繰り返し記法: X(nn) / 9(nn) / N(nn)
        count = 1
        if i + 1 < len(s) and s[i + 1] == "(":
            end_paren = s.index(")", i + 2)
            count = int(s[i + 2 : end_paren])
            next_i = end_paren + 1
        else:
            next_i = i + 1

        if ch == "X":
            pic_type = "X"
            total_chars += count
        elif ch == "N":
            pic_type = "N"
            total_chars += count
        elif ch == "9":
            if pic_type is None:
                pic_type = "S9" if has_sign else "9"
            if in_decimal:
                dec_digits += count
            else:
                int_digits += count
        elif ch == "V":
            in_decimal = True
            next_i = i + 1
        else:
            next_i = i + 1

        i = next_i

    if pic_type == "X":
        return {
            "pic_type": "X",
            "size_bytes": total_chars,
            "display": f"X({total_chars})",
        }
    elif pic_type == "N":
        return {
            "pic_type": "N",
            "size_bytes": total_chars * 2,
            "chars": total_chars,
            "display": f"N({total_chars})",
        }
    elif pic_type in ("9", "S9"):
        total_digits = int_digits + dec_digits
        if dec_digits > 0:
            display = f"{'S' if has_sign else ''}9({int_digits})V9({dec_digits})"
        else:
            display = f"{'S' if has_sign else ''}9({total_digits})"
        return {
            "pic_type": pic_type,
            "total_digits": total_digits,
            "int_digits": int_digits,
            "dec_digits": dec_digits,
            "has_sign": has_sign,
            "display": display,
        }
    return {"pic_type": "?", "display": pic_str}


def calc_byte_size(pic_info: dict, usage: str) -> int:
    """PIC情報とUSAGEからバイト数を計算"""
    pt = pic_info["pic_type"]
    if pt in ("X", "N"):
        return pic_info["size_bytes"]
    elif pt in ("9", "S9"):
        total_digits = pic_info["total_digits"]
        if usage in ("PACKED-DECIMAL", "COMP-3"):
            return (total_digits + 2) // 2
        else:
            # DISPLAY (デフォルト)
            return total_digits
    return 0


def usage_display(usage: str) -> str:
    """USAGE表示名"""
    if usage in ("PACKED-DECIMAL", "COMP-3"):
        return "PACKED-DECIMAL"
    return "DISPLAY"


def parse_statements(statements: list[str]) -> list[dict]:
    """文のリストからデータ項目定義を抽出"""
    items = []

    for stmt in statements:
        tokens = stmt.split()
        if not tokens:
            continue

        # レベル番号で始まるか
        if not tokens[0].isdigit():
            continue

        level = int(tokens[0])
        if level == 66 or level == 88:
            continue

        name = tokens[1] if len(tokens) > 1 else ""

        # PIC句を探す
        pic_str = None
        usage = "DISPLAY"
        occurs = None
        redefines = None

        upper_stmt = stmt.upper()

        # REDEFINES
        m = re.search(r"\bREDEFINES\s+(\S+)", upper_stmt)
        if m:
            redefines = m.group(1)

        # PIC / PICTURE
        m = re.search(
            r"\bPIC(?:TURE)?\s+(\S+(?:\s*\(\s*\d+\s*\))?(?:\s*V\s*(?:9|9\s*\(\s*\d+\s*\)))?)",
            upper_stmt,
        )
        if m:
            pic_str = m.group(1)
            # PICの後にさらに9(xx)等が続く場合の補完パース
            # より正確に: PIC以降の句全体を再取得
            pic_match = re.search(
                r"\bPIC(?:TURE)?\s+(S?[9XN](?:\(\d+\))?(?:V9(?:\(\d+\))?)?)", upper_stmt
            )
            if pic_match:
                pic_str = pic_match.group(1)

        # USAGE / PACKED-DECIMAL / COMP-3
        if re.search(r"\bPACKED-DECIMAL\b", upper_stmt):
            usage = "PACKED-DECIMAL"
        elif re.search(r"\bCOMP-3\b", upper_stmt):
            usage = "COMP-3"

        # OCCURS
        m = re.search(r"\bOCCURS\s+(\d+)\s+TIMES?\b", upper_stmt)
        if m:
            occurs = int(m.group(1))

        items.append(
            {
                "level": level,
                "name": name,
                "pic_str": pic_str,
                "usage": usage,
                "occurs": occurs,
                "redefines": redefines,
            }
        )

    return items


def resolve_layout(items: list[dict]) -> list[dict]:
    """データ項目リストにバイトサイズ・開始位置・終了位置を付与"""
    # まず各項目のバイトサイズを決定
    for item in items:
        if item["pic_str"]:
            pic_info = parse_pic(item["pic_str"])
            item["pic_info"] = pic_info
            item["byte_size"] = calc_byte_size(pic_info, item["usage"])
        else:
            item["pic_info"] = None
            item["byte_size"] = 0  # グループ項目: 子の合計で後計算

    # グループ項目のサイズを子項目合計で計算 (ボトムアップ)
    _calc_group_sizes(items)

    # 位置の割り当て
    _assign_positions(items)

    return items


def _calc_group_sizes(items: list[dict]):
    """グループ項目のサイズを子項目の合計から計算"""
    n = len(items)
    for i in range(n):
        item = items[i]
        if item["pic_str"] is not None:
            # 基本項目: OCCURSの反映
            if item["occurs"]:
                item["byte_size"] *= item["occurs"]
            continue
        # グループ項目: 直下の子の合計
        level = item["level"]
        total = 0
        j = i + 1
        while j < n:
            if items[j]["level"] <= level:
                break
            # 直下の子 (REDEFINESの子は加算しない)
            if items[j]["redefines"]:
                # REDEFINES項目はサイズに加算しない - スキップ
                skip_level = items[j]["level"]
                j += 1
                while j < n and items[j]["level"] > skip_level:
                    j += 1
                continue
            if items[j]["level"] == level + 2 or _is_direct_child(items, i, j):
                total += items[j]["byte_size"]
            j += 1
        if total > 0:
            item["byte_size"] = total
        # OCCURSがグループにある場合
        if item["occurs"]:
            item["byte_size"] *= item["occurs"]


def _is_direct_child(items: list[dict], parent_idx: int, child_idx: int) -> bool:
    """child_idxがparent_idxの直接の子かどうか"""
    parent_level = items[parent_idx]["level"]
    child_level = items[child_idx]["level"]
    if child_level <= parent_level:
        return False
    # 間に同レベル以下がないか
    for k in range(parent_idx + 1, child_idx):
        if items[k]["level"] <= parent_level:
            return False
        if items[k]["level"] < child_level and items[k]["level"] > parent_level:
            return False  # 中間グループがある
    # 中間にchild_levelより上位のグループがなければ直接の子
    for k in range(parent_idx + 1, child_idx):
        if parent_level < items[k]["level"] < child_level:
            return False
    return True


def _assign_positions(items: list[dict]):
    """各項目に開始位置・終了位置を割り当て"""
    # スタックベースで位置追跡
    # (level, name, start_pos) のスタック
    n = len(items)

    # 名前→開始位置のマッピング (REDEFINES解決用)
    name_to_start = {}

    # 現在位置
    pos = 1

    for i in range(n):
        item = items[i]

        # REDEFINES: 対象項目の開始位置を使う
        if item["redefines"]:
            target_name = item["redefines"]
            if target_name in name_to_start:
                pos = name_to_start[target_name]

        # スタックから同レベル以上を除去して位置を合わせる
        # (ここではposを進めるロジックは基本項目のみで行う)

        item["start_pos"] = pos
        item["end_pos"] = pos + item["byte_size"] - 1

        name_to_start[item["name"]] = pos

        # 基本項目（PICあり）ならposを進める
        if item["pic_str"] is not None:
            # ただしREDEFINESの中の項目は位置を進めない場合がある
            # → REDEFINES内かどうかを判定
            if not _is_inside_redefines(items, i):
                pos += item["byte_size"]
            else:
                # REDEFINES内: 同じ領域の再定義なのでposは進めない
                # ただしREDEFINESブロック内の連続項目ではposを進める
                pos += item["byte_size"]
        else:
            # グループ項目: posは子が進める
            pass


def _is_inside_redefines(items: list[dict], idx: int) -> bool:
    """指定インデックスの項目がREDEFINES句を持つグループの中にあるか"""
    level = items[idx]["level"]
    for k in range(idx - 1, -1, -1):
        if items[k]["level"] < level:
            if items[k]["redefines"]:
                return True
            level = items[k]["level"]
    return False


def _find_redefines_ancestor(items: list[dict], idx: int) -> int | None:
    """REDEFINES句を持つ直近の祖先のインデックスを返す"""
    level = items[idx]["level"]
    for k in range(idx - 1, -1, -1):
        if items[k]["level"] < level:
            if items[k]["redefines"]:
                return k
            level = items[k]["level"]
    return None


def resolve_layout_v2(items: list[dict]) -> list[dict]:
    """データ項目リストにバイトサイズ・開始位置・終了位置を付与 (改良版)"""
    # PIC情報とバイトサイズ計算
    for item in items:
        if item["pic_str"]:
            pic_info = parse_pic(item["pic_str"])
            item["pic_info"] = pic_info
            base_size = calc_byte_size(pic_info, item["usage"])
            if item["occurs"]:
                item["elem_size"] = base_size
                item["byte_size"] = base_size * item["occurs"]
            else:
                item["elem_size"] = base_size
                item["byte_size"] = base_size
        else:
            item["pic_info"] = None
            item["byte_size"] = 0
            item["elem_size"] = 0

    # グループサイズ計算 (逆順)
    _calc_group_sizes_v2(items)

    # 位置割り当て
    _assign_positions_v2(items)

    return items


def _calc_group_sizes_v2(items: list[dict]):
    """グループ項目のサイズを子の合計から計算 (逆順パス)"""
    n = len(items)
    for i in range(n - 1, -1, -1):
        item = items[i]
        if item["pic_str"] is not None:
            continue
        level = item["level"]
        total = 0
        j = i + 1
        while j < n and items[j]["level"] > level:
            child = items[j]
            if child["level"] == _find_direct_child_level(items, i):
                if not child["redefines"]:
                    total += child["byte_size"]
                # REDEFINES項目はサイズに含めない
            j += 1
        item["byte_size"] = total
        item["elem_size"] = total
        if item["occurs"]:
            item["byte_size"] = total * item["occurs"]


def _find_direct_child_level(items: list[dict], parent_idx: int) -> int:
    """親の直接の子レベルを取得"""
    parent_level = items[parent_idx]["level"]
    n = len(items)
    for j in range(parent_idx + 1, n):
        if items[j]["level"] <= parent_level:
            break
        return items[j]["level"]
    return parent_level + 2


def _assign_positions_v2(items: list[dict]):
    """位置割り当て (スタックベース)"""
    name_to_start = {}
    # 各グループの「次の空き位置」を管理するスタック
    # スタック要素: (level, next_pos)
    pos_stack = [(0, 1)]  # ルートレベル0, 開始位置1

    for item in items:
        level = item["level"]

        # 現レベル以上のスタック要素を除去
        while pos_stack and pos_stack[-1][0] >= level:
            pos_stack.pop()

        if item["redefines"]:
            target = item["redefines"]
            start = name_to_start.get(target, pos_stack[-1][1] if pos_stack else 1)
        else:
            start = pos_stack[-1][1] if pos_stack else 1

        item["start_pos"] = start
        item["end_pos"] = (
            start + item["byte_size"] - 1 if item["byte_size"] > 0 else start
        )

        name_to_start[item["name"]] = start

        if item["pic_str"] is not None:
            # 基本項目: 親の次位置を更新
            if not item["redefines"]:
                if pos_stack:
                    parent_level, _ = pos_stack[-1]
                    pos_stack[-1] = (parent_level, start + item["byte_size"])
            # グループ項目の中の場合はスタックに自身を追加しない
        else:
            # グループ項目: 子のためにスタックにpush
            pos_stack.append((level, start))
            # REDEFINES でないなら親の次位置も更新
            if not item["redefines"] and len(pos_stack) >= 2:
                parent_level, _ = pos_stack[-2]
                pos_stack[-2] = (parent_level, start + item["byte_size"])


def format_type_display(item: dict) -> str:
    """型情報の表示文字列を生成"""
    if item["pic_info"] is None:
        return "GROUP"
    pic = item["pic_info"]
    display = pic["display"]
    usage = usage_display(item["usage"])
    parts = [display]
    if usage != "DISPLAY":
        parts.append(usage)
    if item["occurs"]:
        parts.append(f"OCCURS {item['occurs']}")
    return " ".join(parts)


def _display_width(s: str) -> int:
    """文字列の端末表示幅を計算 (全角=2, 半角=1)"""
    import unicodedata

    width = 0
    for ch in s:
        eaw = unicodedata.east_asian_width(ch)
        if eaw in ("F", "W"):
            width += 2
        else:
            width += 1
    return width


def _ljust_width(s: str, width: int) -> str:
    """表示幅ベースで左寄せパディング"""
    pad = width - _display_width(s)
    return s + " " * max(pad, 0)


def _rjust_width(s: str, width: int) -> str:
    """表示幅ベースで右寄せパディング"""
    pad = width - _display_width(s)
    return " " * max(pad, 0) + s


def print_table(items: list[dict], copybook_path: str):
    """結果をテーブル形式で出力"""
    COL_NAME = 32
    COL_TYPE = 32
    COL_SIZE = 6
    COL_START = 6
    COL_END = 6

    print(f"コピーブック: {copybook_path}")
    print()

    header = (
        _rjust_width("Lv", 2)
        + "  "
        + _ljust_width("データ項目名", COL_NAME)
        + "  "
        + _ljust_width("データ型", COL_TYPE)
        + "  "
        + _rjust_width("バイト", COL_SIZE)
        + "  "
        + _rjust_width("開始", COL_START)
        + "  "
        + _rjust_width("終了", COL_END)
    )
    print(header)
    total_width = (
        2 + 2 + COL_NAME + 2 + COL_TYPE + 2 + COL_SIZE + 2 + COL_START + 2 + COL_END
    )
    print("-" * total_width)

    for item in items:
        level = item["level"]
        indent = "  " * ((level - 1) // 2)
        name = indent + item["name"]
        type_str = format_type_display(item)
        if item["redefines"]:
            type_str += f" [REDEFINES {item['redefines']}]"
        size = item["byte_size"]
        start = item["start_pos"]
        end = item["end_pos"]

        line = (
            f"{level:>2}  "
            + _ljust_width(name, COL_NAME)
            + "  "
            + _ljust_width(type_str, COL_TYPE)
            + "  "
            + f"{size:>{COL_SIZE}d}  "
            + f"{start:>{COL_START}d}  "
            + f"{end:>{COL_END}d}"
        )
        print(line)


def print_csv(items: list[dict]):
    """結果をCSV形式で出力"""
    import csv as csv_mod

    writer = csv_mod.writer(sys.stdout, lineterminator="\n")
    writer.writerow(
        [
            "レベル",
            "データ項目名",
            "データ型",
            "バイト数",
            "開始位置",
            "終了位置",
            "REDEFINES",
        ]
    )
    for item in items:
        writer.writerow(
            [
                item["level"],
                item["name"],
                format_type_display(item),
                item["byte_size"],
                item["start_pos"],
                item["end_pos"],
                item.get("redefines", "") or "",
            ]
        )


def main():
    parser = argparse.ArgumentParser(
        description="COBOLコピーブックをパースし、データ項目一覧を出力する",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用例:
    python parse_copybook.py copylib/KJCF010.cob
    python parse_copybook.py --csv copylib/KCCFSHO.cob > output.csv
        """,
    )
    parser.add_argument("copybook", help="コピーブックファイルのパス")
    parser.add_argument("--csv", action="store_true", help="CSV形式で出力")
    args = parser.parse_args()

    text = read_copybook(args.copybook)
    lines = extract_source_lines(text)
    statements = tokenize_lines(lines)
    items = parse_statements(statements)

    if not items:
        print("データ項目が見つかりませんでした。", file=sys.stderr)
        sys.exit(1)

    resolve_layout_v2(items)

    if args.csv:
        print_csv(items)
    else:
        print_table(items, args.copybook)


if __name__ == "__main__":
    main()
