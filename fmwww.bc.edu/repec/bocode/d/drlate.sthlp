{smcl}
{* 12may2026}{...}
{viewerjumpto "Syntax" "drlate##syntax"}{...}
{viewerjumpto "Description" "drlate##description"}{...}
{viewerjumpto "Methods" "drlate##methods"}{...}
{viewerjumpto "Normalization" "drlate##normalization"}{...}
{viewerjumpto "Overlap" "drlate##overlap"}{...}
{viewerjumpto "Examples" "drlate##examples"}{...}
{viewerjumpto "Stored results" "drlate##results"}{...}
{viewerjumpto "References" "drlate##references"}{...}
{viewerjumpto "Authors" "drlate##authors"}{...}
{hline}
help for {hi:drlate}
{hline}

{title:Title}

{phang}
{bf:drlate} {hline 2} Doubly robust estimation of the local average treatment effect (LATE) and the local average treatment effect on the treated (LATT)

{marker syntax}
{title:Syntax}

{p 8 17 2}
{cmd:drlate}
{cmd:(}{it:{help varname:ovar}} [{it:{help varlist:omvarlist}}] [{cmd:,} {it:{help drlate##omodel:omodel}}]{cmd:)}
{cmd:(}{it:{help varname:tvar}} [{it:{help varlist:tmvarlist}}] [{cmd:,} {it:{help drlate##tmodel:tmodel}}]{cmd:)}
{cmd:(}{it:{help varname:iv}} [{it:{help varlist:ivvarlist}}] [{cmd:,} {it:{help drlate##ivmodel:ivmodel}}]{cmd:)}
{ifin}
[{it:{help weight}}]
[{cmd:,} {it:{help drlate##options_table:options}}]

{phang}
{it:ovar} is an outcome variable.

{phang}
{it:omvarlist} specifies the covariates in the outcome model.

{phang}
{it:tvar} is a treatment variable.

{phang}
{it:tmvarlist} specifies the covariates in the treatment model.

{phang}
{it:iv} is a binary instrumental variable.

{phang}
{it:ivvarlist} specifies the covariates in the instrument propensity score model.

{phang}
{it:omvarlist}, {it:tmvarlist}, and {it:ivvarlist} may contain
factor variables; see {help fvvarlists}.

{synoptset 24 tabbed}{...}
{marker omodel}{...}
{synopthdr:omodel}
{synoptline}
{syntab:Outcome model}
{synopt:{opt linear}}linear regression; the default{p_end}
{synopt:{opt logit}}logistic regression; {it:ovar} must be 0/1{p_end}
{synopt:{opt poisson}}Poisson regression; {it:ovar} must be non-negative{p_end}
{synoptline}

{synoptset 24 tabbed}{...}
{marker tmodel}{...}
{synopthdr:tmodel}
{synoptline}
{syntab:Treatment model}
{synopt:{opt logit}}logistic regression; {it:tvar} must be 0/1; the default{p_end}
{synopt:{opt linear}}linear regression{p_end}
{synopt:{opt poisson}}Poisson regression; {it:tvar} must be non-negative{p_end}
{synoptline}

{synoptset 24 tabbed}{...}
{marker ivmodel}{...}
{synopthdr:ivmodel}
{synoptline}
{syntab:Instrument propensity score model}
{synopt:{opt logit}}logistic regression estimated by maximum likelihood (MLE); the default{p_end}
{synopt:{opt cbps}}logistic regression estimated by covariate balancing (CBPS),
as in Imai and Ratkovic (2014); not available with {cmd:latt}{p_end}
{synopt:{opt ipt}}logistic regression estimated by inverse probability tilting (IPT),
as in Egel et al. (2008) and Graham et al. (2012, 2016){p_end}
{synoptline}

{marker options_table}{...}
{synoptset 24 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Estimand}
{synopt:{opt late}}estimate the local average treatment effect (LATE); the default{p_end}
{synopt:{opt latt}}estimate the local average treatment effect on the treated (LATT){p_end}

{syntab:Estimator}
{synopt:{opt method(string)}}{it:string} may be {opt ipwra} (default), {opt ipw},
{opt aipw}, or {opt ra}; see {help drlate##methods:Methods} below{p_end}
{synopt:{opt nrm}}use normalized moment conditions (only relevant for {opt ipw} and {opt aipw}); the default{p_end}
{synopt:{opt unnrm}}use unnormalized moment conditions (only relevant for {opt ipw} and {opt aipw}){p_end}

{syntab:SE/Robust}
{synopt:{opth vce(vcetype)}}{it:vcetype} may be {opt robust} (default) or
{opt cluster} {it:clustvar}{p_end}

{syntab:GMM options}
{synopt:{opt iter:ate(#)}}perform maximum of {it:#} iterations{p_end}
{synopt:{opt tech:nique(string)}}optimization technique; {opt gn} (default),
{opt nr}, {opt dfp}, and {opt bfgs} are allowed{p_end}

{syntab:Overlap}
{synopt:{opt pstol:erance(#)}}set tolerance for the overlap assumption;
default is {cmd:1e-5}; {cmd:drlate} exits with an error if any estimated
instrument propensity score is below {it:#} or above 1−{it:#}{p_end}
{synopt:{opth os:ample(newvar)}}create indicator variable {it:newvar} equal
to 1 for observations that violate the overlap assumption{p_end}
{synoptline}

{p 4 6 2}
{opt pweight}s are allowed; see {help weight}.{p_end}

{marker description}
{title:Description}

{pstd}
{cmd:drlate} estimates the local average treatment effect (LATE) and the local
average treatment effect on the treated (LATT) using observational data.
The command accommodates a binary instrument, a continuous, binary, or count
treatment, and a continuous, binary, or count outcome.
All standard errors are computed jointly for the instrument propensity score,
the outcome regression, the treatment regression, and the causal estimand,
using Stata's {cmd:gmm} command with {opt iterate(0)} (one-step GMM with
analytical starting values), yielding valid inference.

{pstd}
This is a companion software package for Słoczyński, Uysal, and Wooldridge (2022).
Please cite this paper if you use {cmd:drlate} in your work.

{marker methods}
{title:Methods}

{pstd}
The estimator is selected via {opt method()}.  All methods jointly estimate the
causal parameter and all nuisance models in a single GMM system, so that
standard errors correctly account for estimation uncertainty in each stage.

{phang}
{opt ipwra} (default) selects inverse-probability-weighted regression adjustment
(IPWRA).  The outcome and treatment models are fitted with IPW weights derived
from the instrument propensity score, and the causal parameter is identified from
the implied regression predictions.  IPWRA weights are always normalized.
This method is doubly robust: the estimator is consistent if either the instrument
propensity score model or the outcome/treatment regression models are
correctly specified.{p_end}

{phang}
{opt ipw} selects inverse probability weighting (IPW).  This method does not feature
an explicit outcome or treatment regression.  {it:omvarlist} and {it:tmvarlist} should
not be specified with {opt method(ipw)}.{p_end}

{phang}
{opt aipw} selects augmented inverse probability weighting (AIPW).  The outcome and
treatment models are fitted without IPW weights, and an IPW-based augmentation
term is added to the moment conditions.  This method is also doubly robust.{p_end}

{phang}
{opt ra} selects regression adjustment (RA).  No instrument propensity score is
estimated.  The outcome and treatment models are fitted separately for both instrument
values, and predictions are averaged.  Standard errors are computed by GMM.
{it:ivvarlist} should not be specified with {opt method(ra)}.{p_end}

{marker normalization}
{title:Normalization}

{pstd}
For {opt method(ipw)} and {opt method(aipw)}, the user may choose between
normalized ({opt nrm}) and unnormalized ({opt unnrm}) moment conditions.
Normalized estimators ensure that the IPW weights sum to one within each
instrument group.

{pstd}
For {opt method(ipwra)} and {opt method(ra)}, normalization is not necessary
and the {opt nrm}/{opt unnrm} options have no effect.

{pstd}
When {opt ipt} is selected for {it:ivmodel}, the IPT weights are ex-ante normalized,
so normalized and unnormalized estimators coincide; {cmd:drlate} automatically
sets normalization to {opt nrm} in this case.

{marker overlap}
{title:Overlap}

{pstd}
{cmd:drlate} checks the overlap assumption after estimating the instrument
propensity score.  It exits with an error if any in-sample estimated propensity
score falls outside the interval [{it:pstolerance}, 1−{it:pstolerance}].
The default tolerance is 1e-5.  Use {opt osample(newvar)} to save an indicator
of violating observations for inspection before re-running on a restricted
sample.

{marker examples}
{title:Examples}

{pstd}Load data and prepare variables:{p_end}

        {com}. {stata "use https://people.brandeis.edu/~tslocz/sipp.dta, clear"}{txt}

        {com}. {stata "drop if kwage==. | educ==. | rsncode==999"}{txt}

        {com}. {stata "generate double lwage = ln(kwage)"}{txt}

{pstd}LATE with default settings (IPWRA, logit instrument propensity score and treatment models,
linear outcome model):{p_end}

        {com}. {stata "drlate (lwage age_5) (nvstat age_5) (rsncode age_5)"}{txt}

{pstd}LATE with IPT instrument propensity score:{p_end}

        {com}. {stata "drlate (lwage age_5) (nvstat age_5) (rsncode age_5, ipt)"}{txt}

{pstd}LATT with IPT instrument propensity score:{p_end}

        {com}. {stata "drlate (lwage age_5) (nvstat age_5) (rsncode age_5, ipt), latt"}{txt}

{pstd}LATE with IPW estimator:{p_end}

        {com}. {stata "drlate (lwage) (nvstat) (rsncode age_5), method(ipw)"}{txt}

{pstd}LATE with AIPW estimator, unnormalized:{p_end}

        {com}. {stata "drlate (lwage age_5) (nvstat age_5) (rsncode age_5), method(aipw) unnrm"}{txt}

{pstd}LATE with regression adjustment:{p_end}

        {com}. {stata "drlate (lwage age_5) (nvstat age_5) (rsncode), method(ra)"}{txt}

{pstd}LATE with regression adjustment, including Poisson regression for the original wage variable:{p_end}

        {com}. {stata "drlate (kwage age_5, poisson) (nvstat age_5) (rsncode), method(ra)"}{txt}

{marker results}
{title:Stored results}

{pstd}
{cmd:drlate} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2:Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters (if {opt vce(cluster)} is specified){p_end}
{synopt:{cmd:e(dmeanz1)}}mean of treatment variable among observations with {it:Z}=1{p_end}
{synopt:{cmd:e(dmeanz0)}}mean of treatment variable among observations with {it:Z}=0{p_end}

{p2col 5 22 26 2:Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:drlate}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(yvar)}}name of outcome variable{p_end}
{synopt:{cmd:e(tvar)}}name of treatment variable{p_end}
{synopt:{cmd:e(zvar)}}name of instrumental variable{p_end}
{synopt:{cmd:e(ymodelvars)}}covariates in outcome equation{p_end}
{synopt:{cmd:e(tmodelvars)}}covariates in treatment equation{p_end}
{synopt:{cmd:e(zmodelvars)}}covariates in instrument equation{p_end}
{synopt:{cmd:e(omodel)}}model for outcome equation{p_end}
{synopt:{cmd:e(tmodel)}}model for treatment equation{p_end}
{synopt:{cmd:e(zmodel)}}model for instrument propensity score{p_end}
{synopt:{cmd:e(method)}}estimator used ({cmd:ipwra}, {cmd:ipw}, {cmd:aipw}, or {cmd:ra}){p_end}
{synopt:{cmd:e(stat)}}estimand ({cmd:late} or {cmd:latt}){p_end}
{synopt:{cmd:e(statnorm)}}normalization ({cmd:nrm} or {cmd:unnrm}){p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {opt vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label standard errors{p_end}
{synopt:{cmd:e(ifcond)}}{cmd:if} condition used in estimation{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 22 26 2:Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector; columns are the causal estimate,
the numerator, and the denominator{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}

{p2col 5 22 26 2:Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{pstd}
The column labeled {cmd:LATE: D on Y} (or {cmd:LATT: D on Y}) in {cmd:e(b)}
contains the causal estimate.  The columns labeled {cmd:ATE: Z on Y} and
{cmd:ATE: Z on D} (or {cmd:ATT: Z on Y} and {cmd:ATT: Z on D}) contain the
estimated intent-to-treat (ITT) effect and first-stage compliance probability,
respectively, from which the causal estimate is formed as their ratio.

{marker references}
{title:References}

{phang}
Egel, Daniel, Bryan S. Graham, and Cristine Campos de Xavier Pinto
(2008). "Inverse Probability Tilting and Missing Data Problems."
NBER Working Paper No. 13981.

{phang}
Graham, Bryan S., Cristine Campos de Xavier Pinto, and Daniel Egel
(2012). "Inverse Probability Tilting for Moment Condition Models with
Missing Data." {it:Review of Economic Studies} 79(3), 1053{c 150}1079.

{phang}
Graham, Bryan S., Cristine Campos de Xavier Pinto, and Daniel Egel
(2016). "Efficient Estimation of Data Combination Models by the Method
of Auxiliary-to-Study Tilting (AST)."
{it:Journal of Business & Economic Statistics} 34(2), 288{c 150}301.

{phang}
Imai, Kosuke, and Marc Ratkovic (2014). "Covariate Balancing Propensity
Score." {it:Journal of the Royal Statistical Society, Series B} 76(1),
243{c 150}263.

{phang}
Słoczyński, Tymon, S. Derya Uysal, and Jeffrey M. Wooldridge
(2022). "Doubly Robust Estimation of Local Average Treatment Effects
Using Inverse Probability Weighted Regression Adjustment."
Available at {browse "https://doi.org/10.48550/arXiv.2208.01300"}.

{marker authors}
{title:Authors}

{phang} S. Derya Uysal, LMU Munich{p_end}
{pstd}Email: {browse "mailto:derya.uysal@econ.lmu.de":derya.uysal@econ.lmu.de}{p_end}

{phang} Tymon Słoczyński, Brandeis University{p_end}
{pstd}Email: {browse "mailto:tslocz@brandeis.edu":tslocz@brandeis.edu}{p_end}

{phang} Jeffrey M. Wooldridge, Michigan State University{p_end}
{pstd}Email: {browse "mailto:wooldri1@msu.edu":wooldri1@msu.edu}{p_end}
