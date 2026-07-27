{smcl}
{* 25jul2026}{...}
{vieweralsosee "causalrep" "help causalrep"}{...}
{vieweralsosee "causalrep ols" "help causalrep ols"}{...}
{vieweralsosee "causalrep iv" "help causalrep iv"}{...}
{viewerjumpto "Syntax" "causalrep did##syntax"}{...}
{viewerjumpto "Description" "causalrep did##description"}{...}
{viewerjumpto "References" "causalrep did##references"}{...}
{viewerjumpto "Examples" "causalrep did##examples"}{...}
{viewerjumpto "Stored results" "causalrep did##results"}{...}
{viewerjumpto "License" "causalrep did##license"}{...}
{viewerjumpto "Authors" "causalrep did##authors"}{...}
{hline}
help for {hi:causalrep did}
{hline}

{title:Title}

{phang}
{bf:causalrep did} {hline 2} Quantifying the internal validity and representativeness of the
TWFE estimand{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:causalrep} {cmd:did}
{it:groupvar}
{it:timevar}
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
{synopt:{opt cate(varname)}}specify a variable that stores the values of the conditional
(group-time) average treatment effect (CATE) function; {opt cate()} requires {opt outcome()} to be specified{p_end}
{synopt:{opt noi:sily}}display the outcome-regression results when {opt outcome()} is specified{p_end}
{synopt:{opt vce(vcetype)}}specify the variance estimator for the TWFE outcome regression; {it:vcetype}
may be {opt ols}, {opt r:obust}, {opt cl:uster}{space 1}{it:clustvar}, {opt boot:strap}, {opt jack:knife},
{opt hc2}, or {opt hc3}; {opt vce()} is relevant only when {opt outcome()} is specified; default
is {opt cluster}{space 1}{it:groupvar}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:causalrep} {cmd:did} estimates the measure of internal validity (MIV) and the measure of
representativeness (MR) of the TWFE estimand, as proposed by Poirier and Słoczyński (2026).  Under
the parallel trends assumption, this estimand can be written as a weighted average of conditional
(group-time) average treatment effects.

{pstd}
When the CATE function is unrestricted and the weights are nonnegative, the MIV equals the
inverse maximum weight.  It is the largest possible share of the treated subpopulation for
which the TWFE estimand can be represented as an average treatment effect.  By contrast, the MR
is the largest possible share of the entire population for which such a representation is
possible.  It is equal to the product of the MIV and the proportion of treated units.

{pstd}
When negative estimated weights are detected, the value reported as MIV when the CATE function
is unrestricted is the inverse maximum weight.  If any population weights are negative, the
unrestricted-CATE MIV and MR are zero.  See Poirier and Słoczyński (2026) for details.

{pstd}
If {opt outcome()} is omitted, the command estimates the MIV and MR using only the treatment,
group, and time variables.  If {opt outcome()} is specified, the command also estimates the
TWFE coefficient and posts its coefficient vector and variance–covariance matrix.

{pstd}
If {opt cate()} is specified, the command additionally estimates the MIV and MR given the
supplied CATE function.  The supplied CATE values are treated as fixed, and their estimation
uncertainty is not incorporated.  They are required to be nonmissing for every treated
observation in the estimation sample.

{pstd}
{opt outcome()} is required when {opt cate()} is specified because the CATE-based calculation
compares the supplied CATE values with the estimated TWFE coefficient.

{pstd}
If the TWFE estimate lies outside the range of the supplied CATE values, the CATE-based MIV is
zero.  If the TWFE estimate equals the mean of the supplied CATE values for the treated units,
the CATE-based MIV is one.  The CATE-based MIV can be positive even when the unrestricted-CATE
measure is zero.

