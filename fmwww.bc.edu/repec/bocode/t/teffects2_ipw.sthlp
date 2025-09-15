{smcl}
{* 12sep2025}{...}
{vieweralsosee "teffects2" "help teffects2"}{...}
{vieweralsosee "teffects2 aipw" "help teffects2 aipw"}{...}
{vieweralsosee "teffects2 ipwra" "help teffects2 ipwra"}{...}
{viewerjumpto "Syntax" "teffects2 ipw##syntax"}{...}
{viewerjumpto "Description" "teffects2 ipw##description"}{...}
{viewerjumpto "References" "teffects2 ipw##references"}{...}
{viewerjumpto "Examples" "teffects2 ipw##examples"}{...}
{viewerjumpto "Stored results" "teffects2 ipw##results"}{...}
{viewerjumpto "Acknowledgments" "teffects2 ipw##acknowledgments"}{...}
{viewerjumpto "License" "teffects2 ipw##license"}{...}
{viewerjumpto "Authors" "teffects2 ipw##authors"}{...}
{hline}
help for {hi:teffects2 ipw}
{hline}

{title:Title}

{phang}
{bf:teffects2 ipw} {hline 2} Inverse probability weighting

{marker syntax}
{title:Syntax}

{p 8 12 2}
{cmd:teffects2} {cmd:ipw}
   {cmd:(}{it:{help varname:ovar}}{cmd:)}
   {cmd:(}{it:{help varname:tvar}} {it:{help varlist:tmvarlist}}
      [{cmd:,} {it:{help teffects2 ipw##tmodel:tmodel}}]{cmd:)}
	{ifin} 
        [{it:{help teffects2 ipw##weight:weight}}]
     [{cmd:,}
          {it:{help teffects2 ipw##stat:stat}}
          {it:{help teffects2 ipw##options_table:options}}]

{phang}
{it:ovar} is an outcome of interest.

{phang}
{it:tvar} is a binary treatment variable.

{phang}
{it:tmvarlist} specifies the covariates in the propensity score model.

{synoptset 22 tabbed}{...}
{marker tmodel}{...}
{synopthdr:tmodel}
{synoptline}
{syntab:Model}
{synopt :{opt ipt}}estimate the logit model using
inverse probability tilting (IPT), as in Egel et al. (2008)
and Graham et al. (2012, 2016); the default{p_end}
{synopt :{opt logit}}estimate the logit model using
maximum likelihood (ML), as in {cmd:teffects}{p_end}
{synopt :{opt cbps}}estimate the logit model using
the covariate balancing propensity score (CBPS) approach
of Imai and Ratkovic (2014); only available for the ATE{p_end}
{synoptline}
{p 4 6 2}
{it:tmodel} specifies the model and estimation
method for the propensity score.{p_end}
{p 4 6 2}
{p_end}

{marker stat}{...}
{synopthdr:stat}
{synoptline}
{syntab:Stat}
{synopt :{opt ate}}estimate the average
treatment effect (ATE); the default{p_end}
{synopt :{opt atet}}estimate the average
treatment effect on the treated (ATT){p_end}
{synoptline}

{marker options_table}{...}
{synopthdr}
{synoptline}
{syntab:SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be
{opt r:obust} or {opt cl:uster} {it:clustvar} {p_end}

{syntab:Normalization}
{synopt :{opt nrm}}IPW weights are ex-post
normalized to add up to one; the default{p_end}
{synopt :{opt unnrm}}IPW weights are not normalized{p_end}

{syntab:GMM options}
{synopt :{opt iter:ate(#)}}perform maximum of # iterations{p_end}
{synopt :{opt tech:nique()}}optimization
technique; {cmd:gn} (the default), {cmd:nr},
{cmd:dfp}, and {cmd:bfgs} are allowed{p_end}

{syntab:Advanced}
{synopt :{opt pstol:erance(#)}}set tolerance for overlap
assumption; default is {cmd:pstolerance(1e-5)}{p_end}
{synopt :{opth os:ample(newvar)}}{it:newvar} identifies
observations that violate the overlap assumption{p_end}
{synoptline}

{p 4 6 2}
{it:tmvarlist} may contain factor variables; see
{help fvvarlists}.{p_end}
{p 4 6 2}
{marker weight}{...}
{opt pweight}s are allowed; see {help weight}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:teffects2} {cmd:ipw} estimates the average treatment effect (ATE)
and the average treatment effect on the treated (ATT) from observational
data by inverse probability weighting (IPW).  IPW estimators use estimated
probability weights to correct for the missing data on the potential
outcomes.  {cmd:teffects2} {cmd:ipw} also reports an estimate of the average
untreated outcome (when estimating the ATE) or the average untreated outcome
for the treated (when estimating the ATT).  This estimate is referred to
as {cmd:POmean}.

{pstd}
Unlike {cmd:teffects} {cmd:ipw}, {cmd:teffects2} {cmd:ipw} allows for estimation
of the propensity score using the inverse probability tilting (IPT) estimator of
Egel, Graham, and Pinto (2008) and Graham, Pinto, and Egel (2012, 2016), as well
as the covariate balancing propensity score (CBPS) approach of Imai and Ratkovic
(2014).  When estimating the ATT, the two approaches are equivalent.  Thus,
{cmd:cbps} may only be chosen for {it:tmodel} when estimating the ATE.

{pstd}
As shown by Słoczyński, Uysal, and Wooldridge (2025), IPT is associated with
several numerical equivalences between IPW, AIPW, and IPWRA estimators.  Also,
the IPT weights are automatically normalized, which implies that the {cmd:nrm}
and {cmd:unnrm} options have no effect when {cmd:ipt} is chosen for {it:tmodel}.

{pstd}
{cmd:teffects2} {cmd:ipw} will determine that the overlap assumption is violated
and will exit with an error if an observation has an estimated propensity score
smaller than that specified by {cmd:pstolerance()} when estimating the ATE or larger
than one minus that specified by {cmd:pstolerance()} when estimating the ATE or ATT.

{pstd}
This is a companion software package for Słoczyński, Uysal, and Wooldridge (2025).
Please cite this paper if you use {cmd:teffects2} {cmd:ipw} in your work.


{marker references}{...}
{title:References}

{phang}
Egel, Daniel, Bryan S. Graham, and Cristine Campos de Xavier Pinto (2008). "Inverse
Probability Tilting and Missing Data Problems." NBER Working Paper No. 13981.

{phang}
Graham, Bryan S., Cristine Campos de Xavier Pinto, and Daniel Egel (2012). "Inverse
Probability Tilting for Moment Condition Models with Missing
Data." {it:Review of Economic Studies} 79(3), 1053{c 150}1079.

{phang}
Graham, Bryan S., Cristine Campos de Xavier Pinto, and Daniel Egel (2016). "Efficient
Estimation of Data Combination Models by the Method of Auxiliary-to-Study Tilting
(AST)." {it:Journal of Business & Economic Statistics} 34(2), 288{c 150}301.

{phang}
Imai, Kosuke, and Marc Ratkovic (2014). "Covariate Balancing Propensity
Score." {it:Journal of the Royal Statistical Society, Series B} 76(1), 243{c 150}263.

{phang}
Słoczyński, Tymon, S. Derya Uysal, and Jeffrey M. Wooldridge (2025). "Covariate
Balancing and the Equivalence of Weighting and Doubly Robust Estimators of Average
Treatment Effects." arXiv preprint arXiv:2310.18563.
Available at {browse "https://arxiv.org/abs/2310.18563"}.


{marker examples}{...}
{title:Examples}

        {com}. {stata "use https://tslocz.github.io/lalonde.dta, clear"}

        . {stata "keep if (dataset==0 | dataset==4) & treated==0"}

        . {stata "replace treated = 1 if dataset==0"}

        . {stata "teffects2 ipw (diff) (treated age educ re74 nodegree married black hispanic), atet"}

        . {stata "teffects2 ipw (diff) (treated age educ re74 nodegree married black hispanic, logit), atet"}
        {txt}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:teffects2} {cmd:ipw} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2:Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(N_clust)}}number of clusters{p_end}

{p2col 5 23 26 2:Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:teffects2}{p_end}
{synopt :{cmd:e(depvar)}}name of outcome variable{p_end}
{synopt :{cmd:e(tvar)}}name of treatment variable{p_end}
{synopt :{cmd:e(subcmd)}}{cmd:ipw}{p_end}
{synopt :{cmd:e(tmodel)}}{cmd:ipt}, {cmd:logit}, or {cmd:cbps}{p_end}
{synopt :{cmd:e(stat)}}statistic estimated, {cmd:ate} or {cmd:atet}{p_end}
{synopt :{cmd:e(statnorm)}}normalization option implemented, {cmd:nrm} or {cmd:unnrm}{p_end}
{synopt :{cmd:e(title)}}title in estimation output{p_end}
{synopt :{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt :{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt :{cmd:e(vcetype)}}title used to label Std. err.{p_end}
{synopt :{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 23 26 2:Matrices}{p_end}
{synopt :{cmd:e(b)}}coefficient vector{p_end}
{synopt :{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{p2col 5 23 26 2:Functions}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker acknowledgments}{...}
{title:Acknowledgments}

{phang} Portions of the code are adapted from official Stata code (StataCorp LLC)
and redistributed under the Stata EULA for use with Stata.


{marker license}{...}
{title:License}

{phang} This package is licensed under the MIT License.  See the LICENSE
file included with the distribution.


{marker authors}{...}
{title:Authors}

{phang} Derya Uysal, LMU Munich{p_end}
{pstd}Email: {browse "mailto:derya.uysal@econ.lmu.de":derya.uysal@econ.lmu.de}{p_end}

{phang} Tymon Słoczyński, Brandeis University{p_end}
{pstd}Email: {browse "mailto:tslocz@brandeis.edu":tslocz@brandeis.edu}{p_end}

{phang} Jeffrey M. Wooldridge, Michigan State University{p_end}
{pstd}Email: {browse "mailto:wooldri1@msu.edu":wooldri1@msu.edu}{p_end}
