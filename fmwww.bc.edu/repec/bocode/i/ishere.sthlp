{smcl}
{* *! version 1.0.0  18jan2026}{...}
{vieweralsosee "tohtml" "help tohtml"}{...}
{vieweralsosee "markdown" "help markdown"}{...}
{viewerjumpto "Syntax" "ishere##syntax"}{...}
{viewerjumpto "Description" "ishere##description"}{...}
{viewerjumpto "Options" "ishere##options"}{...}
{viewerjumpto "Examples" "ishere##examples"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{cmd:ishere} {hline 2}}Insert markers in log files for report generation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:Mode 1: Placeholder syntax (for marking flags for markdown generation)}

{p 8 16 2}
{cmd:ishere}

{p 8 16 2}
{cmd:ishere} {cmd:```}

{p 8 16 2}
{cmd:ishere} {it:# heading text}

{p 8 16 2}
{cmd:ishere} {cmd:/*}

{p 8 16 2}
{cmd:ishere} {cmd:*/}

{p 8 16 2}
{cmd:ishere} {cmd: tab[other_text]}

{p 8 16 2}
{cmd:ishere} {cmd: fig[other_text]}


{pstd}
{bf:Mode 2: Markdown insertion syntax (for embedding figures and tables)}

{pstd}
Insert figure

{p 8 16 2}
{cmd:ishere} {cmd:fig}|{cmd:figure} {cmd:using} {it:filename} 
[{cmd:,} {opt zoom(string)} {opt height(string)} {opt width(string)}]


{pstd}
Insert table

{p 8 16 2}
{cmd:ishere} {cmd:tab}|{cmd:table} {cmd:using} {it:filename}
[{cmd:,} {opt height(string)} {opt width(string)}]


{pstd}
Display local or scalar values

{p 8 16 2}
{cmd:ishere} {cmd:display} {it:expression}


{marker description}{...}
{title:Description}

{pstd}
The name {cmd:ishere} draws inspiration from a long-standing convention in academic and technical writing: 
the humble placeholder note like "Table 1 goes here" or "Figure inserted here." For decades, researchers 
have used such phrases to mark where results should appear in a manuscript—especially when figures and 
tables are generated separately from the main text.

{pstd}
In the world of reproducible research with Stata, a similar need arises: how do you tell your analysis 
script, "Put the graph right here in the log," so that it can later be cleanly converted into a polished 
report? The answer is {cmd:ishere}.

{pstd}
Literally meaning "insert something here, on this line, in this do-file," {cmd:ishere} acts as a dynamic, 
executable placeholder. It is a dual-purpose command designed to work with {help tohtml} for generating 
formatted HTML reports from Stata log files.

{pstd}
{bf:Mode 1: Placeholder mode}

{pmore}
In this mode, {cmd:ishere} acts as a passive marker in your log file. When you run it during your Stata session, 
it produces no visible output but leaves markers in the log that {help tohtml} later uses to structure your report.
This mode is used for:

{pmore2}
- Marking code block boundaries: {cmd:ishere} or {cmd:ishere ```}

{pmore2}
- Inserting markdown headings: {cmd:ishere # Main Title} or {cmd:ishere ## Subtitle}

{pmore2}
- Marking text blocks: {cmd:ishere /*} ... {cmd:ishere */}

{pmore2}
- Specifying inserting a table: ishere tab[other_text] 

{pmore2}
- Specifying inserting a figure: ishere fig[other_text] 



{pstd}
{bf:Mode 2: Markdown insertion mode}

{pmore}
In this mode, {cmd:ishere} actively generates markdown code that is printed to the log file. This markdown code 
will be preserved when {help tohtml} processes the log. This mode is used for:

{pmore2}
- Embedding figures: {cmd:ishere fig using "figure1.png"} generates an HTML <img> tag or markdown image syntax

{pmore2}
- Embedding HTML tables: {cmd:ishere tab using "table1.html"} generates an HTML <iframe> tag

{pmore2}
- Embedding Markdown tables: {cmd:ishere tab using "table1.md"} generates markdown table syntax directly

{pmore2}
- Displaying values: {cmd:ishere display} outputs local macros, scalars, or any valid Stata expression to the log

{pmore2}
This mode supports various image formats (PNG, JPG, JPEG, SVG, GIF, BMP, WEBP), HTML tables, and Markdown tables.


{marker options}{...}
{title:Options}

{pstd}
{bf:Options are only available in Mode 2 (markdown insertion syntax)}

{dlgtab:Figure options}

{phang}
{opt zoom(string)} specifies the zoom level for the image, default is 100%. You can specify a percentage 
(e.g., "80%" or "80").

{phang}
{opt height(string)} specifies the image height. Can use any valid CSS dimension unit (e.g., "300px", "50%").

{phang}
{opt width(string)} specifies the image width. Can use any valid CSS dimension unit.


{dlgtab:Table options}

{phang}
{opt height(string)} specifies the iframe height for HTML tables, default is "400px". For Markdown tables, this option is ignored.

{phang}
{opt width(string)} specifies the iframe width for HTML tables, default is "100%". For Markdown tables (.md files), this option is ignored.


{dlgtab:Display syntax}

{pstd}
The {cmd:display} subcommand has no options. It accepts any valid Stata expression and outputs it to the log.
This is primarily used in combination with text blocks ({cmd:ishere /*} ... {cmd:ishere */}) to insert computed 
values into narrative text. The typical workflow is:

{pmore}
1. Run {cmd:ishere display} in your code to output the value

{pmore}
2. Reference it in text blocks using the placeholder syntax {cmd:{c -(}ishere display ...{c )-}}

{pmore}
3. When {help tohtml} processes the log, it automatically replaces placeholders with actual values

{pmore}
{bf:Important}: The {cmd:ishere display} command only affects the {bf:first textcell} ({cmd:ishere /*} ... {cmd:ishere */}) 
that appears {bf:after} the display command in the log file. If you have multiple text blocks, each {cmd:ishere display} 
will only replace placeholders in the immediately following text block, not in later ones.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Mode 1 Examples: Using ishere as placeholder}{p_end}

