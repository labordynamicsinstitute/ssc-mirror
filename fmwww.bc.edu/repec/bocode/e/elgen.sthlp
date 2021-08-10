{smcl}
{* 14feb2014}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "C-function spec" "cfuncspec"}{...}
{vieweralsosee "tstats" "tstats"}{...}
{vieweralsosee "collapsel" "collapsel"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:elgen} {hline 2} generate variables
 
{title:Syntax}

{pmore}{cmd:elgen} [{it:{help cfuncspec:C-function spec}}] {ifin}, [{cmd:by(}{it:{help varelist}}{cmd:)}]


{title:Description}

{pstd}{cmd:elgen} adds a set of variables to the current dataset {hline 1} especially variables holding summary statistics for groups of observations.


{title:Options}

{phang}{cmd:by(}{it:{help varelist}}{cmd:)} specifies the groups over which to calculate the statistics.

