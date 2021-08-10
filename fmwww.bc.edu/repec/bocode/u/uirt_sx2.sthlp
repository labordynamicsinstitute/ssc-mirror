{smcl}
{* *! version 1,0 2021.03.09}{...}
{viewerjumpto "Syntax" "uirt_sx2##syntax"}{...}
{viewerjumpto "Description" "uirt_sx2##description"}{...}
{viewerjumpto "Options" "uirt_sx2##options"}{...}
{viewerjumpto "Examples" "uirt_sx2##examples"}{...}
{viewerjumpto "Stored results" "uirt_sx2##results"}{...}
{viewerjumpto "References" "uirt_sx2##references"}{...}
{cmd:help uirt_sx2}
{hline}

{title:Title}

{phang}
{bf:uirt_sx2} {hline 2} Postestimation command of {helpb uirt} to compute S-X2 item-fit statistic

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:uirt_sx2} [{varlist}] [{cmd:,}{it:{help uirt_sx2##options:options}}]

{pmore}
{it:varlist} must include only variables that were declared in the main list of items of current {cmd:uirt} run. 
If {it:varlist} is skipped or asterisk * is used, {cmd:uirt_sx2} will either display the results that are currently stored in {cmd:e(item_fit_SX2)} matrix
or it will compute S-X2 item-fit statistic for all items declared in main list of items of current {cmd:uirt} run. 
This behavior depends on whether S-X2 item-fit statistics were produced by current uirt run or not.

{synoptset 24 tabbed}{p2colset 7 32 34 4}
{marker options}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt minf:req(#)}} minimum expected number of observations in ability intervals (NP and NQ); default: minf(1){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:uirt_sx2} is a postestimation command of {helpb uirt} that computes the classical S-X2 statistic proposed by Orlando and Thissen (2000).
It is available only for dichotomous items and it cannot be used in multigroup setting. 
The number-correct score used for grouping is obtained from dichotomous items
- if polytomous items are present in data, they are ignored in computation of S-X2.
If a dichotomous item has missing responses it is also ignored in computation of S-X2. The results are stored in {cmd:r(item_fit_SX2)}.

{marker options}{...}
{title:Options}

{phang}
{opt minf:req(#)} sets a minimum for both NP and NQ integrated over any ability interval, where:
N is the number of observations,
P is the expected item mean, and Q=(1-P).
Default value is {opt minf:req(1)}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse masc2} {p_end}

{pstd}Fit an IRT model with all items being 1PLM (1PLM is a dichotomous case of PCM) {p_end}
{phang2}{cmd:. uirt q*,pcm(*)} {p_end}

{pstd}Compute S-X2 item fit statistic for all items {p_end}
{phang2}{cmd:. uirt_sx2 } {p_end}

{pstd}Re-fit the model with all items being 2PLM (the default for {cmd:uirt}), and compute S-X2 for all items under this model {p_end}
{phang2}{cmd:. uirt q*} {p_end}
{phang2}{cmd:. uirt_sx2 } {p_end}

{pstd}Re-fit the model asking item q6 to be 3PLM, and compute S-X2 only for that item {p_end}
{phang2}{cmd:. uirt q*,guess(q6,lr(1))} {p_end}
{phang2}{cmd:. uirt_sx2 q6} {p_end}


{marker results}{...}
{title:Stored results}

{syntab: {cmd: uirt_sx2} stores the following in r():}

{p2col 5 17 21 2: Matrices}{p_end}
{synopt:{cmd:r(item_fit_SX2)}}item-fit results for S-X2 statistic{p_end}


{title:Author}

Bartosz Kondratek
everythingthatcounts@gmail.com


{marker references}{...}
{title:References}

{phang}
Orlando, M., & Thissen, D. 2000. 
Likelihood-based item-fit indices for dichotomous item response theory models.
{it:Applied Psychological Measurement}, 24, 50{c -}64.




