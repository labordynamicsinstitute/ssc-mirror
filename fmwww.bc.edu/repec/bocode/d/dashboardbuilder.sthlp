{smcl}
{* *! version 1.3.1  15jul2026}{...}
{viewerjumpto "Syntax" "dashboardbuilder##syntax"}{...}
{viewerjumpto "Description" "dashboardbuilder##description"}{...}
{viewerjumpto "Panel types" "dashboardbuilder##paneltypes"}{...}
{viewerjumpto "The selector" "dashboardbuilder##selector"}{...}
{viewerjumpto "Options" "dashboardbuilder##options"}{...}
{viewerjumpto "Python requirements" "dashboardbuilder##python"}{...}
{viewerjumpto "Examples" "dashboardbuilder##examples"}{...}
{viewerjumpto "Stored results" "dashboardbuilder##results"}{...}
{title:Title}

{p2colset 5 26 28 2}{...}
{p2col :{bf:dashboardbuilder} {hline 2}}Build a self-contained, interactive HTML
dashboard from Stata (tabs, charts, KPI tiles, selector dropdown, CSV/PDF
download buttons, themed styling){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}Start a dashboard:{p_end}

{p 8 16 2}
{cmd:dashboardbuilder} {cmd:init} {cmd:,} {opth ti:tle(string)}
[{opth sub:title(string)} {opt sel:ector(name)} {opth sellab:el(string)}
{opth refval:ue(string)} {opt tx2036} {opt theme(simple|tx2036)}]

{pstd}Declare a tab (optional; panels without tabs share one page):{p_end}

{p 8 16 2}
{cmd:dashboardbuilder} {cmd:tab} {cmd:,} {opt na:me(name)} [{opth lab:el(string)}]

{pstd}Capture the data currently in memory as one panel (repeat per panel):{p_end}

{p 8 16 2}
{cmd:dashboardbuilder} {cmd:panel} {it:paneltype} {cmd:,} {it:type_options}
[{opt tab(name)} {opth ti:tle(string)} {opth note(string)} {opth interp(string)}
{opth yti:tle(string)}]

{p 8 16 2}where {it:paneltype} is
{cmd:kpi} | {cmd:line} | {cmd:bar} | {cmd:hbar} | {cmd:compare} | {cmd:table} | {cmd:html}

{pstd}Write the HTML file and print the build receipt:{p_end}

{p 8 16 2}
{cmd:dashboardbuilder} {cmd:build} {cmd:using} {it:filename.html}
[{cmd:,} {opt replace} {opt nocsv} {opt nopng} {opt notooltip} {opt pdf}
{opt truepdf} {opt corner} {opth call:out(string)} {opth source:note(string)} {opt noopen}]

{pstd}Utilities:{p_end}

{p 8 16 2}{cmd:dashboardbuilder} {cmd:describe}{space 4}(show what has been registered so far){p_end}
{p 8 16 2}{cmd:dashboardbuilder} {cmd:clear}{space 7}(abandon the current build){p_end}
{p 8 16 2}{cmd:dashboardbuilder} {cmd:openlast}{space 4}(open the last-built dashboard in the browser){p_end}
{p 8 16 2}{cmd:dashboardbuilder} {cmd:openfolder}{space 2}(open the folder that contains it){p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dashboardbuilder} is a {help putdocx}-style {it:builder}: you call it
several times, then finish. Each {cmd:panel} call snapshots {it:the data
currently in memory}, so the natural workflow is to load or derive one analytic
subset, capture it as a panel, derive the next subset, capture it, and so on.
{cmd:build} then writes {bf:one self-contained HTML file}: all data embedded as
inline JSON, all charts drawn by readable vanilla JavaScript/SVG, no internet,
no CDN, no external files. The file opens by double-click, works from a shared
drive or email attachment, and prints cleanly.

