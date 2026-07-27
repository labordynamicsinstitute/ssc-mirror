{smcl}
{* 25jul2026}{...}
{vieweralsosee "causalrep" "help causalrep"}{...}
{vieweralsosee "causalrep iv" "help causalrep iv"}{...}
{vieweralsosee "causalrep did" "help causalrep did"}{...}
{viewerjumpto "Syntax" "causalrep ols##syntax"}{...}
{viewerjumpto "Description" "causalrep ols##description"}{...}
{viewerjumpto "References" "causalrep ols##references"}{...}
{viewerjumpto "Examples" "causalrep ols##examples"}{...}
{viewerjumpto "Stored results" "causalrep ols##results"}{...}
{viewerjumpto "License" "causalrep ols##license"}{...}
{viewerjumpto "Authors" "causalrep ols##authors"}{...}
{hline}
help for {hi:causalrep ols}
{hline}

{title:Title}

{phang}
{bf:causalrep ols} {hline 2} Quantifying the internal validity and representativeness of the
OLS estimand{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:causalrep} {cmd:ols}
{it:indepvars}
{ifin}{cmd:,}
{opt t:reatment(varname)} [{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt t:reatment(varname)}}specify a treatment variable coded 0 for untreated observations
and 1 for treated observations{p_end}

{syntab:Optional}
{synopt:{opt o:utcome(varname)}}specify an outcome variable; if omitted, no outcome regression
is estimated{p_end}
{synopt:{opt tmodel(string)}}specify the model for the propensity score; {opt regress} (linear
probability model), {opt logit}, and {opt probit} are allowed; in principle, only {opt regress}
is supported by theory; default is {opt regress} {p_end}
{synopt:{opt cate(varname)}}specify a variable that stores the values of the conditional
average treatment effect (CATE) function; {opt cate()} requires {opt outcome()} to be specified{p_end}
{synopt:{opt noi:sily}}display the outcome-regression results when {opt outcome()} is specified{p_end}
{synopt:{opt vce(vcetype)}}specify the variance estimator for the OLS outcome regression; {it:vcetype}
may be {opt ols}, {opt r:obust}, {opt cl:uster}{space 1}{it:clustvar}, {opt boot:strap}, {opt jack:knife},
{opt hc2}, or {opt hc3}; {opt vce()} is relevant only when {opt outcome()} is specified; default
is {opt robust}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:causalrep} {cmd:ols} estimates the measure of internal validity (MIV) of the OLS
estimand, as proposed by Poirier and Słoczyński (2026).  Under unconfoundedness and
when the propensity score lies in the linear span of the included controls, this
estimand can be written as a weighted average of conditional average treatment
effects, with weights proportional to the conditional variance of treatment.

{pstd}
When the CATE function is unrestricted and the weights are nonnegative, the MIV equals the
inverse maximum weight.  It is the largest possible share of the population for which the
OLS estimand can be represented as an average treatment effect.  Because the target
population for {cmd:causalrep} {cmd:ols} is the entire population, the MIV also equals
the measure of representativeness.

{pstd}
When negative estimated weights are detected, the value reported as MIV when the CATE function
is unrestricted is the inverse maximum weight.  If any population weights are negative, the
unrestricted-CATE MIV and MR are zero.  See Poirier and Słoczyński (2026) for details.

{pstd}
If {opt outcome()} is omitted, the command estimates this measure using only the treatment
and control variables.  If {opt outcome()} is specified, the command also estimates the OLS
coefficient and posts its coefficient vector and variance–covariance matrix.

{pstd}
If {opt cate()} is specified, the command additionally computes the largest share of the
sample whose mean supplied CATE equals the estimated OLS coefficient.  The supplied CATE
values are treated as fixed, and their estimation uncertainty is not incorporated.  They are
required to be nonmissing for every observation in the estimation sample.

{pstd}
{opt outcome()} is required when {opt cate()} is specified because the CATE-based calculation
compares the supplied CATE values with the estimated OLS coefficient.

