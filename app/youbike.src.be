# @name    YouBike Stations TW
# @desc    Unofficial. Live bikes to rent and free docks at your chosen YouBike stations anywhere in Taiwan, with Chinese station names. Pick stations at patw0929.github.io/awtrix-youbike and press the knob to refresh
# @author  patw
# @version 2.0.0
# @display 52x16
# @config  st     text   "Stations 站點"           maxlen=256 group=Stations help="Paste from the station picker at https://patw0929.github.io/awtrix-youbike/ (up to 8)"
# @config  every  number "Refresh 更新間隔"         default=2 min=1 max=30 unit=min group=Stations help="How often the clock asks YouBike for new numbers"
# @config  flip   number "Seconds per station 每站秒數" default=5 min=2 max=15 unit=s group=Display help="Long names stay until they have scrolled through"
# @config  low    number "Few bikes 車少門檻"       default=3 min=1 max=20 group=Display help="The count turns orange below this, red at zero"
# @config  ebike  bool   "Show e-bikes 顯示電輔車"   default=true group=Display help="Yellow bolt with the number of YouBike 2.0E bikes"
#
# Chinese glyphs: Fusion Pixel Font 8px by TakWolf (SIL Open Font License 1.1), subset to the characters used in YouBike station names.
import json
import string

# 9 bytes per glyph: 2 bytes code point (big endian), 7 rows (MSB = left), sorted by code point
var FONT = bytes("FONT_HEX")

var BIKE = ["........##.", "..##....#..", "...#####.#.", ".##.#..###.",
            "#..##.##..#", "#..#...#..#", ".##.....##."]
var BOX = [0x7E, 0x42, 0x42, 0x42, 0x42, 0x7E, 0]
var YB = 0xFFEF00       # YouBike yellow
var ORANGE = 0xFF8A00
var RED = 0xFF3030
var GRAY = 0x8A8A8A
var BLUE = 0x4A90E2
var TRACK = 0x262626
var LIVE_URL = "https://apis.youbike.com.tw/tw2/parkingInfo"

