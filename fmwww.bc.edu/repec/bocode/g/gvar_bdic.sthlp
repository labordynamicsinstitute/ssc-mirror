{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{vieweralsosee "gvar bconv" "help gvar_bconv"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar bforecast" "help gvar_bforecast"}{...}
{viewerjumpto "Syntax" "gvar_bdic##syntax"}{...}
{viewerjumpto "Description" "gvar_bdic##description"}{...}
{viewerjumpto "Remarks" "gvar_bdic##remarks"}{...}
{viewerjumpto "Examples" "gvar_bdic##examples"}{...}
{viewerjumpto "Stored results" "gvar_bdic##results"}{...}
{viewerjumpto "Options" "gvar_bdic##options"}{...}
{title:Title}

{phang}
{bf:gvar bdic} {hline 2} deviance information criterion for the sampled model


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar bdic} [{cmd:,} {opt nosum:mary}]

{pstd}
{helpb gvar_bayes:gvar bayes} and {helpb gvar_solve:gvar solve} must have run
first.


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar bdic} evaluates the global likelihood at every retained draw and
reports

{p 8 8 2}{it:Dbar} {space 3}= {it:-2 mean_s logL(theta_s)}{space 8}posterior mean deviance{p_end}
{p 8 8 2}{it:pD} {space 5}= {it:Dbar - D(theta_bar)}{space 10}effective parameters{p_end}
{p 8 8 2}{it:DIC} {space 4}= {it:Dbar + pD}{p_end}

{pstd}
The likelihood is the reduced form itself,
{it:Y_t = d0 + d1 t + sum_l F_l Y_{t-l} + eta_t}, with
{it:Sigma = G0^-1 S G0^-1'} and {it:S} block diagonal in the country
covariances.


{marker options}{...}
{title:Options}

{phang}
{opt nosummary} suppresses the report. Everything still appears in {cmd:r()},
which is the usual way to compare two models:

        {cmd:. gvar bdic, nosummary}
        {cmd:. scalar dic_a = r(dic)}

{pstd}
There are no other options. DIC has no tuning parameters -- it is a function of
the chain that is already in memory.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Only differences mean anything.} The level carries the arbitrary constant of
the Gaussian density, so a DIC of {it:-86013} is not "good" or "bad" on its own.
Compare models fitted to the {bf:same} data, the same lag orders and the same
variables. A DIC computed on a different sample is not comparable, and nothing
in the number will tell you that -- {cmd:gvar bdic} cannot check it either.

{pstd}
{bf:Do not read pD as a measure of prior tightness}, in either direction. It is
concentration times curvature: tightening the prior concentrates the posterior,
which lowers pD, and simultaneously pushes it into a steeper region of the
likelihood, which raises pD. The two oppose, so nothing guarantees which wins.
Measured on the 26-unit demo with {opt prmean(0)}, 150 draws, seed 20260811,
under the {bf:earlier} {opt gendog(poil=usa)} specification: K = 136 with a lag
order of 2 and 37128 parameters. The shipped example now uses
{opt dominant(poil pmat pmetal)}, which raises the lag order to 3 and the
parameter count to 55624, so {bf:the levels below no longer match what the
command prints} -- at {it:lambda1} = 0.1 it now reports Dbar near -84567 rather
than -86444. Only the shape of the relationship carries over.

{p 8 8 2}{it:lambda1}{space 5}{it:Dbar}{space 9}{it:pD}{space 6}{it:pD/count}{p_end}
{p 8 8 2}{space 2}0.5{space 5}-89403.7{space 6}1305.2{space 7}0.035{p_end}
{p 8 8 2}{space 2}0.2{space 5}-88301.6{space 7}698.5{space 7}0.019{p_end}
{p 8 8 2}{space 2}0.1{space 5}-86443.5{space 7}428.8{space 7}0.012{space 3}(the default){p_end}
{p 8 8 2}{space 2}0.05{space 4}-80996.2{space 8}-73.9{space 6}-0.002{p_end}
{p 8 8 2}{space 2}0.01{space 4}-42151.1{space 7}-926.0{space 6}-0.025{p_end}

{pstd}
On this demo pD falls steadily as the prior tightens and goes {bf:negative}
below about {it:lambda1 = 0.1}, while {it:Dbar} rises. That is one dataset and
five points, not a theorem -- the useful conclusion is the negative one: a
smaller pD does not mean a tighter prior, or a looser one.

{pstd}
{bf:When to distrust it.} A negative pD is the clearest signal, and on the table
above it appears at {opt lambda1(0.05)} and tighter -- so this is a warning that
fires on the shipped demo, not a theoretical caveat. pD is the {it:effective}
number of parameters; a negative one is impossible as a count and means the
normal approximation behind DIC has broken down. At {it:lambda1 = 0.01} the
coefficients are pinned near zero while the data sit around 4.8, so the model is
badly misspecified rather than parsimonious. {cmd:gvar bdic} flags a negative pD,
and separately flags pD above half the actual count, which is the same failure
from the other side.