{pstd}
{cmd:causalrep} {cmd:did} requires the time variable to take integer values and a balanced
group–period structure in the estimation sample.  Every group must be observed in the same set
of periods, and, within each group, the number of observations in each group–time cell must be
constant over time.  Multiple observations per group–time cell are allowed, and cell sizes may
differ across groups.  Treatment must be constant within each group–time cell, no group may be
treated in the first sample period, and once a group becomes treated, it must remain
treated.  The command returns an error if missing values or if/in restrictions cause these
conditions to fail.

{pstd}
This is a companion software package for Poirier and Słoczyński (2026).  Please cite this paper
if you use {cmd:causalrep} {cmd:did} in your work.


{marker references}{...}
{title:References}

{phang}
Poirier, Alexandre, and Tymon Słoczyński (2026). "Quantifying the Internal Validity
of Weighted Estimands." arXiv preprint arXiv:2404.14603. Available at {browse "https://arxiv.org/abs/2404.14603"}.


{marker examples}{...}
{title:Examples}

{pstd}Load data from Goodman-Bacon (2021):{p_end}

        {com}. {stata "use http://fmwww.bc.edu/repec/bocode/b/bacon_example.dta, clear"}{txt}

{pstd}Drop always-treated states and states excluded by Goodman-Bacon (2021):{p_end}

        {com}. {stata "drop if stfips==22 | stfips==24 | stfips==37 | stfips==40 | stfips==49 | stfips==50 | stfips==51 | stfips==54"}{txt}

{pstd}Estimate the MIV of the TWFE estimand:{p_end}

        {com}. {stata "causalrep did stfips year, t(post)"}{txt}

{pstd}In Stata 18 or later, estimate the group–time ATT using {cmd:xthdidregress} {cmd:twfe}:{p_end}

        {com}. {stata "xthdidregress twfe (asmrs) (post), group(stfips)"}{txt}

        {com}. {stata "matrix atets = e(b)"}{txt}

        {com}. {stata `"generate double att = el(atets, 1, colnumb(atets, trim(string(_did_cohort)) + ":" + trim(string(year)) + ".year")) if post==1"'}{txt}

{pstd}Estimate the MIV of the TWFE estimand, including conditional on the estimated group–time ATT values:{p_end}

        {com}. {stata "causalrep did stfips year, t(post) o(asmrs) cate(att)"}{txt}

{pstd}Display stored estimation results:{p_end}

        {com}. {stata "ereturn list"}{txt}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:causalrep} {cmd:did} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2:Always stored}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(miv)}}estimate of the inverse maximum weight; this is the MIV when the CATE function is unrestricted and the weights are nonnegative{p_end}
{synopt :{cmd:e(mr)}}product of the estimate of the inverse maximum weight and the proportion of treated units; this is the MR when the CATE function is unrestricted and the weights are nonnegative{p_end}
{synopt :{cmd:e(cmdline)}}command line{p_end}
{synopt :{cmd:e(cmd)}}{cmd:causalrep}{p_end}
{synopt :{cmd:e(subcmd)}}{cmd:did}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}

{p2col 5 23 26 2:Only when {opt outcome()} is specified}{p_end}
{synopt :{cmd:e(twfe)}}estimated coefficient on the treatment variable in the TWFE regression{p_end}
{synopt :{cmd:e(depvar)}}name of dependent (outcome) variable{p_end}
{synopt :{cmd:e(b)}}estimated coefficient vector, as obtained by {cmd:regress}{p_end}
{synopt :{cmd:e(V)}}estimated variance–covariance matrix, as obtained by {cmd:regress}{p_end}
{synopt :{cmd:e(df_r)}}residual degrees of freedom, as obtained by {cmd:regress}{p_end}

{p2col 5 23 26 2:Only when {opt cate()} is specified}{p_end}
{synopt :{cmd:e(att)}}estimate of the ATT based on the supplied CATE values{p_end}
{synopt :{cmd:e(miv_cate)}}estimate of the MIV based on the supplied CATE values{p_end}
{synopt :{cmd:e(mr_cate)}}estimate of the MR based on the supplied CATE values{p_end}
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
