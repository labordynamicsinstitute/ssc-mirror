{smcl}
{* Copyright 2022 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 29Jun2022}{...}
{cmd:help sdchronoplot}
{hline}

{title:Title}

{p2colset 5 17 23 2}{...}
{p2col:{hi:sdchronoplot} {hline 2}}Graph the time-dependent state distribution{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:sdchronoplot} {it: varlist} (min=2) [if] [in] {cmd:,} {it:options} [options] 

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Optional}
{synopt :{opt by(string)}} Graph by varlist, allows options. {p_end}
{synopt :{opt prop:ortional}} Graph proportional distribution (useful with by). {p_end}
{synopt :{opt ydf(real)}} Improve appearance when using {cmd:proportional}. {p_end}
{synopt :{opt *}} Accepts many graph options. {p_end}
{synoptline} {p2colreset}{...}



{title:Description}

{pstd}{cmd:sdchronoplot} takes a set of sequences described by {it:varlist} in
wide format and graphs the time-dependent distribution of the state variable. This is sometimes called a
chronogram or chronoplot, or the transversal state distribution.

{pstd}The state variable must be enumerated from 1 upwards. Cases with
missing values on any of the state or {cmd:by} variables are dropped.

{pstd}The {opt prop:ortional} option shows the percentage distribution
within groups using {cmd:by}. If the group sizes differ a lot, the
smaller groups may be printed with gaps: experiment with the
{cmd:ydf(#)} option, where # is a number a little greater than 1.0 (this
feeds into the {cmd:ydiscrete} option of the {cmd:heatplot} command; high values overstate the size of the top
category, so numbers near 1.0 are preferred).

{pstd}{cmd:sdchronoplot} is built on Ben Jann's {cmd:heatplot}. You can install this by 
{cmd:ssc install heatplot}. The command thus has access to the power of {cmd:heatplot} and the related packages {cmd:palettes} and {cmd:colrspace}.

{title:Author}

{pstd}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{phang}{cmd:. sdchronoplot state1-state72, by(male, legend(off))}{p_end}
{phang}{cmd:. sdchronoplot state1-state72, by(male) color(tableau)}{p_end}

