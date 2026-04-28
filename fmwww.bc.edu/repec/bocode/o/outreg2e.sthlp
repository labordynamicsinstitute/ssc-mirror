{smcl}
{* *! version 1.0.0  12jan2026}{...}
{vieweralsosee "outreg2" "help outreg2"}{...}
{vieweralsosee "tohtml" "help tohtml"}{...}
{vieweralsosee "ishere" "help ishere"}{...}
{viewerjumpto "Syntax" "outreg2e##syntax"}{...}
{viewerjumpto "Description" "outreg2e##description"}{...}
{viewerjumpto "Options" "outreg2e##options"}{...}
{viewerjumpto "Examples" "outreg2e##examples"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{bf:outreg2e} {hline 2}}outreg2 with direct HTML/Markdown table export{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmdab:outreg2e} [{it:varlist}] [{it:estlist}]
{cmd:using} {it:filename}
[{cmd:,} {it:options}]

{marker options}{...}
{title:Options}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt replace}}overwrite existing file{p_end}
{synopt :{opt append}}append to existing file{p_end}
{synopt :{opt html}}output in HTML format{p_end}
{synopt :{opt md}}output in Markdown format{p_end}
{synopt :{opt tex}}output in LaTeX format{p_end}
{synopt :{opt word}}output in Word format{p_end}
{synopt :{opt excel}}output in Excel format{p_end}
{synopt :{opt title(text)}}add a title above the table{p_end}
{synopt :{opt ctitle(text)}}add column title{p_end}
{synopt :{opt dec(#)}}decimal places for coefficients{p_end}
{synopt :{opt bdec(#)}}decimal places for coefficients (specific){p_end}
{synopt :{opt tdec(#)}}decimal places for t-stats/SE{p_end}
{synopt :{opt rdec(#)}}decimal places for R-squared{p_end}
{synopt :{opt alpha(...)}}significance levels and asterisks{p_end}
{synopt :{opt ishere}}display an iframe snippet for quick embedding after HTML export{p_end}
{synopt :{opt isheretext(text)}}display custom text after the iframe snippet{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:outreg2e} is based on {cmd:outreg2} ({cmd:outreg2.ado}) and keeps the original table-building behavior.

{pstd}
Its main extension is direct HTML/Markdown table output for web/markdown workflows. In other words, {cmd:outreg2e} is intended as a lightweight extension of {cmd:outreg2}, adding HTML/Markdown export while preserving familiar syntax.


{marker options_details}{...}
{title:Detailed Options}

{phang}
{opt replace} overwrites the {it:filename} if it exists.

{phang}
{opt append} adds a new column to the existing table in {it:filename}.

{phang}
{opt html} outputs the table in HTML format, suitable for web embedding or further conversion.

{phang}
{opt md} outputs the table in Markdown format, which can be directly used in markdown editors, GitHub, or converted to other formats using tools like pandoc.

{phang}
{opt tex}, {opt word}, {opt excel} specify the output format. {cmd:outreg2e} defaults to text if unspecified.

{phang}
{opt title(text)} specifies a title for the table.

{phang}
{opt dec(#)} and other formatting options behave identically to {cmd:outreg2}.

{phang}
{opt ishere} prints an iframe HTML snippet to the Results window after file export. This helps embed the generated HTML table quickly in an {help ishere}/{help tohtml} workflow.

{phang}
{opt isheretext(text)} prints custom text after the iframe snippet. It is usually used with {opt ishere}.


{marker remarks}{...}
{title:Remarks}

{pstd}
When using {cmd:outreg2e} with the {opt html} option for Markdown reporting, it is highly recommended to follow the command with {cmd:cmdcell out}.
This ensures that the table embedding code is placed outside of Stata code blocks, allowing the table to render correctly in the browser.

{marker examples}{...}

{title:Examples}

{pstd}
{bf:1. Basic Regression Table to Markdown}

{pstd}
Run a regression and output to a Markdown file:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg weight}{p_end}
{phang2}{cmd:. outreg2e using "regtable", replace md title("OLS Regression Results") dec(3)}{p_end}

{pstd}
{bf:2. Basic Regression Table to HTML}

{pstd}
Run detailed regressions and output to an HTML file for a report:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg weight}{p_end}
{phang2}{cmd:. outreg2e using "regtable", replace html title("OLS Regression Results") sec dec(3)}{p_end}

{pstd}
{bf:4. Multiple Models in LaTeX}

{pstd}
Compare two models in a LaTeX table:

{phang2}{cmd:. regress price mpg}{p_end}
{phang2}{cmd:. outreg2e using "models.tex", replace tex title("Model Comparison") ct("Model 1")}{p_end}

{phang2}{cmd:. regress price mpg weight foreign}{p_end}
{phang2}{cmd:. outreg2e using "models.tex", append tex ct("Model 2")}{p_end}

{pstd}
{bf:5. Workflow with Stored Estimates}

{pstd}
Store models first, then output all at once (efficient):

{phang2}{cmd:. regress price mpg}{p_end}
{phang2}{cmd:. estimates store m1}{p_end}
{phang2}{cmd:. regress price mpg i.foreign}{p_end}
{phang2}{cmd:. estimates store m2}{p_end}
{phang2}{cmd:. outreg2e [m1 m2] using "allmodels.html", replace html title("Combined Results")}{p_end}


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
Based on outreg2 by Roy Wada (roywada@hotmail.com).{break}
Enhanced for markdown workflows, and supports HTML file export.{break}
