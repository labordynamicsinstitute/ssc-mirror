{smcl}
{* *! version 1.0.0 12jun2026}{...}
{vieweralsosee "mmqrtest" "help mmqrtest"}{...}
{vieweralsosee "mmqrtest postestimation" "help mmqrtest_postestimation"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{viewerjumpto "Syntax" "mmqrtest_scalepos##syntax"}{...}
{viewerjumpto "Description" "mmqrtest_scalepos##description"}{...}
{viewerjumpto "Options" "mmqrtest_scalepos##options"}{...}
{viewerjumpto "Examples" "mmqrtest_scalepos##examples"}{...}
{viewerjumpto "Stored results" "mmqrtest_scalepos##results"}{...}
{title:Title}

{phang}
{bf:mmqrtest scalepos} {hline 2} Positivity check for the MM-QR fitted
scale function


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mmqrtest} {cmd:scalepos} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {opt id(panelvar)} {opt q:uantile(numlist)} {opt gr:aph}
{opt name(string)} {opt gen:erate(stub)} {opt noheader}]


{marker description}{...}
{title:Description}

{pstd}
The MM-QR panel model requires Pr({it:delta_i} + {it:X_it'gamma} > 0) = 1
(Machado and Santos Silva 2019, eq. 5): the scale attached to every
observation must be strictly positive, otherwise the standardized residual
{it:U_it} = {it:R_it}/{it:sigma_it} {hline 2} and with it every estimated
quantile {hline 2} is meaningless for that observation.  This is a
{it:diagnostic / violation check} rather than a classical hypothesis test:
the condition is part of the model definition.

{pstd}
{cmd:mmqrtest scalepos} re-runs the MM-QR sequential algorithm, computes
{it:sigma_it} = {it:delta_i} + {it:X_it'gamma} for every in-sample
observation, and reports: the minimum and mean fitted scale, the number and
share of observations with {it:sigma_it} <= 0, the number of cross-section
units affected, and the number of units whose scale intercept
{it:delta_i} is non-positive.  The verdict is {bf:PASS} (no violations) or
{bf:VIOLATION}.

{pstd}
Run this check {it:first}: the other {helpb mmqrtest} subcommands exclude
non-positive-scale observations from {it:U}-based computations and refer
you back here when violations exist.


{marker options}{...}
{title:Options}

{phang}
{opt id(panelvar)}, {opt quantile(numlist)} {hline 2} see {helpb mmqrtest}.

{phang}
{opt graph} draws a histogram of the fitted scale with a reference line at
zero; any mass at or left of the line is a violation.

{phang}
{opt name(string)} names the graph (default {cmd:mmqrt_scalepos}).

{phang}
{opt generate(stub)} saves {it:stub}{cmd:_sigma} (fitted scale) and
{it:stub}{cmd:_delta} (unit scale intercept {it:delta_i}) as new variables.

{phang}
{opt noheader} suppresses the title box (used internally by
{cmd:mmqrtest all}).


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. mmqreg ln_wage tenure ttl_exp, absorb(idcode) quantile(25 50 75)}{p_end}
{phang2}{cmd:. mmqrtest scalepos, graph}{p_end}
{phang2}{cmd:. mmqrtest scalepos, generate(sc)}{p_end}
{phang2}{cmd:. list idcode year sc_sigma if sc_sigma<=0}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}observations used{p_end}
{synopt:{cmd:r(G)}}number of units{p_end}
{synopt:{cmd:r(nneg)}}observations with {it:sigma_it} <= 0{p_end}
{synopt:{cmd:r(pctneg)}}percent of observations with {it:sigma_it} <= 0{p_end}
{synopt:{cmd:r(Gneg)}}units with at least one violation{p_end}
{synopt:{cmd:r(minsigma)}}minimum fitted scale{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(verdict)}}{cmd:PASS} or {cmd:VIOLATION}{p_end}


{title:Author}

{pstd}
Merwan Roudane {hline 2}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{hline 2} {browse "https://github.com/merwanroudane"}