class YouBikeTW
  var ids, names, lays, rows, per, every, low, ebike, ink, bike
  var busy, busy_at, next_at, ok_at, fail, err, cur, since, poke
  var msgs

  def init()
    self.per = int(store.get("flip", 5)) * 1000
    if self.per < 2000 self.per = 2000 end
    self.every = int(store.get("every", 2)) * 60000
    if self.every < 60000 self.every = 60000 end
    self.low = int(store.get("low", 3))
    var e = store.get("ebike")
    self.ebike = e == nil ? true : e
    self.ink = settings.get("textColor")
    if self.ink == nil || self.ink == 0 self.ink = 0xFFFFFF end
    self.bike = []
    for r:BIKE
      var m = []
      for x:0..size(r) - 1
        if r[x] == "#" m.push(x) end
      end
      self.bike.push(m)
    end
    self.msgs = {}
    self.parse(store.get("st", ""))
    self.rows = {}
    self.busy = false
    self.busy_at = 0
    self.ok_at = 0
    self.fail = 0
    self.err = nil
    self.cur = 0
    self.since = now_ms()
    self.poke = 0
    self.next_at = 0          # fetch right away (a settings change or data push reloads the app)
  end

  # ---------- settings ----------

  def trim(s)
    var a = 0
    var b = size(s)
    while a < b && (s[a] == " " || s[a] == "\t") a += 1 end
    while b > a && (s[b - 1] == " " || s[b - 1] == "\t") b -= 1 end
    return a < b ? s[a .. b - 1] : ""
  end

  # "500101001:科技大樓, 500101002" (half or full width , and :) -> ids + names
  def parse(s)
    self.ids = []
    self.names = []
    self.lays = []
    if s == nil return end
    for chunk:string.split(str(s), ",")
      for part:string.split(chunk, "，")
        var p = self.trim(part)
        if size(p) == 0 || size(self.ids) >= 8 continue end
        var c = string.find(p, ":")
        var cl = 1
        if c < 0
          c = string.find(p, "：")
          cl = 3
        end
        var id = c > 0 ? self.trim(p[0 .. c - 1]) : (c == 0 ? "" : p)
        var nm = c >= 0 && c + cl < size(p) ? self.trim(p[c + cl ..]) : ""
        if size(id) == 0 continue end
        self.ids.push(id)
        self.names.push(nm)
        self.lays.push(nil)
      end
    end
  end

  # ---------- text ----------

  def utf8(s)
    var out = []
    var i = 0
    var n = size(s)
    while i < n
      var c = string.byte(s[i])
      if c < 0x80
        out.push(c)
        i += 1
      elif c >= 0xE0 && c < 0xF0 && i + 2 < n
        out.push(((c & 0x0F) << 12) | ((string.byte(s[i + 1]) & 0x3F) << 6) | (string.byte(s[i + 2]) & 0x3F))
        i += 3
      elif c >= 0xC0 && c < 0xE0 && i + 1 < n
        out.push(((c & 0x1F) << 6) | (string.byte(s[i + 1]) & 0x3F))
        i += 2
      elif c >= 0xF0
        out.push(0x25A1)
        i += 4
      else
        i += 1
      end
    end
    return out
  end

  def glyph(cp)
    var f = FONT
    var lo = 0
    var hi = size(f) / 9 - 1
    while lo <= hi
      var mid = (lo + hi) / 2
      var o = mid * 9
      var c = (f[o] << 8) | f[o + 1]
      if c == cp
        return [f[o + 2], f[o + 3], f[o + 4], f[o + 5], f[o + 6], f[o + 7], f[o + 8]]
      elif c < cp
        lo = mid + 1
      else
        hi = mid - 1
      end
    end
    return nil
  end

  # -> [width, [[x, glyph rows | ascii string], ...]]; call only from draw() (measures with the small font)
  def layout(s)
    font("small")
    var items = []
    var run = ""
    var x = 0
    for cp:self.utf8(s)
      if cp < 0x80
        run += string.char(cp)
      else
        if size(run) > 0
          items.push([x, run])
          x += text_width(run) + 1
          run = ""
        end
        var g = self.glyph(cp)
        items.push([x, g != nil ? g : BOX])
        x += 8
      end
    end
    if size(run) > 0
      items.push([x, run])
      x += text_width(run)
    end
    return [x, items]
  end

  def msg(s)
    var l = self.msgs.find(s)
    if l == nil
      l = self.layout(s)
      self.msgs[s] = l
    end
    return l
  end

  # Draw a laid-out line with its top at y, shifted left by off, kept left of column clip
  def draw_line(lay, x0, y, off, c, clip)
    for it:lay[1]
      var x = x0 + it[0] - off
      if x >= clip continue end
      var g = it[1]
      if type(g) == "string"
        text(x, y + 6, g, c)
      elif x > -8
        for r:0..6
          var b = g[r]
          if b != 0
            for k:0..7
              if (b & (0x80 >> k)) != 0
                var px = x + k
                if px >= 0 && px < clip pixel(px, y + r, c) end
              end
            end
          end
        end
      end
    end
  end

  # ---------- data ----------

  def fetch()
    if size(self.ids) == 0 return end
    self.busy = true
    self.busy_at = now_ms()
    http.post(LIVE_URL, json.dump({'station_no': self.ids}), / b, st -> self.on_body(b, st),
              {'headers': {'Content-Type': "application/json"}, 'timeout': 15})
  end

  def retry()
    self.fail += 1
    var w = 15000
    var k = 1
    while k < self.fail && w < self.every
      w *= 2
      k += 1
    end
    if w > self.every w = self.every end
    self.next_at = now_ms() + w
  end

  def on_body(b, st)
    self.busy = false
    var d = st == 200 && b != nil ? json.load(b) : nil
    var rv = isinstance(d, map) ? d.find("retVal") : nil
    var arr = isinstance(rv, map) ? rv.find("data") : nil
    if !isinstance(arr, list)
      self.err = st == 200 ? "資料錯誤" : "連線失敗"
      self.retry()
      return
    end
    var m = {}
    for s:arr
      if !isinstance(s, map) continue end
      var det = s.find("available_spaces_detail")
      var eb = isinstance(det, map) ? det.find("eyb", 0) : 0
      m[str(s.find("station_no", ""))] = [int(s.find("available_spaces", 0)), int(eb == nil ? 0 : eb),
                                         int(s.find("empty_spaces", 0)), int(s.find("status", 1))]
    end
    self.rows = m
    self.err = nil
    self.fail = 0
    self.ok_at = now_ms()
    self.next_at = now_ms() + self.every
  end

  def refresh_now()
    self.poke = now_ms()
    if self.busy return end
    self.fail = 0
    self.next_at = 0
  end

  def loop()
    var t = now_ms()
    if self.busy
      if t - self.busy_at > 40000
        self.busy = false
        self.err = "連線失敗"
        self.retry()
      end
      return
    end
    if t >= self.next_at self.fetch() end
  end

  # ---------- app hooks ----------

  def should_show() return true end

  def page_ms(i)
    var l = i < size(self.lays) ? self.lays[i] : nil
    if l == nil || l[0] <= 50 return self.per end
    var need = 1200 + (l[0] - 50) * 1000 / 16 + 1500
    return need > self.per ? need : self.per
  end

  def duration()
    var n = size(self.ids)
    if n == 0 return 5000 end
    var s = 0
    for i:0..n - 1 s += self.page_ms(i) end
    return s
  end

  def on_show()
    self.since = now_ms()
    self.cur = 0
    if self.ok_at > 0 && now_ms() - self.ok_at > 60000 self.refresh_now() end
  end

  def on_button(btn)
    if btn == "select"
      self.refresh_now()
      return true
    end
    return false
  end

  def on_button_event(btn, ev)
    if btn == "select" && ev == "press"
      self.refresh_now()
      return true
    end
    return false
  end

  def on_knob(ev)
    var n = size(self.ids)
    if ev == "press"
      self.refresh_now()
      return true
    end
    if n <= 1 return false end
    if ev == "right" self.cur = (self.cur + 1) % n
    elif ev == "left" self.cur = (self.cur - 1 + n) % n
    else return false end
    self.since = now_ms()
    return true
  end

  # ---------- drawing ----------

  def draw_bike(x0, y0, c)
    for y:0..6
      for x:self.bike[y]
        pixel(x0 + x, y0 + y, c)
      end
    end
  end

  def draw()
    clear()
    var t = now_ms()
    var n = size(self.ids)
    if n == 0
      self.draw_bike(0, 5, YB)
      self.draw_line(self.msg("請設定站點"), 12, 4, 0, YB, 52)
      return
    end
    if self.cur >= n self.cur = 0 end
    if t - self.since >= self.page_ms(self.cur)
      self.cur = (self.cur + 1) % n
      self.since = t
    end
    var i = self.cur
    var id = self.ids[i]

    # Top: station name (scrolls when longer than 50 px)
    if self.lays[i] == nil
      self.lays[i] = self.layout(size(self.names[i]) > 0 ? self.names[i] : (size(id) > 4 ? "#" + id[size(id) - 4 ..] : id))
    end
    var lay = self.lays[i]
    var off = 0
    if lay[0] > 50
      var el = t - self.since - 1200
      off = el > 0 ? el * 16 / 1000 : 0
      if off > lay[0] - 50 off = lay[0] - 50 end
    end
    self.draw_line(lay, 0, 0, off, self.ink, 50)
    rect_fill(50, 0, 2, 8, 0)

    # Right edge: which station (red thumb = last update failed)
    if n > 1 || self.err != nil
      rect_fill(51, 0, 1, 8, TRACK)
      var h = 8 / n
      if h < 2 h = 2 end
      var y = n > 1 ? i * (8 - h) / (n - 1) : 0
      rect_fill(51, y, 1, h, self.err != nil ? RED : YB)
    end

    # Bottom: bike (rides while updating), bikes, e-bikes, free docks
    var riding = self.busy || t - self.poke < 700
    var bx = riding ? (t / 120) % 2 : 0
    var r = self.rows.find(id)
    if r == nil
      self.draw_bike(bx, 9, 0x606060)
      var m = self.ok_at > 0 ? "查無此站" : (self.err != nil ? self.err : "載入中")
      self.draw_line(self.msg(m), 13, 9, 0, self.ok_at > 0 || self.err != nil ? ORANGE : GRAY, 52)
      return
    end
    if r[3] != 1
      self.draw_bike(bx, 9, 0x606060)
      self.draw_line(self.msg("暫停營運"), 13, 9, 0, ORANGE, 52)
      return
    end
    self.draw_bike(bx, 9, YB)
    var bikes = r[0]
    var c = bikes == 0 ? RED : (bikes < self.low ? ORANGE : self.ink)
    font("large")
    var x = 13 + text(13, 15, str(bikes), c)
    font("small")
    if self.ebike && r[1] > 0
      x += 2
      pixel(x + 1, 10, YB) pixel(x, 11, YB) pixel(x, 12, YB) pixel(x + 1, 12, YB)
      pixel(x + 1, 13, YB) pixel(x, 14, YB)
      text(x + 3, 15, str(r[1]), YB)
    end
    var ds = str(r[2])
    var dx = 52 - text_width(ds)
    text(dx, 15, ds, GRAY)
    text(dx - 5, 15, "P", BLUE)
  end
end
return YouBikeTW()
