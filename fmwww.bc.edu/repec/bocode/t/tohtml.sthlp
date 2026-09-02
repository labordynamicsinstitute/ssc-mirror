{smcl}
{* *! version 1.0.0  18jan2026}{...}
{vieweralsosee "ishere" "help ishere"}{...}
{vieweralsosee "markdown" "help markdown"}{...}
{viewerjumpto "Syntax" "tohtml##syntax"}{...}
{viewerjumpto "Description" "tohtml##description"}{...}
{viewerjumpto "Options" "tohtml##options"}{...}
{viewerjumpto "Examples" "tohtml##examples"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{cmd:tohtml} {hline 2}}Convert Stata log files to HTML reports{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Basic usage

{p 8 16 2}
{cmd:tohtml} {it:filename}|{it:directory}
[{cmd:,} {it:options}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Output options}
{synopt:{opt md(filename)}}output Markdown file; default matches {opt html()} with {bf:.md}{p_end}
{synopt:{opt html(filename)}}HTML file; default is the input stem with {bf:.html}{p_end}
{synopt:{opt replace}}overwrite existing output files{p_end}

{syntab:Style options}
{synopt:{opt css(filename)}}custom CSS file; default is package resource {bf:tohtml.css}{p_end}
{synopt:{opt mathjax}}inject MathJax when equations are detected (independent of CSS){p_end}

{syntab:Table options}
{synopt:{opt tabwidth(size)}}max width of an inlined table box; overflow scrolls (default {bf:100%}){p_end}
{synopt:{opt tabheight(size)}}max height of an inlined table box; overflow scrolls (default {bf:80vh}){p_end}

{syntab:Portable package options}
{synopt:{opt bundle}}collect figures/tables into {bf:figures/} and {bf:tables/} under the HTML folder{p_end}
{synopt:{opt embed}}self-contained HTML: inline {bf:tohtml.css} and Base64 images{p_end}
{synopt:{opt zip(filename|.)}}create a zip archive of the HTML package (implies {cmd:bundle}); use {cmd:.} for default name{p_end}

{syntab:Cleaning modes}
{synopt:{opt clean}}keep only headings, images, and tables{p_end}
{synopt:{opt cleancode}}keep Stata commands from the log (drop output); retain figure/table embeds{p_end}

{syntab:Figure options}
{synopt:{opt width(string)}}set default width for images{p_end}
{synopt:{opt height(string)}}set default height for images{p_end}
{synopt:{opt zoom(string)}}set default zoom level for images{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tohtml} is specifically designed to work hand-in-hand with {help ishere}, forming a unified workflow 
embodied by the phrase: {it:everything is here: from do to html}. This design philosophy emphasizes 
a minimalist approach to reproducible research—where "is here" corresponds to the {cmd:ishere} command 
(marking where elements belong), and "to html" corresponds to the {cmd:tohtml} command (converting marked 
logs into polished reports).

{pstd}
The core principle is simple: everything you need for your analysis lives in one place—your do-file. 
You mark locations with {cmd:ishere}, run your analysis, and {cmd:tohtml} transforms the log into a 
professional HTML report. No external tools, no manual editing, no copy-pasting—just a streamlined path 
from code to publication-ready output.

{pstd}
{cmd:tohtml} converts Stata log files containing {help ishere} markers into formatted HTML reports.
The command can process a single log file or a directory containing multiple table and figure files. The latter gathers all table and figure files in the directory in a HTML.

{pstd}
{cmd:tohtml} provides the following main functions:

{pmore}
1. {bf:Clean log files}: Removes Stata log control characters and extraneous output to produce clean Markdown files.

{pmore}
2. {bf:Process markers}: Recognizes and processes {cmd:ishere} markers in log files, correctly formatting code blocks, headings, figures, and tables.

{pmore}
3. {bf:Generate HTML}: Converts cleaned Markdown to HTML with customizable or preset CSS styles.

{pmore}
4. {bf:Path management}: Supports resource file path replacement for generating portable reports.

{pmore}
5. {bf:Multiple modes}: Supports standard mode, minimal mode (clean), and code-only mode (cleancode).


{marker options}{...}
{title:Options}

{dlgtab:Output options}

{phang}
{opt md(filename)} specifies the output Markdown file. If omitted, the Markdown
path is the same as the HTML file with extension {bf:.md}
(e.g. {cmd:html(report.html)} → {bf:report.md}; omitted {opt html()} from
{bf:analysis.log} → {bf:analysis.md}). If {it:filename} does not
end with {bf:.md}, the extension is added automatically.
The Markdown output path must differ from the input file; otherwise {cmd:tohtml}
errors with {err:input file and Markdown output file must be different}
before any file is deleted. If the input is already a {bf:.md} file, specify
a different {opt md()} (or an {opt html()} whose basename is not the input).

{phang}
{opt html(filename)} converts the Markdown output to HTML after processing.
If omitted, the HTML path is the input stem with extension {bf:.html}
(e.g. {cmd:tohtml "analysis.log"} → {bf:analysis.html}).
If {it:filename} does not end with {bf:.html}, the extension is added automatically.

{phang}
{opt replace} overwrites existing output files. If this option is not specified and files exist,
the command will error.


{dlgtab:Style options}

{phang}
{opt css(filename)} applies a custom stylesheet to the generated HTML file.
When {opt css()} is omitted, the package resource
{bf:tohtml.css} (GitHub-like
layout). Pass a file path only when you want a different stylesheet; the
file must exist. The chosen CSS is copied to a
{bf:css/} subdirectory beside the HTML output. Iframe tables from
{cmd:collect} / {cmd:outreg2e} keep their own three-line styles and
are not restyled by {bf:tohtml.css}.

{phang}
{opt mathjax} enables MathJax for LaTeX formulas in the HTML report. This option
is independent of {opt css()}: you can combine MathJax with {bf:tohtml.css} or any
custom stylesheet. The MathJax CDN script is injected only when equation
delimiters are detected in the cleaned Markdown (e.g. {cmd:$...$}, {cmd:$$...$$},
{cmd:\(...\)}, {cmd:\[...\]}); otherwise nothing is linked. Requires
internet access when viewing formulas.


{dlgtab:Table options}

{phang}
{opt tabwidth(size)} sets the maximum width of each inlined table box
({cmd:.tohtml-embedded-table}). The box grows with the table up to this cap;
if the table is still wider, a horizontal scrollbar appears. The default is
{bf:100%} of the report content width. A value larger than {bf:100%} (e.g.
{cmd:tabwidth(1000%)}) lets the table extend past the text column instead of
scrolling. A bare number is treated as pixels ({cmd:tabwidth(800)} → {bf:800px}).
CSS lengths such as {cmd:100%}, {cmd:90vw}, and {cmd:800px} are accepted.
Use {cmd:none}, {cmd:off}, or {cmd:.} to disable the width cap.

{phang}
{opt tabheight(size)} sets the maximum height of each inlined table box.
If a table is taller than this, a vertical scrollbar appears. The default
is {bf:80vh} (80% of the browser viewport). A bare number is treated as
pixels ({cmd:tabheight(400)} → {bf:400px}). CSS lengths such as {cmd:80vh}
and {cmd:600px} are accepted. Use {cmd:none}, {cmd:off}, or {cmd:.} to let
the table grow with the page.

{phang}
These options apply in every report mode (default, {cmd:clean},
{cmd:cleancode}, and {opt embed}), because HTML tables are always inlined.
They require {opt html()}. They are independent of {opt width()}/{opt height()},
which only affect directory-mode figures.


{dlgtab:Portable package options}

{phang}
{opt bundle} reorganizes linked local resources so the HTML report is self-contained as a folder
tree. After HTML generation, {cmd:tohtml} scans {cmd:<img>} / {cmd:<iframe>} references, copies
files into:

{pmore2}
{bf:ROOT/css/}{break}
{bf:ROOT/figures/}{break}
{bf:ROOT/tables/}

{pmore2}
where {bf:ROOT} is the directory of {opt html()}, then rewrites links to relative paths
({cmd:./figures/...}, {cmd:./tables/...}, {cmd:./css/...}).

{phang}
{opt embed} writes a self-contained HTML file that does not need sidecar CSS or
figure files. The report stylesheet ({bf:tohtml.css}, or {opt css()}) is inlined
as a {cmd:<style>} block. Images are passed to {help markdown}'s {opt embedimage} (Base64 data URIs).
Because {cmd:markdown} only embeds Markdown image links ({cmd:![ ](file.png)}),
{cmd:tohtml} first rewrites local {cmd:<img src="...">} tags (PNG/JPEG/GIF/TIFF)
to that syntax. SVG and other types are left as file links.
HTML tables referenced by {cmd:ishere tab} ({cmd:<iframe src="file.html">}) are
always inlined: the table markup replaces the iframe in every report mode
({cmd:clean}, {cmd:cleancode}, default, and {opt embed}). If {cmd:ishere} was
given {opt title()}, {cmd:tohtml} places that caption above the table
(outside the scroll box) and below a figure, centered. Table {cmd:<style>}
blocks are not written to Markdown (CSS braces break {cmd:markdown}); they are
injected into the HTML {cmd:<head>} after conversion. Companion CSS written by
{help collect export} (same basename as the table, or a {cmd:<link>} already in
the table HTML) is inlined the same way. Scripts are dropped.
Table and CSS files may be given as absolute or relative paths; they only need
to exist. Image paths in {cmd:![ ](...)} and {cmd:<img>} tags are left as written
unless {opt embed} is used; then {cmd:markdown, embedimage} accepts Windows
absolute paths (e.g. {cmd:D:/...}) and encodes them as Base64.
Figure {cmd:src} attributes keep the path as written when it is absolute, or when a
relative path resolves from the report HTML folder. If a relative
{cmd:<img>} path would not work from that folder, it is
replaced by the file's absolute path so the browser can load it.
You may combine {opt embed} with {opt bundle}/{opt zip()}, but a successful
{opt embed} already inlines the report CSS and figure files.

{phang}
{opt zip(filename|.)} first performs {opt bundle}, then creates a zip archive with Stata's
{help zipfile} command so you can share one file with colleagues. Use {cmd:zip(.)} (or
{cmd:zip(auto)}) to name the archive after the HTML file (e.g., {bf:report.html} →
{bf:report.zip} in {bf:ROOT}). A custom path/name is also allowed, e.g.
{cmd:zip("delivery/report_v1.zip")}.

{pmore2}
Note: If you used {opt mathjax}, MathJax is still loaded from a CDN, so formulas
need internet access when viewing the unzipped HTML. The same applies to
highlight.js in {opt cleancode} HTML reports.


{dlgtab:Cleaning modes}

{phang}
{opt clean} activates the clean output variant, keeping only headings starting with #, <img> tags,
<iframe> tags, and Markdown narrative blocks marked with {cmd:/**} ... {cmd:**/}.
Removes all code and output. May not be combined with {opt cleancode}.

{phang}
{opt cleancode} activates code-only mode. Stata already echoes commands in the log
(lines beginning with {cmd:.}, with continuations beginning with {cmd:>}). This option
keeps those command lines and drops command output. Lines that insert figures/tables
({cmd:<img>}, {cmd:<iframe>}) are also kept. No separate do-file is required, so the
report always matches the log that was actually run.
When {opt html()} is specified, {cmd:tohtml} automatically injects
{browse "https://highlightjs.org/":highlight.js} so {cmd:```stata} blocks are
syntax-highlighted in the HTML (CDN; internet access is required when viewing).
There is no option to turn this off. {opt clean} and {opt cleancode} may not be
combined.

{pmore2}
This mode is suitable for teaching materials or technical documentation that show
commands together with figures and tables, without lengthy output.


{dlgtab:Figure options}

{phang}
{opt width(string)} sets the default width for all images. Only effective when processing a directory.

{phang}
{opt height(string)} sets the default height for all images. Only effective when processing a directory.

{phang}
{opt zoom(string)} sets the default zoom level for all images. Only effective when processing a directory.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage: same-stem Markdown and HTML ({bf:analysis.md}, {bf:analysis.html}){p_end}
{phang2}{cmd:. tohtml "analysis.log", replace}{p_end}

{pstd}Choose a different HTML name (Markdown follows it unless {opt md()} is set){p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report.html") replace}{p_end}

{pstd}Bundle resources into css/figures/tables under the HTML folder{p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report/report.html") bundle replace}{p_end}

{pstd}Self-contained HTML: Base64 images and inlined HTML tables{p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report.html") embed replace}{p_end}

{pstd}Scroll a wide or tall inlined table (defaults are {bf:100%} × {bf:80vh}){p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report.html") tabwidth(100%) tabheight(80vh) replace}{p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report.html") tabheight(400) replace}{p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report.html") tabheight(none) replace}{p_end}

{pstd}Bundle and create a zip archive for sharing{p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report/report.html") zip(.) replace}{p_end}

{phang2}{cmd:. tohtml "analysis.log", html("report/report.html") zip("report_v1.zip") replace}{p_end}

{pstd}Use GitHub style{p_end}
{phang2}{cmd:. tohtml "analysis.log", html("analysis.html") replace}{p_end}

{pstd}Use custom CSS (optionally with MathJax){p_end}
{phang2}{cmd:. tohtml "analysis.log", html("analysis.html") css("mystyle.css") mathjax replace}{p_end}

{pstd}Specify output file names{p_end}
{phang2}{cmd:. tohtml "analysis.log", md("report.md") html("report.html") replace}{p_end}

{pstd}Omit {opt md()}: Markdown defaults to the HTML basename{p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report.html") replace}{p_end}
{phang2}{cmd:→ writes report.md and report.html}{p_end}

{pstd}Minimal mode: Keep only headings and figures/tables{p_end}
{phang2}{cmd:. tohtml "analysis.log", clean html("analysis_clean.html") replace}{p_end}

{pstd}Code-only mode: Keep commands from the log (drop output){p_end}
{phang2}{cmd:. tohtml "analysis.log", cleancode html("report.html") replace}{p_end}

{pstd}Process entire directory{p_end}
{phang2}{cmd:. tohtml "output/", html("report.html") zoom(80%) replace}{p_end}


{title:Complete workflow example}

{pstd}1. Create a do-file with ishere markers (text log recommended){p_end}
{phang2}{cmd:. * ---- analysis.do ----}{p_end}
{phang2}{cmd:. capture log close}{p_end}
{phang2}{cmd:. log using "analysis.log", replace text}{p_end}
{phang2}{cmd:. ishere # Data Analysis Report}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. ishere ## Data Description}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. describe}{p_end}
{phang2}{cmd:. summarize price mpg weight}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. ishere ## Regression Analysis}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. regress price mpg weight}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. ishere ## Visualization}{p_end}
{phang2}{cmd:. scatter price mpg}{p_end}
{phang2}{cmd:. graph export "scatter.png", replace}{p_end}
{phang2}{cmd:. ishere fig using "scatter.png", zoom(80%)}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. log close}{p_end}

{pstd}2. Generate the HTML report{p_end}
{phang2}{cmd:. tohtml "analysis.log", html("report.html") replace}{p_end}

{pstd}
SMCL logs are also accepted: if the input is {bf:.smcl} (or begins with {cmd:{c -(}smcl{c )-}}),
{cmd:tohtml} automatically runs {help translate} with translator {cmd:smcl2log} before
processing. 


{title:Remarks}

{pstd}
{bf:Stata code fences}: Opening Markdown fences for Stata commands are written as
{cmd:```stata} (Typora, GitHub, and Stata {cmd:markdown} all recognize this).
Log-header fences remain {cmd:```text}. The default stylesheet {bf:tohtml.css}
styles {cmd:language-stata} blocks (left border and background).
With {opt cleancode} and {opt html()}, highlight.js is also injected so those
blocks receive token-level coloring in the browser.

{pstd}
{bf:MathJax}: Independent of CSS. {cmd:tohtml} injects the MathJax library only
when equation delimiters are found ({cmd:$...$}, {cmd:$$...$$}, {cmd:\(...\)},
{cmd:\[...\]}). A lone {cmd:$100} or an escaped {cmd:\$} does not trigger
injection.

{pstd}
{bf:Log header}: In default mode the Stata text-log header ({cmd:name:}, {cmd:log:},
{cmd:log type:}, {cmd:opened on:}) is wrapped in a {cmd:```text} fence so Markdown
does not treat the dash line as a horizontal rule. {opt clean} and {opt cleancode}
drop the header.

{pstd}
{bf:Log formats}: Prefer text logs ({cmd:log using ..., text}). SMCL logs are detected and
converted automatically via {cmd:translate ..., translator(smcl2log)}.

{pstd}
{bf:File paths}: Backslashes are converted to forward slashes. Figure and table
paths are kept as written (absolute or relative).
{cmd:tohtml} locates those files from the input log's directory (walking up
parent folders), so you do not need to {cmd:cd} to the log folder or the
project root before calling {cmd:tohtml}.
In the default HTML report, a relative {cmd:<iframe>} / {cmd:<img>} path is
kept when it resolves from the HTML folder; otherwise it is replaced by the
file's absolute path. {opt embed} does not rewrite image, table, or CSS paths
(Windows absolute image paths are passed through to {cmd:markdown, embedimage}).
{opt zip()} / {opt bundle} copy resources into {bf:css/}, {bf:figures/}, and
{bf:tables/} and rewrite every local link to a package-relative path.

{pstd}
{bf:Processing directories}: When the input argument is a directory rather than a file, {cmd:tohtml} automatically
scans for all HTML files starting with "table" and all image files starting with "figure", generating a
temporary Markdown file containing these resources.

{title:Dependencies}

{pstd}{help tohtml} requires two dependencies: {help moremata} and {help fs}. These can be installed as follows{p_end}
{phang2}{cmd:.} {bf:{stata "ssc install moremata"}}{p_end}
{phang2}{cmd:.} {bf:{stata "ssc install fs"}}{p_end}

{pstd}
{bf:AI agents}: copy {bf:skills/stata-tohtml/} from the package source into
the agent's skills folder so it can write {cmd:ishere}/{cmd:tohtml} do-files
and run them to HTML.


{title:Author}

{pstd}
Kerry Du{break}
School of Management{break}
Xiamen University{break}
kerrydu@xmu.edu.cn

{pstd}
Huanyu Jia{break}
School of Business{break}
Zhengzhou University{break}
jiahuanyu@zzu.edu.cn

{title:See also}
{psee}

Help:  {help ishere}, {help markdown}, {help log}, {help translate}
