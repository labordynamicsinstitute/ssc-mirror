{smcl}
{* *! version 1.0.0  08jul2026}{...}
{vieweralsosee "totimpact" "help totimpact"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "totimpact_postestimation##syntax"}{...}
{viewerjumpto "Description" "totimpact_postestimation##description"}{...}
{viewerjumpto "Options" "totimpact_postestimation##options"}{...}
{viewerjumpto "Remarks" "totimpact_postestimation##remarks"}{...}
{viewerjumpto "Examples" "totimpact_postestimation##examples"}{...}
{viewerjumpto "Author" "totimpact_postestimation##author"}{...}
{title:Title}

{phang}
{bf:totimpact postestimation} {hline 2} Total impact effects after
{cmd:regress}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:totimpact}
{ifin}
[{cmd:,} {it:options}]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opth focus(varlist)}}report only these regressors; default is all of
them{p_end}
{synopt :{opt level(#)}}confidence level for the total effect; default
{cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt :{opt gamma}}also display the co-movement matrix {it:gamma_ji}{p_end}
{synopt :{opt noheader}}suppress the results table{p_end}

{syntab:Graphs}
{synopt :{opt graph}}draw the full dashboard{p_end}
{synopt :{opt plots(types)}}draw only the named plot(s):
{opt compare}, {opt decompose}, {opt gamma}, {opt all}{p_end}
{synopt :{opt name(name)}}name of the resulting graph{p_end}
{synopt :{opt saving(filename)}}save the graph to {it:filename}{cmd:.gph}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
When {cmd:totimpact} is typed with no {it:varlist}, it operates as a
postestimation command on the {cmd:regress} results currently in memory. Every
option of {helpb totimpact:totimpact} is available; the options above are
identical to the standalone ones.


{marker description}{...}
{title:Description}

{pstd}
After {cmd:regress}, {cmd:totimpact} reuses the fitted model rather than asking
you to re-type it. Specifically it reads:

{p2colset 9 30 32 2}{...}
{p2col :{cmd:e(depvar)}}the dependent variable{p_end}
{p2col :{cmd:colnames e(b)}}the regressors (the intercept {cmd:_cons} is
dropped){p_end}
{p2col :{cmd:e(sample)}}the estimation sample; the total impact effects are
computed on exactly the observations {cmd:regress} used{p_end}
{p2colreset}{...}

{pstd}
The full-model error variance needed for the corrected standard errors (see
{helpb totimpact##methods:Methods and formulas}) is recomputed internally from
these variables on {cmd:e(sample)}, so the reported inference is consistent with
the model in memory.


{marker options}{...}
{title:Options}

{pstd}
See {helpb totimpact##options:Options} in {bf:help totimpact}; the meaning of
each option is identical in postestimation mode. In particular, {opt focus()}
still restricts only the {it:report} — the full model in memory (all its
regressors) is what supplies {it:omega} for the standard errors.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:totimpact} postestimation requires an active {cmd:regress} fit. If
{cmd:e(cmd)} is empty, or is not {cmd:regress}, the command stops and asks you to
run {cmd:regress} first (or to supply an explicit {it:varlist}). The estimator in
Pesaran and Smith (2014) is derived for the classical linear regression model,
so {cmd:regress} is the supported estimator; use the standalone form for any
other situation.

{pstd}
Only continuous regressors are supported. Factor-variable ({cmd:i.}, {cmd:c.})
or time-series-operator ({cmd:L.}, {cmd:D.}) terms in the {cmd:regress}
specification are not expanded internally; if you need them, create the
corresponding variables and pass them through the standalone syntax.

{pstd}
{cmd:totimpact} does not disturb the estimation results in memory: after it
runs, the original {cmd:regress} results (and {cmd:e(sample)}) are unchanged and
available to other postestimation commands.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. regress y x1 x2 x3}{p_end}
{phang2}{cmd:. totimpact}{p_end}

{phang2}{cmd:. totimpact, focus(x2 x3) level(90)}{p_end}

{phang2}{cmd:. totimpact, graph name(dash) saving(dash)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane
