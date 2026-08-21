{smcl}
{* *! version 1.0.0 13Aug2026}{...}

{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:varatio} {hline 2}} {it:k}-group omnibus variance-ratio balance diagnostic{p_end}
{p2colreset}{...}



{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:varatio}
{varname} {ifin} {weight} {cmd:,}
{opth "by(varname:groupvar)"}

{pstd}
{it:groupvar} must take on {it:k} >= 2 distinct values, numeric or string.
The (optionally weighted) variance of {it:varname} is compared across all
{it:k} groups simultaneously.



{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth "by(varname:groupvar)"}}specify a variable that
identifies the {it:k} groups ({it:k} >= 2){p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt Required}{p_end}
{p 4 6 2}
{cmd:aweight}s, {cmd:pweight}s, and {cmd:iweight}s are allowed; see
{help weight}.



{title:Description}

{pstd}
{cmd:varatio} reports a {it:k}-group omnibus summary of variance-ratio
imbalance across levels of {it:by()}. Three omnibus statistics are
reported together: (1) {bf:F_VR}, a size-weighted quadratic combination of the
pairwise log-variance-ratios (Linden, 2026), (2) {bf:GMVR}, the geometric mean 
of the pairwise variance ratios, extended from two-groups (Linden and Samuels, 2013), and (3) {bf:max(VR*)}, 
the largest pairwise variance ratio, extended from two-groups for standardized mean differences (Lopez and Gutman, 2017).{p_end}



{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Interpreting the omnibus statistics:} {bf:GMVR} and {bf:max(VR*)} inherit Rubin's (2001) 
convention that values above 2.0 (or, before symmetrizing, below 0.5) indicate
imbalance; Linden and Samuels (2013) state the same convention applies to
the geometric mean specifically. {bf:F_VR} is {ul:not} on the same scale --
it is a log/RMS-based construction. Based on extensive simulations, Linden (2026)
derived the following recommendations:

{pstd}
F_VR < 0.10 — groups are well balanced{p_end}
{pstd}
F_VR > 0.30 — groups are imbalanced{p_end}
{pstd}
0.10 <= F_VR <= 0.30 — balance is uncertain: inspect the per-group and pairwise results{p_end}



{title:Options}

{p 6 8 2}
{opth "by(varname:groupvar)"} is required. It specifies a variable that
identifies the {it:k} groups, where {it:k} >= 2. It may be numeric or
string.



{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}
{phang2}{cmd:. tab msmoke}{p_end}

{pstd}{cmd:varatio} across the 4 levels of {cmd:msmoke} (0, 1-5, 6-10, 11+
cigarettes/day), unweighted{p_end}
{phang2}{cmd:. varatio mage, by(msmoke)}{p_end}

{dlgtab:Multivalued treatment (IPTW)}

{pstd}Build generalized propensity score weights across all 4 levels of
{cmd:msmoke} and re-check {cmd:mage}'s variance-ratio balance after
weighting. Comparing this to the unweighted call above shows whether the
multivalued IPTW succeeded in reducing variance imbalance in {cmd:mage}
across levels of {cmd:msmoke}, not just mean imbalance.{p_end}
{phang2}{cmd:. mlogit msmoke i.(mmarried fbaby) mage c.mage#c.mage medu c.medu#c.medu c.mage#c.medu, base(0)}{p_end}
{phang2}{cmd:. predict double (ps1 ps2 ps3 ps4), pr}{p_end}
{phang2}{cmd:. gen iptw2 = 1/ps1 if msmoke==0}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps2 if msmoke==1}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps3 if msmoke==2}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps4 if msmoke==3}{p_end}
{phang2}{cmd:. varatio mage [pweight=iptw2], by(msmoke)}{p_end}

{dlgtab:Bootstrapping F_VR}

{pstd}{cmd:varatio} has no closed-form confidence interval. Every 
quantity {cmd:varatio} computes -- omnibus, per-group, and pairwise
-- is returned in {cmd:r()} (see {help varatio##results:Stored results}
below), so any of them can be bootstrapped directly.{p_end}

{phang2}{cmd:capture program drop bootvr}{p_end}
{phang2}{cmd:program define bootvr, rclass}{p_end}
{phang3}{cmd:    varatio mage [pweight=iptw2], by(msmoke)}{p_end}
{phang3}{cmd:    return scalar fvr  = r(F_VR)}{p_end}
{phang3}{cmd:    return scalar gmvr = r(GMVR)}{p_end}
{phang2}{cmd:end}{p_end}
{phang2}{cmd:bootstrap r(fvr) r(gmvr), reps(1000) seed(12345): bootvr}{p_end}

{pstd}F_VR is bounded below at zero by construction (it is a root-mean-
square), so the default normal-approximation
bootstrap CI can report an implausible negative lower bound, particularly
when the true F_VR is small. Check the percentile and BCa intervals as
well, which respect that boundary.{p_end}
{phang2}{cmd:. estat bootstrap, all}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:varatio} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(F_VR)}}omnibus F_VR{p_end}
{synopt:{cmd:r(GMVR)}}geometric mean variance ratio{p_end}
{synopt:{cmd:r(maxVR)}}maximum pairwise variance ratio{p_end}
{synopt:{cmd:r(N)}}total number of observations across all groups{p_end}
{synopt:{cmd:r(k)}}number of groups{p_end}
{synopt:{cmd:r(npairs)}}number of pairwise comparisons{p_end}
{p2colreset}{...}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(by)}}the group variable{p_end}
{p2colreset}{...}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(pergroup)}}each group's variance, log-variance, and
deviation from the weighted mean log-variance{p_end}
{synopt:{cmd:r(pairwise)}}VR* and log(VR*) for every pairwise comparison{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Linden, A. 2026. Beyond the mean: A weighted {it:k}-sample omnibus
variance-ratio statistic for covariate balance diagnostics.
Preprint: arXiv: {p_end}

{p 4 8 2}
Linden, A., and S. J. Samuels. 2013. Using balance statistics to determine
the optimal number of controls in matching studies. 
{it:Journal of Evaluation in Clinical Practice} 
19: 968-975.{p_end}

{p 4 8 2}
Lopez, M. J., and R. Gutman. 2017. Estimation of causal effects with
multiple treatments: a review and new ideas. 
{it:Statistical Science}
32(3): 432-454.{p_end}

{p 4 8 2}
Rubin, D. B. 2001. Using propensity scores to help design observational
studies: application to the tobacco litigation. 
{it:Health Services and Outcomes Research Methodology} 
2: 169-188.{p_end}



{marker citation}{title:Citation of {cmd:varatio}}

{p 4 8 2}{cmd:varatio} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). VARATIO: Stata module for calculating the {it:k}-group omnibus variance-ratio balance diagnostic. 
Statistical Software Components SXXXXXX, Boston College Department of Economics. {p_end}



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb esizereg}, {helpb kstest} (if installed), {helpb cvmtest} (if installed), {helpb adtest} (if installed) {p_end}
