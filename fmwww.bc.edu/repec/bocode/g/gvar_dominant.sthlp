{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar solve" "help gvar_solve"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar import" "help gvar_import"}{...}
{viewerjumpto "Syntax" "gvar_dominant##syntax"}{...}
{viewerjumpto "Description" "gvar_dominant##description"}{...}
{viewerjumpto "Options" "gvar_dominant##options"}{...}
{viewerjumpto "The two stages" "gvar_dominant##stages"}{...}
{viewerjumpto "Remarks" "gvar_dominant##remarks"}{...}
{viewerjumpto "Examples" "gvar_dominant##examples"}{...}
{viewerjumpto "Stored results" "gvar_dominant##results"}{...}
{title:Title}

{phang}
{bf:gvar dominant} {hline 2} the dominant unit / global exogenous model


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar dominant} [{cmd:,} {it:options}]

{synoptset 34 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt lag:s(#)}}lag order of the dominant block. Default 2.{p_end}
{synopt:{opt flag:s(#)}}lag order on the feedback variables. Default 1.{p_end}
{synopt:{opt cas:e(#)}}deterministic case, as in {helpb gvar_estimate:gvar estimate}. Default 4.{p_end}
{synopt:{opt rank(#)}}cointegrating rank within the dominant block. Default 1.{p_end}
{synopt:{opt diff}}estimate in differences rather than levels.{p_end}
{synopt:{opt feed:back(varlist)}}the feedback variables, as {it:unit:variable} or plain names.{p_end}
{synopt:{opt weight:s(string)}}weights for building the feedback aggregates.{p_end}
{synopt:{opt trend}}include a linear trend.{p_end}
{synopt:{opt sav:ing(name)}}save the estimated block under this name.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}

{pstd}
The dominant variables must have been declared with
{cmd:gvar setup}{it: ..., }{opt dominant()}. Run {cmd:gvar dominant} after
{helpb gvar_estimate:gvar estimate} and before
{helpb gvar_solve:gvar solve}.


{marker description}{...}
{title:Description}

{pstd}
A global variable -- an oil price, a commodity index -- can be handled two
ways. Attach it to a country block with {cmd:gendog()}, which makes it that
country's endogenous variable and gives it that country's dynamics; or give it
its own block, which is what {cmd:gvar dominant} does. The second is what the
Toolbox calls the {bf:dominant unit}, and it is the honest choice when the
variable is nobody's domestic variable.

{pstd}
The dominant block is {bf:not} a unit. {it:N} stays the number of country
models, because every per-country table in the package expects a beta, an
alpha and a residual matrix per index. {it:K} does grow, so the dominant
variables appear as responses and as shocks in
{helpb gvar_irf:gvar irf}, {helpb gvar_fevd:gvar fevd},
{helpb gvar_spillover:gvar spillover} and {helpb gvar_hd:gvar hd} -- which is
the point of modelling them at all.


{marker stages}{...}
{title:The two stages}

{pstd}
Estimation is in two stages, and the distinction matters because the printed
output of the first is not what feeds the model.

{p 8 12 2}
{bf:Stage I} {hline 1} the dominant block on its own: a univariate AR({it:p})
in levels or differences, or a multivariate VECM when there is more than one
dominant variable, giving the cointegrating vector and the loadings.{p_end}

{p 8 12 2}
{bf:Stage II} {hline 1} a joint OLS regression per equation, on the block's own
lags {bf:and} the lagged feedback variables. This is the stage whose
coefficients enter the GVAR.{p_end}

{pstd}
Stage II {bf:always} runs, even with no feedback variables. The recovered VARX
form pairs stage I's {it:alpha} with stage II's {it:Gamma}; the ECM
coefficients that stage I prints are not used in that recovery.

{pstd}
The feedback enters at {bf:lags only}. That is the zero in the stacked
{it:H0 = [G0, -J0 ; 0, I]}, and it is what makes the dominant block weakly
exogenous contemporaneously while still responding to the rest of the world
with a delay.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} and {opt flags(#)} are the block's own lag order and the lag
order on the feedback variables. The GVAR's overall lag order becomes
{it:max(maxlag, lags, flags)}, so raising either can raise the order of the
whole solved system -- {helpb gvar_solve:gvar solve} reports the result.

{phang}
{opt case(#)} is the deterministic specification, numbered as in
{helpb gvar_estimate:gvar estimate}.

{phang}
{opt rank(#)} is the cointegrating rank {bf:within} the dominant block.
{helpb gvar_solve:gvar solve} subtracts it when it works out how many unit
roots the stacked system ought to have, so an overstated rank here shows up
there as a mismatch rather than passing unnoticed.

{phang}
{opt diff} estimates in differences instead of levels
({it:estimate_VECM_dumodel.m} {it:esttype} 1 rather than 0).

{phang}
{opt feedback(varlist)} names the variables the dominant block responds to,
given as {it:unit:variable} or as plain variable names. With plain names an
aggregate is built across units using {opt weights()}.

{phang}
{opt weights(string)} supplies the weights for those aggregates. Without it
the weights already attached to the model by
{helpb gvar_weights:gvar weights} are used.

{phang}
{opt saving(name)} stores the estimated block so it can be inspected or
reused.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Which to use, gendog() or dominant()?} {cmd:gendog()} is right when the
variable genuinely belongs to one economy's block and should share its
dynamics -- US-denominated variables in the US model, for instance.
{opt dominant()} is right when the variable is global and belongs to nobody:
it then gets its own dynamics and its own shock, and it feeds back from the
world with a lag rather than being driven by one country contemporaneously.

{pstd}
{bf:Verification.} The dominant-unit path is checked in the shipped test
suite: the stacked residuals reproduce the levels form to
{it:max |zeta_dominant - levels form| = 1.998e-15}, and the link identity
{it:W_i x(t) = y_i} holds exactly across all 26 units.

{pstd}
{bf:A refuted hypothesis, kept because it looked convincing.} The stage-I and
stage-II residuals differ, and the gap was 10:1 constant-to-varying -- the
signature of a trend-origin offset. It is not one: {it:mean gap / a1} comes out
111.6, then -187.9, then -97.4 across the blocks, which kills that
explanation. The residuals differ because the two stages fit different
regressions, and the source never claims the identity.


{marker examples}{...}
{title:Examples}

{pstd}
Declare the oil price as a dominant unit rather than a US variable, then
estimate the country models and the dominant block:{p_end}
{phang2}{cmd:. use gvar_demo26, clear}{p_end}
{phang2}{cmd:. gvar setup y Dp eq ep r lr, unit(country) time(quarter) global(poil pmat pmetal) dominant(poil) spec(gvar_demospec)}{p_end}
{phang2}{cmd:. gvar weights using gvar_flows, flow(trade) source(partner) destination(home) year(year) years(2009 2011) type(1) map(gvar_demoagg)}{p_end}
{phang2}{cmd:. gvar foreign}{p_end}
{phang2}{cmd:. gvar estimate}{p_end}
{phang2}{cmd:. gvar dominant, lags(2) flags(1) case(4) rank(1)}{p_end}
{phang2}{cmd:. gvar solve}{p_end}

{pstd}
An oil price that responds to world output and world inflation with a
lag:{p_end}
{phang2}{cmd:. gvar dominant, lags(2) flags(1) feedback(y Dp)}{p_end}

{pstd}
A single dominant variable in differences, with no cointegration to
estimate:{p_end}
{phang2}{cmd:. gvar dominant, lags(2) diff rank(0)}{p_end}

{pstd}
Once solved, the dominant variable is available as a shock like any
other:{p_end}
{phang2}{cmd:. gvar irf, shock(poil:poil) horizon(24) graph}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar dominant} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(theta)}}the reduced-form lag coefficients{p_end}
{synopt:{cmd:r(omega)}}the residual covariance of the block{p_end}
{synopt:{cmd:r(a0)}}the intercept{p_end}
{synopt:{cmd:r(a1)}}the trend coefficient{p_end}
{synopt:{cmd:r(variables)}}the dominant variables{p_end}
{synopt:{cmd:r(feedback)}}the feedback variables{p_end}
{synopt:{cmd:r(nvars)}}number of dominant variables{p_end}
{synopt:{cmd:r(nfeedback)}}number of feedback variables{p_end}
{synopt:{cmd:r(lags)}}the block's lag order{p_end}
{synopt:{cmd:r(flags)}}the feedback lag order{p_end}
{synopt:{cmd:r(pmax)}}the lag order the GVAR will take{p_end}
{synopt:{cmd:r(case)}}the deterministic case{p_end}
{synopt:{cmd:r(rank)}}the cointegrating rank used{p_end}
{synopt:{cmd:r(diff)}}1 if estimated in differences{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:estimate_VECM_dumodel.m}, {it:vec2var_du.m},
{it:augmentedregression.m}, and the dominant-unit branch of
{it:solve_GVAR.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
