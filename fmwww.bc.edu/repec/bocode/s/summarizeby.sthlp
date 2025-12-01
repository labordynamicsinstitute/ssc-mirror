{smcl}
{* *! version 1.2.0  20nov2025  I I Bolotov}{...}
{viewerjumpto "Syntax" "summarizeby##syntax"}{...}
{viewerjumpto "Description" "summarizeby##description"}{...}
{viewerjumpto "Options" "summarizeby##options"}{...}
{viewerjumpto "Examples" "summarizeby##examples"}{...}
{viewerjumpto "Author" "summarizeby##author"}{...}
{title:Title}

{phang}
{bf:summarizeby} {hline 2} Use {cmd:statsby} functionality with 
{cmd:summarize} across all variables without specifying a colon command

{marker syntax}{...}
{title:Syntax}

{p 8 8 2}
{cmd:summarizeby}
[{it:exp_list}]
[{it:{help weight}}]
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt clear}}replace data in memory with results{p_end}
{synopt:{opt sa:ving(filename)}}save results to a Stata dataset{p_end}
{synopt:{opt d:etail}}pass {cmd:detail} to {cmd:summarize}{p_end}
{synopt:{opt mean:only}}pass {cmd:meanonly} to {cmd:summarize}{p_end}
{synopt:{opt f:ormat}}pass {cmd:format} to {cmd:summarize}{p_end}
{synopt:{it:*}}additional {cmd:statsby} options{p_end}
{synoptline}

{pstd}
Either {opt clear} or {opt saving()} must be specified.

{marker description}{...}
{title:Description}

{pstd}
{cmd:summarizeby} automates the use of {cmd:statsby} together with 
{cmd:summarize}, applying the statistics to every variable in the dataset. The
program loops over all variables, collects the results returned by 
{cmd:summarize}, and combines them into one dataset.

{pstd}
The syntax mirrors {cmd:statsby}, but without requiring a colon command. 
Instead, {cmd:summarizeby} automatically performs:

{p 12 12 2}
{cmd:statsby} {it:exp_list}: {cmd:summarize varname, ...}

{pstd}
Weights, {cmd:if}, {cmd:in}, expression lists, and all 
{cmd:statsby} options are supported.

{marker options}{...}
{title:Options}

{phang}
{opt clear}  
    loads the resulting dataset into memory. Mutually exclusive with
    {opt saving()}.

{phang}
{opt sa:ving(filename)}  
    saves the results to {it:filename}.dta. Mutually exclusive with
    {opt clear}.

{phang}
{opt d:etail}  
    passes {cmd:detail} to {cmd:summarize} and collects extended statistics.

{phang}
{opt mean:only}  
    passes {cmd:meanonly} to {cmd:summarize}.

{phang}
{opt f:ormat}  
    passes {cmd:format} to {cmd:summarize}.

{phang}
{it:*}  
    any remaining options are passed directly to {cmd:statsby}. These may 
    include {opt by()}, {opt subsets}, {opt total}, {opt trace}, and others.

{marker examples}{...}
{title:Examples}

{pstd}
Load example data:

{cmd}
    . sysuse auto, clear
{txt}

{pstd}
Collect all statistics returned by {cmd:summarize}

{cmd}
    . summarizeby, clear
{txt}

{pstd}
With a {cmd:by()} group

{cmd}
    . summarizeby, clear by(foreign)
{txt}

{pstd}
Detailed example

{cmd}
    . summarizeby, clear d
{txt}

{pstd}
Save selected statistics (mean, sd, min, max)

{cmd}
    . summarizeby mean=r(mean) sd=r(sd) min=r(min) max=r(max), sa(stats)
{txt}

{pstd}
Compare main statistics across two datasets

{cmd}
    . tempfile tmpf
    . preserve
    . summarizeby mean=r(mean) sd=r(sd) if mpg > 20, sa(`tmpf')
    . restore
    . summarizeby mean=r(mean) sd=r(sd), clear
    . append using `tmpf', gen(id)
    . order id
    . label define dataset 0 "full" 1 "reduced"
    . label values id dataset
{txt}

{pstd}
Export results to Excel

{cmd}
    . export excel * using "stats.xlsx", firstrow(variables)
{txt}

{marker author}{...}
{title:Author}

{pstd}
{bf:Ilya Bolotov}{break}
Prague University of Economics and Business{break}
Prague, Czech Republic{break}
{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
Please cite this software as:

{p 8 8 2}
Bolotov, I. (2020). {bf:SUMMARIZEBY}: Stata module to use {cmd:statsby}
functionality with {cmd:summarize}.  
Available from {browse "https://ideas.repec.org/c/boc/bocode/s458870.html"}.
