{smcl}
{* *! version 1.0.0  02dec2023}{...}
{p2colreset}{...}

{marker title}{...}
{title:Title}

{pstd}
{bf:multiauc} - Calculation of correlated areas under the receiver operating 
characteristic curves and their differences.

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:multiauc} 
{it:groupvar}
{varlist}
{ifin}{cmd:,}
[{it:{help multiauc##options_tbl:options}}]

{synoptset 20 tabbed}{...}
{marker options_tbl}{...}
{synopthdr:options}
{synoptline}
{syntab:Options}
{synopt:{opt id:var(idvar)}}specify a numeric ID variable for the 
observations in the dataset{p_end}
{synopt:{opth ci:type(multiauc##citypes:citype)}}specify the 
transformation method to use when constructing confidence intervals for 
individual score AUC estimates.{p_end}
{synopt:{opt ci:level(cilevel)}}specify the two-sided significance level 
to construct confidence intervals.{p_end}
{synopt:{opt keepd:values}}keeps the calculated D-values in a separate frame.
{p_end}
{synopt:{opt onlyd:values}}computes the D-values only and stops 
exection. Must be used with option {opt keepdvalues}.{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{marker citype}{...}
{synopthdr:citypes}
{synoptline}
{syntab:Options}
{synopt:{opt normal}}uses Normal (Wald-type) method to calculate the 
confidence interval (no transformation).{p_end}
{synopt:{opt logit}}uses a logit transformation. {it:This is the default}.
{p_end}
{synopt:{opt atanh}}uses Fisher's Z (atanh) transformation.{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{opt multiauc} is intended to produce point estimates and confidence intervals
for the AUC for two or more correlated scores (or prognostic values). In 
addition, it will also compute all pair-wise contrasts and their confidence 
intervals.

{pstd}
{opt groupvar} is the binary (0/1) indicator of the outcome. It is assumed 
that the AUC is to estimate the win probability of {it:group==1} over 
{it:group==0}.

{pstd}
{opt varlist} are the scores (or prognostic indices). For each score, higher 
values are assumed to be associated with {it:group==1}, that is, higher values 
indicate the condition of interest. A {bf: minimum of 2} scores are required.

{pstd}
{opt citype()} applies only the specified confidence interval type to the 
AUC for the individual scores. The confidence intervals for the pair-wise 
contrasts of AUC values are always constructed with Fisher's Z (atah) 
transformation.

{pstd}
{opt keepdvalues} retains the calculated D-values in a a frame named 
{it:_Dvalues}. If this frame exists, it will be replaced.

{pstd}
{opt onlydvalues} stops execution of this program after calculating the 
D-values. It must be used with {opt keepdvalues}.

{marker examples}{...}
{title:Examples}

{pstd}Using the De Long, et al. (1988) data, compute the correlated AUCs and 
their differences.{p_end}
{phang2}{cmd:. use delong1988}{p_end}
{phang2}{cmd:. multiauc group tp alb kg, idvar(pid)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
The following results are stored in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(level)}}Confidence interval level.{p_end}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(group)}}Group variable for condition of interest.{p_end}
{synopt:{cmd:r(scores)}}Score variables as chosen in varlist.{p_end}
{synopt:{cmd:r(auc_citype)}}Method of construction of CI for each AUC.{p_end}
{synopt:{cmd:r(delta_citype)}}Method of construction of CI for AUC contrasts. 
This is always {it:"atanh"}.{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(N_obs)}}Number of valid observations from each score in 
estimation sample.{p_end}
{synopt:{cmd:r(auc)}}AUC estimates for each score.{p_end}
{synopt:{cmd:r(SE_auc)}}Standard errors for each AUC.{p_end}
{synopt:{cmd:r(CI_auc)}}Confidence intervals for each AUC.{p_end}
{synopt:{cmd:r(V_auc)}}Multivariate normal estimate of variance-covariance 
matrix of the AUCs.{p_end}
{synopt:{cmd:r(delta)}}Pair-wise estimates of the contrast (difference) 
between correlated AUC values.{p_end}
{synopt:{cmd:r(SE_delta)}}Standard errors for the AUC contrasts.{p_end}
{synopt:{cmd:r(CI_delta)}}Confidence intervals for the AUC contrasts.{p_end}

{p2colreset}{...}

{marker author}{...}
{title:Author}

{pstd}Leonardo Guizzetti{p_end}
{pstd}leonardo.guizzetti@gmail.com{p_end}

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}Thanks to Guangyong Zou for the encouragement to write this program.{p_end}

{marker references}{...}
{title:References}

{phang}
DeLong ER, DeLong DM, Clarke-Pearson DL. 
Comparing the areas under two or more correlated receiver operating 
characteristic curves: A nonparametric approach.
{it:Biometrics}. 1988; 44: 837–845. doi: 10.2307/2531595
{p_end}

{phang}
Zou L, Choi Y-H, Guizzetti L, Shu D, Zou J, Zou G. 
Extending the DeLong algorithm for comparing areas under correlated 
receiver operating characteristic curves with missing data. 
{it:Statistics in Medicine}. 2024; 43(21): 4148-4162. 
doi: 10.1002/sim.10172
{p_end}
