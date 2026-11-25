#!/usr/bin/env python3
"""畫 52x16 版面示意圖（SVG），中文用行事曆專案的 8px 點陣字。

python3 scripts/mockups.py <cjk_font.bin> <輸出資料夾>
"""
import os
import sys

FONT = {}
SMALL = {  # 3x5
    "0": "###,#.#,#.#,#.#,###", "1": ".#.,##.,.#.,.#.,###", "2": "###,..#,###,#..,###",
    "3": "###,..#,###,..#,###", "4": "#.#,#.#,###,..#,..#", "5": "###,#..,###,..#,###",
    "6": "###,#..,###,#.#,###", "7": "###,..#,..#,.#.,.#.", "8": "###,#.#,###,#.#,###",
    "9": "###,#.#,###,..#,###", "P": "##.,#.#,##.,#..,#..", " ": "...,...,...,...,...",
}
LARGE = {  # 3x7
    "0": "###,#.#,#.#,#.#,#.#,#.#,###", "1": ".#.,##.,.#.,.#.,.#.,.#.,###",
    "2": "###,..#,..#,###,#..,#..,###", "3": "###,..#,..#,###,..#,..#,###",
    "4": "#.#,#.#,#.#,###,..#,..#,..#", "5": "###,#..,#..,###,..#,..#,###",
    "6": "###,#..,#..,###,#.#,#.#,###", "7": "###,..#,..#,.#.,.#.,.#.,.#.",
    "8": "###,#.#,#.#,###,#.#,#.#,###", "9": "###,#.#,#.#,###,..#,..#,###",
}
BOLT = ".#,#.,##,.#,#."  # 2x5 lightning
BIKE13 = ["..........##.", "...###....#..", "....#####.#..", ".###.#...###.",
          "#...#.#.#...#", "#.#.#..##.#.#", "#...#...#...#", ".###.....###."]
BIKE11 = ["........##.", "..##....#..", "...#####.#.", ".##.#..###.",
          "#..##.##..#", "#..#...#..#", ".##.....##."]

YB = 0xFFEF00      # YouBike 官網主色
WHITE = 0xFFFFFF
GRAY = 0x8A8A8A
DIM = 0x333333
ORANGE = 0xFF8A00
RED = 0xFF3030


class Screen:
    def __init__(self):
        self.p = [[0] * 52 for _ in range(16)]

    def px(self, x, y, c):
        if 0 <= x < 52 and 0 <= y < 16:
            self.p[y][x] = c

    def pat(self, rows, x, y, c):
        if isinstance(rows, str):
            rows = rows.split(",")
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch == "#":
                    self.px(x + i, y + j, c)
        return len(rows[0])

    def small(self, s, x, y, c):
        for ch in s:
            x += self.pat(SMALL[ch], x, y, c) + 1
        return x

    def large(self, s, x, y, c):
        for ch in s:
            x += self.pat(LARGE[ch], x, y, c) + 1
        return x

    def cjk(self, s, x, y, c, clip=(0, 52)):
        for ch in s:
            rows = FONT.get(ord(ch))
            if rows:
                for j, b in enumerate(rows):
                    for i in range(8):
                        if b & (0x80 >> i) and clip[0] <= x + i < clip[1]:
                            self.px(x + i, y + j, c)
            x += 8
        return x

    def svg(self, path, title):
        s = 10
        out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{52 * s + 20}" height="{16 * s + 44}" '
               f'viewBox="0 0 {52 * s + 20} {16 * s + 44}"><rect width="100%" height="100%" rx="8" fill="#111"/>',
               f'<text x="10" y="22" fill="#ddd" font-size="14" font-family="sans-serif">{title}</text>']
        for y in range(16):
            for x in range(52):
                c = self.p[y][x]
                fill = f"#{c:06x}" if c else "#1c1c1c"
                out.append(f'<rect x="{10 + x * s + 1}" y="{34 + y * s + 1}" width="{s - 2}" height="{s - 2}" rx="2" fill="{fill}"/>')
        out.append("</svg>")
        open(path, "w").write("\n".join(out))


def bike_color(n, low=3):
    return RED if n == 0 else (ORANGE if n < low else WHITE)


