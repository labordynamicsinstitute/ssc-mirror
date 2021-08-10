{smcl}
{* 2Nov2006}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "out()" "outopt"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:toview} {hline 2} Send results to viewer
 
{title:Syntax}

{p 8 16 2}
{cmd:toview} [{it:tab-name}] [{cmd:,} {opt a:ppend}] {cmd::} {it:stata_cmd} [; {it:stata_cmd} ]...

{title:Description}

{pstd}{cmd:toview} sends the results of the list of {it:stata-cmd}s to a viewer window. If {it:tab-name} is specified, it will use the tab with that name (if it exists) or open a tab with that name (if it doesn't).

{pstd}If {opt a:ppend} is specified, the results of this {cmd:toview} command will be appended to the relevant viewer tab (either {it:tab-name} if specified, or the default if not).

{title:Examples}

{pstd}{cmd:. toview: des}

{pstd}{cmd:. toview thistab: tabulate v1; tabulate v2; tabulate v3}

{pstd}{cmd:. toview cb: des, s}{break}
{cmd:. toview cb, app: codebook, all header}