{pstd}Mark code block boundaries{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. summarize}{p_end}
{phang2}{cmd:. ishere}{p_end}

{pstd}Insert markdown headings{p_end}
{phang2}{cmd:. ishere # Data Analysis Report}{p_end}
{phang2}{cmd:. ishere ## Descriptive Statistics}{p_end}

{pstd}Mark text blocks for narrative content{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * This is explanatory text}{p_end}
{phang2}{cmd:. * It can span multiple lines}{p_end}
{phang2}{cmd:. ishere */}{p_end}

{pstd}{bf:Mode 2 Examples: Inserting markdown code for figures and tables}{p_end}

{pstd}Insert a figure with default settings{p_end}
{phang2}{cmd:. scatter price mpg}{p_end}
{phang2}{cmd:. graph export "figure1.png", replace}{p_end}
{phang2}{cmd:. ishere fig using "figure1.png"}{p_end}

{pstd}Insert a figure with zoom{p_end}
{phang2}{cmd:. ishere fig using "figure1.png", zoom(80%)}{p_end}

{pstd}Insert a figure with custom dimensions{p_end}
{phang2}{cmd:. ishere figure using "figure1.png", height(400px) width(600px)}{p_end}

{pstd}Insert an HTML table{p_end}
{phang2}{cmd:. ishere tab using "table1.html"}{p_end}

{pstd}Insert a table with custom dimensions{p_end}
{phang2}{cmd:. ishere table using "table1.html", height(500px) width(100%)}{p_end}

{pstd}Insert a Markdown table{p_end}
{phang2}{cmd:. ishere tab using "table1.md"}{p_end}

{pstd}Basic usage: Insert value in text block{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. local N = _N}{p_end}
{phang2}{cmd:. ishere display `N'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * The dataset contains {c -(}ishere display `N'{c )-} observations.}{p_end}
{phang2}{cmd:. ishere */}{p_end}

{pstd}Insert formatted numeric values{p_end}
{phang2}{cmd:. summarize price}{p_end}
{phang2}{cmd:. local mean_price = r(mean)}{p_end}
{phang2}{cmd:. ishere display %9.2f `mean_price'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * The average price is ${c -(}ishere display %9.2f `mean_price'{c )-}.}{p_end}
{phang2}{cmd:. ishere */}{p_end}

{pstd}Insert multiple values in text{p_end}
{phang2}{cmd:. regress price mpg weight}{p_end}
{phang2}{cmd:. local r2 = e(r2)}{p_end}
{phang2}{cmd:. local N = e(N)}{p_end}
{phang2}{cmd:. ishere display %5.3f `r2'}{p_end}
{phang2}{cmd:. ishere display `N'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * The model R-squared is {c -(}ishere display %5.3f `r2'{c )-} based on {c -(}ishere display `N'{c )-} observations.}{p_end}
{phang2}{cmd:. ishere */}{p_end}

{pstd}Insert regression coefficients{p_end}
{phang2}{cmd:. regress price mpg weight}{p_end}
{phang2}{cmd:. local coef = _b[mpg]}{p_end}
{phang2}{cmd:. local se = _se[mpg]}{p_end}
{phang2}{cmd:. ishere display %6.2f `coef'}{p_end}
{phang2}{cmd:. ishere display %6.2f `se'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * The coefficient on mpg is {c -(}ishere display %6.2f `coef'{c )-} (SE = {c -(}ishere display %6.2f `se'{c )-}).}{p_end}
{phang2}{cmd:. ishere */}{p_end}

{pstd}Using display with multiple text blocks (each needs its own display command){p_end}
{phang2}{cmd:. regress price mpg weight}{p_end}
{phang2}{cmd:. local r2 = e(r2)}{p_end}
{phang2}{cmd:. ishere display %5.3f `r2'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * First text block: R-squared is {c -(}ishere display %5.3f `r2'{c )-}.}{p_end}
{phang2}{cmd:. ishere */}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. * To use the same value in a second text block, you need another display command:}{p_end}
{phang2}{cmd:. ishere display %5.3f `r2'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * Second text block: The model explains {c -(}ishere display %5.3f `r2'{c )-} of the variance.}{p_end}
{phang2}{cmd:. ishere */}{p_end}

{pstd}{bf:Complete workflow example with display}{p_end}
{phang2}{cmd:. log using "analysis.smcl", replace}{p_end}
{phang2}{cmd:. ishere # Data Analysis Report}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. ishere ## Data Overview}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. local N = _N}{p_end}
{phang2}{cmd:. ishere display `N'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * This analysis uses the automobile dataset containing {c -(}ishere display `N'{c )-} observations.}{p_end}
{phang2}{cmd:. ishere */}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. ishere ## Summary Statistics}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. summarize price mpg weight}{p_end}
{phang2}{cmd:. local mean_price = r(mean)}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. ishere display %9.2f `mean_price'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * The average price is ${c -(}ishere display %9.2f `mean_price'{c )-}.}{p_end}
{phang2}{cmd:. ishere */}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. ishere ## Regression Analysis}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. regress price mpg weight}{p_end}
{phang2}{cmd:. local r2 = e(r2)}{p_end}
{phang2}{cmd:. local coef_mpg = _b[mpg]}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. ishere display %5.3f `r2'}{p_end}
{phang2}{cmd:. ishere display %6.2f `coef_mpg'}{p_end}
{phang2}{cmd:. ishere /*}{p_end}
{phang2}{cmd:. * The regression model has an R-squared of {c -(}ishere display %5.3f `r2'{c )-}.}{p_end}
{phang2}{cmd:. * The coefficient on mpg is {c -(}ishere display %6.2f `coef_mpg'{c )-}.}{p_end}
{phang2}{cmd:. ishere */}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. ishere ## Visualization}{p_end}
{phang2}{cmd:. scatter price mpg}{p_end}
{phang2}{cmd:. graph export "scatter.png", replace}{p_end}
{phang2}{cmd:. ishere fig using "scatter.png", zoom(80%)}{p_end}
{phang2}{cmd:.}{p_end}
{phang2}{cmd:. log close}{p_end}
{phang2}{cmd:. translate analysis.smcl analysis.md, translator(smcl2log) replace}{p_end}
{phang2}{cmd:. tohtml analysis.md, html(analysis.html) replace}{p_end}


{title:Remarks}

{pstd}
{bf:Understanding the two modes:}

{pmore}
Mode 1 (placeholder) produces no visible output during your Stata session - it simply leaves markers in the log file 
that {help tohtml} interprets later. Mode 2 (markdown insertion) actively prints markdown/HTML code to your log, 
which becomes part of the final document.

{pstd}
{bf:Using ishere display for narrative text:}

{pmore}
The {cmd:ishere display} command is designed to work with text blocks ({cmd:ishere /*} ... {cmd:ishere */}) to create 
dynamic narrative text with embedded computed values. The workflow has two steps:

{pmore}
{bf:Step 1}: In your code section, compute values and output them using {cmd:ishere display}:

{pmore2}
{cmd:local r2 = e(r2)}{break}
{cmd:ishere display %5.3f `r2'}

{pmore}
{bf:Step 2}: In your text block, reference the values using placeholder syntax {cmd:{c -(}ishere display ...{c )-}}:

{pmore2}
{cmd:ishere /*}{break}
{cmd:* The model R-squared is {c -(}ishere display %5.3f `r2'{c )-}.}{break}
{cmd:ishere */}

{pmore}
When {help tohtml} processes the log file, it automatically matches the placeholder references with the computed values 
and inserts them into the text. This ensures your narrative text always reflects the current analysis results without 
manual copying or updating.

{pmore}
The {cmd:display} subcommand accepts the same syntax as Stata's regular {help display} command, including format specifiers
like {cmd:%5.3f} for controlling number precision. This allows precise control over how numbers appear in your report text.

{pmore}
{bf:Scope limitation}: Each {cmd:ishere display} command only affects the {bf:first textcell} that appears after it in the log file.
If you need to use the same value in multiple text blocks, you must place an {cmd:ishere display} command before each text block.

{pstd}
{bf:Cross-platform compatibility:}

{pmore}
File paths with backslashes (\) are automatically converted to forward slashes (/) to ensure cross-platform compatibility.

{pstd}
{bf:Workflow:}

{pmore}
The typical workflow is: (1) run your analysis with {cmd:ishere} markers, (2) translate SMCL to markdown, 
(3) use {help tohtml} to process the markdown into a clean HTML report.


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

Help:  {help tohtml}, {help markdown}, {help log}