def v_a(name, bikes, ebikes, docks, page, pages):
    """方案 A：站名滿版在上，下排 黃色車圖示＋可借數＋電輔＋空位"""
    s = Screen()
    s.cjk(name, 0, 0, WHITE, clip=(0, 51))
    s.pat(BIKE11, 0, 9, YB)
    x = s.large(str(bikes), 13, 9, bike_color(bikes))
    if ebikes:
        s.pat(BOLT, x + 1, 10, YB)
        s.small(str(ebikes), x + 4, 10, YB)
    d = str(docks)
    w = len(d) * 4 - 1
    s.small(d, 52 - w, 10, GRAY)
    s.pat(SMALL["P"], 52 - w - 5, 10, 0x4A90E2)
    for i in range(pages):  # 右邊捲軸
        pass
    h = max(2, 8 // pages)
    for y in range(8):
        s.px(51, y, DIM)
    for y in range(page * (8 - h) // max(1, pages - 1), page * (8 - h) // max(1, pages - 1) + h):
        s.px(51, y, YB)
    return s


def v_b(name, bikes, ebikes, docks, page, pages):
    """方案 B：左邊大圖示（黃）＋頁點，右邊中文站名、下排 借 12 還 14"""
    s = Screen()
    s.pat(BIKE13, 0, 3, YB)
    for i in range(pages):
        s.px(i * 2, 15, YB if i == page else DIM)
    s.cjk(name, 15, 0, WHITE, clip=(15, 52))
    x = s.cjk("借", 15, 9, GRAY)
    x = s.large(str(bikes), x + 1, 9, bike_color(bikes))
    x = s.cjk("還", x + 2, 9, GRAY)
    s.large(str(docks), x + 1, 9, GRAY)
    return s


def v_c(name, bikes, ebikes, docks, page, pages):
    """方案 C：數字優先，大黃底色塊顯示可借數，站名在右上捲動"""
    s = Screen()
    c = bike_color(bikes)
    bg = YB if bikes >= 3 else (ORANGE if bikes else RED)
    for y in range(16):
        for x in range(17):
            s.px(x, y, bg)
    txt = str(bikes)
    w = len(txt) * 4 - 1
    s.large(txt, (17 - w) // 2, 2, 0x222222)
    s.pat(BIKE11[2:], 3, 10, 0x222222) if False else None
    s.small("P", 2, 10, 0x222222)
    s.small(str(docks), 6, 10, 0x222222)
    s.cjk(name, 19, 0, WHITE, clip=(19, 52))
    s.cjk("可借", 19, 9, GRAY)
    s.large(str(bikes), 37, 9, WHITE)
    return s


def status_screens():
    """共用狀態畫面（中文）"""
    out = []
    for label, color in (("載入中", GRAY), ("暫停營運", ORANGE), ("查無此站", RED), ("請設定站點", YB)):
        s = Screen()
        s.pat(BIKE11, 0, 5, 0x555555 if label != "請設定站點" else YB)
        s.cjk(label, 13, 4, color)
        out.append((label, s))
    return out


def main():
    font_path, out_dir = sys.argv[1], sys.argv[2]
    b = open(font_path, "rb").read()
    for i in range(0, len(b), 9):
        FONT[int.from_bytes(b[i:i + 2], "big")] = list(b[i + 2:i + 9])
    os.makedirs(out_dir, exist_ok=True)
    samples = [("捷運科技大樓站", 12, 5, 14, 0, 3), ("台北教育大學", 0, 0, 53, 1, 3), ("捷運科技大樓站2號出口", 2, 1, 68, 2, 3)]
    for key, fn, title in (("A", v_a, "方案 A"), ("B", v_b, "方案 B"), ("C", v_c, "方案 C")):
        for k, smp in enumerate(samples):
            fn(*smp).svg(os.path.join(out_dir, f"{key}{k + 1}.svg"), f"{title}：{smp[0]}（可借 {smp[1]}）")
    for k, (label, s) in enumerate(status_screens()):
        s.svg(os.path.join(out_dir, f"S{k + 1}.svg"), f"狀態：{label}")
    print("ok", out_dir)


if __name__ == "__main__":
    main()
