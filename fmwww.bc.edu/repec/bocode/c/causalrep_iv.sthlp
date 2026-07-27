{smcl}
{* 25jul2026}{...}
{vieweralsosee "causalrep" "help causalrep"}{...}
{vieweralsosee "causalrep ols" "help causalrep ols"}{...}
{vieweralsosee "causalrep did" "help causalrep did"}{...}
{viewerjumpto "Syntax" "causalrep iv##syntax"}{...}
{viewerjumpto "Description" "causalrep iv##description"}{...}
{viewerjumpto "References" "causalrep iv##references"}{...}
{viewerjumpto "Examples" "causalrep iv##examples"}{...}
{viewerjumpto "Stored results" "causalrep iv##results"}{...}
{viewerjumpto "License" "causalrep iv##license"}{...}
{viewerjumpto "Authors" "causalrep iv##authors"}{...}
{hline}
help for {hi:causalrep iv}
{hline}

{title:Title}

{phang}
{bf:causalrep iv} {hline 2} Quantifying the internal validity and representativeness of the
IV estimand{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:causalrep} {cmd:iv}
{it:indepvars}
{ifin}{cmd:,}
{opt t:reatment(varname)} {opt i:nstrument(varname)} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt t:reatment(varname)}}specify a treatment variable coded 0 for untreated observations
and 1 for treated observations{p_end}
{synopt:{opt i:nstrument(varname)}}specify an instrumental variable coded 0 for observations not
encouraged and 1 for observations encouraged to be treated{p_end}

