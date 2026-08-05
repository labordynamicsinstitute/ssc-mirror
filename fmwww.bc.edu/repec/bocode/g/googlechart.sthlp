{smcl}
{* *! version 0.1.3  2026-07-04}{...}
{vieweralsosee "[G] graph" "help graph"}{...}
{vieweralsosee "sparkta2" "help sparkta2"}{...}
{viewerjumpto "Syntax" "googlechart##syntax"}{...}
{viewerjumpto "Description" "googlechart##description"}{...}
{viewerjumpto "Options" "googlechart##options"}{...}
{viewerjumpto "Chart types" "googlechart##types"}{...}
{viewerjumpto "Examples" "googlechart##examples"}{...}
{viewerjumpto "Network requirement" "googlechart##network"}{...}
{viewerjumpto "Limitations" "googlechart##limitations"}{...}

{title:Title}

{p2colset 5 19 23 2}{...}
{p2col :{cmd:googlechart} {hline 2}}Stata wrapper for the Google Charts (Visualization API) library{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:googlechart} [{it:varlist}] {ifin} {cmd:,} {cmd:type(}{it:type}{cmd:)}
[ {it:type_specific_options} {it:cross-cutting_options} ]
{p_end}

{phang}
{it:type} is one of:
{cmd:column} {cmd:bar} {cmd:line} {cmd:area} {cmd:combo} {cmd:pie} {cmd:donut}
{cmd:scatter} {cmd:bubble} {cmd:geo} {cmd:timeline} {cmd:table} {cmd:histogram} {cmd:divbar}


{marker description}{...}
{title:Description}

{pstd}
{cmd:googlechart} renders an interactive Google Charts visualization from a
long-form Stata dataset and writes a self-contained HTML file.  The package
is a {bf:sibling} to sparkta2, not a replacement: sparkta2 ships D3 and
TopoJSON inline (offline-capable), while googlechart uses the Google Charts
loader at gstatic.com (CDN-only, requires network at view time).