{pstd}
The output is deliberately a {bf:starter wireframe}. Every chart is plain,
commented JS you can open and tweak; the file marks intended tweak points with
{cmd:EDIT-ME} comments, and the Stata {bf:build receipt} lists what was built
plus what likely still needs a human pass (missing titles, missing sources,
crowded charts, oversize panels, and similar).

{pstd}
Layout, top to bottom: themed header (title + subtitle); a controls card with
the optional selector dropdown and the tab bar; one card per panel (title,
optional interpretation callout, optional CSV button, chart, legend, note); an
optional callout box; and a source/footer line. An optional
{bf:save-as-PDF} button uses the browser's print-to-PDF with a bundled print
stylesheet.


{marker paneltypes}{...}
{title:Panel types}

{p2colset 6 15 17 2}{...}
{p2col :{cmd:kpi}}big-number tiles. {opt values(varlist)} names the numeric
variables; each becomes a tile using its variable label. Collapse your data to
one row (per selector unit) first: the first visible row supplies the values.{p_end}
{p2col :{cmd:line}}line chart. {opt x()} is the horizontal variable (numeric,
for example year); {opt y(varlist)} draws one line per variable. String
{it:x} is treated as ordered categories.{p_end}
{p2col :{cmd:bar}}vertical bars. {opt x()} is the category; {opt y()} the
numeric height. Value labels on {it:x} are honored.{p_end}
{p2col :{cmd:hbar}}horizontal bars; better when category names are long or
numerous (rankings).{p_end}
{p2col :{cmd:compare}}bullet bars: one row per {opt x()} category, a bar for
{opt y()}, and a {bf:|} reference marker from {opt ref(varname)} or, when a
selector reference is set, from the reference unit's own rows (see below). All
rows share one scale, so bar lengths are comparable.{p_end}
{p2col :{cmd:table}}plain table of {opt vars(varlist)} (default: all
variables). Renders the first 500 rows; the CSV download has all rows.{p_end}
{p2col :{cmd:html}}embed an external HTML file named in {opt file(string)} (for
example a sparkta2 map or any saved interactive chart). The file's
contents are inlined into an {cmd:<iframe>}, so the dashboard stays one
self-contained file. Takes no data from memory; use {opt height(#)} to set the
frame height in pixels (default 520). Static (it does not filter with the
selector).{p_end}
{p2colreset}{...}


{marker selector}{...}
{title:The selector (the "choose a county" pattern)}

{pstd}
{opt selector(name)} on {cmd:init} names a variable (for example
{cmd:selector(county)}). Any panel whose captured data {it:contains a variable
with that name} becomes {bf:filterable}: the dashboard gets a dropdown, and
those panels re-render showing only the rows of the chosen unit. Panels
without the column stay static.

{pstd}
With tabs, the dropdown is shown only on tabs that have at least one filterable
panel, and {bf:auto-hidden} on tabs where nothing filters (so a "choose a unit"
control is never offered where it would do nothing). A tab that is entirely
static therefore reads as a selection-independent overview.

{pstd}
{opt refvalue(string)} names one {it:value} of the selector to treat as the
reference unit, for example {cmd:refvalue("Texas (statewide)")} or
{cmd:refvalue("United States")}. Effects: the value is pinned to the top of the
dropdown; {cmd:line} panels overlay the reference unit's series as dashed
lines; {cmd:compare} panels place the {bf:|} marker at the reference unit's
value when no {opt ref()} variable was given. Build the reference row yourself
(for example {cmd:collapse} + {cmd:append}) before capturing panels; it is
ordinary data.


{marker options}{...}
{title:Options}

{dlgtab:init}

{phang}{opth title(string)} dashboard title (required). Shown in the header
and the browser tab.{p_end}
{phang}{opth subtitle(string)} smaller text next to the title.{p_end}
{phang}{opt selector(name)} variable name that activates the dropdown-filter
machinery; see {help dashboardbuilder##selector:the selector}.{p_end}
{phang}{opth sellabel(string)} dropdown label; default "Choose a {it:selector}".{p_end}
{phang}{opth refvalue(string)} selector value treated as the reference unit.{p_end}
{phang}{opt tx2036} Texas 2036 branding (navy {cmd:#1B2D55}, orange
{cmd:#D44500}); shorthand for {cmd:theme(tx2036)}.{p_end}
{phang}{opt theme(simple|tx2036)} color theme; default {cmd:simple}, a neutral
slate/blue.{p_end}

{dlgtab:tab}

{phang}{opt name(name)} short internal name (no spaces).{p_end}
{phang}{opth label(string)} button text; defaults to the name.{p_end}

{dlgtab:panel (all types)}

{phang}{opt tab(name)} which tab the panel lives on; default is the most
recently declared tab (an implicit "main" tab is created if none exists).{p_end}
{phang}{opth title(string)} card heading. Strongly recommended; untitled
panels are flagged in the receipt.{p_end}
{phang}{opth note(string)} small muted text under the chart (source or caveat).{p_end}
{phang}{opth interp(string)} one-line takeaway shown in an accent-colored
callout under the title.{p_end}
{phang}{opth ytitle(string)} value-axis caption shown in the legend area
(line/bar/hbar/compare).{p_end}

{dlgtab:panel html (extra options)}

{phang}{opth file(string)} path to the HTML file to embed (required for
{cmd:html} panels). Relative paths resolve against Stata's current working
directory; the file's contents are inlined into an {cmd:<iframe srcdoc>} at build
time, so the dashboard stays self-contained. Build the file first (for example a
sparkta2 map exported with {cmd:offline}), then pass its path here.{p_end}
{phang}{opt height(#)} iframe height in pixels (default 520). Maps usually want
more, for example {cmd:height(760)}.{p_end}

{dlgtab:build}

{phang}{cmd:using} {it:filename.html} output path; ".html" is appended if
missing. Relative paths resolve against Stata's current working directory.{p_end}
{phang}{opt replace} overwrite an existing file.{p_end}

{pmore}{it:Per-panel buttons and tooltips are ON by default; all three are fully
self-contained (no internet). Turn them off with:}{p_end}
{phang}{opt nocsv} drop the per-panel CSV download button (CSV downloads the
panel's rows, filtered to the current selection).{p_end}
{phang}{opt nopng} drop the per-panel PNG download button. PNG appears on the
chart panels (line/bar/hbar/compare), which are drawn as SVG and rasterized in
the browser with no library. The exported image carries the panel's {bf:title,
interpretation, legend, and note}, not just the plot, so the chart is
self-describing. kpi and table are HTML, where a no-library canvas export cannot
be guaranteed across browsers, so they show CSV only.{p_end}
{phang}{opt notooltip} disable the styled hover tooltips (self-contained; they
need no external library).{p_end}

{pmore}{it:PDF download buttons (opt-in):}{p_end}
{phang}{opt pdf} add a {bf:Save as PDF} button that uses the browser's own
print-to-PDF (controls are hidden by the print stylesheet). Fully offline.{p_end}
{phang}{opt truepdf} add a one-click {bf:Download PDF} button.
{err:This pulls a JavaScript library (html2pdf.js) from a CDN}, so this one
button needs internet and will {bf:not} work on an air-gapped machine; the rest
of the dashboard still works offline. The button degrades gracefully (it alerts
and points the user to Save as PDF) when the library cannot load.{p_end}
{phang}{opt corner} float the global PDF button(s) ({bf:Save as PDF} /
{bf:Download PDF}) as a fixed button in the {bf:bottom-right corner} of the page,
instead of in the top controls card. Handy when the top of the dashboard is
busy (for example above a tall embedded map).{p_end}

{pmore}{it:Notes and opening:}{p_end}
{phang}{opth callout(string)} highlighted note box near the bottom (use for
"projections are scenarios, not predictions"-style guardrails).{p_end}
{phang}{opth sourcenote(string)} source citation line in the footer.{p_end}
{phang}{opt noopen} do {it:not} auto-open the finished file. By default the
dashboard opens in your OS default browser as soon as the build finishes (via
the operating system's own opener: {cmd:open} on macOS, {cmd:start} on Windows,
{cmd:xdg-open} on Linux). Pass {opt noopen} to suppress that, for example in
batch runs or loops that build many files at once.{p_end}

{pmore}The build receipt also prints two clickable {bf:browse} links {hline 1}
the finished file and its containing folder {hline 1} whose link text is the
full path, so a click opens it and you can also copy the path to navigate there
yourself. Reopen the last-built dashboard any time with
{cmd:dashboardbuilder openlast}, or open its folder with
{cmd:dashboardbuilder openfolder}.{p_end}


{marker python}{...}
{title:Python requirements (read once, then forget)}

{pstd}
{cmd:dashboardbuilder} uses Stata's built-in Python integration (Stata 16+) for
JSON serialization and HTML templating. It uses {bf:only the Python standard
library} ({cmd:json}, {cmd:os}): there is {bf:nothing to pip install}, ever.
The only requirement is that Stata can see a Python 3 interpreter.

{pstd}Every {cmd:init} checks this and stops with instructions if not. To set
up or repair the link yourself:{p_end}

{phang2}1. {stata python query} {hline 2} shows what Stata is currently using.{p_end}
{phang2}2. {stata python search} {hline 2} lists Python installs Stata can find.{p_end}
{phang2}3. Point Stata at one (path varies by machine):{p_end}
{phang3}{cmd:. python set exec /usr/local/bin/python3, permanently}   (Mac/Linux){p_end}
{phang3}{cmd:. python set exec C:\Python312\python.exe, permanently}  (Windows){p_end}

{pstd}
If a call ever fails with "the Python helper functions are missing", someone
ran {cmd:python clear} mid-session; run {stata discard} and start again from
{cmd:dashboardbuilder init}.


{marker examples}{...}
{title:Examples}

{pstd}{bf:1. Two-minute minimal dashboard} (auto data, default theme):{p_end}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. collapse (mean) price mpg weight, by(foreign)}{p_end}
{phang2}{cmd:. dashboardbuilder init , title("Auto quick look")}{p_end}
{phang2}{cmd:. dashboardbuilder panel bar , x(foreign) y(price) title("Mean price by origin")}{p_end}
{phang2}{cmd:. dashboardbuilder panel table , title("The numbers")}{p_end}
{phang2}{cmd:. dashboardbuilder build using "auto_quick.html", replace}{p_end}
{phang2}{it:(the dashboard opens automatically; add }{cmd:noopen}{it: to suppress)}{p_end}

{pstd}{bf:2. Selector + reference unit} (each state vs. a hand-built US row),
Texas 2036 theme, tabs, downloads:{p_end}

{phang2}{cmd:. sysuse census, clear}{p_end}
{phang2}{cmd:. * build the reference row: a synthetic "United States" aggregate}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. collapse (sum) pop death marriage divorce (mean) medage [aw=pop]}{p_end}
{phang2}{cmd:. gen state = "United States"}{p_end}
{phang2}{cmd:. tempfile us}{p_end}
{phang2}{cmd:. save `us'}{p_end}
{phang2}{cmd:. restore}{p_end}
{phang2}{cmd:. append using `us'}{p_end}
{phang2}{cmd:. dashboardbuilder init , title("State explorer") tx2036 selector(state) refvalue("United States")}{p_end}
{phang2}{cmd:. dashboardbuilder tab , name(today) label("Where states stand")}{p_end}
{phang2}{cmd:. dashboardbuilder panel kpi , values(pop medage) title("Headline numbers")}{p_end}
{phang2}{cmd:. dashboardbuilder build using "states.html", replace pdf sourcenote("Source: 1980 census extract.")}{p_end}

{pstd}{bf:3. Feeding analytic subsets}: reload/reshape between panel calls;
each panel embeds its own snapshot:{p_end}

{phang2}{cmd:. sysuse uslifeexp, clear}{p_end}
{phang2}{cmd:. dashboardbuilder init , title("US life expectancy, 1900-1999")}{p_end}
{phang2}{cmd:. dashboardbuilder panel line , x(year) y(le_male le_female) title("The gap")}{p_end}
{phang2}{cmd:. keep if year >= 1950}{p_end}
{phang2}{cmd:. dashboardbuilder panel line , x(year) y(le_wm le_bm) title("White vs Black men, postwar")}{p_end}
{phang2}{cmd:. dashboardbuilder build using "lifeexp.html", replace}{p_end}

{pstd}{bf:4. Embed a map (or any HTML)}: build a self-contained HTML with another
tool, then inline it as an {cmd:html} panel:{p_end}

{phang2}{cmd:. * a sparkta2 choropleth, exported OFFLINE so it is self-contained}{p_end}
{phang2}{cmd:. sparkta2 readiness, id(fips) geo(texas) type(choropleth) offline noopen export("map.html")}{p_end}
{phang2}{cmd:. use county_data, clear}{p_end}
{phang2}{cmd:. dashboardbuilder init , title("County explorer") tx2036}{p_end}
{phang2}{cmd:. dashboardbuilder panel html , file("map.html") height(760) title("Readiness by county")}{p_end}
{phang2}{cmd:. dashboardbuilder panel kpi , values(readiness) title("Statewide average")}{p_end}
{phang2}{cmd:. dashboardbuilder build using "county.html", replace}{p_end}

{pstd}A fuller worked script ships with the package:
{cmd:example_dashboardbuilder.do}. It builds four dashboards that exercise every
panel type and most options, and each maps onto a common use case:{p_end}

{p2colset 8 26 28 2}{...}
{p2col :{bf:auto_quick}}two-minute minimal look at a collapsed table (example 1
above); a bar chart plus a data table, default theme.{p_end}
{p2col :{bf:state_explorer}}the "choose a unit vs. a reference" pattern (example
2 above): a state selector, a synthetic United States reference row, tabs, KPI
tiles, compare bullet bars, a static ranking, PDF buttons, callout and source.{p_end}
{p2col :{bf:lifeexp}}a time series told across tabs, feeding a restricted subset
between panel calls (example 3 above).{p_end}
{p2col :{bf:nhanes_bp}}an optional health-survey example (needs internet once for
{cmd:webuse}); collapsing microdata to group means before charting.{p_end}
{p2colreset}{...}

{pstd}A second script, {cmd:example_dashboardbuilder_map.do}, is the extended
example behind {bf:4} above: it builds a sparkta2 Texas county choropleth and
embeds it in a dashboard via {cmd:panel html} (needs {cmd:sparkta2} installed).{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:dashboardbuilder build} stores in {cmd:r()}:{p_end}
{synoptset 12 tabbed}{...}
{synopt:{cmd:r(file)}}absolute path of the HTML file{p_end}
{synopt:{cmd:r(ntabs)}}number of tabs{p_end}
{synopt:{cmd:r(npanels)}}number of panels{p_end}
{synopt:{cmd:r(bytes)}}file size in bytes{p_end}


{title:Remarks}

{pstd}
{bf:What the receipt's TODO list watches for}: untitled panels; Stata-date
x variables (convert to year or a labeled string first); panels embedding more
than 2,000 rows (collapse first); tables over 500 rows; KPI cards with more
than 6 tiles; bar charts with more than 25 categories; a selector with static
panels; missing {opt sourcenote()}; no {opt interp()} anywhere.

{pstd}
{bf:Data stay local}: everything is embedded in the file you write; nothing is
uploaded anywhere. Anyone you send the file to can read the data out of it, so
share it as you would share the underlying data.


{title:Author}

{pstd}Eric Booth, Texas 2036 Data & Research.{p_end}
{pstd}Contact: {browse "mailto:eric.booth@texas2036.org":eric.booth@texas2036.org}
or {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}.{p_end}
{pstd}Inspired by the hand-built "Texas County Explorer" prototype; this tool
generalizes that layout into a reusable wireframe generator.{p_end}
