{smcl}
{* *! version 1.0.0  03jul2026}{...}
{vieweralsosee "xtfmg" "help xtfmg"}{...}
{vieweralsosee "xtfmg fccemg" "help xtfmg_fccemg"}{...}
{vieweralsosee "xtfmg map" "help xtfmg_map"}{...}
{viewerjumpto "Syntax" "xtfmg_breaks##syntax"}{...}
{viewerjumpto "Description" "xtfmg_breaks##description"}{...}
{viewerjumpto "Options" "xtfmg_breaks##options"}{...}
{viewerjumpto "Stored results" "xtfmg_breaks##results"}{...}
{viewerjumpto "Examples" "xtfmg_breaks##examples"}{...}

{title:Title}

{phang}
{bf:xtfmg breaks} {hline 2} per-unit sup-Wald test for a structural break at
an unknown date (Andrews 1993)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtfmg breaks} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt trim(#)}}trimming fraction; default {cmd:trim(0.15)}{p_end}
{synopt :{opt plot}}timeline plot of the estimated break dates by unit{p_end}
{synopt :{opt sav:ing(filename)}}export the break-test table in journal
format ({cmd:.tex}, {cmd:.rtf}/{cmd:.doc}, {cmd:.csv} or {cmd:.txt}){p_end}
{synopt :{opt ti:tle(string)}}caption for the exported table{p_end}
{synopt :{opt rep:lace}}overwrite the export file if it exists{p_end}
{synoptline}
{p 4 6 2}The time variable must be integer-valued (Stata date/time variables
are).{p_end}


{marker description}{...}
{title:Description}

{pstd}
For each panel unit, {cmd:xtfmg breaks} regresses {depvar} on {indepvars}
and a level-shift dummy D_t(tau) = 1{c -(}t > tau{c )-}, computes the Wald
statistic on the dummy for every candidate date tau in the trimmed range,
and reports the supremum together with the date at which it is attained
{hline 2} the sup-Wald test of Andrews (1993) for a single intercept break
at an unknown change point, applied unit by unit as in Table 7 of Guliyev
(2026).

{pstd}
Widely dispersed estimated break dates are the empirical signature of
{it:idiosyncratic} structural change {hline 2} the situation in which the
cross-sectional averages of CCEMG cannot absorb the breaks and the Fourier
augmentation of {helpb xtfmg_fccemg:xtfmg fccemg} and
{helpb xtfmg_fsurmg:xtfmg fsurmg} is required. In the paper's G7
application the dates span three decades (Italy 1974 to Canada 2004).

{pstd}
Significance is assessed against the asymptotic critical values of Andrews
(1993; 2003 corrigendum) for one parameter and 15% trimming: 7.12 (10%),
8.68 (5%), 12.16 (1%).


{marker options}{...}
{title:Options}

{phang}
{opt trim(#)} sets the fraction of the sample trimmed at each end of the
candidate-date range; default 0.15. The tabulated critical values assume 15%
trimming; a note is displayed if a different value is used.

{phang}
{opt plot} draws a timeline of the estimated break dates by unit (graph
{cmd:xtfmg_breaks}), making the dispersion of the break timing immediately
visible.

{phang}
{opt saving(filename)} exports the unit / sup-Wald / break-date table in
publication format chosen by the file extension ({cmd:.tex} with booktabs
rules, {cmd:.rtf}/{cmd:.doc} for Word, {cmd:.csv}, {cmd:.txt}), with the
critical values and the star legend in the table notes {hline 2} the format
of Table 7 in Guliyev (2026). {opt title(string)} sets the caption;
{opt replace} permits overwriting.


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of units{p_end}
{synopt:{cmd:r(cv10)}, {cmd:r(cv5)}, {cmd:r(cv1)}}critical values{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(breaks)}}N x 3 matrix: sup-Wald statistic, estimated break
date, unit id{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtfmg breaks invest mvalue kstock, plot}{p_end}
{phang2}{cmd:. matrix list r(breaks)}{p_end}


{title:References}

{phang}Andrews, D. W. K. 1993. Tests for parameter instability and
structural change with unknown change point. {it:Econometrica} 61: 821-856.
(Corrigendum: {it:Econometrica} 71 (2003): 395-397.){p_end}
{phang}Guliyev, H. 2026. Second-generation heterogeneous panel data model
with individual and common shocks. arXiv:2606.29063.{p_end}


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}
{p_end}
