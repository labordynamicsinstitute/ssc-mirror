{smcl}
{* 12nov2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:intercorr} {hline 2} Correlate two sets of values

{title:Syntax}

{pstd}{cmd:intercorr} [{it:corr-stat}] {ifin}, {cmd:a(}{it:{help varelist}}{cmd:)} {cmd:b(}{it:{help varelist}}{cmd:)} [ {it:options} ]

{pmore}where {it:corr-stat} is one of:

{pmore}{cmdab:p:earson} or {cmd:r}{p_end}
{pmore}{cmdab:s:pearman} or {cmd:rho}{p_end}
{pmore}{cmdab:k:endall} or {cmdab:t:au}

{synoptset 17}
{synopthdr:options}
{synoptline}
{synopt :{opt adjust}}adjust the p-values for the number of comparisons{p_end}
{synopt :{opt n}}report {it:n} for each correlation{p_end}
{synopt :{cmdab:st:ars}[{opt (plevels)}]}Report p-level as a number of stars (categories){p_end}
{synopt :{opt nop}}Do not report the numeric p-level{p_end}
{synopt :{opt nost:at}}Do not report the correlation statistic{p_end}
{synopt :{opt save(name)}}Save the correlation data in a mata variable{p_end}

INCLUDE help tabel_options1

{title:Description}

{pstd}{cmd:intercorr} produces a table of correlations, of a-variables vs. b-variables.

{title:Options}

{phang}{opt adjust} multiplies the reported p-values by the number of comparisons; ie, it applies the bonferroni correction.

{phang}{cmdab:st:ars}[{opt (p categories)}] appends a number of stars to the correlation coefficient, depending on the significance level.

{pmore}When one or more categories are supplied, p-levels equal to or lower than the first category will get one star, those equal to or lower than the second category will get two stars, etc.

{pmore}When no parameter is supplied, (ie, {cmd:stars}), the values {cmd:.05 .01 .001} are used.

{phang}{opt save(name)} creates {it:name} as a Mata global {help mf asarray:array}. The array includes the keys {cmd:rowvars}, {cmd:colvars}, {cmd:n}, {cmd:stat}, and {cmd:p} {hline 2} each key retrieving the appropriate data.

INCLUDE help tabel_options2n

INCLUDE help tabel_options2v

INCLUDE help tabel_out2

