{smcl}
{* Copyright 2012 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 17Jun2012}{...}
{cmd:help sdchronogram}
{hline}

{title:Title}

{p2colset 5 17 23 2}{...}
{p2col:{hi:sdchronogram} {hline 2}}Graph the time-dependent state distribution{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:sdchronogram} {it: varlist} (min=2) [if] [in] {cmd:,} {it:options} [options] 

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Optional}
{synopt :{opt by(string)}} Graph by varlist, allows options. {p_end}
{synopt :{opt tex:tsize(string)}} Text size of labels. {p_end}
{synopt :{opt prop:ortional}} Graph proportional distribution (useful with by). {p_end}
{synopt :{opt *}} Accepts many graph options. {p_end}
{synoptline} {p2colreset}{...}



{title:Description}

{pstd}{cmd:sdchronogram} is deprecated in favour of {cmd:sdchronoplot}.

{pstd}{cmd:sdchronogram} takes a set of sequences described by {it:varlist} in
wide format and graphs the time-dependent distribution of the state variable. This is sometimes called a
chronogram, or the transversal state distribution.

{pstd}The state variable must be enumerated from 1 upwards. Cases with
missing values on any of the state or {cmd:by} variables are dropped.

{title:Author}

{pstd}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{phang}{cmd:. sdchronogram mon1-mon36, by(sex, legend(off))}{p_end}

