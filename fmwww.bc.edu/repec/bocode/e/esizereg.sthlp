{smcl}
{* *! version 3.0.0 12Aug2026}{...}
{* *! version 2.0.5 20Oct2025}{...}
{* *! version 2.0.4 21Mar2024}{...}
{* *! version 2.0.3 07Mar2024}{...}
{* *! version 2.0.2 29Feb2024}{...}
{* *! version 2.0.1 26Feb2024}{...}
{* *! version 2.0.0 29May2019}{...}

{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:esizereg} {hline 2}} Effect sizes for a {it:k}-level regression coefficient{p_end}
{p2colreset}{...}



{marker syntax}{...}
{title:Syntax}

{pstd}
Postestimation version of esizereg 

{p 8 14 2}
{cmd:esizereg}
{it: coef_name}
[{cmd:,}
{opt coh:ensd}
{opt hed:gesg}
{opt z:distribution}
{opt lev:el(#)}
{opt pw:compare}
]

{pstd}
{it: coef_name} is the categorical variable (with 2 or more levels) entered as a factor in the
preceding estimation model; see {helpb fvvarlist}.  The easiest way to identify the {it: coef_name} 
assigned by the estimation model is to specify the {cmd: coeflegend} option; see {helpb estimation options}. 


{pstd}
Immediate form of esizereg

{p 8 14 2}
{cmd:esizeregi}
{it: #coefficient}
{cmd:,}
{opt sd:p(#)}
{opt n1(#)}
{opt n2(#)}
[
{opt coh:ensd} 
{opt hed:gesg}
{opt z:distribution}
{opt lev:el(#)}
]

{pstd}
In the immediate version of {cmd:esizereg}, {it: coefficient} is the actual numeric value of the coefficient.


{synoptset 16 tabbed}{...}
{synopthdr:esizereg}
{synoptline}
{synopt:{opt coh:ensd}}report Cohen's {it:d}-family estimates; {cmd:the default}{p_end}
{synopt:{opt hed:gesg}}report Hedges's {it:g}-family estimates instead of Cohen's {it:d}{p_end}
{synopt:{opt z:distribution}}compute confidence limits using the {it:z} distribution instead of the default noncentral {it:t} distribution{p_end}
{synopt:{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt pw:compare}}report pairwise Cohen's {it:d}/Hedges's {it:g}, with confidence intervals, for every pair of levels of {it:coef_name}{p_end}
{synoptline}



{title:Description}

{pstd}
{cmd:esizereg} works with a categorical {it:coef_name} of 2 or more levels and reports
an omnibus {bf:Cohen's {it:f}}, the weighted root-mean-square of each level's standardized distance
from the adjusted grand (pooled) mean, and a per-level table of {bf:Cohen's {it:d}} or {bf:Hedges's {it:g}} 
comparing each level's adjusted mean to the adjusted grand mean, each with a noncentral-{it:t}-based confidence interval.
{cmd:esizereg} also reports an equivalent eta-squared for Cohen's {it:f}, and with 
the {opt pwcompare} option, {cmd:esizereg} additionally reports Cohen's {it:d}/Hedges's {it:g}, with
confidence intervals, for every pairwise comparison among the levels of {it:coef_name}.



{title:Options}

{p 4 8 2}
{cmd:cohensd} requests that Cohen's {it:d} (1988) be reported for the per-level and (if {opt pwcompare} is
specified) pairwise tables; {cmd:the default}.

{p 4 8 2}
{cmd:hedgesg} requests that Hedges's {it:g} (1981) be reported instead of Cohen's {it:d}.

{p 4 8 2}
{cmd:zdistribution} specifies that the {it:z} distribution be used to compute confidence limits rather than the
default {it:t} distribution (with a noncentrality parameter).

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for confidence intervals. The default
is {cmd:level(95)}.

{p 4 8 2}
{cmd:pwcompare} requests pairwise Cohen's {it:d}/Hedges's {it:g} comparisons, with confidence intervals, for
every pair of levels of {it:coef_name}.



{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}
{phang2}{cmd:. tab msmoke}{p_end}

{pstd}Estimate a model with a k-level factor variable (here, {cmd:msmoke}, with 4 levels: 0, 1-5, 6-10, 11+
cigarettes/day) and report the omnibus Cohen's {it:f} and per-level Cohen's {it:d} on birthweight.{p_end}
{phang2}{cmd:. regress bweight i.msmoke i.mmarried mage fbaby medu}{p_end}
{phang2}{cmd:. esizereg msmoke}{p_end}

{pstd}Report Hedges's {it:g} instead, using the {it:z} distribution for confidence limits, with pairwise
comparisons across all 6 pairs of {cmd:msmoke} levels.{p_end}
{phang2}{cmd:. esizereg msmoke, hedgesg zdistribution pwcompare}{p_end}

{dlgtab:Covariate balance -- unweighted}

{pstd}To use {cmd:esizereg} as an SMD balance diagnostic across the levels of a treatment/exposure variable,
fit the covariate on {it:coef_name} alone, with no other predictors -- this reduces the pooled SD to the plain
within-group pooled SD and the adjusted means to the raw group means, matching standard SMD balance
diagnostics. Here we check {cmd:mage}'s balance across the 4 levels of {cmd:msmoke} before any weighting.{p_end}
{phang2}{cmd:. regress mage i.msmoke}{p_end}
{phang2}{cmd:. esizereg msmoke, pwcompare}{p_end}

{dlgtab:Covariate balance -- multivalued treatment (IPTW)}

{pstd}Build generalized propensity score weights across all 4 levels of {cmd:msmoke} and re-check {cmd:mage}'s balance 
after weighting. Comparing this pairwise table (and the omnibus Cohen's {it:f}/eta-squared) to the unweighted version 
above shows whether the multivalued IPTW succeeded in reducing standardized mean differences in {cmd:mage} across levels of
{cmd:msmoke}.{p_end}
{phang2}{cmd:. mlogit msmoke i.(mmarried fbaby) mage c.mage#c.mage medu c.medu#c.medu c.mage#c.medu, base(0)}{p_end}
{phang2}{cmd:. predict double (ps1 ps2 ps3 ps4), pr}{p_end}
{phang2}{cmd:. gen iptw2 = 1/ps1 if msmoke==0}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps2 if msmoke==1}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps3 if msmoke==2}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps4 if msmoke==3}{p_end}
{phang2}{cmd:. regress mage i.msmoke [pweight=iptw2]}{p_end}
{phang2}{cmd:. esizereg msmoke, pwcompare}{p_end}

{dlgtab:Bootstrapping Cohen's f}

{pstd}The omnibus Cohen's {it:f} has no closed-form confidence interval in {cmd:esizereg} so a bootstrap is the way to obtain one, 
for any model type. Wrap the model-fitting step and {cmd:esizereg} call in a small program and pass it to {helpb bootstrap}. This 
example reuses the weighted model from the previous example; because {cmd:iptw2} was constructed once, upfront, from the full sample, this
bootstrap captures sampling uncertainty in the outcome model and Cohen's {it:f} itself, but not in the
propensity-score estimation step that produced {cmd:iptw2}. The per-level Cohen's {it:d}'s (also without a closed-form CI; see 
{help esizereg##results:Stored results} below) can be bootstrapped in the same run at no extra cost.{p_end}

{phang2}{cmd:capture program drop bootf}{p_end}
{phang2}{cmd:program define bootf, rclass}{p_end}
{phang3}{cmd:    regress mage i.msmoke [pweight=iptw2]}{p_end}
{phang3}{cmd:    esizereg msmoke}{p_end}
{phang3}{cmd:    return scalar f  = r(f)}{p_end}
{phang3}{cmd:    return scalar d1 = r(d1)}{p_end}
{phang3}{cmd:    return scalar d2 = r(d2)}{p_end}
{phang3}{cmd:    return scalar d3 = r(d3)}{p_end}
{phang3}{cmd:    return scalar d4 = r(d4)}{p_end}
{phang2}{cmd:end}{p_end}
{phang2}{cmd:bootstrap r(f) r(d1) r(d2) r(d3) r(d4), reps(1000) seed(12345): bootf}{p_end}

{pstd}Cohen's {it:f} is bounded below at zero by construction (it is a root-mean-square), so the default
normal-approximation bootstrap CI can report an implausible negative lower bound, particularly when the true
{it:f} is small. Check the percentile and BCa intervals as well, which respect that boundary.{p_end}
{phang2}{cmd:. estat bootstrap, all}{p_end}

{pstd}{it:coef_name} should always be the underlying categorical variable, never a specific level or interaction
term -- this holds even when {it:coef_name} is interacted with another variable elsewhere in the model.
{cmd:esizereg} obtains adjusted means via {helpb margins}, which correctly averages over the interacting
variable's distribution within each level of {it:coef_name}.{p_end}
{phang2}{cmd:. regress bweight i.msmoke##i.mmarried mage fbaby medu}{p_end}
{phang2}{cmd:. esizereg msmoke, pwcompare}{p_end}

{dlgtab:Using esizeregi directly}

{pstd}Estimate the treatment effect of {cmd:mbsmoke} on {cmd:bweight}, controlling for several covariates.{p_end}
{phang2}{cmd:. regress bweight mbsmoke mmarried mage fbaby medu}{p_end}

{pstd}Get the pooled standard error of the adjusted model using {helpb margins}.{p_end}
{phang2}{cmd:. margins}{p_end}

{pstd}Convert the pooled standard error to a pooled standard deviation by multiplying it by the square root of N (4642).{p_end}
{phang2}{cmd:. display 8.253892 * sqrt(4642)}{p_end}

{pstd}Get the number of observations in each group of {cmd:mbsmoke}.{p_end}
{phang2}{cmd:. tab mbsmoke}{p_end}

{pstd}Compute the effect size.{p_end}
{phang2}{cmd:. esizeregi -224.422, sdp(562.355997) n1(864) n2(3778)}{p_end}

{pstd}Compute confidence limits using the {it:z} distribution instead.{p_end}
{phang2}{cmd:. esizeregi -224.422, sdp(562.355997) n1(864) n2(3778) zdist}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:esizereg} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(f)}}Cohen's {it:f} (omnibus){p_end}
{synopt:{cmd:r(eta2)}}equivalent eta-squared, {cmd:r(f)}^2/(1+{cmd:r(f)}^2){p_end}
{synopt:{cmd:r(sdpooled)}}pooled/model standard deviation used as the common denominator{p_end}
{synopt:{cmd:r(N)}}total number of observations across all levels{p_end}
{synopt:{cmd:r(k)}}number of levels of {it:coef_name}{p_end}
{synopt:{cmd:r(n#)}}sample size of level {it:#}{p_end}
{synopt:{cmd:r(d#)}}Cohen's {it:d} for level {it:#} vs. the pooled mean{p_end}
{synopt:{cmd:r(lb_d#)}}lower confidence bound for {cmd:r(d#)}{p_end}
{synopt:{cmd:r(ub_d#)}}upper confidence bound for {cmd:r(d#)}{p_end}
{synopt:{cmd:r(g#)}}Hedges's {it:g} for level {it:#} vs. the pooled mean{p_end}
{synopt:{cmd:r(lb_g#)}}lower confidence bound for {cmd:r(g#)}{p_end}
{synopt:{cmd:r(ub_g#)}}upper confidence bound for {cmd:r(g#)}{p_end}
{synopt:{cmd:r(npairs)}}number of pairwise comparisons ({opt pwcompare} only){p_end}
{p2colreset}{...}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(pairwise)}}matrix of pairwise Estimate/SE/LL/UL ({opt pwcompare} only){p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Cohen, J. 1988. {it:Statistical Power Analysis for the Behavioral Sciences}. 2nd ed. Hillsdale, NJ: Erlbaum.{p_end}

{p 4 8 2}
Hedges, L. V. 1981. Distribution theory for Glass's estimator of effect size and related estimators.
{it:Journal of Educational Statistics} 6: 107-128.{p_end}

{p 4 8 2}
Linden, A. 2026. Cohen's {it:f} or mean standardized differences? Assessing covariate balance with multivalued treatments.
Preprint: arXiv:2608.10266 {p_end}

{p 4 8 2}
Lipsey, M. W., and Wilson, D. B. (2001). Applied social research methods series; Vol. 49. 
{it:Practical meta-analysis}. Thousand Oaks, CA, US: Sage Publications, Inc. {p_end}



{marker citation}{title:Citation of {cmd:esizereg}}

{p 4 8 2}{cmd:esizereg} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2019). ESIZEREG: Stata module for calculating effect size based on a {it:k}-level linear regression coefficient. 
Statistical Software Components S458607, Boston College Department of Economics. {p_end}



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb esize}{p_end}
