#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1
echo "RUNNING SCRIPT: $0"
# ====== CONFIG ======
VOLUME="Extreme SSD"
HUB_ROOT="/Volumes/${VOLUME}/Backup_Files_To_NAS/PhotographyHub"
PAGES="$HUB_ROOT/pages"
TOOLS="$HUB_ROOT/tools"
MASTER="$PAGES/MASTER-steps.txt"
INDEX="$HUB_ROOT/index.html"
TMP_INDEX="$HUB_ROOT/.index.new.html"
STAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
MASTER_STAMP="$(date -r "$MASTER" '+%Y-%m-%d %H:%M:%S %Z')"
TITLE="Bridge Tools — Photography Workflow Hub - Website"
SYNC_NOTE="Edits happen on the SanDisk. Build syncs to iCloud. iPhone reads the iCloud mirror."
# ====================

ts(){ date "+%Y-%m-%d %H:%M:%S"; }

clean_appledouble() {
  find "$HUB_ROOT" -path "$HUB_ROOT/.git" -prune -o -name '._*' -type f -delete 2>/dev/null || true
}

trap clean_appledouble EXIT

write_geodetic_converter_page() {
  local out="$PAGES/geodetic-converter.html"
  cat > "$out" <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Geodetic Converter</title>
  <style>
    :root {
      --bg:#eef1f4;
      --fg:#101828;
      --card:#fff;
      --accent:#0e49c2;
      --muted:#475467;
      --line:#d0d5dd;
      --good:#067647;
      --bad:#b42318;
    }
    body{margin:24px;font:16px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Arial,sans-serif;background:var(--bg);color:var(--fg)}
    .wrap{max-width:960px;margin:0 auto}
    .card{background:var(--card);border-radius:16px;padding:20px;box-shadow:0 6px 18px rgba(16,24,40,.08)}
    h1{margin:0 0 8px}
    p{margin:0 0 12px;color:var(--muted)}
    .grid{display:grid;gap:16px;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));margin-top:18px}
    label{display:block;font-weight:600;margin:0 0 6px}
    input[type="text"]{width:100%;padding:12px 13px;border:1px solid var(--line);border-radius:12px;font:inherit;box-sizing:border-box}
    input[readonly]{background:#f8fafc}
    .actions{display:flex;flex-wrap:wrap;gap:10px;margin-top:18px}
    button,.linkbtn{display:inline-block;padding:11px 15px;border-radius:12px;border:0;background:var(--accent);color:#fff;text-decoration:none;font:inherit;cursor:pointer}
    button.secondary{background:#344054}
    .toggle{display:flex;align-items:center;gap:8px;margin:16px 0 0;color:var(--fg)}
    .toggle input{width:auto}
    .status{margin-top:16px;padding:12px 14px;border-radius:12px}
    .status.ok{background:#ecfdf3;color:var(--good)}
    .status.error{background:#fef3f2;color:var(--bad)}
    .examples{margin-top:18px;padding-top:18px;border-top:1px solid var(--line)}
    .examples code{white-space:nowrap}
    .muted{color:var(--muted)}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>Geodetic Converter</h1>
      <p>Convert latitude and longitude in DDM, DMS, or decimal degrees into Google Maps compatible decimal coordinates.</p>
      <p>Examples: <code>37,23.214N</code>, <code>37°23'12.84"N</code>, <code>37.387N</code>, <code>-118.1798</code></p>

      <div class="grid">
        <div>
          <label for="latitude-input">Latitude</label>
          <input id="latitude-input" type="text" placeholder="Example: 37,23.214N or 37 23 12.84 N or 37.387">
        </div>
        <div>
          <label for="longitude-input">Longitude</label>
          <input id="longitude-input" type="text" placeholder="Example: 118,10.788W or 118 10 47.28 W or -118.1798">
        </div>
      </div>

      <label class="toggle" for="auto-open">
        <input id="auto-open" type="checkbox">
        <span>Open Google Maps automatically after convert</span>
      </label>

      <div class="actions">
        <button id="convert-btn" type="button">Convert</button>
        <button id="open-btn" type="button" class="secondary">Open In Google Maps</button>
      </div>

      <div class="grid" style="margin-top:18px;">
        <div>
          <label for="decimal-lat">Decimal Latitude</label>
          <input id="decimal-lat" type="text" readonly>
        </div>
        <div>
          <label for="decimal-lon">Decimal Longitude</label>
          <input id="decimal-lon" type="text" readonly>
        </div>
      </div>

      <div style="margin-top:18px;">
        <label for="maps-url">Google Maps URL</label>
        <input id="maps-url" type="text" readonly>
      </div>

      <div id="status" class="status" style="display:none;"></div>

      <div class="examples">
        <p class="muted">Accepted formats</p>
        <p><code>37,23.214N</code> and <code>118,10.788W</code> for DDM</p>
        <p><code>37 23 12.84 N</code> and <code>118 10 47.28 W</code> for DMS</p>
        <p><code>37.387</code> and <code>-118.1798</code> for decimal degrees</p>
      </div>
    </div>
  </div>

  <script>
    (function () {
      var latitudeInput = document.getElementById("latitude-input");
      var longitudeInput = document.getElementById("longitude-input");
      var decimalLat = document.getElementById("decimal-lat");
      var decimalLon = document.getElementById("decimal-lon");
      var mapsUrl = document.getElementById("maps-url");
      var status = document.getElementById("status");
      var autoOpen = document.getElementById("auto-open");
      var lastUrl = "";

      function setStatus(message, kind) {
        status.textContent = message;
        status.className = "status " + kind;
        status.style.display = "block";
      }

      function clearStatus() {
        status.style.display = "none";
        status.textContent = "";
      }

      function normalize(raw) {
        return raw.trim().toUpperCase().replace(/[º°]/g, " ").replace(/'/g, " ").replace(/"/g, " ").replace(/,/g, " ");
      }

      function parseCoordinate(raw, kind) {
        var text = raw.trim().toUpperCase();
        if (!text) {
          throw new Error("Enter " + kind + ".");
        }

        var directionMatch = text.match(/[NSEW]$/);
        var direction = directionMatch ? directionMatch[0] : "";
        var sign = direction === "S" || direction === "W" ? -1 : 1;
        var body = direction ? text.slice(0, -1).trim() : text;

        var ddmMatch = body.match(/^([+-]?\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)$/);
        if (ddmMatch) {
          var ddmDegrees = parseFloat(ddmMatch[1]);
          var ddmMinutes = parseFloat(ddmMatch[2]);
          if (ddmMinutes >= 60) throw new Error(kind + " minutes must be less than 60.");
          var ddmValue = Math.abs(ddmDegrees) + (ddmMinutes / 60);
          if (direction) return sign * ddmValue;
          return ddmDegrees < 0 ? -ddmValue : ddmValue;
        }

        var tokens = normalize(text).split(/\s+/).filter(Boolean);
        if (tokens.length >= 2 && tokens.length <= 4) {
          var maybeDirection = tokens[tokens.length - 1];
          var numericTokens = tokens.slice();
          if (/^[NSEW]$/.test(maybeDirection)) {
            direction = maybeDirection;
            sign = direction === "S" || direction === "W" ? -1 : 1;
            numericTokens.pop();
          }

          if (numericTokens.every(function (token) { return /^[-+]?\d+(?:\.\d+)?$/.test(token); })) {
            var degrees = parseFloat(numericTokens[0]);
            if (numericTokens.length === 1) {
              return degrees;
            }

            var minutes = parseFloat(numericTokens[1]);
            var seconds = numericTokens.length > 2 ? parseFloat(numericTokens[2]) : 0;
            if (minutes >= 60 || seconds >= 60) {
              throw new Error(kind + " minutes and seconds must be less than 60.");
            }

            var value = Math.abs(degrees) + (minutes / 60) + (seconds / 3600);
            if (direction) return sign * value;
            return degrees < 0 ? -value : value;
          }
        }

        throw new Error("Could not parse " + kind + ". Use DDM, DMS, or decimal degrees.");
      }

      function validateRange(latitude, longitude) {
        if (latitude < -90 || latitude > 90) throw new Error("Latitude must be between -90 and 90.");
        if (longitude < -180 || longitude > 180) throw new Error("Longitude must be between -180 and 180.");
      }

      function formatDecimal(value) {
        return value.toFixed(6).replace(/0+$/, "").replace(/\.$/, "");
      }

      function buildMapsUrl(latitude, longitude) {
        return "https://www.google.com/maps?q=" + encodeURIComponent(formatDecimal(latitude) + "," + formatDecimal(longitude));
      }

      function convertAndMaybeOpen(shouldOpen) {
        clearStatus();

        try {
          var latitude = parseCoordinate(latitudeInput.value, "latitude");
          var longitude = parseCoordinate(longitudeInput.value, "longitude");
          validateRange(latitude, longitude);

          decimalLat.value = formatDecimal(latitude);
          decimalLon.value = formatDecimal(longitude);
          lastUrl = buildMapsUrl(latitude, longitude);
          mapsUrl.value = lastUrl;

          setStatus("Coordinates converted. Google Maps URL is ready.", "ok");

          if (shouldOpen) {
            window.open(lastUrl, "_blank", "noopener");
          }
        } catch (error) {
          lastUrl = "";
          decimalLat.value = "";
          decimalLon.value = "";
          mapsUrl.value = "";
          setStatus(error.message, "error");
        }
      }

      document.getElementById("convert-btn").addEventListener("click", function () {
        convertAndMaybeOpen(autoOpen.checked);
      });

      document.getElementById("open-btn").addEventListener("click", function () {
        if (!lastUrl) {
          convertAndMaybeOpen(false);
        }
        if (lastUrl) {
          window.open(lastUrl, "_blank", "noopener");
        }
      });
    })();
  </script>
</body>
</html>
HTML
}

echo "[$(ts)] Build starting…"
[[ -d "/Volumes/${VOLUME}" ]] || { echo "[$(ts)] ERROR: SanDisk not mounted at /Volumes/${VOLUME}"; exit 1; }
[[ -f "$MASTER" ]] || { echo "[$(ts)] ERROR: MASTER file not found: $MASTER"; exit 1; }
mkdir -p "$PAGES" "$TOOLS"

# 1) Clean previously generated .html pages (keep template.html if present)
echo "[$(ts)] Cleaning old generated pages…"
find "$PAGES" -type f -name '*.html' ! -name 'template.html' -delete 2>/dev/null || true

# 2) Parse MASTER and generate per-page HTMLs + collect card metadata
META_TMP="$(mktemp)"
trap 'rm -f "$META_TMP"' EXIT

/usr/bin/awk -v PAGES_DIR="$PAGES" -v META="$META_TMP" '
function html_escape(s,   t){ t=s; gsub("&","&amp;",t); gsub("<","&lt;",t); gsub(">","&gt;",t); return t }
function trim(s){ sub(/^[ \t\r\n]+/,"",s); sub(/[ \t\r\n]+$/,"",s); return s }
function slugify(s,   t){ t=tolower(s); gsub(/[^a-z0-9]+/,"-",t); gsub(/^-+|-+$/,"",t); if (t=="") t="untitled"; return t }
function summarize(txt,   t){ t=txt; gsub(/\r/,"",t); gsub(/\n+/," ",t); sub(/^[ \t]+/,"",t); if (length(t)>180) t=substr(t,1,177)"…"; return t }
function end_para(){ if (para!=""){ body_html = body_html "<p>" para "</p>\n"; para="" } }
function emit(   out,esc_title,i,n,line,item,inlist){
  if (title=="") return
  if (slug=="") slug = slugify(title)
  if (order=="") order="999"
  if (back=="") back="../index.html"
  if (summary=="") summary = summarize(body)

  body_html=""; para=""; inlist=0
  n=split(body, L, "\n")
  for (i=1; i<=n; i++){
    line=L[i]
    # blank line => close paragraph or list
    if (line ~ /^[ \t]*$/){
      if (inlist){ body_html = body_html "</ul>\n"; inlist=0 }
      end_para()
      continue
    }
    # bullet list line starting with "- "
    if (line ~ /^[ \t]*-[ \t]+/){
      if (!inlist){ end_para(); body_html = body_html "<ul>\n"; inlist=1 }
      item=line
      sub(/^[ \t]*-[ \t]+/,"",item)
      body_html = body_html "<li>" html_escape(item) "</li>\n"
      continue
    }
    # normal text
    if (inlist){ body_html = body_html "</ul>\n"; inlist=0 }
    if (para!="") para = para " "
    para = para html_escape(line)
  }
  if (inlist){ body_html = body_html "</ul>\n" }
  end_para()

  esc_title = html_escape(title)
  out = PAGES_DIR "/" slug ".html"

  print "<!doctype html>" > out
  print "<html lang=\"en\">" >> out
  print "<head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" >> out
  print "<title>" esc_title "</title>" >> out
  print "<style>*{box-sizing:border-box}html{overflow-x:hidden;-webkit-text-size-adjust:100%}body{margin:24px;font:16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Arial,sans-serif;background:#eef1f4;color:#101828;overflow-x:hidden}a{color:#0e49c2;text-decoration:none}a:hover{text-decoration:underline}.wrap{max-width:900px;width:100%;margin:0 auto}.card{background:#fff;border-radius:14px;padding:20px;box-shadow:0 6px 18px rgba(16,24,40,.08);overflow-wrap:anywhere;word-break:break-word}.back{margin:0 0 16px;display:inline-block}h1{margin:0 0 12px;font-size:2.2rem;line-height:1.15}h1,p,li{overflow-wrap:anywhere;word-break:break-word}p,li{font-size:1rem}ul{margin:0 0 1rem;padding-left:1.25rem}@media (max-width:640px){body{margin:12px}.card{padding:16px;border-radius:12px}h1{font-size:2rem}ul{padding-left:1.1rem}}@media (min-width:768px) and (max-width:1180px){body{font-size:20px}.wrap{max-width:760px}.card{padding:28px}h1{font-size:2.85rem}p,li{font-size:1.22rem;line-height:1.75}ul{padding-left:1.35rem}}</style>" >> out
  print "</head><body><div class=\"wrap\">" >> out

  # Back link: go back if possible, else to the hub. Use &larr; for the arrow.
  # print "<a class=\"back\" href=\"#\" onclick=\"if(history.length>1){history.back();}else{window.location.href='../index.html';}return false;\">&larr; Back</a>" >> out

  print "<div class=\"card\"><h1>" esc_title "</h1>" >> out
  printf "%s", body_html >> out
  print "</div></div></body></html>" >> out
  close(out)

  # metadata line for index
  s = summary
  gsub(/\|/," - ",s)
  print order "|" slug "|" title "|" s >> META
}
BEGIN{
  title=slug=summary=order=back=body=""
}
# metadata lines
/^@@[ \t]*title[ \t]*:/{
  emit()
  title=$0; sub(/^@@[ \t]*title[ \t]*:/,"",title); title=trim(title)
  slug=summary=order=back=""; body=""
  next
}
/^@@[ \t]*slug[ \t]*:/    { slug=$0;    sub(/^@@[ \t]*slug[ \t]*:/,"",slug);       slug=trim(slug);    next }
/^@@[ \t]*summary[ \t]*:/ { summary=$0; sub(/^@@[ \t]*summary[ \t]*:/,"",summary); summary=trim(summary); next }
/^@@[ \t]*order[ \t]*:/   { order=$0;   sub(/^@@[ \t]*order[ \t]*:/,"",order);     order=trim(order);   next }
/^@@[ \t]*back[ \t]*:/    { back=$0;    sub(/^@@[ \t]*back[ \t]*:/,"",back);       back=trim(back);    next }
# body
{ body = body $0 "\n" }
END{ emit() }
' "$MASTER"

echo "[$(ts)] Writing custom tool pages…"
write_geodetic_converter_page

# 3) Build index.html from metadata (sorted by order), open cards in new tab, add “Last built”
echo "[$(ts)] Writing index…"

{
  cat <<HTML_HEAD
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>$TITLE</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    :root { --bg:#eef1f4; --fg:#101828; --card:#fff; --accent:#0e49c2; --muted:#475467; }
    body{margin:24px;font:16px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Arial,sans-serif;background:var(--bg);color:var(--fg)}
    h1{margin:0 0 8px}
    .stamp{margin:0 0 16px;color:#6b7280;font-size:.95rem}
    .device-note{margin:0 0 16px;padding:10px 12px;background:#e7eefc;border-left:4px solid #0e49c2;border-radius:8px;color:#1d2939}
    .grid{max-width:1100px;margin:0 auto;display:grid;gap:16px;grid-template-columns:repeat(auto-fill,minmax(280px,1fr))}
    .card{background:var(--card);border-radius:14px;padding:16px 16px 18px;box-shadow:0 6px 18px rgba(16,24,40,.08)}
    .card h2{margin:0 0 6px;font-size:18px}
    .card p{margin:0 0 10px;color:var(--muted)}
    a{color:#0e49c2;text-decoration:none} a:hover{text-decoration:underline}
  </style>
</head>
<body>
  <h1>$TITLE</h1>
  <div class="stamp">$SYNC_NOTE</div>
  <div class="stamp">MASTER-steps.txt last modified: $MASTER_STAMP</div>
  <div class="stamp">Last built: $STAMP</div>
  <div id="ios-tools-note" class="device-note" style="display:none;">
    Bridge tools are available on Mac only. You are viewing the cards-only hub.
    <a href="?view=tools">Show tools anyway</a>
  </div>
  <div id="hub-cards" class="grid">
HTML_HEAD

  sort -t"|" -k1,1n "$META_TMP" | while IFS="|" read -r ord slug title summary; do
    esc_title=${title//&/&amp;}; esc_title=${esc_title//</&lt;}; esc_title=${esc_title//>/&gt;}
    esc_summary=${summary//&/&amp;}; esc_summary=${esc_summary//</&lt;}; esc_summary=${esc_summary//>/&gt;}
    printf '    <div class="card"><h2><a href="pages/%s.html" >%s</a></h2><p>%s</p><a href="pages/%s.html" >Open →</a></div>\n' \
      "$slug" "$esc_title" "$esc_summary" "$slug"
  done

  cat <<HTML_TAIL
  </div>
  <script>
    (function () {
      var params = new URLSearchParams(window.location.search);
      var requestedView = (params.get("view") || "").toLowerCase();
      var ua = navigator.userAgent || "";
      var platform = navigator.platform || "";
      var maxTouch = navigator.maxTouchPoints || 0;
      var isIOS = /iPhone|iPad|iPod/.test(ua) || (platform === "MacIntel" && maxTouch > 1);

      var toolsPanel = document.getElementById("bridge-tools-panel");
      var cardsGrid = document.getElementById("hub-cards");
      var iosNote = document.getElementById("ios-tools-note");

      var hideToolsForIOS = requestedView !== "tools" && isIOS;
      var hideToolsManual = requestedView === "cards";
      var showToolsOnly = requestedView === "tools";
      var hideTools = hideToolsForIOS || hideToolsManual;
      var hideCards = showToolsOnly;

      if (toolsPanel) toolsPanel.style.display = hideTools ? "none" : "";
      if (cardsGrid) cardsGrid.style.display = hideCards ? "none" : "";

      var showIOSNote = hideTools && (hideToolsForIOS || (hideToolsManual && isIOS));
      if (iosNote) iosNote.style.display = showIOSNote ? "" : "none";
    })();
  </script>
</body>
</html>
HTML_TAIL
TMP_INDEX="$HUB_ROOT/.index.new.html"
} > "$TMP_INDEX"

if [[ -s "$TMP_INDEX" ]]; then
  mv "$TMP_INDEX" "$INDEX"
else
  echo "[$(ts)] ERROR: Generated index was empty; keeping previous index.html"
  rm -f "$TMP_INDEX"
  exit 1
fi

# 4) Inject Tools panel under the H1 (if fragment exists)
TOOLS_FRAG="$TOOLS/hub_tools.html"
if [[ -f "$TOOLS_FRAG" && -f "$INDEX" ]]; then
  echo "[$(ts)] Injecting tools panel…"
  tmp="$HUB_ROOT/.index.tmp"
  awk -v frag="$TOOLS_FRAG" '
  {
    print $0
    if ($0 ~ /<h1>/ && inserted==0) {
      system("cat \"" frag "\"")
      inserted=1
    }
  }
' "$INDEX" > "$tmp" && mv "$tmp" "$INDEX"
fi

echo "[$(ts)] Build complete."
# Prefer Safari for file:// .command links
open -a "Safari" "$INDEX" 2>/dev/null || open "$INDEX" 2>/dev/null || true
# ------------------------------------------------------------
# Sync hub to iCloud for iPhone access
# ------------------------------------------------------------

SYNC_SCRIPT="$TOOLS/SyncHubToiCloudForiPhone.sh"

if [[ -x "$SYNC_SCRIPT" ]]; then
  echo "[$(ts)] Syncing hub to iCloud for iPhone..."
  "$SYNC_SCRIPT"
else
  echo "[$(ts)] WARNING: SyncHubToiCloudForiPhone.sh not found or not executable."
fi

# ------------------------------------------------------------
# Publish hub updates to GitHub (triggers Actions + Pages deploy)
# ------------------------------------------------------------
PUBLISH_SCRIPT="$TOOLS/PublishHubToGitHub.sh"

if [[ -x "$PUBLISH_SCRIPT" ]]; then
  echo "[$(ts)] Publishing hub updates to GitHub..."
  "$PUBLISH_SCRIPT"
else
  echo "[$(ts)] WARNING: PublishHubToGitHub.sh not found or not executable."
fi
