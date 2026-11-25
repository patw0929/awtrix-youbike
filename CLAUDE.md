# awtrix-youbike

AWTRIX（awtrix-ng 韌體，TC002 52×16）YouBike 站點監看 app＋選站網頁。使用說明見 README.md（英文）與 README.zh-TW.md。本機專用資訊（時鐘 IP、歷程）在 `CLAUDE.local.md`，不上傳。

## 規則

- 改 `app/youbike.src.be`，再 `python3 scripts/build.py --check` → `--write` 產生 `app/youbike.be` 與 `picker/chars.js`；不要手改產物
- 上架資訊（@name、@desc、README.md）英文為主；時鐘畫面與選站網頁中文為主，用語是「AWTRIX 終端（如 Ulanzi TC002）」
- app 名稱 `YouBike-Stations-TW`
- 中文字型只含全台站名用到的字＋常用字；新站名有新字時重跑 build

## 已知事實

- 時鐘下載不了 4.2 MB 的站點清單（http find 實測 status 0），站名只能由設定提供
- 中間鍵要用 `on_button_event(btn, "press")` 攔下，只用 `on_button` 會跳出 empty
- 設定欄位要寫 `PATCH apps/<名稱>/config`；`/data` 會回 422
- GitHub repo `patw0929/awtrix-youbike`（公開，MIT）；選站網頁由 `.github/workflows/pages.yml` 把 `picker/` 發布到 https://patw0929.github.io/awtrix-youbike/

## 現況（2026-11-25）

- 2.0.0 已在時鐘實測：中文站名、長名捲動、電輔數、暫停營運、輪播、旋鈕與中間鍵強制更新
- 已上架 AWTRIX Hub：https://awtrix.de/script/KtaA0XnhWNap（Miscellaneous，只支援 52×16）
- 選站網頁：搜尋、附近、即時車數、Google Maps 連結、LED 預覽、複製／直接寫入

## 待辦

- 無。改版時：bump `@version`，重 build，再到 Hub 頁的 Edit script 更新程式碼