{pstd}
{bf:Use googlechart when:} you want native filter dropdowns / range sliders
({help googlechart##filters:filters() option}), polished default tooltips,
animations on most chart types, and types not in sparkta2 -- bubble, combo,
timeline, geo (country/state-level), table.

{pstd}
{bf:Use sparkta2 when:} the HTML must work offline (LaTeX deck handouts,
embargoed reports), the visualization is a Texas county / school-district
choropleth, or you want bivariate / hexbin maps.

{pstd}
Colors come from {cmd:scheme()}, which selects among the built-in palettes
({bf:blues}, {bf:reds}, {bf:viridis}, and others).  One further option,
{cmd:tx2036style}, applies a fixed house style (Montserrat plus the Texas 2036
palette) for teams that publish under it; see the option list below.


{marker types}{...}
{title:Chart types}

{synoptset 22 tabbed}{...}
{synopthdr:type}
{synoptline}
{synopt :{cmd:column}}vertical bars; one row per category{p_end}
{synopt :{cmd:bar}}horizontal bars; one row per category{p_end}
{synopt :{cmd:line}}line chart; supports multiple series via {cmd:over()}{p_end}
{synopt :{cmd:area}}filled-area line chart; same data shape as line{p_end}
{synopt :{cmd:combo}}mixed bars + lines / areas via {cmd:combotypes()}{p_end}
{synopt :{cmd:pie}}pie chart; one row per slice{p_end}
{synopt :{cmd:donut}}pie with center hole; {cmd:innerradius()} controls hole size{p_end}
{synopt :{cmd:scatter}}point cloud; two-variable {it:varlist} = (x y){p_end}
{synopt :{cmd:bubble}}like scatter; two-variable {it:varlist}, plus {cmd:sizevar()} and {cmd:over()} for size/color{p_end}
{synopt :{cmd:geo}}country / US-state choropleth -- see Limitations{p_end}
{synopt :{cmd:timeline}}Gantt-style swimlanes; {cmd:startvar()}/{cmd:endvar()} required{p_end}
{synopt :{cmd:table}}sortable/paginated HTML table -- no chart{p_end}
{synopt :{cmd:histogram}}distribution; one numeric var{p_end}
{synopt :{cmd:divbar}}Pew-style diverging stacked bar for Likert items{p_end}
{synoptline}


{marker options}{...}
{title:Options}

{synoptset 30 tabbed}{...}
{syntab :Data shape}
{synopt :{cmd:name(}{it:varname}{cmd:)}}category / item / region label{p_end}
{synopt :{cmd:over(}{it:varname}{cmd:)}}series / group / color dimension{p_end}
{synopt :{cmd:level(}{it:varname}{cmd:)}}response level (Likert) for {cmd:divbar}{p_end}
{synopt :{cmd:levelorder(}{it:string}{cmd:)}}pipe-separated explicit level order{p_end}
{synopt :{cmd:centerlevel(}{it:string}{cmd:)}}centering level for {cmd:divbar} (e.g. Neutral){p_end}
{synopt :{cmd:startvar(}{it:varname}{cmd:)}}timeline start date or year{p_end}
{synopt :{cmd:endvar(}{it:varname}{cmd:)}}timeline end date or year{p_end}
{synopt :{cmd:sizevar(}{it:varname}{cmd:)}}bubble size{p_end}
{synopt :{cmd:tooltipvars(}{it:varlist}{cmd:)}}extra fields shown in the data table{p_end}

{syntab :Per-type appearance}
{synopt :{cmd:horizontal}}swap column to bar (or accept the bar default){p_end}
{synopt :{cmd:stacked}}stacked instead of grouped{p_end}
{synopt :{cmd:normalize}}stacked + 100% normalised{p_end}
{synopt :{cmd:directlabels}}values on bars (column/bar, via annotation role); switches pie/donut slice text from value to percentage{p_end}
{synopt :{cmd:innerradius(}{it:#}{cmd:)}}donut hole fraction (default 0.45){p_end}
{synopt :{cmd:legendpos(}{it:string}{cmd:)}}{bf:top} | {bf:right} | {bf:bottom} | {bf:left} -- pie/donut default to {bf:bottom}{p_end}
{synopt :{cmd:bucketsize(}{it:#}{cmd:)}}explicit histogram bucket width (default auto){p_end}
{synopt :{cmd:labelwrap(}{it:#}|{bf:none}{cmd:)}}divbar row-label wrap width (default 50 chars; {bf:none} disables){p_end}
{synopt :{cmd:tablesearch}}free-text Search box above {cmd:type(table)} -- substring match across all columns{p_end}
{synopt :{cmd:tableheadersticky}}accepted for compatibility; {cmd:type(table)} headers are sticky on scroll whether or not it is given{p_end}
{synopt :{cmd:time(}{it:varname}{cmd:)}}for {cmd:type(bubble)}: time dimension that drives a Play button + range slider (requires a {it:panel} -- one row per entity per value of {it:varname}){p_end}
{synopt :{cmd:georegion(}{it:string}{cmd:)}}geo region: {bf:world} | {bf:US} | {bf:150} | etc.{p_end}
{synopt :{cmd:georesolution(}{it:string}{cmd:)}}{bf:countries} | {bf:provinces} | {bf:metros} | {bf:us-states} (alias for {bf:provinces}){p_end}
{synopt :{cmd:combotypes(}{it:string}{cmd:)}}pipe-separated per-series chart type for {cmd:combo}{p_end}
{synopt :{cmd:combodflt(}{it:string}{cmd:)}}default chart type per series for {cmd:combo}{p_end}

{syntab :Brand + interactivity}
{synopt :{cmd:tx2036style}}Texas 2036 brand + Montserrat font{p_end}
{synopt :{cmd:scheme(}{it:string}{cmd:)}}color palette: {bf:tx2036} | {bf:blues} | {bf:reds} | {bf:viridis} | etc.{p_end}
{synopt :{cmd:download}}include the Export menu (PNG/SVG){p_end}
{synopt :{cmd:datatable}}add CSV download + "View data table" toggle{p_end}
{synopt :{cmd:animate}}IntersectionObserver-gated draw (chart appears + animates when scrolled into view){p_end}
{synopt :{cmd:downloadpos(}{it:string}{cmd:)}}{bf:side} (default) | {bf:below} | {bf:none}{p_end}
{marker filters}{...}
{synopt :{cmd:filters(}{it:varlist}{cmd:)}}build a Google Dashboard with CategoryFilter (categorical) / NumberRangeFilter (numeric) per variable;{p_end}
{synopt :}takes effect for {cmd:type(column)}, {cmd:type(bar)}, {cmd:type(line)}, {cmd:type(area)}, and {cmd:type(table)} only{p_end}

{syntab :Text + layout}
{synopt :{cmd:title(}{it:string}{cmd:)}}{p_end}
{synopt :{cmd:subtitle(}{it:string}{cmd:)}}{p_end}
{synopt :{cmd:note(}{it:string}{cmd:)}}page-foot attribution{p_end}
{synopt :{cmd:xlabel(}{it:string}{cmd:)}}x-axis title{p_end}
{synopt :{cmd:ylabel(}{it:string}{cmd:)}}y-axis title{p_end}
{synopt :{cmd:namelabel(}{it:string}{cmd:)}}override the category-column display name{p_end}
{synopt :{cmd:valuelabel(}{it:string}{cmd:)}}override the value-column display name{p_end}
{synopt :{cmd:width(}{it:#}{cmd:)}} default 980{p_end}
{synopt :{cmd:height(}{it:#}{cmd:)}} default 644{p_end}

{syntab :Output}
{synopt :{cmd:export(}{it:path}{cmd:)}}output HTML path; default {bf:googlechart_{it:type}.html} in cwd{p_end}
{synopt :{cmd:noopen}}accepted for compatibility; {cmd:googlechart} never opens a browser, it only prints a clickable link{p_end}
{synoptline}


{marker network}{...}
{title:Network requirement}

{pstd}
{bf:Important:} the output HTML requires network access at view time.  The
file is small (~10-20 KB) because the Google Charts library is fetched from
the CDN at https://www.gstatic.com/charts/loader.js at view time, and the
per-chart-type packages (corechart, controls, geochart, timeline, ...) are
fetched lazily after that.  This is a hard requirement of Google's Terms of
Service: the loader.js code may not be self-hosted or bundled into your
output.

{pstd}
If your deliverable must work offline (LaTeX deck handouts, embargoed
reports), use sparkta2 instead.  See {help sparkta2}.


{marker limitations}{...}
{title:Limitations worth knowing}

{phang}{bf:Geo resolution stops at US state level.}  GeoChart does not
support county FIPS, school-district shapes, or any custom GeoJSON.  For
Texas county / school-district choropleth, use sparkta2.{p_end}

{phang}{bf:No native diverging-bar mode.}  The {cmd:divbar} type fakes it
by sign-flipping the negative-side levels and stacking via {cmd:isStacked}.
Axis ticks display absolute values via custom {it:format} so readers see
"40%, 20%, 0%, 20%, 40%" rather than negative numbers on the left half.{p_end}

{phang}{bf:Animation skips some chart types.}  Native Google Charts
animation supports only Column, Bar, Line, Area, Scatter, Bubble, Combo,
Candlestick, SteppedArea, and Gauge.  GeoChart, Pie / Donut, Treemap,
Timeline, Sankey, Table, and Calendar do not animate -- the {cmd:animate}
option is silently ignored.  IntersectionObserver-gated initial draw still
fires for those types; the chart just doesn't ease in.{p_end}

{phang}{bf:isHtml tooltips disable PNG export.}  The package does not
currently turn on isHtml tooltips so PNG export works on all corechart
types.{p_end}

{phang}{bf:animate is incompatible with directlabels on bar/column.}
{cmd:directlabels} adds an annotation-role column, and Google Charts throws
on {cmd:animation.startup} when that column is present, leaving the chart
blank.  {cmd:googlechart} detects this combination on {cmd:type(bar)} and
{cmd:type(column)}, drops {cmd:animate}, and prints a note.  Use one or the
other on these types.{p_end}

{phang}{bf:time() needs a panel.}  {cmd:time(}{it:varname}{cmd:)} on
{cmd:type(bubble)} animates one bubble per entity across the frames given by
{it:varname}, so the data must be in long/panel form: one row per entity per
time value (e.g. 51 states {c 215} 10 years = 510 rows).  A single
cross-section gives the Play control only one frame and nothing moves.{p_end}

{phang}{bf:PDF is intentionally omitted.}  Use your browser's File > Print
to save the chart as PDF -- a print stylesheet in the HTML hides the
controls panel and renders only the chart card.{p_end}


{marker examples}{...}
{title:Examples}

{phang}A runnable do-file exercising every chart type sits at
{bf:examples/test_googlechart.do} in the package.  Each example below
expects an open {bf:cwd}; HTML files are written there.{p_end}


{dlgtab:1. Column chart -- mean poverty by region}

{phang}{cmd}collapse (mean) poverty_rate, by(region){p_end}
{phang}{cmd}googlechart poverty_rate, name(region) type(column) ///{p_end}
{phang}{cmd}    download datatable animate                      ///{p_end}
{phang}{cmd}    title("Texas regions: mean poverty rate")       ///{p_end}
{phang}{cmd}    ylabel("Poverty rate (%)")                      ///{p_end}
{phang}{cmd}    export("01_column.html"){p_end}


{dlgtab:2. Bar (horizontal) with filter dropdowns}

{phang}{cmd}googlechart poverty_rate, name(region) type(bar)                ///{p_end}
{phang}{cmd}    over(year) filters(year urban)                              ///{p_end}
{phang}{cmd}    download datatable downloadpos(below)                       ///{p_end}
{phang}{cmd}    title("Poverty by region -- filter by year / urbanisation") ///{p_end}
{phang}{cmd}    export("02_bar_filters.html"){p_end}


{dlgtab:3. Multi-series line + animate-on-scroll}

{phang}{cmd}googlechart y yr, over(region) type(line)       ///{p_end}
{phang}{cmd}    download datatable animate                  ///{p_end}
{phang}{cmd}    xlabel("Year") ylabel("% meeting standard") ///{p_end}
{phang}{cmd}    title("Texas regions: trend 2018-2024")     ///{p_end}
{phang}{cmd}    export("03_line.html"){p_end}


{dlgtab:4. Donut chart with brand palette (legend below)}

{phang}{cmd}googlechart enrollment, name(sector) type(donut)      ///{p_end}
{phang}{cmd}    innerradius(0.5) directlabels animate             ///{p_end}
{phang}{cmd}    download datatable downloadpos(below)             ///{p_end}
{phang}{cmd}    title("Texas postsecondary enrollment by sector") ///{p_end}
{phang}{cmd}    width(640) height(540)                            ///{p_end}
{phang}{cmd}    export("04_donut.html"){p_end}

{phang}Pie / donut default to legend below the chart and the standard 980x644
frame, so the bounding card hugs the chart instead of leaving an empty
band of right-side legend space.  Pass {cmd:legendpos(right)} to restore
the older layout.{p_end}


{dlgtab:5. Bubble chart -- 3+ variable comparison}

{phang}{cmd}googlechart life_expect poverty_rate, name(county)             ///{p_end}
{phang}{cmd}    over(region_name) sizevar(pop_thou)                        ///{p_end}
{phang}{cmd}    type(bubble) download datatable animate                    ///{p_end}
{phang}{cmd}    title("Life expectancy vs poverty rate; bubble = pop")     ///{p_end}
{phang}{cmd}    xlabel("Poverty rate (%)") ylabel("Life expectancy (yrs)") ///{p_end}
{phang}{cmd}    export("05_bubble.html"){p_end}


{dlgtab:6. Combo chart -- bars + overlay line}

{phang}{cmd}googlechart value, name(year) over(metric) type(combo) ///{p_end}
{phang}{cmd}    combodflt(bars) combotypes("bars|bars|line")       ///{p_end}
{phang}{cmd}    download datatable                                 ///{p_end}
{phang}{cmd}    title("Bars + overlay line via combotypes()")      ///{p_end}
{phang}{cmd}    export("06_combo.html"){p_end}


{dlgtab:7. Geo chart -- US state choropleth}

{phang}{it:Important:} only country and US-state level are supported.{p_end}
{phang}{cmd}googlechart value, name(state_code) type(geo)  ///{p_end}
{phang}{cmd}    georegion("US") georesolution("us-states") ///{p_end}
{phang}{cmd}    download datatable                         ///{p_end}
{phang}{cmd}    title("US states -- example metric")       ///{p_end}
{phang}{cmd}    export("07_geo.html"){p_end}


{dlgtab:8. Timeline -- Gantt-style swimlanes}

{phang}{cmd}* Data: one row per session, with name(=row), startvar, endvar.{p_end}
{phang}{cmd}googlechart, type(timeline) name(session_label) ///{p_end}
{phang}{cmd}    startvar(date_start) endvar(date_end)       ///{p_end}
{phang}{cmd}    download datatable                          ///{p_end}
{phang}{cmd}    title("Texas legislative session timeline") ///{p_end}
{phang}{cmd}    export("08_timeline.html"){p_end}


{dlgtab:9. Table -- searchable, with sticky header}

{phang}A free-text search box can be wired above the rendered table
using {cmd:tablesearch}; rows filter live by substring match across all
columns and the row count updates next to the input.  The header row stays
visible while you scroll a long table; that is the default for every
{cmd:type(table)} rendering and needs no option.{p_end}

{phang}{cmd}googlechart, type(table)                                     ///{p_end}
{phang}{cmd}    tooltipvars(region poverty_rate uninsured_rate pop_thou) ///{p_end}
{phang}{cmd}    tablesearch                                              ///{p_end}
{phang}{cmd}    download datatable                                       ///{p_end}
{phang}{cmd}    title("Texas regions: searchable data table")            ///{p_end}
{phang}{cmd}    export("09_table.html"){p_end}

{phang}For a dropdown-filtered (Dashboard + CategoryFilter) variant, add
{cmd:filters(group year)}.  Note that the two do not combine: when
{cmd:filters()} is given, the table is rendered inside a dashboard and the
{cmd:tablesearch} box is not built.  Choose dropdowns or the search box.{p_end}


{dlgtab:10. Diverging stacked bar (Pew-style Likert)}

{phang}{cmd}* Long form: name = item, level = response, varlist = share %.{p_end}
{phang}{cmd}googlechart share, name(q) level(response) type(divbar)                   ///{p_end}
{phang}{cmd}    levelorder("Strongly disagree|Disagree|Neutral|Agree|Strongly agree") ///{p_end}
{phang}{cmd}    centerlevel(Neutral)                                                  ///{p_end}
{phang}{cmd}    download datatable downloadpos(below)                                 ///{p_end}
{phang}{cmd}    title("Texans on K-12 and higher-ed policy")                          ///{p_end}
{phang}{cmd}    width(1100) height(640)                                               ///{p_end}
{phang}{cmd}    export("10_divbar.html"){p_end}


{dlgtab:11. Combine multiple charts on one page (dashboard)}

{phang}{cmd}* The sparkta2 dashboard composer works on any HTML files,{p_end}
{phang}{cmd}* including googlechart outputs.  Pass the file basenames:{p_end}
{phang}{cmd}sparkta2_dashboard,                                                   ///{p_end}
{phang}{cmd}    files("01_column.html 03_line.html 04_donut.html 10_divbar.html") ///{p_end}
{phang}{cmd}    titles("Column|Line|Donut|Divbar")                                ///{p_end}
{phang}{cmd}    heights("680")                                                    ///{p_end}
{phang}{cmd}    title("googlechart demo gallery")                          ///{p_end}
{phang}{cmd}    export("gallery.html"){p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:googlechart} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt :{cmd:r(n_rows)}}number of data rows written to the HTML payload{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt :{cmd:r(export)}}path of the HTML file written{p_end}
{synopt :{cmd:r(type)}}chart type rendered{p_end}
{p2colreset}{...}


{title:Author and acknowledgements}

{pstd}
googlechart is by Eric A. Booth, Sr Researcher, Texas2036.org (eric.a.booth@gmail.com), 2026.  Built atop Google Charts
(https://developers.google.com/chart) which is the property of Google LLC
and is subject to the Google Charts Terms of Service.  This package is
not affiliated with or endorsed by Google.

{pstd}
Design inheritance: the file layout, brand defaults, Export menu UX,
animate-on-view pattern, and dashboard composer all mirror sparkta2.
{help sparkta2} is the sister package and the right tool when offline
HTML or Texas county / district choropleths are required.
