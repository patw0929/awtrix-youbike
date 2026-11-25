#!/usr/bin/env python3
"""YouBike 站點監看器的電腦端工具（只用 Python 標準函式庫）。

  python3 youbike.py find 科技大樓            查站點代號（全台）
  python3 youbike.py check "500101001:Home,500101002:MRT"
                                              用時鐘相同的查詢抓一次，印出每頁會顯示什麼
  python3 youbike.py install 192.168.1.100    預設只檢查；加 --yes 才把 app 裝到時鐘
  python3 youbike.py set 192.168.1.100 "500101001:Home,..."   預設只檢查；加 --yes 才寫入站點
  python3 youbike.py refresh 192.168.1.100    預設只檢查；加 --yes 才讓時鐘立刻重抓並切到這個 app
"""
import json
import os
import sys
import time
import urllib.request

APP = "YouBike-Stations-TW"
ALL_URL = "https://apis.youbike.com.tw/json/station-yb2.json"
LIVE_URL = "https://apis.youbike.com.tw/tw2/parkingInfo"
HERE = os.path.dirname(os.path.abspath(__file__))
UA = {"User-Agent": "awtrix-youbike/1.0"}


def http(method, url, body=None, ctype="application/json", timeout=20):
    data = None if body is None else (body if isinstance(body, bytes) else json.dumps(body).encode())
    req = urllib.request.Request(url, data=data, method=method, headers={**UA, "Content-Type": ctype})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    try:
        return json.loads(raw)
    except ValueError:
        return raw.decode(errors="replace")


def parse(spec):
    out = []
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        sid, _, label = part.partition(":")
        sid, label = sid.strip(), label.strip()
        if sid:
            out.append((sid, label or "#" + sid[-4:]))
    return out[:8]


def cmd_find(words):
    print("下載全台站點清單（約 6 MB）…", file=sys.stderr)
    stations = http("GET", ALL_URL, timeout=60)
    hits = [s for s in stations
            if all(w in (s["name_tw"] + s["district_tw"] + s["address_tw"] + s["name_en"]) for w in words)]
    for s in hits[:40]:
        state = "" if s["status"] == 1 else "（暫停）"
        print(f'{s["station_no"]}  {s["district_tw"]} {s["name_tw"]}{state}  '
              f'車 {s["available_spaces"]}／空位 {s["empty_spaces"]}')
    print(f"共 {len(hits)} 筆" + ("（只列前 40 筆）" if len(hits) > 40 else ""), file=sys.stderr)


def cmd_check(spec, low=3):
    st = parse(spec)
    if not st:
        sys.exit("沒有站點。格式：代號:標籤,代號:標籤")
    body = json.dumps({"station_no": [s for s, _ in st]}).encode()
    print(f"POST {LIVE_URL}  {len(body)} bytes")
    t = time.time()
    d = http("POST", LIVE_URL, body)
    rows = {r["station_no"]: r for r in d.get("retVal", {}).get("data", [])}
    print(f"回應 {d.get('retCode')} {d.get('retMsg')}，{len(rows)}/{len(st)} 站，{time.time() - t:.1f} 秒\n")
    for sid, label in st:
        r = rows.get(sid)
        if r is None:
            screen = "NO STN（代號不存在）"
        elif r["status"] != 1:
            screen = "PAUSED"
        else:
            b = r["available_spaces"]
            e = r["available_spaces_detail"].get("eyb", 0)
            color = "紅" if b == 0 else ("黃" if b < low else "綠")
            screen = f"車 {b}（電輔 {e}）  P {r['empty_spaces']}   腳踏車圖示：{color}"
        print(f"  {label:<8} {sid}  →  {screen}")


def device(host, method, path, body=None, ctype="application/json"):
    return http(method, f"http://{host}/api/v1/{path}", body, ctype)


def cmd_install(host, yes):
    src = open(os.path.join(HERE, "app", "youbike.be"), "rb").read()
    apps = device(host, "GET", "apps")
    cur = next((a for a in apps if a.get("name") == APP), None)
    print(f"時鐘 {host}：{'已有 ' + APP + ' ' + str(cur.get('meta', {}).get('version')) + '（會更新，設定保留）' if cur else '尚未安裝 ' + APP}")
    print(f"要上傳 app/youbike.be（{len(src)} bytes）到 PUT /api/v1/apps/script/{APP}")
    if not yes:
        print("只檢查，沒有寫入。確認後加 --yes。")
        return
    print(device(host, "PUT", f"apps/script/{APP}", src, "text/plain"))
    time.sleep(2)
    cur = next((a for a in device(host, "GET", "apps") if a.get("name") == APP), {})
    print("錯誤：" + str(cur.get("error")) if cur.get("error") else "安裝完成，app 沒有回報錯誤。")


def cmd_set(host, spec, yes):
    st = parse(spec)
    value = ",".join(f"{s}:{l}" for s, l in st)
    print(f"要寫入站點設定：{value}")
    if not yes:
        print("只檢查，沒有寫入。確認後加 --yes。")
        return
    print(device(host, "PATCH", f"apps/{APP}/config", {"st": value}))  # 設定欄位要寫 /config，寫 /data 會回 422


def cmd_refresh(host, yes):
    # 寫入任一資料都會讓 app 重新載入，載入時立刻向 YouBike 抓一次
    print(f"要 PATCH apps/{APP}/data 寫一個時間戳（app 會重新載入並立刻重抓），再切到這個 app")
    if not yes:
        print("只檢查，沒有寫入。確認後加 --yes。")
        return
    print(device(host, "PATCH", f"apps/{APP}/data", {"r": int(time.time())}))
    print(device(host, "PUT", "apps/active", {"name": APP}))


def main():
    a = [x for x in sys.argv[1:] if x != "--yes"]
    yes = "--yes" in sys.argv
    if len(a) >= 2 and a[0] == "find":
        cmd_find(a[1:])
    elif len(a) == 2 and a[0] == "check":
        cmd_check(a[1])
    elif len(a) == 2 and a[0] == "install":
        cmd_install(a[1], yes)
    elif len(a) == 3 and a[0] == "set":
        cmd_set(a[1], a[2], yes)
    elif len(a) == 2 and a[0] == "refresh":
        cmd_refresh(a[1], yes)
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
