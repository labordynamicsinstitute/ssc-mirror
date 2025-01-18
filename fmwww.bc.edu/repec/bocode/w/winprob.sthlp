{smcl}
{* *! version 1.0  14jan2025}{...}
{p2colreset}{...}

{marker title}{...}
{title:Title}

{pstd}
{bf:winprob} - Compute the win probability for single outcome

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:winprob} 
{it:groupvar}
{it:scorevar}
{ifin}{cmd:,}
[{it:{help multiauc##options_tbl:options}}]

{synoptset 20 tabbed}{...}
{marker options_tbl}{...}
{synopthdr:options}
{synoptline}
{syntab:Options}
{synopt:{opt dir:ection(string)}}Specify the direction of comparison.{p_end}
{synopt:{opth ci:type(multiauc##citypes:citype)}}specify the 
transformation method to use when constructing the confidence interval.{p_end}
{synopt:{opt alpha(real)}}specify the two-sided type 1 error level.{p_end}
{synopt:{opt test0(real)}}Specify the null hypothesis probability to test. 
The default is 0.50.{p_end}
{synopt:{opt winfrac(varname)}}Specify a variable to save the win fractions.{p_end}
{synopt:{opt replace}}Replace the variable specified in {opt winfrac()}.{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{marker citype}{...}
{synopthdr:citypes}
{synoptline}
{syntab:Options}
{synopt:{opt normal}}uses asymptotic Normal (Wald-type) method for large 
samples.{p_end}
{synopt:{opt logit}}uses a logit transformation. {it:This is the default and 
recomended in most cases.}.
{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{opt winprob} performs a non-parametric test for the win probability (also ]
called the Wilcoxon-Mann-Whitney test probability, c-statistic, AUC, 
probabilistic index). The command returns the point estimate and associated 
confidence interval, standard error and hypothesis test for the win probability.

{pstd}
{opt groupvar} is the binary (0/1) indicator for each of two groups (for 
example, placebo and treatment in the context of a randomized controlled trial).
The win probability is formulated to compare values of {it:scorevar} in 
{it:groupvar==1} compared to those in {it:groupvar==0}.

{pstd}
{opt scorevar} is score or value to be compared. The values can be binary, 
ordinal or continuous in nature, but they must be a numeric type.

{pstd}
{opt direction()} specifies the direction of comparison of scores. If higher 
values of {it:scorevar} are "better" or preferred to lower scores, then specify 
{opt direction(>)}, meaning the quantity computed is 
WinProb = Prob[{it:scorevar}({it:groupvar}==1) >= 
{it:scorevar}({it:groupvar}==0)].
If lower scores are preferred, then specify {opt direction(<)}, then the 
quantity computed is 
WinProb = Prob[{it:scorevar}({it:groupvar}==1) <= 
{it:scorevar}({it:groupvar}==0)].
By default, higher scores are considered "better" than lower scores.

{pstd}
{opt citype()} specified how the confidence interval is constructed. 
The default and preferred method is the logit transformation.

{pstd}
{opt winfrac()} specifies the name of a new variable in which to save win 
fractions which are the basis for how the win probability is estimated. If the
variable already exists, then {opt replace} must also be specified. The 
existing variable will be dropped and replaced.

{pstd}
{opt test0()} specifies the null hypothesis test value for the win probability.
By default, this is 0.5, indicating no differences between groups.

{pstd}
{opt alpha()} specifies the two-sided type 1 error rate. By default, this 
is 0.05.

{marker examples}{...}
{title:Examples}

{pstd}Compute the win probability of foreign cars having higher prices than 
domestic cars.{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. winprob foreign price}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
The following results are stored in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(winp)}}win probability{p_end}
{synopt:{cmd:r(winp_ll)}}lower limit of confidence interval{p_end}
{synopt:{cmd:r(winp_ul)}}upper limit of confidence interval{p_end}
{synopt:{cmd:r(se_winp)}}standard error of win probability{p_end}
{synopt:{cmd:r(logit_se)}}logit-based standard error of win probability 
({it:only if logit confidence intervals are requested}){p_end}
{synopt:{cmd:r(alpha)}}two-sided alpha level{p_end}
{synopt:{cmd:r(test0)}}null hypothesis test value{p_end}
{synopt:{cmd:r(p)}}two-sided p-value of test{p_end}
{synopt:{cmd:r(t)}}test statistic based on t-distribution
({it:only if logit confidence intervals are requested}){p_end}
{synopt:{cmd:r(t_df)}}test statistic degrees-of-freedom
({it:only if logit confidence intervals are requested}){p_end}
{synopt:{cmd:r(z)}}test statistic based on standard Normal distribution
({it:only if Normal confidence intervals are requested}){p_end}

{p2colreset}{...}
{synoptset 20 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(citype)}}Method of construction of confidence interval.{p_end}

{p2colreset}{...}
{marker author}{...}
{title:Author}

{pstd}Leonardo Guizzetti{p_end}
{pstd}leonardo.guizzetti@gmail.com{p_end}

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}Thanks to Guangyong Zou for the inpsiration to write this program.{p_end}

{marker references}{...}
{title:References}

{phang}
Zou G. Confidence interval estimation for treatment effects in cluster 
randomization trials based on ranks. {it:Statistics in Medicine}. 
2021;40(14):3227-3250. doi:10.1002/sim.8918
{p_end}

{phang}
Zou G, Zou L, Qiu S. Parametric and nonparametric methods for confidence 
intervals and sample size planning for win probability in parallel-group 
randomized trials with Likert item and Likert scale data. 
{it:Pharmaceutical Statistics}. 2023; 22(3): 418-439. doi:10.1002/pst.2280
{p_end}