{pstd}
{bf:These figures were re-measured.} An earlier version of this table was
computed before {it:Sigma} was corrected from {it:inv(L) D inv(L)'} to
{it:L D L'}. Sigma enters the deviance twice, through {it:log|Sigma|} and
through the quadratic form, so the old table was out by up to 147% on
{it:Dbar} -- and it was U-shaped, which is why this section used to assert a
minimum near {it:lambda1 = 0.2}. The mechanism argument survived the correction;
the shape did not. See {helpb gvar_methods:gvar methods}.

{pstd}
{bf:On this data DIC prefers the loosest prior}, falling monotonically from
{it:+122130} at {it:lambda1 = 0.01} to {it:-73998} at {it:0.5}. That is
substantive: the data want flexibility, and the heavily shrunk models are
misspecified. It is also a reminder that DIC ranks {it:fit adjusted for
complexity}, not economic plausibility.

{pstd}
{bf:theta_bar follows the source, oddly.} {it:BGVAR.R}:1053-1055 averages
{it:A}, {it:S} and {it:G0^-1} {bf:separately} across draws and then combines them
as {it:G0^-1_mean S_mean G0^-1_mean'}. That is not the mean of {it:Sigma} --
{it:E[G0^-1 S G0^-1']} is not {it:E[G0^-1] E[S] E[G0^-1]'} -- and it is not the
model {helpb gvar_solve:gvar solve} holds either, since stacking is nonlinear in
the country coefficients. It is reproduced because DIC gets compared across
papers and a different {it:theta_bar} gives a different pD.

{pstd}
{bf:A draw whose covariance is singular is skipped, not zeroed.} A likelihood
computed from a singular covariance is not a likelihood. Skipped draws are
counted and reported; if the count is large, check
{helpb gvar_bconv:gvar bconv} and the eigenvalue trim before reading the DIC.

{pstd}
{bf:Not the same as what gvar estimate reports.} That gives a log likelihood,
AIC and SBC {it:per country model} from reduced-rank ML. This is one number for
the whole stacked system, and the two cannot be compared.

{pstd}
{bf:On reading the source.} {it:utils.R}:1446 has a {cmd:.globalLik} call
commented out inside {cmd:.gvar.stacking.wrapper}, which looks like the dead
joint sampler at {it:BVAR_linear.cpp}:413. It is not the same situation:
{it:BGVAR.R}:974 and 1051 call a live exported {cmd:globalLik()} and
{it:BGVAR.R}:1012 documents {cmd:dic()}. The commented line is only a storage
shortcut. Commented code near a live call path needs the call path checked
before the comment is trusted.


{marker examples}{...}
{title:Examples}

{pstd}
Fit, check the chains, solve, then score:{p_end}
{phang2}{cmd:. gvar bayes, prior(mn) prmean(0) noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}
{phang2}{cmd:. gvar bconv}{p_end}
{phang2}{cmd:. gvar solve}{p_end}
{phang2}{cmd:. gvar bdic}{p_end}

{pstd}
Comparing two priors on the same data, which is the only comparison DIC
supports:{p_end}
{phang2}{cmd:. gvar bayes, prior(mn) prmean(0) noeigentrim draws(2000) burnin(2000) seed(1)}{p_end}
{phang2}{cmd:. gvar solve, nosummary}{p_end}
{phang2}{cmd:. gvar bdic, nosummary}{p_end}
{phang2}{cmd:. scalar dic_mn = r(dic)}{p_end}
{phang2}{cmd:. gvar bayes, prior(ssvs) prmean(0) noeigentrim draws(2000) burnin(2000) seed(1)}{p_end}
{phang2}{cmd:. gvar solve, nosummary}{p_end}
{phang2}{cmd:. gvar bdic, nosummary}{p_end}
{phang2}{cmd:. display "Minnesota " dic_mn "   SSVS " r(dic)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar bdic} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(dbar)}}posterior mean deviance{p_end}
{synopt:{cmd:r(pd)}}effective number of parameters{p_end}
{synopt:{cmd:r(dic)}}{it:Dbar + pD}{p_end}
{synopt:{cmd:r(nparam)}}actual parameter count{p_end}
{synopt:{cmd:r(nfailed)}}draws skipped for a singular covariance{p_end}
{synopt:{cmd:r(draws)}}draws in the chain{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
BGVAR {it:R/BGVAR.R} {cmd:dic()} and the exported {cmd:globalLik()};
{it:src/helper.cpp} {cmd:dmvnrm_arma_fast}. Spiegelhalter, D. J., Best, N. G.,
Carlin, B. P. and van der Linde, A. (2002), Bayesian measures of model
complexity and fit, {it:JRSS B} 64, 583-639.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