{pstd}
If the OLS estimate lies outside the range of the supplied CATE values, the CATE-based MIV is
zero.  If the OLS estimate equals the mean supplied CATE, the CATE-based MIV is one.  The
CATE-based MIV can be positive even when the unrestricted-CATE measure is zero.

{pstd}
This is a companion software package for Poirier and Słoczyński (2026).  Please cite this paper
if you use {cmd:causalrep} {cmd:ols} in your work.


{marker references}{...}
{title:References}

{phang}
Poirier, Alexandre, and Tymon Słoczyński (2026). "Quantifying the Internal Validity
of Weighted Estimands." arXiv preprint arXiv:2404.14603. Available at {browse "https://arxiv.org/abs/2404.14603"}.


{marker examples}{...}
{title:Examples}

{pstd}Load data from LaLonde (1986):{p_end}

        {com}. {stata "use https://tslocz.github.io/lalonde.dta, clear"}{txt}

{pstd}Keep only the original experimental data:{p_end}

        {com}. {stata "keep if dataset==0"}{txt}

{pstd}Estimate the MIV of the OLS estimand:{p_end}

        {com}. {stata "causalrep ols age educ black hispanic married nodegree re74 re75, t(treated)"}{txt}

{pstd}Estimate the CATE function using {cmd:teffects} {cmd:aipw}:{p_end}

        {com}. {stata "teffects aipw (re78 age educ black hispanic married nodegree re74 re75) (treated age educ black hispanic married nodegree re74 re75)"}{txt}

        {com}. {stata "predict double cate, te"}{txt}

{pstd}Estimate the MIV of the OLS estimand, including conditional on the estimated CATE values:{p_end}

        {com}. {stata "causalrep ols age educ black hispanic married nodegree re74 re75, t(treated) o(re78) cate(cate)"}{txt}

{pstd}Display stored estimation results:{p_end}

        {com}. {stata "ereturn list"}{txt}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:causalrep} {cmd:ols} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2:Always stored}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(miv)}}estimate of the inverse maximum weight; this is the MIV when the CATE function is unrestricted and the weights are nonnegative{p_end}
{synopt :{cmd:e(cmdline)}}command line{p_end}
{synopt :{cmd:e(cmd)}}{cmd:causalrep}{p_end}
{synopt :{cmd:e(subcmd)}}{cmd:ols}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}

{p2col 5 23 26 2:Only when {opt outcome()} is specified}{p_end}
{synopt :{cmd:e(ols)}}estimated coefficient on the treatment variable in the OLS regression{p_end}
{synopt :{cmd:e(depvar)}}name of dependent (outcome) variable{p_end}
{synopt :{cmd:e(b)}}estimated coefficient vector, as obtained by {cmd:regress}{p_end}
{synopt :{cmd:e(V)}}estimated variance–covariance matrix, as obtained by {cmd:regress}{p_end}
{synopt :{cmd:e(df_r)}}residual degrees of freedom, as obtained by {cmd:regress}{p_end}

{p2col 5 23 26 2:Only when {opt cate()} is specified}{p_end}
{synopt :{cmd:e(ate)}}mean of the supplied CATE values over the estimation sample{p_end}
{synopt :{cmd:e(miv_cate)}}estimate of the MIV conditional on the supplied CATE values{p_end}
{p2colreset}{...}


{marker license}{...}
{title:License}

{phang} This package is licensed under the MIT License.  See the LICENSE
file included with the distribution.


{marker authors}{...}
{title:Authors}

{phang} Alexandre Poirier, Georgetown University{p_end}
{pstd}Email: {browse "mailto:alexandre.poirier@georgetown.edu":alexandre.poirier@georgetown.edu}{p_end}

{phang} Tymon Słoczyński, Brandeis University{p_end}
{pstd}Email: {browse "mailto:tslocz@brandeis.edu":tslocz@brandeis.edu}{p_end}
