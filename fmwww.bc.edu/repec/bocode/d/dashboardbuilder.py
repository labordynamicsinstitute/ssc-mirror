# dashboardbuilder.py — the Python engine behind dashboardbuilder.ado
# ----------------------------------------------------------------------------
# Loaded at runtime by the ado via:  python script "dashboardbuilder.py"
# Uses ONLY the Python standard library (json, os) + Stata's sfi bridge.
# Nothing here talks to the network; nothing needs pip.
#
# Two entry points, called as one-liners from the ado:
#   _dbb_capture()   snapshot the current dataset's capture-vars to JSON
#   _dbb_assemble()  read all snapshots + spec globals, write the HTML file
# Both report failures through the Stata global DBB_PYERR (never raise), so
# the ado can print friendly errors.
# ----------------------------------------------------------------------------
import json
import os

from sfi import Data, Macro


def _dbb_g(name):
    """read a Stata global (empty string if unset)"""
    try:
        return Macro.getGlobal(name)
    except Exception:
        return ""


def _dbb_capture():
    """Snapshot the current dataset's capture-vars to <dir>/panel<k>.json.
    Value columns (DBB_CAPRAW) stay numeric; every other column is decoded
    through its value label so categories arrive as readable strings."""
    try:
        k = _dbb_g("DBB_K")
        d = _dbb_g("DBB_DIR")
        cols = _dbb_g("DBB_CAP").split()
        raw = set(_dbb_g("DBB_CAPRAW").split())
        colvals, labels = [], {}
        for c in cols:
            vals = Data.get(var=c, valuelabel=(c not in raw), missingval=None)
            colvals.append(vals)
            try:
                labels[c] = Data.getVarLabel(c) or c
            except Exception:
                labels[c] = c
        rows = [list(t) for t in zip(*colvals)] if colvals else []
        with open(os.path.join(d, "panel%s.json" % k), "w", encoding="utf-8") as f:
            json.dump({"columns": cols, "labels": labels, "rows": rows}, f)
        Macro.setGlobal("DBB_PYERR", "")
    except Exception as e:
        Macro.setGlobal("DBB_PYERR", str(e))


def _dbb_esc(s):
    """escape text for direct HTML embedding"""
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


_DBB_THEMES = {
    "simple": {
        "accent": "#2563EB", "accent2": "#0F172A", "bg": "#F8FAFC",
        "line": "#E2E8F0", "muted": "#64748B", "ink": "#0F172A",
        "hdbg": "#FFFFFF", "hdink": "#0F172A", "hdborder": "1px solid #E2E8F0",
        "palette": ["#2563EB", "#0F172A", "#0E9488", "#B45309", "#7C3AED", "#DC2626", "#64748B"],
    },
    "tx2036": {
        "accent": "#D44500", "accent2": "#1B2D55", "bg": "#F5F7FA",
        "line": "#DDE3EC", "muted": "#6C7A8D", "ink": "#1B2D55",
        "hdbg": "#1B2D55", "hdink": "#FFFFFF", "hdborder": "none",
        "palette": ["#D44500", "#1B2D55", "#0E9488", "#6C7A8D", "#8A4B10", "#5B4FA0", "#2B6CB0"],
    },
}


