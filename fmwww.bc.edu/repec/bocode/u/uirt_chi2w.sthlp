{smcl}
{* *! version 1.01 2022.11.13}{...}
{viewerjumpto "Syntax" "uirt_chi2w##syntax"}{...}
{viewerjumpto "Description" "uirt_chi2w##description"}{...}
{viewerjumpto "Options" "uirt_chi2w##options"}{...}
{viewerjumpto "Examples" "uirt_chi2w##examples"}{...}
{viewerjumpto "Stored results" "uirt_chi2w##results"}{...}
{viewerjumpto "References" "uirt_chi2w##references"}{...}
{cmd:help uirt_chi2w}
{hline}

{title:Title}

{phang}
{bf:uirt_chi2w} {hline 2} Postestimation command of {helpb uirt} to compute chi2W item-fit statistic

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:uirt_chi2w} [{varlist}] [{cmd:,}{it:{help uirt_chi2w##options:options}}]

{pmore}
{it:varlist} must include only variables that were declared in the main list of items of current {cmd:uirt} run.
If {it:varlist} is skipped or asterisk * is used, {cmd:uirt_chi2w} will either display the results that are currently stored in {cmd:e(item_fit_chi2W)} matrix
or it will compute chi2W item-fit statistic for all items declared in main list of items of current {cmd:uirt} run. 
This behavior depends on whether chi2W item-fit statistics were produced by current uirt run or not.

{synoptset 24 tabbed}{p2colset 7 32 34 4}
{marker options}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt bins(#)}} number of ability intervals for computation of chi2W {p_end}
{synopt:{opt npqm:in(#)}} minimum expected number of observations in ability intervals (NPQ); default: npqmin(20){p_end}
{synopt:{opt npqr:eport}} report information about minimum NPQ in ability intervals {synoptset 25 }{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:uirt_chi2w} is a postestimation command of {helpb uirt} that computes chi2W item-fit statistic.
chi2W is a Wald-type test statistic that compares the observed and expected item mean scores over a set of ability bins.
The observed and expected scores are weighted means with weights being {it: a posteriori} density of person's ability within the bin 
- likewise as in the approach used to compute observed proportions in ICC plots provided by {cmd:uirt}.
Properties of chi2W have been examined for dichotomous items, Type I error rate was close to nominal and it exceeded S-X2 in statistical power (Kondratek, 2022).
Behavior of chi2W in case of polytomous items, as for the time of this {cmd:uirt} release, has not been researched.


{marker options}{...}
{title:Options}

{phang}
{opt bins(#)} is used to set the number of ability intervals for computation of chi2W. 
Default settings depend on the item model and number of freely estimated parameters for the item being tested.
In general, the default is either {opt bins(3)} or a minimal number of intervals allowing for 1 degree of freedom
after accounting for the number of estimated item parameters.

{phang}
{opt npqm:in(#)} sets a minimum for NPQ integrated over any ability interval, where:
N is the number of observations, P is the expected item mean, and Q=(max_item_score-P).
Larger NPQ values are associated with better asymptotics of chi2W. 
If NPQ for a given ability bin is smaller than the value declared in {opt npqm:in(#)} {cmd:uirt} will decrease the number of bins for that item.
Default value is {opt npqm:in(20)}.

{phang}
{opt npqr:eport} adds a column to {cmd:r(item_fit_chi2W)} 
with information about smallest observed NPQ value over the ability intervals used for computation of chi2W.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse masc2} {p_end}

{pstd}Fit an IRT model with all items being 1PLM (1PLM is a dichotomous case of PCM) {p_end}
{phang2}{cmd:. uirt q*,pcm(*)} {p_end}

{pstd}Compute chi2W item fit statistic for all items {p_end}
{phang2}{cmd:. uirt_chi2w } {p_end}

{pstd}Re-fit the model with all items being 2PLM (the default for {cmd:uirt}), and compute chi2W for all items under this model {p_end}
{phang2}{cmd:. uirt q*} {p_end}
{phang2}{cmd:. uirt_chi2w } {p_end}

{pstd}Re-fit the model asking item q6 to be 3PLM, and compute chi2W only for that item {p_end}
{phang2}{cmd:. uirt q*,guess(q6,lr(1))} {p_end}
{phang2}{cmd:. uirt_chi2w q6} {p_end}


{marker results}{...}
{title:Stored results}

{syntab: {cmd: uirt_chi2w} stores the following in r():}

{p2col 5 17 21 2: Matrices}{p_end}
{synopt:{cmd:r(item_fit_chi2W)}}item-fit results for chi2W statistic{p_end}


{title:Author}

Bartosz Kondratek
everythingthatcounts@gmail.com


{marker references}{...}
{title:References}

{phang}
Kondratek, B. (2022).
Item-Fit Statistic Based on Posterior Probabilities of Membership in Ability Groups.
{it:Applied Psychological Measurement}, 46(6), 462{c -}478.
https://doi.org/10.1177/01466216221108061


