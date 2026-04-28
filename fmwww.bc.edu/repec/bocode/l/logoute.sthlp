{smcl}
{* *! version 1.0.1  16jan2026}{...}
{vieweralsosee "logout" "help logout"}{...}
{vieweralsosee "tohtml" "help tohtml"}{...}
{vieweralsosee "ishere" "help ishere"}{...}
{viewerjumpto "Syntax" "logoute##syntax"}{...}
{viewerjumpto "Description" "logoute##description"}{...}
{viewerjumpto "Options" "logoute##options"}{...}
{viewerjumpto "Examples" "logoute##examples"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{bf:logoute} {hline 2}}Automated table conversion to HTML, Markdown, and LaTeX{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 10 6}
{cmdab:logoute}, [{it:options} : {it:command}]

{marker options}{...}
{title:Options}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt save(filename)}}name of output file (without extension){p_end}
{synopt :{opt replace}}overwrite existing file{p_end}
{synopt :{opt html}}output in HTML format{p_end}
{synopt :{opt md}}output in Markdown format{p_end}
{synopt :{opt tex}}output in LaTeX format{p_end}
{synopt :{opt excel}}output in Excel (XML) format{p_end}
{synopt :{opt word}}output in Word (RTF) format{p_end}
{synopt :{opt dec(#)}}force distinct decimal places{p_end}
{synopt :{opt fix(#)}}adjust parsing sensitivity (default 5){p_end}
{synopt :{opt clear}}replace data in memory with captured table{p_end}
{synopt :{opt ishere}}display an iframe snippet for direct {cmd:ishere} embedding{p_end}
{synopt :{opt isheretext(text)}}display custom text after the iframe snippet{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:logoute} is built on top of {cmd:logout} ({cmd:logout.ado}). It keeps the original table-capture workflow from {cmd:logout} and adds direct HTML/Markdown table export, so users can generate publish-ready HTML tables from the same syntax.

{pstd}
It is particularly useful for generating descriptive statistics tables or simple frequency lists that need to be embedded in web reports or LaTeX documents. Compared with the original {cmd:logout}, {cmd:logoute} extends functionality by exporting HTML/Markdown tables directly and is optimized for the {help tohtml} workflow, producing cleaner HTML with proper class attributes for styling.

{pstd}
The HTML/Markdown output from {cmd:logoute} is compatible with {help ishere} for embedding in markdown documents. After generating a table with {cmd:logoute}, use {cmd:ishere tab using "filename.html"} to embed the table in your markdown report.


{marker options_details}{...}
{title:Detailed Options}

{phang}
{opt save(filename)} specifies the name of the output file. Extensions like .html or .tex are automatically appended based on the chosen format options.

{phang}
{opt replace} permits overwriting existing files.

{phang}
{opt html} generates a standard HTML table. This is ideal for inclusion in Markdown reports or websites.

{phang}
{opt md} generates a Markdown table. This is suitable for direct use in markdown editors, GitHub, or further conversion using tools like pandoc.

{phang}
{opt tex} generates a LaTeX tabular environment.

{phang}
{opt fix(#)} specifies the sensitivity for the parser when converting plain text output to columns. Lower numbers (e.g., 1) are stricter, while higher numbers are looser. The default usually works well for standard Stata output.

{phang}
{opt ishere} prints an iframe HTML snippet to the Results window after exporting the table. This is convenient when you want to paste/embed the table immediately with the {help ishere} workflow.

{phang}
{opt isheretext(text)} prints custom text after the iframe snippet. It is typically used together with {opt ishere} to add notes or markdown-friendly guidance in the log.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:1. Basic Descriptive Statistics to Markdown}

{pstd}
Calculate summary statistics for auto data and save as Markdown table:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. logoute, save("mytable") replace md : tabstat price mpg weight, s(mean sd min max)}{p_end}

{pstd}
{bf:2. Basic Descriptive Statistics to HTML}

{pstd}
Calculate summary statistics for auto data and save as HTML table:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. logoute, save("mytable") replace html : tabstat price mpg weight, s(mean sd min max)}{p_end}

{pstd}
{bf:3. Frequency Table to LaTeX}

{pstd}
Export a frequency tabulation of foreign cars to LaTeX:

{phang2}{cmd:. logoute, save("freq_table") replace tex : tabulate foreign}{p_end}

{pstd}
{bf:4. Workflow Integration}

{pstd}
Using {cmd:logoute} as part of a Markdown report generation:

{phang2}{cmd:. log using report.md, replace text}{p_end}
{phang2}{cmd:. logoute, save("descriptives") replace html : tabstat price mpg, s(n mean)}{p_end}
{phang2}{cmd:. ishere tab using "descriptives.html"}{p_end}
{phang2}{cmd:. tohtml report.md, saving(final_report.md) html(final_report.html)}{p_end}


{title:Author}

{pstd}
Kerry Du{break}
School of Management{break}
Xiamen University{break}
kerrydu@xmu.edu.cn{break}
{break}

{pstd}
Huanyu Jia{break}
School of Business{break}
Zhengzhou University{break}
jiahuanyu@zzu.edu.cn{break}
{break}

{pstd}
Based on logout by Roy Wada (roywada@hotmail.com).{break}
Enhanced for markdown workflows, and supports HTML/Markdown file export.{break}