def _dbb_assemble():
    try:
        out = _dbb_g("DBB_OUT")
        d = _dbb_g("DBB_DIR")
        theme = _dbb_g("DBB_THEME") or "simple"
        th = _DBB_THEMES[theme]
        np = int(_dbb_g("DBB_NPANELS"))
        nt = int(_dbb_g("DBB_NTABS"))
        sel = _dbb_g("DBB_SEL")
        refval = _dbb_g("DBB_REFVAL")

        tabs = []
        for i in range(1, nt + 1):
            tabs.append({"name": _dbb_g("DBB_TAB_NAME_%d" % i),
                         "label": _dbb_g("DBB_TAB_LAB_%d" % i)})

        panels, todo = [], []
        selvalues = set()
        for i in range(1, np + 1):
            ptype = _dbb_g("DBB_P_%d_TYPE" % i)
            if ptype == "html":
                # external-HTML panel: inline the file (e.g. a sparkta2 map) as an
                # <iframe srcdoc>. There is no JSON snapshot for these.
                hf = _dbb_g("DBB_P_%d_HTMLFILE" % i)
                with open(hf, encoding="utf-8") as f:
                    htmlsrc = f.read()
                spec = {
                    "id": "p%d" % i, "type": "html",
                    "tab": _dbb_g("DBB_P_%d_TAB" % i),
                    "title": _dbb_g("DBB_P_%d_TITLE" % i),
                    "note": _dbb_g("DBB_P_%d_NOTE" % i),
                    "interp": _dbb_g("DBB_P_%d_INTERP" % i),
                    "ytitle": "", "x": "", "y": [], "ref": "", "selcol": "",
                    "columns": [], "labels": {}, "rows": [],
                    "html": htmlsrc,
                    "height": int(_dbb_g("DBB_P_%d_HEIGHT" % i) or 520),
                }
                panels.append(spec)
                nm = spec["title"] or ("panel %d" % i)
                if not spec["title"]:
                    todo.append("panel %d (embedded HTML) has no title() - add one so the card header is not blank" % i)
                kb = round(len(htmlsrc.encode("utf-8")) / 1024)
                if kb > 400:
                    todo.append('"%s" inlines %d KB of external HTML - the dashboard stays one self-contained file but grows; that is expected for an embedded map' % (nm, kb))
                continue
            with open(os.path.join(d, "panel%d.json" % i), encoding="utf-8") as f:
                pd = json.load(f)
            spec = {
                "id": "p%d" % i,
                "type": _dbb_g("DBB_P_%d_TYPE" % i),
                "tab": _dbb_g("DBB_P_%d_TAB" % i),
                "title": _dbb_g("DBB_P_%d_TITLE" % i),
                "note": _dbb_g("DBB_P_%d_NOTE" % i),
                "interp": _dbb_g("DBB_P_%d_INTERP" % i),
                "ytitle": _dbb_g("DBB_P_%d_YTITLE" % i),
                "x": _dbb_g("DBB_P_%d_X" % i),
                "y": _dbb_g("DBB_P_%d_Y" % i).split(),
                "ref": _dbb_g("DBB_P_%d_REF" % i),
                "selcol": _dbb_g("DBB_P_%d_SELCOL" % i),
                "columns": pd["columns"], "labels": pd["labels"], "rows": pd["rows"],
            }
            panels.append(spec)
            if spec["selcol"]:
                si = spec["columns"].index(spec["selcol"])
                for r in spec["rows"]:
                    if r[si] is not None:
                        selvalues.add(str(r[si]))
            # receipt TODO heuristics -------------------------------------------------
            nm = spec["title"] or ("panel %d" % i)
            if not spec["title"]:
                todo.append("panel %d has no title() - add one so the card header is not blank" % i)
            if _dbb_g("DBB_P_%d_XDATE" % i) == "1":
                todo.append('"%s": x looks like a Stata date; consider gen year=year(dofd(x)) or a labeled string before capture' % nm)
            n = len(spec["rows"])
            if spec["type"] in ("line", "bar", "hbar", "compare") and n > 2000:
                todo.append('"%s" embeds %d rows - consider collapsing before the panel call (file size + render speed)' % (nm, n))
            if spec["type"] == "table" and n > 500:
                todo.append('"%s" table renders the first 500 of %d rows (CSV download has all) - aggregate if you need them all visible' % (nm, n))
            if spec["type"] == "kpi" and len(spec["y"]) > 6:
                todo.append('"%s": %d KPI tiles is a lot - consider 6 or fewer' % (nm, len(spec["y"])))
            if spec["type"] in ("bar", "hbar"):
                xi = spec["columns"].index(spec["x"])
                ncat = len({str(r[xi]) for r in spec["rows"]})
                if ncat > 25:
                    todo.append('"%s": %d bar categories will be crowded - consider a top-N or hbar' % (nm, ncat))
        if sel:
            # Static panels on a tab that ALSO has filterable panels look
            # unresponsive (the selector shows but does nothing to them). Static
            # panels on a fully-static tab are fine - the selector auto-hides there.
            filt_tabs = set(p["tab"] for p in panels if p["selcol"])
            mixed_static = [p["title"] or p["id"] for p in panels
                            if not p["selcol"] and p["tab"] in filt_tabs]
            if mixed_static:
                todo.append("selector is on; these panels share a tab with filterable ones but stay static, so they will look unresponsive (rename their %s column only if that is intended): %s"
                            % (sel, "; ".join(mixed_static)))
        if not _dbb_g("DBB_SOURCES"):
            todo.append("no sourcenote() given - cite your sources in the footer before sharing")
        if not any(p["interp"] for p in panels):
            todo.append("no interp() text on any panel - consider a one-line takeaway box for your headline chart")
        todo.append("open the file and search for EDIT-ME comments; all chart code is readable JS you can restyle")
        todo.append("numbers use a generic smart formatter - add $ or % formatting in fmtSmart() where needed")

        meta = {
            "title": _dbb_g("DBB_TITLE"),
            "subtitle": _dbb_g("DBB_SUBTITLE"),
            "theme": theme,
            "palette": th["palette"],
            "selector": sel,
            "sellabel": _dbb_g("DBB_SELLAB") or ("Choose a " + sel if sel else ""),
            "refvalue": refval,
            "csv": _dbb_g("DBB_CSVDL") == "1",
            "png": _dbb_g("DBB_PNGDL") == "1",
            "tooltip": _dbb_g("DBB_TOOLTIP") == "1",
            "pdf": _dbb_g("DBB_PDFDL") == "1",
            "truepdf": _dbb_g("DBB_TRUEPDF") == "1",
            "corner": _dbb_g("DBB_CORNER") == "1",
            "callout": _dbb_g("DBB_CALLOUT"),
            "sources": _dbb_g("DBB_SOURCES"),
        }
        dash = {"meta": meta, "tabs": tabs, "panels": panels}
        dj = json.dumps(dash, separators=(",", ":")).replace("</", "<\\/")

        # one-click PDF pulls a library from a CDN (NOT air-gap safe); everything
        # else is fully self-contained. Empty string when the option is off.
        pdflib = ('<script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.2/'
                  'html2pdf.bundle.min.js"></script>' if meta["truepdf"] else "")

        receipt = ("dashboardbuilder receipt: %d tabs, %d panels, theme=%s, selector=%s. "
                   "This file is a self-contained starter wireframe: all data is inline JSON "
                   "(const DASH) and every chart is readable SVG-generating JS below. "
                   "Search for EDIT-ME to find the intended tweak points."
                   % (nt, np, theme, sel or "none"))

        html = (_DBB_TEMPLATE
                .replace("__TITLE__", _dbb_esc(meta["title"]))
                .replace("__SUBTITLE__", _dbb_esc(meta["subtitle"]))
                .replace("__RECEIPT__", _dbb_esc(receipt))
                .replace("__ACCENT__", th["accent"]).replace("__ACCENT2__", th["accent2"])
                .replace("__BG__", th["bg"]).replace("__LINE__", th["line"])
                .replace("__MUTED__", th["muted"]).replace("__INK__", th["ink"])
                .replace("__HDBG__", th["hdbg"]).replace("__HDINK__", th["hdink"])
                .replace("__HDBORDER__", th["hdborder"])
                .replace("__PDFLIB__", pdflib)
                .replace("__DASH_JSON__", dj))
        with open(out, "w", encoding="utf-8") as f:
            f.write(html)

        Macro.setGlobal("DBB_R_FILE", os.path.abspath(out))
        Macro.setGlobal("DBB_R_BYTES", str(os.path.getsize(out)))
        Macro.setGlobal("DBB_R_KB", str(round(os.path.getsize(out) / 1024)))
        Macro.setGlobal("DBB_R_NSELOPT", str(len(selvalues)))
        Macro.setGlobal("DBB_R_NTODO", str(len(todo)))
        for t, msg in enumerate(todo, start=1):
            Macro.setGlobal("DBB_R_TODO_%d" % t, msg)
        Macro.setGlobal("DBB_PYERR", "")
    except Exception as e:
        Macro.setGlobal("DBB_PYERR", str(e))


