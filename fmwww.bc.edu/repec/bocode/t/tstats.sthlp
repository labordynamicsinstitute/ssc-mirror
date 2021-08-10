{smcl}
{* 1may2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "C-function spec" "cfuncspec"}{...}
{vieweralsosee "collapsel" "collapsel"}{...}
{vieweralsosee "tfreq" "tfreq"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:tstats} {hline 2} Table of statistics
 
{title:Syntax}

{pmore}{cmd:tstats} [{it:{help cfuncspec:C-function spec}}] {ifin}, [{it:options}]

{synoptset 17}
{synopthdr}
{synoptline}
{synopt:{opt by(details)}}Defines groups over which statistics are calculated, and their arrangement{p_end}
{synopt:{opt swap}}Display statistics down rows, instead of across columns{p_end}
{synopt:{opt nest}}Display statistics under variable names{p_end}

INCLUDE help tabel_options1


{title:Description}

{pstd}{cmd:tstats} calculates and displays tables of statistics.

{pstd}If you specify {it:{help cfuncspec:C-function spec}} using {hi:vars-by-funcs} syntax (which includes specifying {ul:no} main parameter), {cmd:tstats} will (by default) create a table of vars X stats.


{title:Options}

{phang}{opt by(details)} {hline 2} The full syntax is:

{phang3}{cmd:by(}{it:{help varelist}} [{cmd:,} {opt f:irstvar} {opt l:astvar} {opt o:verall} {opt c:olumns} ]{cmd:)}

{pmore}{cmd:by(}{it:{help varelist}}{cmd:)} works as you'd expect: partitioning the dataset before calculating statistics for each part.

{pmore}Understanding {it:firstvar} and {it:lastvar} to be the first and last variables in {cmd:by(}{it:{help varelist}}{cmd:)}:

{phang3}{opt f:irstvar} {bf:adds} statistics {opt by(firstvar)}{p_end}
{phang3}{opt l:astvar} {bf:adds} statistics {opt by(lastvar)}{p_end}
{phang3}{opt o:verall} {bf:adds} overall statistics (ie, without {opt by()}){p_end}

{phang3}{opt c:olumns} causes {it:lastvar} to be broken out across columns, rather than rows.{p_end}

{phang}{opt swap} re-arranges the display so that {ul:stats} are row-headings rather than column-headings. With {hi:vars-by-funcs} syntax, {ul:vars} will become column-headings.

{phang}{opt nest} causes {cmd:tstats} to use the usual stats-nested-in-vars display, rather than the vars X stats display, when {hi:vars-by-funcs} syntax is used.

INCLUDE help tabel_options2n.ihlp

{pmore}Variables from the main parameter and/or the {opt by()} option may be present in the display. When both are present, {it:nl1} governs main parameter variables, and {it:nl2} governs the {opt by()} variables. 

INCLUDE help tabel_options2v.ihlp

{pmore}{it:vl1} governs the body of the table. {it:vl2} governs headings.


INCLUDE help tabel_out2.ihlp

