{smcl}
{* *! version 1.1.0  30mar2026}{...}
{vieweralsosee "tohtml" "help tohtml"}{...}
{vieweralsosee "markstat" "help markstat"}{...}
{viewerjumpto "Syntax" "tomarkstat##syntax"}{...}
{viewerjumpto "Description" "tomarkstat##description"}{...}
{viewerjumpto "Options" "tomarkstat##options"}{...}
{viewerjumpto "Remarks" "tomarkstat##remarks"}{...}
{viewerjumpto "Examples" "tomarkstat##examples"}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:tomarkstat} {hline 2}}Convert Markdown from {help tohtml} to {cmd:markstat} {it:.stmd}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Basic syntax

{p 8 16 2}
{cmd:tomarkstat} {it:filename.md} [{cmd:,} {it:options}]


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt save(stubname|filename)}}path for the output {bf:.stmd}; default is same folder and basename as input{p_end}
{synopt:{opt replace}}overwrite an existing output file{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:filename.md} is required and must be a Markdown file with extension {bf:.md} (typically clean markdown 
produced by {cmd:tohtml} with {opt cleanmd()}). Enclose the path in double quotes if it contains spaces.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tomarkstat} takes cleaned Markdown ({.md}) from {help tohtml} (or similar) and converts it to 
Stata Markdown ({.stmd}) for use with {cmd:markstat using} to render dynamic documents in HTML, PDF, Word, 
and other formats.

{pstd}
Suggested workflow:

{phang2}
1. Mark locations in your do-file with {help ishere}, run the job, and obtain a Stata log ({cmd:.log}) with markers.

{phang2}
2. Run {cmd:tohtml} (for example with {opt cleanmd()}) to produce a clean {.md} file.

{phang2}
3. Run {cmd:tomarkstat} on that {.md} to obtain an {.stmd} file.

{phang2}
4. Run {cmd:markstat using} {it:basename}[, {it:markstat_options}] to build the final document.

{pstd}
The output begins with two fixed header lines recognized by {cmd:markstat}. For fenced code blocks, the 
first {cmd:```} on odd-indexed fence lines is rewritten as {cmd:```s} so {cmd:markstat} treats the block as 
Stata code.


{marker options}{...}
{title:Options}

{phang}
{opt save(stubname|filename)} sets the {.stmd} output path. If no extension is given, {bf:.stmd} is appended; 
if an extension is given it must be {bf:.stmd} or the command issues an error. When omitted, the default is 
{bf:.stmd} in the same directory as {it:filename.md} with the same base name.

{phang}
{opt replace} allows overwriting an existing output file; without it, an error is issued if the target file 
already exists.


{marker remarks}{...}
{title:Remarks}

{pstd}
In Mata, the command roughly applies the following line-wise transformations (details may change with the 
source code):

{phang2}
• Lines starting with {cmd:```}: on fence lines with odd index, the opening {cmd:```} becomes {cmd:```s} 
(to delimit Stata code cells for {cmd:markstat}).

{phang2}
• Lines related to internal handling of {cmd:isheredisplay} (after removing all spaces from the line) are 
dropped.

{phang2}
• Two fixed header lines are inserted at the top so the file is treated as a Stata Markdown document.



{title:Examples}

{pstd}
{bf:{ul:From tohtml clean markdown to stmd}}

{phang2}
{cmd:. tohtml mylog.smcl, cleanmd(myreport_clean.md) replace}

{phang2}
{cmd:. tomarkstat myreport_clean.md, replace}

{pstd}
Then, with {cmd:markstat} installed:

{phang2}
{cmd:. markstat using myreport_clean, strict}

{pstd}
{bf:{ul:Custom output path}}

{phang2}
{cmd:. tomarkstat "E:\work\out_clean.md", save("E:\work\article.stmd") replace}

{pstd}
{bf:{ul:Stub only (appends .stmd)}}

{phang2}
{cmd:. tomarkstat out_clean.md, save(../report/main) replace}


{title:Authors}

{pstd}
Stata_tohtml team; tools for the ishere–tohtml workflow.
{p_end}
