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
{synopt:{opt cleanmd(filename)}}specify output path for cleaned markdown file{p_end}
{synopt:{opt html(filename)}}generate HTML file from cleaned markdown{p_end}
{synopt:{opt replace}}overwrite existing output files{p_end}

{syntab:Style options}
{synopt:{opt css(filename|githubstyle)}}specify CSS file or use GitHub style{p_end}

{syntab:Path options}
{synopt:{opt rpath(directory)}}specify local path of resource files{p_end}
{synopt:{opt wpath(url)}}specify web path (URL) for resource files{p_end}

{syntab:Cleaning modes}
{synopt:{opt clean}}keep only headings, images, and tables{p_end}
{synopt:{opt cleancode(dofile)}}replace log code with code from do-file{p_end}

{syntab:Figure options}
{synopt:{opt width(string)}}set default width for images and tables{p_end}
{synopt:{opt height(string)}}set default height for images and tables{p_end}
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
5. {bf:Multiple modes}: Supports standard mode, minimal mode (clean), and code merging mode (cleancode).


{marker options}{...}
{title:Options}

{dlgtab:Output options}

{phang}
{opt cleanmd(filename)} specifies the output path for the cleaned Markdown file. If not specified,
"_clean" will be appended to the input filename.

{phang}
{opt html(filename)} converts the cleaned Markdown to HTML after processing.
Requires the {cmd:markdown} command to be installed.

{phang}
{opt replace} overwrites existing output files. If this option is not specified and files exist,
the command will error.


{dlgtab:Style options}

{phang}
{opt css(filename|githubstyle)} applies CSS styling to the generated HTML file. You can specify:

{pmore2}
- Path to a custom CSS file

{pmore2}
- {cmd:githubstyle} to use the built-in GitHub-style CSS

{pmore2}
Using this option requires the {opt html()} option. The CSS file will be copied to a css 
subdirectory in the HTML file's location.


{dlgtab:Path options}

{phang}
{opt rpath(directory)} specifies the local path of resource files (images, tables, etc.).
This path will be replaced with the path specified in {opt wpath()}. Used for generating portable reports.

{phang}
{opt wpath(url)} specifies the target path for resource files, typically a relative path (e.g., "./") or URL.
In the generated Markdown/HTML, {opt rpath()} will be replaced with this path.


{dlgtab:Cleaning modes}

{phang}
{opt clean} activates minimal cleaning mode, keeping only headings starting with #, <img> tags, 
<iframe> tags, and content within {cmd:ishere} text blocks. Removes all code and output.

{phang}
{opt cleancode(dofile)} activates code merging mode. Uses the original code from the specified 
do-file to replace code in the log file. The do-file must contain {cmd:ishere} markers to indicate
the positions of figures, tables, and other elements.

{pmore2}
This mode is suitable when you want to display clean code (from do-file) alongside
execution results (from log file) in the report.


{dlgtab:Figure options}

{phang}
{opt width(string)} sets the default width for all images and tables. Only effective when processing a directory.

{phang}
{opt height(string)} sets the default height for all images and tables. Only effective when processing a directory.

{phang}
{opt zoom(string)} sets the default zoom level for all images. Only effective when processing a directory.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage: Convert log file to Markdown{p_end}
{phang2}{cmd:. tohtml "analysis.md", replace}{p_end}

{pstd}Generate both Markdown and HTML{p_end}
{phang2}{cmd:. tohtml "analysis.md", html("analysis.html") replace}{p_end}

{pstd}Use GitHub style{p_end}
{phang2}{cmd:. tohtml "analysis.md", html("analysis.html") css(githubstyle) replace}{p_end}

{pstd}Use custom CSS{p_end}
{phang2}{cmd:. tohtml "analysis.md", html("analysis.html") css("mystyle.css") replace}{p_end}

{pstd}Specify output file names{p_end}
{phang2}{cmd:. tohtml "analysis.md", cleanmd("report.md") html("report.html") replace}{p_end}

{pstd}Path replacement: Generate portable report{p_end}
{phang2}{cmd:. tohtml "analysis.md", html("report.html") ///}{p_end}
{phang2}{cmd:    rpath("C:/Users/myname/analysis/output") wpath("./") replace}{p_end}

{pstd}Minimal mode: Keep only headings and figures/tables{p_end}
{phang2}{cmd:. tohtml "analysis.md", clean replace}{p_end}

{pstd}Code merging mode: Use code from do-file{p_end}
{phang2}{cmd:. tohtml "analysis.md", cleancode("analysis.do") html("report.html") replace}{p_end}

{pstd}Process entire directory{p_end}
{phang2}{cmd:. tohtml "output/", html("report.html") zoom(80%) replace}{p_end}


{title:Complete workflow example}

{pstd}1. Create a do-file with ishere markers{p_end}
{phang2}{cmd:. * ---- analysis.do ----}{p_end}
{phang2}{cmd:. log using "analysis.smcl", replace}{p_end}
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

{pstd}2. Translate SMCL log to Markdown{p_end}
{phang2}{cmd:. translate analysis.smcl analysis.md, translator(smcl2log) replace}{p_end}

{pstd}3. Use tohtml to generate HTML report{p_end}
{phang2}{cmd:. tohtml "analysis.md", html("report.html") css(githubstyle) replace}{p_end}


{title:Remarks}

{pstd}
{bf:Mathematical formulas}: When using the {opt css(githubstyle)} option, {cmd:tohtml} automatically
injects the MathJax library, enabling LaTeX mathematical formulas in Markdown. Use $...$ for inline formulas
and $$...$$ for display formulas.

{pstd}
{bf:File paths}: All backslashes in file paths are automatically converted to forward slashes for cross-platform compatibility.

{pstd}
{bf:Processing directories}: When the input argument is a directory rather than a file, {cmd:tohtml} automatically
scans for all HTML files starting with "table" and all image files starting with "figure", generating a
temporary Markdown file containing these resources.

{pstd}
{bf:Dependencies}: Generating HTML requires Stata's {cmd:markdown} command. Install via:

{phang2}{cmd:. ssc install moremata}{p_end}


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