# ----------------------------------------------------------------------------
# THE HTML TEMPLATE (the generated file). Kept deliberately readable: this is
# the starter wireframe a human will open and tweak. No external requests.
# ----------------------------------------------------------------------------
_DBB_TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<!-- __RECEIPT__ -->
<style>
  :root{--accent:__ACCENT__;--accent2:__ACCENT2__;--bg:__BG__;--line:__LINE__;
        --muted:__MUTED__;--ink:__INK__;--hdbg:__HDBG__;--hdink:__HDINK__}
  *{box-sizing:border-box;margin:0;padding:0}
  body{font:15px/1.5 -apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
       background:var(--bg);color:var(--ink)}
  header{background:var(--hdbg);color:var(--hdink);padding:20px 26px;border-bottom:__HDBORDER__}
  header h1{font-size:21px}
  header .sub{font-size:13px;opacity:.8;margin-top:3px}
  .wrap{max-width:1060px;margin:0 auto;padding:18px 16px 40px}
  .card{background:#fff;border:1px solid var(--line);border-radius:10px;
        padding:18px 20px;margin:14px 0;box-shadow:0 1px 2px rgba(15,23,42,.05)}
  .card h2{font-size:17px;margin-bottom:4px}
  label{display:block;font-size:12px;font-weight:700;color:var(--muted);
        text-transform:uppercase;letter-spacing:.04em;margin-bottom:5px}
  select{font:inherit;padding:9px 12px;border:1px solid var(--line);border-radius:8px;
         min-width:260px;max-width:100%;background:#fff;color:var(--ink)}
  .modebar{display:flex;gap:0;margin:6px 0 0;border:1px solid var(--accent2);
           border-radius:8px;overflow:hidden;width:fit-content;max-width:100%;flex-wrap:wrap}
  .modebar button{background:#fff;color:var(--accent2);border:0;padding:9px 18px;
                  font:inherit;font-weight:600;cursor:pointer}
  .modebar button.on{background:var(--accent2);color:#fff}
  .cardtools{display:flex;gap:8px;justify-content:flex-end;margin:2px 0 10px}
  /* corner option: float the global PDF button(s) fixed in the bottom-right */
  .cornertools{position:fixed;right:18px;bottom:18px;margin:0!important;background:#fff;
               border:1px solid var(--line);border-radius:10px;padding:8px 10px;
               box-shadow:0 3px 12px rgba(15,23,42,.18);z-index:50;justify-content:flex-end}
  .dlbtn{background:#fff;color:var(--accent2);border:1px solid var(--line);border-radius:6px;
         padding:6px 12px;font:inherit;font-size:12px;font-weight:600;cursor:pointer}
  .dlbtn:hover{background:var(--bg)}
  .kpi{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin:8px 0}
  .tile{background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:12px 14px}
  .tile .v{font-size:22px;font-weight:800;color:var(--accent2)}
  .tile .l{font-size:12px;color:var(--muted);margin-top:2px}
  .interp{background:#FCF3E8;border-left:3px solid var(--accent);color:#7A4A12;
          font-size:13px;line-height:1.45;padding:9px 12px;border-radius:4px;margin:8px 0}
  .note{font-size:12px;color:var(--muted);margin-top:8px}
  .legend{display:flex;gap:16px;flex-wrap:wrap;font-size:12px;color:var(--muted);margin-top:6px}
  .legend .sw{display:inline-block;width:16px;height:4px;border-radius:2px;
              margin-right:5px;vertical-align:middle}
  .barrow{display:flex;align-items:center;gap:10px;margin:9px 0;font-size:13px}
  .barrow .lab{flex:0 0 200px;color:var(--ink)}
  .barrow .track{flex:1 1 auto;position:relative;height:24px;background:var(--bg);
                 border:1px solid var(--line);border-radius:5px}
  .barrow .fill{position:absolute;top:0;bottom:0;background:var(--accent);border-radius:3px;opacity:.85}
  .barrow .refmark{position:absolute;top:-3px;bottom:-3px;width:2px;background:var(--accent2)}
  .barrow .zero{position:absolute;top:-2px;bottom:-2px;width:1px;background:var(--muted);opacity:.55}
  .barrow .val{flex:0 0 90px;text-align:right;font-weight:700;color:var(--accent2)}
  .barrow .rv{flex:0 0 110px;font-size:11px;color:var(--muted);text-align:right}
  table.dbb{border-collapse:collapse;width:100%;font-size:13px}
  table.dbb th{text-align:left;border-bottom:2px solid var(--line);padding:6px 8px;
               color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.03em}
  table.dbb td{border-bottom:1px solid var(--line);padding:6px 8px}
  .callout{background:#FFF7F2;border:1px solid var(--accent);border-radius:8px;
           color:var(--ink);padding:14px 16px;margin:16px 0;font-size:14px}
  .callout b{color:var(--accent)}
  footer{font-size:12px;color:var(--muted);border-top:1px solid var(--line);
         margin-top:22px;padding-top:12px}
  .toolt{position:fixed;pointer-events:none;background:#0F172A;color:#fff;font-size:12px;
         padding:5px 8px;border-radius:5px;opacity:0;transition:opacity .08s;z-index:60;max-width:280px}
  .hide{display:none!important}
  @media print{
    .cardtools,.dlbtn,.modebar,#selwrap,.toolt,.cornertools,#controls{display:none!important}
    body,.wrap{background:#fff}
    .card{box-shadow:none;border:1px solid #cbd2dc;break-inside:avoid}
    /* keep a tall embedded panel (e.g. a map) on one page instead of orphaning a
       near-blank first page; scrolling="no" means the cap crops cleanly, no bar */
    .htmlcard iframe{max-height:160mm}
    header,.fill,.refmark,.tile,svg,svg *{-webkit-print-color-adjust:exact;print-color-adjust:exact}
    @page{margin:12mm}
  }
</style>
__PDFLIB__
</head>
<body>
<div class="toolt" id="tt"></div>
<header>
  <h1>__TITLE__ <span class="sub" style="display:inline;font-weight:400">__SUBTITLE__</span></h1>
</header>
<div class="wrap">
  <!-- EDIT-ME: controls card (selector dropdown + tab bar are built by JS below) -->
  <div class="card" id="controls">
    <div id="selwrap" class="hide">
      <label id="sellabel" for="selsel"></label>
      <select id="selsel" onchange="pickSel(this.value)"></select>
    </div>
    <div class="modebar hide" id="tabbar" style="margin-top:12px"></div>
    <div class="cardtools hide" id="globaltools" style="margin:12px 0 0"></div>
  </div>

  <!-- EDIT-ME: panel cards are generated into this container, one per panel,
       with ids panelcard_p1, panelcard_p2, ... (chart svg lands in draw_pK) -->
  <div id="tabviews"></div>

  <div class="callout hide" id="callout"></div>
  <footer id="foot"></footer>
</div>

<script>
// =========================== DATA (inlined by Stata) ========================
const DASH = __DASH_JSON__;
const M = DASH.meta, PAL = M.palette;

// =========================== state + helpers ================================
let state = { tab: (DASH.tabs[0] ? DASH.tabs[0].name : "main"), sel: null };
const $ = id => document.getElementById(id);
const esc = s => String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
const tipAttr = s => esc(s).replace(/"/g,"&quot;");   // safe inside a double-quoted data-tip
// EDIT-ME: generic smart number formatter; add $ / % / decimals per your data
function fmtSmart(v){
  if(v==null) return "n/a";
  if(typeof v !== "number") return String(v);
  const a = Math.abs(v);
  if(a>=1e9) return (v/1e9).toFixed(1)+"B";
  if(a>=1e6) return (v/1e6).toFixed(1)+"M";
  if(Number.isInteger(v)) return v.toLocaleString("en-US");
  if(a>=1000) return Math.round(v).toLocaleString("en-US");
  if(a>=100) return v.toFixed(0);
  if(a>=1) return v.toFixed(1);
  return v.toFixed(2);
}
function colIdx(p,name){ return p.columns.indexOf(name); }
function colLab(p,name){ return (p.labels && p.labels[name]) || name; }
// rows visible for a panel under the current selection
function rowsFor(p){
  if(!p.selcol || !state.sel) return p.rows;
  const si = colIdx(p, p.selcol);
  return p.rows.filter(r => String(r[si])===state.sel);
}
// rows of the REFERENCE unit (selector's refvalue), for overlays
function refRowsFor(p){
  if(!p.selcol || !M.refvalue || state.sel===M.refvalue) return null;
  const si = colIdx(p, p.selcol);
  const rr = p.rows.filter(r => String(r[si])===M.refvalue);
  return rr.length ? rr : null;
}

// =========================== scaffold =======================================
(function scaffold(){
  // selector dropdown (union of values across filterable panels; refvalue first)
  const vals = new Set();
  DASH.panels.forEach(p=>{ if(p.selcol){ const si=colIdx(p,p.selcol);
    p.rows.forEach(r=>{ if(r[si]!=null) vals.add(String(r[si])); }); }});
  if(M.selector && vals.size){
    let arr=[...vals].sort();
    if(M.refvalue && arr.includes(M.refvalue)) arr=[M.refvalue, ...arr.filter(x=>x!==M.refvalue)];
    state.sel = arr[0];
    $("sellabel").textContent = M.sellabel;
    arr.forEach(v=>{ const o=document.createElement("option"); o.value=v; o.textContent=v;
      $("selsel").appendChild(o); });
    $("selsel").value = state.sel;
    $("selwrap").classList.remove("hide");
  }
  // tab bar (hidden when only one tab)
  if(DASH.tabs.length>1){
    DASH.tabs.forEach(t=>{ const b=document.createElement("button");
      b.id="tabbtn_"+t.name; b.textContent=t.label; b.onclick=()=>pickTab(t.name);
      $("tabbar").appendChild(b); });
    $("tabbar").classList.remove("hide");
  }
  // global tools: save-as-PDF (offline print-to-PDF) and/or one-click PDF (CDN lib)
  if(M.pdf || M.truepdf){
    if(M.pdf){ const b=document.createElement("button"); b.className="dlbtn";
      b.innerHTML="&#8623; Save as PDF"; b.title="Uses your browser's print-to-PDF (works offline)";
      b.onclick=()=>window.print(); $("globaltools").appendChild(b); }
    if(M.truepdf){ const b=document.createElement("button"); b.className="dlbtn";
      b.innerHTML="&#8623; Download PDF"; b.title="One-click PDF (loads a library from a CDN; needs internet)";
      b.onclick=truePdf; $("globaltools").appendChild(b); }
    $("globaltools").classList.remove("hide");
    // corner option: pin the PDF button(s) to the bottom-right of the viewport
    if(M.corner) $("globaltools").classList.add("cornertools");
  }
  // per-tab containers + per-panel cards
  DASH.tabs.forEach(t=>{
    const tv=document.createElement("div"); tv.id="tv_"+t.name;
    DASH.panels.filter(p=>p.tab===t.name).forEach(p=>{
      const c=document.createElement("div"); c.className=(p.type==="html"?"card htmlcard":"card"); c.id="panelcard_"+p.id;
      // PNG is offered on the SVG chart panels (self-contained rasterization);
      // kpi/table are HTML, where a no-library canvas export can't be guaranteed
      // (browsers taint the canvas), so they keep CSV. Edit CHARTPNG to change this.
      const CHARTPNG = new Set(["line","bar","hbar","compare"]);
      const hasData = p.type!=="html";   // html panels embed a file; no CSV/PNG
      const tools = (M.csv && hasData?`<button class="dlbtn" onclick="csvPanel('${p.id}')">&#8623; CSV</button>`:``) +
                    (M.png && CHARTPNG.has(p.type)?`<button class="dlbtn" onclick="panelToPng('${p.id}')">&#8623; PNG</button>`:``);
      c.innerHTML =
        (p.title?`<h2>${esc(p.title)}</h2>`:``) +
        (p.interp?`<div class="interp">${esc(p.interp)}</div>`:``) +
        (tools?`<div class="cardtools">${tools}</div>`:``) +
        `<div id="draw_${p.id}"></div><div class="legend" id="leg_${p.id}"></div>` +
        (p.note?`<p class="note">${esc(p.note)}</p>`:``);
      tv.appendChild(c);
    });
    $("tabviews").appendChild(tv);
  });
  if(M.callout){ $("callout").innerHTML="<b>Note.</b> "+esc(M.callout);
    $("callout").classList.remove("hide"); }
  $("foot").textContent = (M.sources? M.sources+"  " : "") +
    "Built with dashboardbuilder (Stata). Self-contained file; data embedded inline.";
  // styled hover tooltips (self-contained; no library). Delegated off the panel
  // container so it also covers charts re-drawn on every selection change.
  if(M.tooltip){
    const host=$("tabviews");
    host.addEventListener("mousemove", e=>{ const t=e.target.closest("[data-tip]");
      if(t) tip(e, t.getAttribute("data-tip")); else tipHide(); });
    host.addEventListener("mouseleave", tipHide);
  }
})();

// ---- tooltip helpers (EDIT-ME: restyle .toolt in the CSS above) ----
const TT=$("tt");
function tip(e,txt){ TT.textContent=txt; TT.style.opacity=1;
  const x=Math.min(e.clientX+12, window.innerWidth-TT.offsetWidth-10);
  TT.style.left=Math.max(6,x)+"px"; TT.style.top=(e.clientY+14)+"px"; }
function tipHide(){ TT.style.opacity=0; }

function pickTab(t){ state.tab=t; renderAll(); }
function pickSel(v){ state.sel=v; $("selsel").value=v; renderAll(); }

// =========================== renderers (EDIT-ME: plain SVG) =================
function svgOpen(W,H,label){ return `<svg viewBox="0 0 ${W} ${H}" width="100%" role="img" aria-label="${esc(label)}">`; }

function renderLine(p){
  const W=880,H=300,mL=58,mR=14,mT=12,mB=30;
  const xi=colIdx(p,p.x), rows=rowsFor(p);
  const xs=[...new Set(rows.map(r=>r[xi]).filter(v=>v!=null))];
  const xnum = xs.every(v=>typeof v==="number");
  const xv = xnum? xs.slice().sort((a,b)=>a-b) : xs;
  const X = v => xnum
      ? mL+(W-mL-mR)*((v-xv[0])/((xv[xv.length-1]-xv[0])||1))
      : mL+(W-mL-mR)*(xv.indexOf(v)/Math.max(1,xv.length-1));
  const series = p.y.map((yc,si)=>({name:colLab(p,yc), col:PAL[si%PAL.length],
      pts: rows.filter(r=>r[xi]!=null&&r[colIdx(p,yc)]!=null)
               .map(r=>[r[xi], r[colIdx(p,yc)]])
               .sort((a,b)=> xnum? a[0]-b[0] : xv.indexOf(a[0])-xv.indexOf(b[0]))}));
  const refRows = refRowsFor(p);
  const refSeries = refRows ? p.y.map((yc,si)=>({name:colLab(p,yc), col:PAL[si%PAL.length],
      pts: refRows.filter(r=>r[xi]!=null&&r[colIdx(p,yc)]!=null)
                  .map(r=>[r[xi], r[colIdx(p,yc)]])
                  .sort((a,b)=> xnum? a[0]-b[0] : xv.indexOf(a[0])-xv.indexOf(b[0]))})) : [];
  const allv=[]; series.concat(refSeries).forEach(s=>s.pts.forEach(pt=>allv.push(pt[1])));
  if(!allv.length){ $("draw_"+p.id).innerHTML="<p class='note'>No data for this selection.</p>"; return; }
  let ymax=Math.max(...allv), ymin=Math.min(...allv);
  const pad=(ymax-ymin)*.08||1; ymax+=pad; ymin-=pad;
  const Y = v => mT+(H-mT-mB)*(1-(v-ymin)/((ymax-ymin)||1));
  let svg=svgOpen(W,H,p.title||"line chart");
  for(let g=0;g<=4;g++){ const gy=mT+(H-mT-mB)*(1-g/4);
    svg+=`<line x1="${mL}" y1="${gy}" x2="${W-mR}" y2="${gy}" stroke="#EEF1F6"/>`+
         `<text x="${mL-8}" y="${gy+4}" text-anchor="end" font-size="11" fill="#6C7A8D">${fmtSmart(ymin+(ymax-ymin)*g/4)}</text>`; }
  const tickN=Math.min(6,xv.length);
  for(let t=0;t<tickN;t++){ const v=xv[Math.round(t*(xv.length-1)/Math.max(1,tickN-1))];
    svg+=`<text x="${X(v)}" y="${H-10}" text-anchor="middle" font-size="11" fill="#6C7A8D">${esc(String(v))}</text>`; }
  refSeries.forEach(s=>{ let dd=""; s.pts.forEach(pt=>{ dd+=(dd?"L":"M")+X(pt[0])+","+Y(pt[1]); });
    svg+=`<path d="${dd}" fill="none" stroke="${s.col}" stroke-width="2.2" stroke-dasharray="7 4" opacity=".75"/>`; });
  series.forEach(s=>{ let dd=""; s.pts.forEach(pt=>{ dd+=(dd?"L":"M")+X(pt[0])+","+Y(pt[1]); });
    svg+=`<path d="${dd}" fill="none" stroke="${s.col}" stroke-width="3.4"/>`;
    s.pts.forEach(pt=>{ svg+=`<circle cx="${X(pt[0])}" cy="${Y(pt[1])}" r="3.4" fill="${s.col}" data-tip="${tipAttr(s.name+" — "+pt[0]+": "+fmtSmart(pt[1]))}"></circle>`; }); });
  svg+="</svg>";
  $("draw_"+p.id).innerHTML=svg;
  let leg=series.map(s=>`<span><span class="sw" style="background:${s.col}"></span>${esc(s.name)}</span>`).join("");
  if(refSeries.length) leg+=`<span><span class="sw" style="background:transparent;border-top:2px dashed #6C7A8D;height:0"></span>${esc(M.refvalue)} (dashed)</span>`;
  $("leg_"+p.id).innerHTML=leg;
}

function renderBarish(p, horizontal){
  const rows=rowsFor(p), xi=colIdx(p,p.x), yi=colIdx(p,p.y[0]);
  const data=rows.filter(r=>r[xi]!=null&&r[yi]!=null).map(r=>[String(r[xi]), r[yi]]);
  if(!data.length){ $("draw_"+p.id).innerHTML="<p class='note'>No data for this selection.</p>"; return; }
  const vmax=Math.max(0,...data.map(d=>d[1])), vmin=Math.min(0,...data.map(d=>d[1]));
  const span=(vmax-vmin)||1;
  if(horizontal){
    const W=880, rowH=26, mL=190, mR=70, H=data.length*rowH+16;
    let svg=svgOpen(W,H,p.title||"bar chart");
    const X=v=>mL+(W-mL-mR)*((v-vmin)/span);
    data.forEach((d,i)=>{ const y0=8+i*rowH;
      svg+=`<text x="${mL-8}" y="${y0+15}" text-anchor="end" font-size="12" fill="#334155">${esc(d[0]).slice(0,28)}</text>`+
           `<rect x="${Math.min(X(0),X(d[1]))}" y="${y0+3}" width="${Math.abs(X(d[1])-X(0))}" height="${rowH-9}" rx="3" fill="${PAL[0]}" data-tip="${tipAttr(d[0]+": "+fmtSmart(d[1]))}"></rect>`+
           `<text x="${X(d[1])+(d[1]>=0?6:-6)}" y="${y0+15}" text-anchor="${d[1]>=0?"start":"end"}" font-size="11" font-weight="700" fill="${PAL[1]}">${fmtSmart(d[1])}</text>`; });
    if(vmin<0) svg+=`<line x1="${X(0)}" y1="4" x2="${X(0)}" y2="${H-4}" stroke="#94A3B8"/>`;
    svg+="</svg>"; $("draw_"+p.id).innerHTML=svg;
  } else {
    const W=880,H=300,mL=58,mR=14,mT=12,mB=46;
    let svg=svgOpen(W,H,p.title||"bar chart");
    const Y=v=>mT+(H-mT-mB)*(1-(v-vmin)/span);
    const bw=(W-mL-mR)/data.length;
    for(let g=0;g<=4;g++){ const gy=mT+(H-mT-mB)*(1-g/4);
      svg+=`<line x1="${mL}" y1="${gy}" x2="${W-mR}" y2="${gy}" stroke="#EEF1F6"/>`+
           `<text x="${mL-8}" y="${gy+4}" text-anchor="end" font-size="11" fill="#6C7A8D">${fmtSmart(vmin+span*g/4)}</text>`; }
    data.forEach((d,i)=>{ const x0=mL+i*bw;
      svg+=`<rect x="${x0+bw*0.12}" y="${Math.min(Y(0),Y(d[1]))}" width="${bw*0.76}" height="${Math.abs(Y(d[1])-Y(0))}" rx="3" fill="${PAL[0]}" data-tip="${tipAttr(d[0]+": "+fmtSmart(d[1]))}"></rect>`+
           `<text x="${x0+bw/2}" y="${H-28}" text-anchor="middle" font-size="11" fill="#334155">${esc(d[0]).slice(0,12)}</text>`+
           `<text x="${x0+bw/2}" y="${Y(d[1])-6}" text-anchor="middle" font-size="11" font-weight="700" fill="${PAL[1]}">${fmtSmart(d[1])}</text>`; });
    if(vmin<0) svg+=`<line x1="${mL}" y1="${Y(0)}" x2="${W-mR}" y2="${Y(0)}" stroke="#94A3B8"/>`;
    svg+="</svg>"; $("draw_"+p.id).innerHTML=svg;
  }
  if(p.ytitle) $("leg_"+p.id).innerHTML=`<span>${esc(p.ytitle)}</span>`;
}

function renderCompare(p){
  // bullet bars (SVG): a value bar + a reference | marker, one shared scale for
  // the whole panel. SVG (not HTML divs) so the PNG export is self-contained.
  const rows=rowsFor(p), xi=colIdx(p,p.x), yi=colIdx(p,p.y[0]);
  const ri = p.ref ? colIdx(p,p.ref) : -1;
  const refRows=refRowsFor(p);
  function refFor(lbl,row){
    if(ri>=0) return row[ri];
    if(refRows){ const m=refRows.find(rr=>String(rr[xi])===lbl); return m? m[yi] : null; }
    return null;
  }
  const data=rows.filter(r=>r[xi]!=null&&r[yi]!=null)
                 .map(r=>[String(r[xi]), r[yi], refFor(String(r[xi]),r)]);
  if(!data.length){ $("draw_"+p.id).innerHTML="<p class='note'>No data for this selection.</p>"; return; }
  const allv=data.flatMap(d=>[d[1],d[2]]).filter(v=>v!=null);
  const vmax=Math.max(0,...allv), vmin=Math.min(0,...allv), span=(vmax-vmin)||1;
  const W=880, rowH=30, mL=200, mR=96, plotL=mL, plotR=W-mR, H=data.length*rowH+16;
  const X=v=>plotL+(plotR-plotL)*((v-vmin)/span), zeroX=X(0);
  let svg=svgOpen(W,H,p.title||"comparison");
  data.forEach((d,i)=>{ const cy=8+i*rowH;
    const bx=Math.min(X(d[1]),zeroX), bw=Math.abs(X(d[1])-zeroX);
    const tt=d[0]+": "+fmtSmart(d[1])+(d[2]!=null?"  (reference "+fmtSmart(d[2])+")":"");
    svg+=`<text x="${mL-10}" y="${cy+18}" text-anchor="end" font-size="12" fill="#334155">${esc(d[0]).slice(0,30)}</text>`+
         `<rect x="${plotL}" y="${cy+4}" width="${plotR-plotL}" height="${rowH-13}" rx="4" fill="#EEF1F6"/>`+
         (vmin<0?`<line x1="${zeroX}" y1="${cy+2}" x2="${zeroX}" y2="${cy+rowH-7}" stroke="#94A3B8" stroke-dasharray="2 2"/>`:``)+
         `<rect x="${bx}" y="${cy+5}" width="${bw}" height="${rowH-15}" rx="3" fill="${PAL[0]}" opacity=".9" data-tip="${tipAttr(tt)}"></rect>`+
         (d[2]!=null?`<line x1="${X(d[2])}" y1="${cy+1}" x2="${X(d[2])}" y2="${cy+rowH-6}" stroke="${PAL[1]}" stroke-width="2.5"/>`:``)+
         `<text x="${plotR+8}" y="${cy+18}" font-size="11" font-weight="700" fill="${PAL[1]}">${fmtSmart(d[1])}</text>`; });
  svg+="</svg>";
  $("draw_"+p.id).innerHTML=svg;
  $("leg_"+p.id).innerHTML =
    `<span><span class="sw" style="background:${PAL[0]}"></span>value</span>`+
    `<span><span class="sw" style="background:${PAL[1]};width:3px;height:12px"></span>reference marker`+
    (M.refvalue&&!p.ref?` (${esc(M.refvalue)})`:``)+`</span>`+
    (p.ytitle?`<span>${esc(p.ytitle)}</span>`:``);
}

function renderKpi(p){
  const rows=rowsFor(p);
  const r=rows[0];
  if(!r){ $("draw_"+p.id).innerHTML="<p class='note'>No data for this selection.</p>"; return; }
  let html='<div class="kpi">';
  p.y.forEach(yc=>{ const v=r[colIdx(p,yc)];
    html+=`<div class="tile"><div class="v">${fmtSmart(v)}</div><div class="l">${esc(colLab(p,yc))}</div></div>`; });
  html+="</div>";
  $("draw_"+p.id).innerHTML=html;
  if(rows.length>1) $("leg_"+p.id).innerHTML="<span>showing the first row of "+rows.length+" for this selection; collapse your data to one row per unit for KPIs</span>";
  else $("leg_"+p.id).innerHTML="";
}

function renderTable(p){
  const rows=rowsFor(p), cap=500;
  let html='<div style="overflow-x:auto"><table class="dbb"><thead><tr>';
  p.columns.forEach(c=>{ html+=`<th>${esc(colLab(p,c))}</th>`; });
  html+="</tr></thead><tbody>";
  rows.slice(0,cap).forEach(r=>{ html+="<tr>"+r.map(v=>`<td>${v==null?"":esc(typeof v==="number"?fmtSmart(v):String(v))}</td>`).join("")+"</tr>"; });
  html+="</tbody></table></div>";
  if(rows.length>cap) html+=`<p class="note">showing first ${cap} of ${rows.length} rows; the CSV download has all rows</p>`;
  $("draw_"+p.id).innerHTML=html; $("leg_"+p.id).innerHTML="";
}

// embed an external HTML file (e.g. a sparkta2 map) once, via <iframe srcdoc>.
// Rendered a single time and skipped on later re-renders, so an interactive map
// keeps its zoom/selection state when you switch tabs or the selector.
function renderHtml(p){
  const host=$("draw_"+p.id);
  if(host.querySelector("iframe")) return;
  const f=document.createElement("iframe");
  f.setAttribute("loading","lazy"); f.setAttribute("scrolling","no");
  f.setAttribute("title", p.title||"embedded content");
  f.style.cssText="display:block;width:100%;border:0;overflow:hidden;height:"+(p.height||520)+"px";
  f.srcdoc=p.html;                      // full HTML string, set as a property (no escaping needed)
  host.innerHTML=""; host.appendChild(f);
}

function renderAll(){
  DASH.tabs.forEach(t=>{ const el=$("tv_"+t.name); if(el) el.classList.toggle("hide", t.name!==state.tab);
    const b=$("tabbtn_"+t.name); if(b) b.classList.toggle("on", t.name===state.tab); });
  // Show the selector only on tabs where a panel actually filters by it, so the
  // "choose a unit" control isn't offered where it would do nothing.
  if(M.selector){ const sw=$("selwrap");
    if(sw && DASH.tabs.length){ const anyFilter=DASH.panels.some(p=>p.tab===state.tab && p.selcol);
      sw.classList.toggle("hide", !anyFilter); } }
  DASH.panels.filter(p=>p.tab===state.tab).forEach(p=>{
    if(p.type==="line") renderLine(p);
    else if(p.type==="bar") renderBarish(p,false);
    else if(p.type==="hbar") renderBarish(p,true);
    else if(p.type==="compare") renderCompare(p);
    else if(p.type==="kpi") renderKpi(p);
    else if(p.type==="html") renderHtml(p);
    else renderTable(p);
  });
}

// =========================== downloads ======================================
function saveBlob(blob, name){
  const url=URL.createObjectURL(blob);
  const a=document.createElement("a"); a.href=url; a.download=name;
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  setTimeout(()=>URL.revokeObjectURL(url),1500);
}
function panelFile(pid,ext){ const p=DASH.panels.find(q=>q.id===pid);
  return ((p.title||pid)+(p.selcol&&state.sel?"_"+state.sel:"")).replace(/[^\w]+/g,"_")+"."+ext; }

function csvEscape(v){ v=(v==null?"":String(v)); return /[",\n]/.test(v)?'"'+v.replace(/"/g,'""')+'"':v; }
function csvPanel(pid){
  const p=DASH.panels.find(q=>q.id===pid);
  const rows=[p.columns].concat(rowsFor(p));
  const csv=rows.map(r=>r.map(csvEscape).join(",")).join("\n");
  saveBlob(new Blob([csv],{type:"text/csv;charset=utf-8"}), panelFile(pid,"csv"));
}

// PNG export — SELF-CONTAINED (no library). For SVG chart panels we serialize
// the SVG straight to a canvas (robust everywhere). For HTML panels (kpi /
// compare / table) we wrap the node + the page CSS in an SVG <foreignObject>
// and rasterize that; solid in Chrome/Edge/Firefox, best-effort in old Safari.
function rasterize(svgString, w, h, name){
  const scale=2;
  const img=new Image();
  const blob=new Blob([svgString],{type:"image/svg+xml;charset=utf-8"});
  const url=URL.createObjectURL(blob);
  img.onload=function(){
    const cv=document.createElement("canvas"); cv.width=w*scale; cv.height=h*scale;
    const ctx=cv.getContext("2d"); ctx.fillStyle="#ffffff"; ctx.fillRect(0,0,cv.width,cv.height);
    ctx.drawImage(img,0,0,cv.width,cv.height); URL.revokeObjectURL(url);
    try{ cv.toBlob(b=> b? saveBlob(b,name) : saveBlob(dataUrlToBlob(cv.toDataURL("image/png")),name), "image/png"); }
    catch(e){ alert("PNG export was blocked by this browser. Try the CSV download, or a screenshot."); }
  };
  img.onerror=function(){ URL.revokeObjectURL(url);
    alert("Sorry — PNG export failed in this browser (likely Safari on an HTML panel). Try the CSV, or a screenshot."); };
  img.src=url;
}
function dataUrlToBlob(u){ const b=atob(u.split(",")[1]), a=new Uint8Array(b.length);
  for(let i=0;i<b.length;i++) a[i]=b.charCodeAt(i); return new Blob([a],{type:"image/png"}); }
// wrap a string into lines that fit maxW px at font-size fs (rough char metric)
function wrapText(text, maxW, fs){
  const cpl=Math.max(8, Math.floor(maxW/(fs*0.56)));
  const words=String(text).split(/\s+/), lines=[]; let cur="";
  words.forEach(w=>{ if(((cur?cur+" ":"")+w).length>cpl && cur){ lines.push(cur); cur=w; }
                     else cur=(cur?cur+" ":"")+w; });
  if(cur) lines.push(cur); return lines;
}
// read a panel's on-screen legend as {color,label} items, to redraw in the PNG
function legendItems(pid){
  const leg=$("leg_"+pid); if(!leg) return [];
  return [...leg.children].map(sp=>{ const sw=sp.querySelector(".sw"); let color=null;
    if(sw){ const cs=getComputedStyle(sw);
      const bg=cs.backgroundColor;
      color=(bg && bg!=="rgba(0, 0, 0, 0)" && bg!=="transparent") ? bg : cs.borderTopColor; }
    return {color, label: sp.textContent.trim()}; }).filter(it=>it.label||it.color);
}
function panelToPng(pid){
  const p=DASH.panels.find(q=>q.id===pid);
  const host=$("draw_"+pid), svg=host.querySelector("svg"), name=panelFile(pid,"png");
  if(svg){
    // Compose ONE export image = title + interpretation + chart + legend + note,
    // all as SVG (no <foreignObject>), so it rasterizes reliably everywhere and
    // the chart travels with its context — not just the bare plot area.
    const vb=(svg.getAttribute("viewBox")||"0 0 880 300").split(/\s+/).map(Number);
    const W=vb[2]||880, chartH=vb[3]||300, PAD=18;
    const FF="-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif";
    let y=PAD; const parts=[];
    if(p.title){ parts.push(`<text x="${PAD}" y="${y+16}" font-family="${FF}" font-size="18" font-weight="700" fill="#1B2D55">${esc(p.title)}</text>`); y+=32; }
    if(p.interp){ wrapText(p.interp, W-2*PAD, 13).forEach(ln=>{ parts.push(`<text x="${PAD}" y="${y+11}" font-family="${FF}" font-size="13" fill="#7A4A12">${esc(ln)}</text>`); y+=18; }); y+=6; }
    parts.push(`<svg x="0" y="${y}" width="${W}" height="${chartH}" viewBox="0 0 ${W} ${chartH}">${svg.innerHTML}</svg>`); y+=chartH+10;
    const items=legendItems(pid);
    if(items.length){ let x=PAD;
      items.forEach(it=>{ const w=(it.color?20:0)+it.label.length*6.6+18;
        if(x+w>W-PAD && x>PAD){ x=PAD; y+=20; }
        if(it.color){ parts.push(`<rect x="${x}" y="${y+2}" width="14" height="10" rx="2" fill="${it.color}"/>`); x+=20; }
        parts.push(`<text x="${x}" y="${y+11}" font-family="${FF}" font-size="12" fill="#64748B">${esc(it.label)}</text>`);
        x+=it.label.length*6.6+18; });
      y+=22;
    }
    if(p.note){ wrapText(p.note, W-2*PAD, 12).forEach(ln=>{ parts.push(`<text x="${PAD}" y="${y+10}" font-family="${FF}" font-size="12" fill="#64748B">${esc(ln)}</text>`); y+=16; }); }
    const H=y+PAD;
    const s=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><rect width="${W}" height="${H}" fill="#ffffff"/>${parts.join("")}</svg>`;
    rasterize(s, W, H, name);
  } else {
    const css=[...document.querySelectorAll("style")].map(s=>s.textContent).join("\n");
    const r=host.getBoundingClientRect();
    const w=Math.max(360,Math.ceil(r.width)), h=Math.max(90,Math.ceil(r.height)+8);
    const s=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">`+
            `<foreignObject width="100%" height="100%">`+
            `<div xmlns="http://www.w3.org/1999/xhtml" style="background:#fff"><style>${css}</style>${host.innerHTML}</div>`+
            `</foreignObject></svg>`;
    rasterize(s, w, h, name);
  }
}

// one-click PDF via the CDN library (needs internet; see the Stata receipt note)
function truePdf(){
  if(typeof html2pdf==="undefined"){
    alert("Download PDF needs internet: the PDF library is loaded from a CDN, so this button "+
          "won't work on an air-gapped machine. Use 'Save as PDF' (your browser's print dialog), "+
          "which works fully offline.");
    return;
  }
  const name=(M.title||"dashboard").replace(/[^\w]+/g,"_")+".pdf";
  html2pdf().set({margin:8, filename:name, image:{type:"jpeg",quality:0.95},
    html2canvas:{scale:2,useCORS:true,backgroundColor:"#ffffff"},
    jsPDF:{unit:"mm",format:"a4",orientation:"portrait"}})
    .from(document.querySelector(".wrap")).save();
}

renderAll();
</script>
</body>
</html>
"""
