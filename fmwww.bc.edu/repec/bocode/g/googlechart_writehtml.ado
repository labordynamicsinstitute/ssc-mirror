*! googlechart_writehtml v0.1.1  2026-06-28
*! Assemble the self-contained HTML for a googlechart chart.
*!
*! Page structure mirrors sparkta2's chart writehtml (Texas 2036 brand
*! tokens, sidebar controls panel, optional under-chart export footer,
*! collapsible data-table panel) -- but the renderer is Google Charts
*! and the loader.js comes from gstatic.com (CDN-only by Google ToS).
*!
*! NOT OFFLINE.  An open .html file requires network access at view time
*! so the Google Charts loader and per-package code can fetch.  For
*! offline-capable maps and charts, use sparkta2 instead.

program define googlechart_writehtml
    version 17.0
    syntax , ENGPATH(string) ROWJSON(string) METAJSON(string) FILTERJSON(string) ///
        EXPORT(string)                                                   ///
        TYPE(string) SCHEME(string) TITLE(string)                        ///
        WIDTH(integer) HEIGHT(integer)                                   ///
        ISDOWNload(integer) ISDATAtable(integer) ISANImate(integer)      ///
        ISTX2036Style(integer) ISSTACKed(integer) ISNORMAlize(integer)   ///
        ISDIRECTlabels(integer)                                          ///
        [ SUBtitle(string) NOTE(string)                                  ///
          XLAbel(string) YLAbel(string)                                  ///
          XVAR(string) YVAR(string) NAME(string) OVER(string)            ///
          LEVel(string) LEVELORDer(string) CENTERlevel(string)           ///
          TIME(string)                                                   ///
          DOWNLOADPos(string)                                            ///
          INNERradius(real 0)                                            ///
          BUCKETSize(real 0)                                             ///
          GEOREGion(string) GEORESolution(string)                        ///
          COMBOTypes(string) COMBODefault(string)                        ///
          NAMELabel(string) VALUELabel(string)                           ///
          LABELWRap(string)                                              ///
          LEGENDPos(string)                                              ///
          ISTBLSEArch(integer 0)                                         ///
          ISTBLSTIcky(integer 0)                                         ///
          TBLFROZencols(integer 0) ]
    if "`downloadpos'" == "" local downloadpos "side"
    if "`labelwrap'"   == "" local labelwrap   "auto"

    tempname fh
    file open `fh' using `"`export'"', write text replace

    local esc_title : subinstr local title `"&"' `"&amp;"', all
    local esc_title : subinstr local esc_title `"<"' `"&lt;"', all
    local esc_title : subinstr local esc_title `">"' `"&gt;"', all

    file write `fh' `"<!DOCTYPE html>"' _n
    file write `fh' `"<html lang="en"><head>"' _n
    file write `fh' `"<meta charset="utf-8">"' _n
    file write `fh' `"<meta name="viewport" content="width=device-width, initial-scale=1">"' _n
    file write `fh' `"<title>`esc_title'</title>"' _n

    * tx2036style: Montserrat from Google Fonts.
    if `istx2036style' {
        file write `fh' `"<link rel="preconnect" href="https://fonts.googleapis.com">"' _n
        file write `fh' `"<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>"' _n
        file write `fh' `"<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&display=swap" rel="stylesheet">"' _n
    }

    * Google Charts loader -- CDN-only by ToS.  Per-package fetches happen
    * later when google.charts.load() runs.
    file write `fh' `"<script src="https://www.gstatic.com/charts/loader.js"></script>"' _n

    file write `fh' `"<style>"' _n
    file write `fh' `":root{--ink:#1B2D55;--accent:#D44500;--link:#2B6CB0;--bg:#F5F7FA;--muted:#6C7A8D;--card:#ffffff;--line:#e2e8f0;}"' _n
    if `istx2036style' {
        file write `fh' `"*{box-sizing:border-box;}body{margin:0;font-family:'Montserrat',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:var(--bg);color:var(--ink);font-weight:400;letter-spacing:-0.005em;}"' _n
        file write `fh' `"h1{font-weight:700;letter-spacing:-0.01em;}"' _n
        file write `fh' `".controls h3{font-weight:600;}"' _n
    }
    else {
        file write `fh' `"*{box-sizing:border-box;}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;background:var(--bg);color:var(--ink);}"' _n
    }
    file write `fh' `".wrap{max-width:1180px;margin:0 auto;padding:24px 18px 48px;}"' _n
    file write `fh' `"h1{font-size:1.5rem;margin:0 0 4px;color:var(--ink);}"' _n
    file write `fh' `".sub{color:var(--muted);margin:0 0 16px;font-size:.95rem;}"' _n
    file write `fh' `".panels{display:grid;grid-template-columns:240px 1fr;gap:18px;align-items:start;}"' _n
    file write `fh' `"@media (max-width:780px){.panels{grid-template-columns:1fr;}}"' _n
    file write `fh' `".card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px;box-shadow:0 1px 2px rgba(15,23,42,.05);}"' _n
    file write `fh' `".controls h3{font-size:.78rem;text-transform:uppercase;letter-spacing:.05em;margin:8px 0 6px;color:var(--muted);}"' _n
    file write `fh' `".controls label{display:block;font-size:.85rem;margin:8px 0 2px;color:var(--ink);font-weight:500;}"' _n
    file write `fh' `".controls button{width:100%;padding:6px 8px;font-size:.85rem;border:1px solid var(--line);border-radius:6px;background:#fff;color:var(--ink);cursor:pointer;}"' _n
    file write `fh' `".controls button:hover{background:#eef2f7;}"' _n
    file write `fh' `".chartcard{padding:14px;min-height:100px;}"' _n
    file write `fh' `".meta{font-size:.78rem;color:var(--muted);margin-top:10px;}"' _n
    file write `fh' `".note{margin-top:14px;color:var(--muted);font-size:.78rem;}"' _n
    * Export menu CSS (Highcharts-style burger menu)
    file write `fh' `".exportmenu{position:relative;}"' _n
    file write `fh' `".exportbtn{width:100%;padding:6px 8px;font-size:.85rem;border:1px solid var(--line);border-radius:6px;background:#fff;color:var(--ink);cursor:pointer;text-align:left;}"' _n
    file write `fh' `".exportbtn:hover{background:#eef2f7;}"' _n
    file write `fh' `".exportlist{position:absolute;top:calc(100% + 4px);left:0;right:0;background:#fff;border:1px solid var(--line);border-radius:6px;box-shadow:0 4px 12px rgba(15,23,42,.12);z-index:40;display:flex;flex-direction:column;padding:4px;}"' _n
    file write `fh' `".exportlist button{width:100%;padding:6px 8px;font-size:.85rem;border:none;border-radius:4px;background:none;color:var(--ink);cursor:pointer;text-align:left;}"' _n
    file write `fh' `".exportlist button:hover{background:#eef2f7;}"' _n
    * Under-chart export footer (downloadpos=below)
    file write `fh' `"#chart-footer{display:none;justify-content:flex-end;align-items:center;gap:8px;padding:8px 0 0;border-top:1px solid var(--line);margin-top:8px;}"' _n
    file write `fh' `"#chart-footer.active{display:flex;}"' _n
    file write `fh' `"#chart-footer button{padding:4px 10px;font-size:.8rem;border:1px solid var(--line);border-radius:6px;background:#fff;color:var(--ink);cursor:pointer;}"' _n
    file write `fh' `"#chart-footer button:hover{background:#eef2f7;}"' _n
    file write `fh' `"#chart-footer .exportmenu{position:relative;}"' _n
    file write `fh' `"#chart-footer .exportlist{left:auto;right:0;min-width:170px;}"' _n
    file write `fh' `".panels.no-sidebar{grid-template-columns:1fr !important;}"' _n
    file write `fh' `".controls.empty{display:none;}"' _n
    * Filter widgets (Google Charts ControlWrapper containers)
    file write `fh' `".gc-filters{display:flex;flex-direction:column;gap:6px;margin-bottom:8px;align-items:flex-start;}"' _n
    file write `fh' `".gc-filter-slot{min-height:34px;}"' _n
    file write `fh' `".gc-filters label{display:block;font-size:.78rem;color:var(--muted);font-weight:500;margin-top:6px;}"' _n
    * Play button for bubble + other time-driven charts.  Compact, not
    * full-width -- aligns to the left of the filter row.
    file write `fh' `".gc-play{align-self:flex-start;width:auto;padding:5px 14px;font-size:.85rem;border:1px solid var(--link);border-radius:6px;background:var(--ink);color:#fff;cursor:pointer;font-weight:500;}"' _n
    file write `fh' `".gc-play:hover{background:var(--link);}"' _n
    * Data-table panel (collapsible)
    file write `fh' `"#datatable{display:none;margin-top:14px;border:1px solid var(--line);border-radius:8px;background:#fff;}"' _n
    file write `fh' `"#datatable.open{display:block;}"' _n
    file write `fh' `"#datatable .dt-header{display:flex;align-items:center;justify-content:space-between;padding:8px 12px;border-bottom:1px solid var(--line);background:#f8fafc;border-radius:8px 8px 0 0;font-size:.9rem;}"' _n
    file write `fh' `"#datatable .dt-count{color:var(--muted);font-size:.8rem;font-weight:normal;margin-left:8px;}"' _n
    file write `fh' `"#datatable .dt-close{background:none;border:none;font-size:1.3rem;line-height:1;cursor:pointer;color:var(--muted);padding:0 4px;}"' _n
    file write `fh' `"#datatable .dt-scroll{max-height:360px;overflow:auto;}"' _n
    file write `fh' `"#datatable table.dt-table{width:100%;border-collapse:collapse;font-size:.8rem;}"' _n
    file write `fh' `"#datatable .dt-table th{position:sticky;top:0;background:#fff;border-bottom:1px solid var(--line);padding:6px 10px;text-align:left;font-weight:600;color:var(--ink);white-space:nowrap;}"' _n
    file write `fh' `"#datatable .dt-table td{padding:5px 10px;border-bottom:1px solid #f1f5f9;color:#334155;}"' _n
    file write `fh' `"#datatable .dt-table tr:hover td{background:#f8fafc;}"' _n
    file write `fh' `"#datatable .dt-truncated{padding:8px 12px;border-top:1px solid var(--line);color:var(--muted);font-size:.78rem;background:#f8fafc;border-radius:0 0 8px 8px;}"' _n
    * Print stylesheet
    file write `fh' `"@media print {.controls{display:none !important;}#datatable{display:none !important;}.panels{grid-template-columns:1fr !important;}body{background:#fff;}}"' _n
    * Type-specific layout tweaks.  For pie / donut the natural shape is
    * square-ish and the chart frame should hug the chart so it doesn't
    * look orphaned in the right column.  For table + timeline, the
    * card stretches full-width but the inner chart area scrolls
    * horizontally when content exceeds the column (wide tables, long
    * gantt swimlanes); the export footer at the bottom sits inside the
    * scrollable card so it never pushes width further right.
    file write `fh' `".gc-type-pie .panels, .gc-type-donut .panels { grid-template-columns: 240px max-content; justify-content: start; }"' _n
    file write `fh' `".gc-type-pie .chartcard, .gc-type-donut .chartcard { width: max-content; max-width: 100%; }"' _n
    file write `fh' `"@media (max-width:780px){.gc-type-pie .panels,.gc-type-donut .panels{grid-template-columns:1fr;}.gc-type-pie .chartcard,.gc-type-donut .chartcard{width:auto;}}"' _n
    * Timeline: let the chart be its natural width; horizontal scroll
    * inside the card when the rendered timeline is wider than the card.
    file write `fh' `".gc-type-timeline #chart { overflow-x: auto; overflow-y: hidden; }"' _n
    file write `fh' `".gc-type-timeline .chartcard { overflow: hidden; }"' _n
    * Tables: same idea -- horizontal scroll lives inside the card so
    * the search input + page controls stay aligned with the visible
    * portion of the table.
    * Table inside a card: pin the chartcard to its grid cell so wide
    * tables don't push the whole page to overflow the .wrap container;
    * the #chart slot then forces the .gc-table-wrap to clip + scroll
    * horizontally rather than expand outward.
    file write `fh' `".gc-type-table .chartcard { min-width: 0; max-width: 100%; overflow: hidden; }"' _n
    file write `fh' `".gc-type-table #chart { overflow: hidden; min-width: 0; width: 100%; }"' _n
    * Rendered Google Charts Table polish (the *interactive* table, not
    * the collapsible #datatable panel).  Google injects td/th elements
    * directly; we attach via the cssClassNames slot the engine passes.
    file write `fh' `".gc-table-wrap { border-radius: 8px; overflow: hidden; border: 1px solid var(--line); }"' _n
    file write `fh' `".gc-table-search { display: flex; gap: 8px; padding: 8px 12px; background:#f8fafc; border-bottom:1px solid var(--line); align-items:center;}"' _n
    file write `fh' `".gc-table-search input { flex: 1; padding: 6px 10px; font-size: .88rem; border: 1px solid var(--line); border-radius: 6px; outline: none; }"' _n
    file write `fh' `".gc-table-search input:focus { border-color: var(--link); box-shadow: 0 0 0 2px rgba(43,108,176,.15); }"' _n
    file write `fh' `".gc-table-search .count { color: var(--muted); font-size: .78rem; white-space: nowrap; }"' _n
    * Table sizing: do NOT force 100% width.  Let the natural column
    * widths apply; the wrapper handles horizontal scroll when total
    * content exceeds the column.  This is the difference between a
    * cramped equal-share table and a table that breathes + scrolls.
    * Horizontal scroll lives on the wrapper, NOT the inner table-host
    * div.  When both had overflow:auto, the inner div clipped the
    * overflowing table and the wrapper saw zero overflow, so no scroll
    * affordance ever appeared.  Single level of overflow control fixes
    * that.
    file write `fh' `".gc-table-wrap { overflow-x: auto; max-width: 100%; }"' _n
    file write `fh' `".gc-table-wrap > div:not(.gc-table-search) { display: block; min-width: max-content; }"' _n
    * Width: auto + min-width:100% lets the table grow to its natural
    * content size (per-cell min-widths below).  With width:100% (the
    * default the Google Charts Table sets inline), the table can never
    * exceed its container, so per-cell min-widths get ignored and the
    * scroll affordance never triggers.
    file write `fh' `".google-visualization-table-table { border-collapse: collapse !important; font-family: 'Montserrat',-apple-system,sans-serif !important; font-size: .85rem !important; width: auto !important; min-width: 100% !important; }"' _n
    * Give cells comfortable padding so 6-column tables exceed the card
    * width and trigger the horizontal scroll affordance.  Without this
    * Google's defaults pack everything into ~720px regardless of column count.
    file write `fh' `".google-visualization-table-table th, .google-visualization-table-table td { white-space: nowrap !important; min-width: 180px !important; padding: 8px 12px !important; }"' _n
    file write `fh' `".google-visualization-table-table th:first-child, .google-visualization-table-table td:first-child { min-width: 500px !important; }"' _n
    file write `fh' `".google-visualization-table-table th { position: sticky; top: 0; background: var(--ink) !important; color: #fff !important; padding: 8px 10px !important; font-weight: 600 !important; text-align: left !important; border-bottom: 1px solid var(--line) !important; }"' _n
    file write `fh' `".google-visualization-table-table td { padding: 6px 10px !important; border-bottom: 1px solid #f1f5f9 !important; color: #1B2D55 !important; vertical-align: top !important; }"' _n
    file write `fh' `".google-visualization-table-table tr.google-visualization-table-tr-even td { background: #ffffff !important; }"' _n
    file write `fh' `".google-visualization-table-table tr.google-visualization-table-tr-odd  td { background: #f8fafc !important; }"' _n
    file write `fh' `".google-visualization-table-table tr.google-visualization-table-tr-over td { background: #eef2f7 !important; }"' _n
    * Right-align cells that hold numerics, monospace for stable alignment
    file write `fh' `".google-visualization-table-table td.gc-num { font-variant-numeric: tabular-nums; text-align: right; font-feature-settings:'tnum'; }"' _n
    file write `fh' `".google-visualization-table-page-numbers { padding: 8px 12px !important; background:#f8fafc !important; border-top:1px solid var(--line) !important; }"' _n
    file write `fh' `"</style>"' _n

    * Body class so per-type CSS can target without inline styles.
    local _btype = lower("`type'")
    file write `fh' `"</head><body class="gc-type-`_btype'">"' _n
    file write `fh' `"<div class="wrap">"' _n
    file write `fh' `"<h1>`esc_title'</h1>"' _n
    if "`subtitle'" != "" {
        local esc_sub : subinstr local subtitle `"&"' `"&amp;"', all
        file write `fh' `"<p class="sub">`esc_sub'</p>"' _n
    }
    file write `fh' `"<div class="panels">"' _n
    file write `fh' `"  <div class="card controls" id="controls"></div>"' _n
    file write `fh' `"  <div class="card chartcard"><div id="chart"></div><div id="chart-footer"></div></div>"' _n
    file write `fh' `"</div>"' _n
    file write `fh' `"<div id="datatable"></div>"' _n
    if "`note'" != "" {
        local esc_note : subinstr local note `"&"' `"&amp;"', all
        file write `fh' `"<p class="note">`esc_note'</p>"' _n
    }
    file write `fh' `"</div>"' _n

    * --- JSON payload + engine injection ----------------------------------
    file write `fh' `"<script>"' _n
    file write `fh' `"window.__GOOGLECHART__ = {"' _n
    file write `fh' `""meta":{"' _n
    * JSON-safe escape of free-text fields (backslash + double-quote).
    local _jtitle    : subinstr local title    `"\"' `"\\"', all
    local _jtitle    : subinstr local _jtitle  `"""' `"\""', all
    local _jsubtitle : subinstr local subtitle `"\"' `"\\"', all
    local _jsubtitle : subinstr local _jsubtitle `"""' `"\""', all
    local _jnote     : subinstr local note     `"\"' `"\\"', all
    local _jnote     : subinstr local _jnote   `"""' `"\""', all
    local _jxlabel   : subinstr local xlabel   `"\"' `"\\"', all
    local _jxlabel   : subinstr local _jxlabel `"""' `"\""', all
    local _jylabel   : subinstr local ylabel   `"\"' `"\\"', all
    local _jylabel   : subinstr local _jylabel `"""' `"\""', all
    local _jnamelbl  : subinstr local namelabel `"""' `"\""', all
    local _jvallbl   : subinstr local valuelabel `"""' `"\""', all
    local _jlevord   : subinstr local levelorder `"""' `"\""', all
    local _jctrlvl   : subinstr local centerlevel `"""' `"\""', all

    file write `fh' `""type":"`type'","scheme":"`scheme'","' _n
    file write `fh' `""width":`width',"height":`height',"' _n
    file write `fh' `""title":"`_jtitle'","subtitle":"`_jsubtitle'","note":"`_jnote'","' _n
    file write `fh' `""xvar":"`xvar'","yvar":"`yvar'","' _n
    file write `fh' `""xlabel":"`_jxlabel'","ylabel":"`_jylabel'","' _n
    file write `fh' `""name":"`name'","over":"`over'","level":"`level'","time":"`time'","' _n
    file write `fh' `""namelabel":"`_jnamelbl'","valuelabel":"`_jvallbl'","' _n
    file write `fh' `""levelorder":"`_jlevord'","centerlevel":"`_jctrlvl'","' _n
    file write `fh' `""download":`isdownload',"datatable":`isdatatable',"animate":`isanimate',"' _n
    file write `fh' `""tx2036style":`istx2036style',"downloadpos":"`downloadpos'","' _n
    file write `fh' `""stacked":`isstacked',"normalize":`isnormalize',"directlabels":`isdirectlabels',"' _n
    file write `fh' `""innerradius":`innerradius',"bucketsize":`bucketsize',"' _n
    file write `fh' `""geo_region":"`georegion'","geo_resolution":"`georesolution'","' _n
    file write `fh' `""combo_types":"`combotypes'","combo_default":"`combodefault'","' _n
    file write `fh' `""labelwrap":"`labelwrap'","' _n
    file write `fh' `""legendpos":"`legendpos'","' _n
    file write `fh' `""table_search":`istblsearch',"' _n
    file write `fh' `""table_sticky":`istblsticky',"' _n
    file write `fh' `""table_frozencols":`tblfrozencols'"' _n
    file write `fh' `"},"' _n
    file write `fh' `""filters":"' _n
    googlechart_appendfile, fh(`fh') path("`filterjson'") outpath(`"`export'"')
    file write `fh' `","' _n
    file write `fh' `""data":["' _n
    googlechart_appendfile, fh(`fh') path("`rowjson'") outpath(`"`export'"')
    file write `fh' `"]"' _n
    file write `fh' `"};"' _n
    file write `fh' `"</script>"' _n

    * Inline the engine source (one self-contained file).
    googlechart_embedjs, fh(`fh') path("`engpath'") outpath(`"`export'"')
    file write `fh' `"<script>googlechartRender(window.__GOOGLECHART__);</script>"' _n

    file write `fh' `"</body></html>"' _n
    file close `fh'
end
