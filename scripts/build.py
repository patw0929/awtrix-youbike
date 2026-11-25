#!/usr/bin/env python3
"""把站名用到的中文字做成字型子集，嵌進 app，並產生選站網頁的「可顯示字」清單。

python3 scripts/build.py --check   只統計，不寫檔
python3 scripts/build.py --write   寫出 app/youbike.be 與 picker/chars.js

來源：
- app/youbike.src.be（app 原始碼，FONT_HEX 標記處放字型）
- assets/cjk_font.bin（Fusion Pixel 8px，每字 9 bytes：2 bytes 碼位＋7 列點陣；OFL 1.1）
- 全台站名（YouBike station-min-yb2.json，執行時下載）
"""
import json
import os
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "app", "youbike.src.be")
OUT = os.path.join(ROOT, "app", "youbike.be")
CHARS_JS = os.path.join(ROOT, "picker", "chars.js")
FONT = os.path.join(ROOT, "assets", "cjk_font.bin")
LIST_URL = "https://apis.youbike.com.tw/json/station-min-yb2.json"

# 介面用字與自訂標籤常用字
UI = "載入中暫停營運查無此站請設定站點連線失敗資料錯誤更新可借還空位電輔"
COMMON = ("家公司學校捷運站前後左右東西南北門口上下中大小新舊一二三四五六七八九十百號出入路街巷弄段樓館園院"
          "場市區里村醫診所超商市場公園車站火高鐵辦室健身房圖書運動中心國小國中高中大學宿舍爸媽阿公嬤"
          "朋友店餐廳咖啡便利商店銀行郵局停車場對面旁邊附近轉角舊家老家工作補習班")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("--check", "--write"):
        sys.exit(__doc__)
    font = open(FONT, "rb").read()
    glyphs = {int.from_bytes(font[i:i + 2], "big"): font[i:i + 9] for i in range(0, len(font), 9)}
    req = urllib.request.Request(LIST_URL, headers={"User-Agent": "awtrix-youbike-build/1.0"})
    stations = json.load(urllib.request.urlopen(req, timeout=60))
    text = "".join(s["name_tw"] + s["district_tw"] for s in stations) + UI + COMMON
    want = sorted({ord(c) for c in text if ord(c) > 0x7F})
    have = [c for c in want if c in glyphs]
    miss = [chr(c) for c in want if c not in glyphs]
    blob = b"".join(glyphs[c] for c in have)
    print(f"站點 {len(stations)}，非英數字 {len(want)}，字型有 {len(have)}，缺 {len(miss)}：{''.join(miss)}")
    print(f"字型子集 {len(blob)} bytes，嵌入 app 後約 {len(blob) * 2 // 1024} KB（十六進位）")
    src = open(SRC, encoding="utf-8").read()
    if "FONT_HEX" not in src:
        sys.exit("app/youbike.src.be 裡找不到 FONT_HEX 標記")
    lines = [blob[i:i + 900].hex() for i in range(0, len(blob), 900)]
    hexsrc = 'bytes(\n  "' + '" +\n  "'.join(lines) + '")'
    app = src.replace('bytes("FONT_HEX")', hexsrc)
    print(f"app 產物 {len(app.encode())} bytes → {os.path.relpath(OUT, ROOT)}")
    js = ("// 由 scripts/build.py 產生：時鐘能顯示的中文字與點陣（每字 9 bytes：碼位 2 bytes＋7 列）\n"
          "window.YB_FONT = \"" + blob.hex() + "\";\n")
    print(f"可顯示字清單 {len(js.encode())} bytes → {os.path.relpath(CHARS_JS, ROOT)}")
    if sys.argv[1] == "--check":
        print("只檢查，沒有寫檔。")
        return
    open(OUT, "w", encoding="utf-8").write(app)
    os.makedirs(os.path.dirname(CHARS_JS), exist_ok=True)
    open(CHARS_JS, "w", encoding="utf-8").write(js)
    print("已寫入。")


if __name__ == "__main__":
    main()
