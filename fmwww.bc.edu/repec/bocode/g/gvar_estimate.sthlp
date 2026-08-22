{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar coint" "help gvar_coint"}{...}
{vieweralsosee "gvar solve" "help gvar_solve"}{...}
{vieweralsosee "gvar diag" "help gvar_diag"}{...}
{vieweralsosee "gvar overid" "help gvar_overid"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{vieweralsosee "gvar dominant" "help gvar_dominant"}{...}
{vieweralsosee "gvar report" "help gvar_report"}{...}
{viewerjumpto "Syntax" "gvar_estimate##syntax"}{...}
{viewerjumpto "Description" "gvar_estimate##description"}{...}
{viewerjumpto "Remarks" "gvar_estimate##remarks"}{...}
{viewerjumpto "Examples" "gvar_estimate##examples"}{...}
{viewerjumpto "Stored results" "gvar_estimate##results"}{...}
{viewerjumpto "Options" "gvar_estimate##options"}{...}
{title:Title}

{phang}
{bf:gvar estimate} {hline 2} reduced-rank ML of every VECMX* country model


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar estimate} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt vce(string)}}{cmd:ols}, {cmd:robust} (White) or {cmd:nwest} (Newey-West). Affects the reported standard errors, not the point estimates.{p_end}
{synopt:{opt beta}}print the normalised cointegrating vectors.{p_end}
{synopt:{opt betar:estr(name)}}impose restrictions on beta; see {helpb gvar_overid:gvar overid}.{p_end}
{synopt:{opt det:ail(unit)}}full equation-by-equation output for one unit.{p_end}
{synopt:{opt solve}}run {helpb gvar_solve:gvar solve} immediately afterwards.{p_end}
{synopt:{opt nosum:mary}}suppress the fit table.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar estimate} fits each country model by Johansen reduced-rank maximum
likelihood, conditional on the foreign variables being I(1) and weakly
exogenous, at the rank, lag orders and deterministic case currently declared.
It then recovers the VARX* levels representation that
{helpb gvar_solve:gvar solve} stacks.


{marker options}{...}
{title:Options}

{phang}
{opt vce(ols|robust|nwest)} chooses the standard errors reported for the
short-run coefficients. {cmd:ols} is the default;
{cmd:robust} is White; {cmd:nwest} is Newey-West.

{pmore}
The choice affects the {it:reported} standard errors only. It does not change
the coefficients, the cointegrating vectors, or anything
{helpb gvar_solve:gvar solve} does downstream -- reduced-rank ML is what it is.
Note also that these are conditional on the estimated cointegrating vectors
being the true ones; they carry no allowance for rank uncertainty, which is
usually the larger problem.

{phang}
{opt beta} prints the normalised cointegrating vectors for every unit. Worth
reading before any persistence profile or over-identification test, since both
are defined on them.

{phang}
{opt betarestr(name)} imposes restrictions on {it:beta} from a matrix rather
than letting Johansen normalisation pick the basis. Use it when theory names the
relations -- a real interest-rate parity, a PPP condition -- and use
{helpb gvar_overid:gvar overid} afterwards to test whether the data accept them.

{phang}
{opt detail(unit)} prints the full equation-by-equation table for one unit:
coefficients, standard errors, and the diagnostics for each equation. Give the
unit name as it appears in {helpb gvar_describe:gvar describe}. With 26 country
models the summary table is the only readable default, so this is how you look
inside one of them.

{phang}
{opt solve} runs {helpb gvar_solve:gvar solve} immediately afterwards, which is
convenient in a do-file but hides {cmd:gvar solve}'s own report unless you also
read {cmd:r()}. Prefer two separate commands when the stability check matters.

{phang}
{opt nosummary} suppresses the report. The model is still estimated and
{cmd:r()} is still filled.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:What to check first.} The fit table reports the log likelihood, AIC and
SBC per unit. A missing log likelihood means the residual covariance was
singular for that unit, which almost always traces back to a constant or
duplicated series in its block - look at
{helpb gvar_setup:gvar setup}'s report of absent and partially observed
series.

{pstd}
{bf:The three standard errors.} OLS, White and Newey-West are computed from
the same coefficients. The Toolbox reports all three; which you quote is a
judgement about the residuals, and {helpb gvar_diag:gvar diag} is where you
form it.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar estimate, vce(nwest)}
        {cmd:. gvar estimate, vce(nwest) beta}
        {cmd:. gvar estimate, detail(usa)}
        {cmd:. gvar estimate, vce(nwest) solve}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar estimate} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(fit)}}log likelihood, AIC and SBC per unit{p_end}
{synopt:{cmd:r(rank)}}the ranks used{p_end}
{synopt:{cmd:r(lags)}}the lag orders used{p_end}
{synopt:{cmd:r(vce)}}the standard-error type{p_end}
{synopt:{cmd:r(N)}}units{p_end}
{synopt:{cmd:r(pmax)}}the GVAR lag order, max over units of (p,q){p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:mlcoint.m}, {it:vecx2varx.m}, {it:neweywest.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