{syntab:Optional}
{synopt:{opt o:utcome(varname)}}specify an outcome variable; if omitted, no outcome regression
is estimated{p_end}
{synopt:{opt ivmodel(string)}}specify the model for the instrument propensity score; {opt regress} (linear
probability model), {opt logit}, and {opt probit} are allowed; in principle, only {opt regress}
is supported by theory; default is {opt regress} {p_end}
{synopt:{opt fsmodel(string)}}specify the model for the conditional mean of treatment, estimated separately
for observations encouraged and not encouraged to be treated; {opt regress} (linear probability model),
{opt logit}, and {opt probit} are allowed; default is {opt logit} {p_end}
{synopt:{opt cate(varname)}}specify a variable that stores the values of the conditional
(local) average treatment effect (CATE) function; {opt cate()} requires {opt outcome()} to be specified{p_end}
{synopt:{opt pstol:erance(#)}}set tolerance for overlap assumption; the default value is 1e-5;
{cmd:causalrep} {cmd:iv} will exit with an error if an observation has an estimated instrument propensity score
smaller than that specified by {opt pstolerance()} or larger than one minus that specified by {opt pstolerance()} {p_end}
{synopt:{opth os:ample(newvar)}}create an indicator variable {it:newvar} that identifies observations
that violate the overlap assumption{p_end}
{synopt:{opt noi:sily}}display the outcome-regression results when {opt outcome()} is specified{p_end}
{synopt:{opt vce(vcetype)}}specify the variance estimator for the IV outcome regression; {it:vcetype}
may be {opt unadj:usted}, {opt r:obust}, {opt cl:uster}{space 1}{it:clustvar}, {opt boot:strap}, {opt jack:knife},
or {opt hac}{space 1}{it:kernel}; {opt vce()} is relevant only when {opt outcome()} is specified; default
is {opt robust}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:causalrep} {cmd:iv} estimates the measure of internal validity (MIV) and the measure of
representativeness (MR) of the IV estimand, as proposed by Poirier and Słoczyński (2026).  Under
instrument validity, monotonicity, and when the instrument propensity score lies in the linear
span of the included controls, this estimand can be written as a weighted average of conditional
(local) average treatment effects, with weights proportional to the conditional variance of
the instrument.

{pstd}
When the CATE function is unrestricted and the weights are nonnegative, the MIV equals the
inverse maximum weight.  It is the largest possible share of the complier subpopulation for
which the IV estimand can be represented as an average treatment effect.  By contrast, the MR
is the largest possible share of the entire population for which such a representation is
possible.  It is equal to the product of the MIV and the proportion of compliers.

{pstd}
When negative estimated weights are detected, the value reported as MIV when the CATE function
is unrestricted is the inverse maximum weight.  If any population weights are negative, the
unrestricted-CATE MIV and MR are zero.  See Poirier and Słoczyński (2026) for details.

{pstd}
If {opt outcome()} is omitted, the command estimates the MIV and MR using only the instrument,
the treatment, and control variables.  If {opt outcome()} is specified, the command also
estimates the IV coefficient and posts its coefficient vector and variance–covariance matrix.

{pstd}
If {opt cate()} is specified, the command additionally estimates the MIV and MR given the
supplied CATE function.  The supplied CATE values are treated as fixed, and their estimation
uncertainty is not incorporated.  They are required to be nonmissing for every observation in
the estimation sample.

{pstd}
The command assumes the monotonicity direction in which encouragement weakly increases
treatment.  If the average estimated conditional first stage is negative, the command issues
a warning.  When {opt cate()} is specified, the command returns an error if any estimated
conditional complier share is negative.

{pstd}
{opt outcome()} is required when {opt cate()} is specified because the CATE-based calculation
compares the supplied CATE values with the estimated IV coefficient.

{pstd}
If the IV estimate lies outside the range of the supplied CATE values, the CATE-based MIV is
zero.  If the IV estimate equals the mean of the supplied CATE values weighted by the estimated
conditional complier shares, the CATE-based MIV is one.  The CATE-based MIV can be positive even
when the unrestricted-CATE measure is zero.

{pstd}
This is a companion software package for Poirier and Słoczyński (2026).  Please cite this paper
if you use {cmd:causalrep} {cmd:iv} in your work.


{marker references}{...}
{title:References}

{phang}
Poirier, Alexandre, and Tymon Słoczyński (2026). "Quantifying the Internal Validity
of Weighted Estimands." arXiv preprint arXiv:2404.14603. Available at {browse "https://arxiv.org/abs/2404.14603"}.


{marker examples}{...}
{title:Examples}

{pstd}Load data from Angrist (1990):{p_end}

        {com}. {stata "use https://tslocz.github.io/sipp.dta, clear"}{txt}

{pstd}Drop incomplete observations:{p_end}

        {com}. {stata "drop if kwage==. | educ==. | rsncode==999"}{txt}

{pstd}Estimate the MIV of the IV estimand:{p_end}

        {com}. {stata "causalrep iv i.age_5, t(nvstat) i(rsncode)"}{txt}

{pstd}Generate the outcome variable:{p_end}

        {com}. {stata "generate double lwage = ln(kwage)"}{txt}

{pstd}Estimate the conditional LATE using {cmd:teffects} {cmd:ra}:{p_end}

        {com}. {stata "teffects ra (lwage i.age_5) (rsncode)"}{txt}

        {com}. {stata "predict double rf, te"}{txt}

        {com}. {stata "teffects ra (nvstat i.age_5) (rsncode)"}{txt}

        {com}. {stata "predict double fs, te"}{txt}

        {com}. {stata "generate double cate = rf/fs"}{txt}

{pstd}Attempt to estimate the MIV of the IV estimand using the estimated conditional LATE values:{p_end}

        {com}. {stata "causalrep iv i.age_5, t(nvstat) i(rsncode) o(lwage) cate(cate)"}{txt}

{pstd}Because some estimated conditional first stages are negative, restrict attention to covariate cells with nonnegative estimated first stages:{p_end}

        {com}. {stata "causalrep iv i.age_5 if fs>=0, t(nvstat) i(rsncode) o(lwage) cate(cate)"}{txt}

{pstd}Display stored estimation results:{p_end}

        {com}. {stata "ereturn list"}{txt}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:causalrep} {cmd:iv} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2:Always stored}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(miv)}}estimate of the inverse maximum weight; this is the MIV when the conditional LATE function is unrestricted and the weights are nonnegative{p_end}
{synopt :{cmd:e(mr)}}product of the estimate of the inverse maximum weight and the proportion of compliers; this is the MR when the conditional LATE function is unrestricted and the weights are nonnegative{p_end}
{synopt :{cmd:e(cmdline)}}command line{p_end}
{synopt :{cmd:e(cmd)}}{cmd:causalrep}{p_end}
{synopt :{cmd:e(subcmd)}}{cmd:iv}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}

{p2col 5 23 26 2:Only when {opt outcome()} is specified}{p_end}
{synopt :{cmd:e(iv)}}estimated coefficient on the treatment variable in the IV regression{p_end}
{synopt :{cmd:e(depvar)}}name of dependent (outcome) variable{p_end}
{synopt :{cmd:e(b)}}estimated coefficient vector, as obtained by {cmd:ivregress}{p_end}
{synopt :{cmd:e(V)}}estimated variance–covariance matrix, as obtained by {cmd:ivregress}{p_end}
{synopt :{cmd:e(df_r)}}residual degrees of freedom, as obtained by {cmd:ivregress}{p_end}

{p2col 5 23 26 2:Only when {opt cate()} is specified}{p_end}
{synopt :{cmd:e(late)}}estimate of the LATE based on the supplied conditional LATE values{p_end}
{synopt :{cmd:e(miv_cate)}}estimate of the MIV based on the supplied conditional LATE values{p_end}
{synopt :{cmd:e(mr_cate)}}estimate of the MR based on the supplied conditional LATE values{p_end}
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
