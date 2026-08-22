{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar diag" "help gvar_diag"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{viewerjumpto "Syntax" "gvar_stability##syntax"}{...}
{viewerjumpto "Description" "gvar_stability##description"}{...}
{viewerjumpto "Remarks" "gvar_stability##remarks"}{...}
{viewerjumpto "Examples" "gvar_stability##examples"}{...}
{viewerjumpto "Stored results" "gvar_stability##results"}{...}
{viewerjumpto "Options" "gvar_stability##options"}{...}
{title:Title}

{phang}
{bf:gvar stability} {hline 2} structural stability battery with bootstrap critical values


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar stability} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt ccut(#)}}trimming fraction at each end of the sequential Chow. Default 0.15.{p_end}
{synopt:{opt tests(list)}}which statistics to display.{p_end}
{synopt:{opt reps(#)}}bootstrap replications for the critical values.{p_end}
{synopt:{opt shuffle}}resample whole date columns rather than orthogonalised scalars.{p_end}
{synopt:{opt shrinkd:raw}}shrink the covariance used to generate the draws.{p_end}
{synopt:{opt lamd:raw(#)}}set that shrinkage intensity by hand.{p_end}
{synopt:{opt vcov(string)}}{cmd:sample}, {cmd:blockdiag} or {cmd:blockdiag }{it:unit}.{p_end}
{synopt:{opt shrink}}shrink the covariance used for the point estimate.{p_end}
{synopt:{opt lam:bda(#)}}set that intensity by hand.{p_end}
{synopt:{opt det:ail}}also print the robust sequential Chow statistics.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)} {opt savecv(name)}}save the statistics and the critical values.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar stability} runs the Toolbox's battery on every country-model
equation: the Ploberger-Kramer maximal OLS-CUSUM and its mean-square variant,
the Nyblom LM test and its heteroskedasticity-robust form, and the Quandt
sup-F, mean-F and Andrews-Ploberger exp-F, each with a robust version. The
break date is the observation at which the sup-F is attained.

{pstd}
These statistics have non-standard distributions and cannot be read against a
chi-squared or F table. With {cmd:reps()} the command bootstraps their
critical values as the Toolbox does.


{marker options}{...}
{title:Options}

{phang}
{opt tests(spec)} which of the battery to run, and {opt all} runs everything.
The set covers the Ploberger-Kramer-Kontrus and Nyblom statistics, the sequential
and mean Wald tests, and the QLR.

{phang}
{opt efp(spec)} and {opt hfrac(#)} add the empirical fluctuation process family
from {it:strucchange} -- OLS-CUSUM, recursive CUSUM, MOSUM and the rest --
{opt hfrac()} being the bandwidth for the moving-sum variants. Default 0.15.

{phang}
{opt ccut(#)} the trimming fraction at each end of the sample. Default 0.15. A
break cannot be detected in the first or last {it:ccut} of the observations, so
this is a statement about where you are willing to look, not a nuisance
parameter.

{phang}
{opt reps(#)} bootstrap replications for the critical values.

{pmore}
{bf:Use them.} The asymptotic critical values for this family are derived for a
single equation with fixed regressors; a GVAR country model has estimated
cointegrating vectors and weakly exogenous regressors, and the asymptotic values
are correspondingly optimistic.

{phang}
{opt shuffle}, {opt shrinkdraw} and {opt lamdraw(#)} govern the bootstrap;
{opt vcov(spec)}, {opt shrink} and {opt lambda(#)} the covariance, as in
{helpb gvar_irf:gvar irf}.

{phang}
{opt equations(spec)} restricts which equations are tested and {opt top(#)} how
many are listed. Default 6.

{phang}
{opt detail} prints per-equation results, {opt graph} and {opt name()} plot the
paths, {opt saving()} and {opt savecv(name)} write the statistics and the
bootstrap critical values. {opt nosummary} suppresses the report.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Use at least 200 replications.} A 95th percentile from {it:B} draws is the
0.95{it:B}-th order statistic, and these statistics are strongly right-skewed,
so a small {it:B} under-samples the upper tail, biases the critical value
{bf:down} and inflates the rejection rate. The command warns below 200.

{pstd}
{bf:What the demo shows.} Rejection rates settle at about 32 per cent overall
and are stable from {it:B} = 60 to 250, so they are a property of the country
models rather than a small-sample artefact. The pattern - Ploberger-Kramer
near nominal, Nyblom moderate, sup-type far higher - is what Dees, di Mauro,
Pesaran and Smith report; their reading is that the sup-type tests respond to
breaks in the error variances rather than in the coefficients.

{pstd}
{bf:On shuffle.} For a model with more variables than periods, resampling
whole date columns is the better choice: it needs no Cholesky factor and
preserves the empirical cross-section correlation. See
{helpb gvar_methods##singular:gvar methods}.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar stability}
        {cmd:. gvar stability, reps(250) shuffle}
        {cmd:. gvar stability, reps(250) shuffle savecv(CV) detail}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar stability} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(stability)}}the statistics, one row per equation{p_end}
{synopt:{cmd:r(cv)}}the 90, 95 and 99 per cent critical values{p_end}
{synopt:{cmd:r(ccut)}}the trimming fraction{p_end}
{synopt:{cmd:r(nrej)}}rejections at 5 per cent{p_end}
{synopt:{cmd:r(ntest)}}tests compared against a critical value{p_end}
{synopt:{cmd:r(reps)}}replications that converged{p_end}
{synopt:{cmd:r(discarded)}}draws discarded as unstable{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:structural_stability_tests.m}, {it:kraplob.m}, {it:nyblom.m},
{it:schow.m}; critical values from {it:bootstrap_GVAR_ss.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
