{smcl}
{* 23jul2026}{...}
{vieweralsosee "ffrals" "help ffrals"}{...}
{vieweralsosee "ffadf" "help ffadf"}{...}
{vieweralsosee "ffrals library" "help ffrals_hub"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{viewerjumpto "Syntax" "fflm2##syntax"}{...}
{viewerjumpto "Description" "fflm2##description"}{...}
{viewerjumpto "Options" "fflm2##options"}{...}
{viewerjumpto "Examples" "fflm2##examples"}{...}
{viewerjumpto "Stored results" "fflm2##results"}{...}
{title:Title}

{phang}
{bf:fflm2} {hline 2} Two-break LM unit-root test with RALS and RALS2 (factor)
augmentation

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:fflm2} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The series must be {helpb tsset}.{p_end}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt r:als(#)}}{cmd:0} plain two-break LM (default), {cmd:1} RALS, {cmd:2}
RALS with common/group factors{p_end}
{synopt:{opt f:actors(varlist)}}common and group factors (required with {cmd:rals(2)}){p_end}
{synopt:{opt p:max(#)}}maximum augmentation lag (default 8){p_end}
{synopt:{opt ic(#)}}lag selection: 1=AIC, 2=BIC, 3=t-stat (default){p_end}
{synopt:{opt t:rim(#)}}break-location trimming fraction (default 0.10){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:fflm2} implements the Lee-Strazicich (2003) minimum-LM unit-root test with
{it:two} endogenous structural breaks in level and trend. The two break dates are
selected by grid search (minimising the LM statistic). With {cmd:rals(1)} the LM
regression is augmented by the residual-augmented least-squares (RALS) moment
terms for non-normal errors, and with {cmd:rals(2)} by supplied common and group
{opt factors()}.

{pstd}
Unlike {helpb ffrals} and {helpb ffadf}, the two-break LM null distribution is
{it:tabulated}, so {cmd:fflm2} computes {bf:deterministic} p-values by
interpolation: the plain test uses the Lee-Strazicich (2003) critical values
(indexed by the break fractions) and the RALS test uses the Meng-Lee-Tieslau
(2017) rho-squared-indexed critical values with Hansen interpolation. The plain
test therefore reproduces the source GAUSS routine {bf:byte-for-byte}; the RALS
statistic matches to about two decimal places (the residual difference is the
numerical linear algebra of the augmented impulse-dummy design). {cmd:fflm2} is
part of the {helpb ffrals_hub:ffrals} library.

{marker options}{...}
{title:Options}

{phang}{opt rals(#)}, {opt factors(varlist)}: as in {helpb ffrals}.

{phang}{opt pmax(#)}, {opt ic(#)}: the maximum lag (default 8) and lag-selection
rule (3=t-stat, the default, as in the source routine).

{phang}{opt trim(#)}: the trimming fraction for the break search (default 0.10).

{marker examples}{...}
{title:Examples}

{pstd}Plain two-break LM test:{p_end}
{phang2}{cmd:. fflm2 lgdp, rals(0)}{p_end}

{pstd}RALS and factor-augmented versions:{p_end}
{phang2}{cmd:. fflm2 lgdp, rals(1)}{p_end}
{phang2}{cmd:. fflm2 lgdp, rals(2) factors(fcommon fgroup)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:fflm2} is {cmd:rclass} and stores {cmd:r(stat)}, {cmd:r(p)},
{cmd:r(break1)}, {cmd:r(break2)}, {cmd:r(lag)}, {cmd:r(rho2)} (RALS),
{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)} and {cmd:r(N)}. The test rejects for a
statistic {bf:below} the critical value. The break columns report the estimated
break {it:periods} in the units of the time variable.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS {cmd:LM2_trend_break}/{cmd:RALS_LM2}
routines by S. Nazlioglu; the plain test validated byte-for-byte against the GAUSS
output (statistic, breaks, lag and critical values).{p_end}
