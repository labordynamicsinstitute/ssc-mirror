{smcl}
{* Copyright 2022 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 28Jun2022}{...}
{cmd:help sdindexplot}
{hline}

{title:Title}

{p2colset 5 17 23 2}{...}
{p2col:{hi:sdindexplot} {hline 2}}Graph sequences{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:sdindexplot} {it: varlist} (min=2) [if] [in] {cmd:,} {it:options} [options] 

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Optional}
{synopt :{opt by(string)}} Graph by varlist, allows options. {p_end}
{synopt :{opt *}} Accepts many graph options. {p_end}
{synoptline} {p2colreset}{...}



{title:Description}

{pstd}{cmd:sdindexplot} takes a set of sequences described by {it:varlist} in
wide format and graphs them, with one row per sequence. This is often called an indexplot.

{pstd}The state variable must be enumerated from 1 upwards. Cases with
missing values on any of the state or {cmd:by} variables are dropped.


{pstd}{cmd:sdindexplot} is built on Ben Jann's {cmd:heatplot}. You can install this by 
{cmd:ssc install heatplot}. The command thus has access to the power of {cmd:heatplot} and the related packages {cmd:palettes} and {cmd:colrspace}.     

{title:Author}

{pstd}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{phang}{cmd:. sdindexplot state1-state72, by(sex, legend(off))}{p_end}
{phang}{cmd:. sdindexplot state1-state72, by(sex) color(tableau)}{p_end}

