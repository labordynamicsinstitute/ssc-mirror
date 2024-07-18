{smcl}
{* *! version 2.0.0  17jul2024}{...}
{cmd:help pwmc}
{hline}

{title:Title}

{p 5 8 2}
{cmd:pwmc} {hline 2} Pairwise multiple comparisons of means with
unequal variances


{title:Syntax}

{p 5 8 2}
Pairwise multiple comparisons of means  

{p 8 8 2}
{cmd:pwmc} 
{varname} 
{ifin} 
{cmd:,} {cmd:over(}{varname}{cmd:)} 
[
{it:options}
]


{p 5 8 2}
Immediate form

{p 8 12}
{cmd:pwmci} 
{cmd:(}{it:#obs1} {it:#mean1} {it:#sd1}{cmd:)} 
{cmd:(}{it:#obs2} {it:#mean2} {it:#sd2}{cmd:)}
{cmd:(}{it:#obs3} {it:#mean3} {it:#sd3}{cmd:)}
{it:...}
[
{cmd:,} 
{it:options}
]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:* {cmd:{ul:o}ver(}{varname}{cmd:)}}compare means over the levels 
of {it:varname}
{p_end}

{syntab:Reporting}
{synopt:{cmd:{ul:mcomp}are(}{it:{help pwmc##mcmethod:method}}{cmd:)}}adjust 
for multiple comparisons; default is {cmd:mcompare(c gh t2)}
{p_end}
{synopt:{opt hc3}}estimate HC3 standard errors; see {helpb regress}{p_end}
{synopt:{opt w:elch}}use Welch's approximate degrees of freedom{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is 
{cmd:level({ccl level})}
{p_end}
{synopt:{opt ci:effects}}display confidence intervals; the default
{p_end}
{synopt:{opt pv:effects}}display test statistics and p-values
{p_end}
{synopt:{opt eff:ects}}display test statistics, p-values, and 
confidence intervals
{p_end}
{synopt:{opt varl:abel}}display variable labels{p_end}
{synopt:{opt vall:abel}}display value labels{p_end}
{synopt:{it:{help pwmc##fmtopts:format_options}}}control column formats
{p_end}
{synopt:{opt notab:le}}suppress coefficient table
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 8 2}* {opt over(varname)} is not allowed with the 
immediate command and required otherwise.


{title:Description}

{pstd}
{cmd:pwmc} 
performs pairwise comparisons of means. 
It computes pairwise differences of the means of {varname} 
over the levels of {opt over(varname)}. 
The standard errors and confidence intervals 
do not assume equal variances across groups. 
{cmd:pwmc} 
adjusts the p-values and confidence intervals for multiple comparisons. 

{pstd}
{cmd:pwmci} 
is the immediate form of {cmd:pwmc}; see {help immed}.


{title:Options}

{dlgtab:Main}

{phang}
{opt over(varname)} 
is required with {cmd:pwmc} 
and it specifies that means are computed for each level of {it:varname}. 
The option is not allowed with {cmd:pwmci}.

{dlgtab:Reporting}

{marker mcmethod}{...}
{phang}
{opt mcompare(method)} 
specifies the method for computing p-values and confidence intervals. 
Confidence intervals are computed as 

{p 24 24 2}
CI = d +/- A*se

{phang2}
where d is the difference between means, se is the standard error of 
the difference, and A is the critical value adjusted according to 
{it:method}. 

{phang2}
{cmd:mcompare({ul:noadj}ust)} specifies no adjustment for multiple 
comparisons.

{p 24 24 2}
A = inv_t{nuhat, (1-alpha)/2}

{p 12 12 2}
where inv_t is the inverse cumulative (upper tail) 
{help f_invttail:Student's t distribution} with nuhat degrees 
of freedom using Satterthwaite's (1946) approximation formula, 
and alpha = {ccl level}/100 (see option {opt level()}).

{p 12 12 2}
The unadjusted p-value is 

{p 24 24 2}
p = 2 * ttail{nuhat, {c |}t{c |}}

{p 12 12 2}
where ttail is the cumulative (upper tail) 
{help f_ttail:Student's t distribution} and {c |}t{c |} is the 
(absolute) t value. 

{p 12 12 2}
{opt noadjust} is a synonym for {cmd:mcompare(noadjust)}.

{phang2}
{cmd:mcompare(c)} implements Dunnett's (1980) C method. 

{p 24 24 2}
A = inv_SR_star^(1/2)

{p 12 12 2}
where inv_SR_star is computed as follows. Let i = 1, 2, ..., k denote 
the k groups. Let n_i denote the number of observations in group i and 
v_i the squared standard error of the mean in group i. Further, let 
inv_SR_i{k, n_i-1, alpha} denote the inverse 
{help f_invtukeyprob:Studentized range distribution} with k, n_i, and 
alpha defined as above. Then, 

{p 24 24 2}
inv_SR_star = (inv_SR_i*v_i + inv_SR_j*v_j) / (v_i + v_j)

{p 12 12 2}
{cmd: pwmc} does not compute adjusted p-values for Dunnett's C method.

{phang2}
{cmd:mcompare(gh)} implements the method discussed in 
Games and Howell (1976). 

{p 24 24 2}
A = inv_SR{k, nuhat, alpha}^(1/2)

{p 12 12 2}
where inv_SR is the inverse Studentized range distribution and all other 
terms are defined as above.

{p 12 12 2}
The adjusted p-value is computed as 

{p 24 24 2}
p_adj = 1 - SR{k, nuhat, {c |}t{c |}*2^(1/2)}

{p 12 12 2}
where SR is the cumulative {help f_tukeyprob:Studentized range distribution} 
and all other terms are defined as above.

{phang2}
{cmd:mcompare(t2)} implements Tamhane's (1979) T2 method. 

{p 24 24 2}
A = inv_t{nuhat, (1-alpha^(1/kstar))/2}

{p 12 12 2}
where kstar = k*(k-1)/2, the number of comparisons, and all other 
terms are defined as above.

{p 12 12 2}
The adjusted p-value is computed as 

{p 24 24 2}
p_adj = 1 - (1-p)^kstar

{p 12 12 2}
where p is the unadjusted p-value and all other terms are defined as above.


{phang2}
In {it:method}, case does not matter, and the default is (historically)
{cmd:mcompare(c gh t2)}.

{phang}
{opt hc3} 
uses (n-1) as the denominator for computing standard errors. 
The resulting standard errors are equivalent to those reported by {helpb regress} 
for a model with a single categorical predictor that indicates the groups
when {cmd:vce(hc3)} is specified.
The default standard errors are equivalent to those of {cmd:regress} 
when the {cmd:vce(hc2)} option is specified 
and those reported by {helpb ttest} with the {opt unequal} option.

{phang}
{opt welch} 
uses Welch's (1947) formula to approximate the degrees of freedom. 
The default is to use Satterthwaite's (1946) approximation.

{phang}
{opt l:evel(#)} 
specifies the confidence level, as a percentage, for confidence intervals. 
The default is {cmd:level({hi:{ccl level}})}; see {helpb set level}.

{phang}
{opt cieffects} 
reports mean differences, standard errors, and confidence intervals. 
This is the default. 

{phang}
{opt pveffects} 
reports mean differences, standard errors, test statistics, and p-values.
        
{phang}
{opt effects} 
reports mean differences, standard errors, test statistics, p-values, and confidence intervals.

{phang}
{opt varlabel} 
displays variable labels instead of variable names. 
This option is not allowed with {cmd:pwmci}.

{phang}
{opt vallabel} 
displays value labels instead of numeric codes. 
This option is not allowed with {cmd:pwmci}.

{marker fmtopts}{...}
{phang}
{cmd:cformat(}{it:{help %fmt}}{cmd:)}; 
{cmd:pformat(}{it:{help %fmt}}{cmd:)}; 
and {cmd:sformat(}{it:{help %fmt}}{cmd:)} 
specify how to format 
differences of means, 
standard errors, 
confidence limits; 
(adjusted) p-values; 
and test statistics, 
respectively.

{phang}
{opt notable} 
does not report the results; results are still stored in {cmd:r()}.


{title:Examples}

{phang2}
{cmd:. sysuse nlsw88}
{p_end}
{phang2}
{cmd:. pwmc wage , over(race)}
{p_end}
{phang2}
{cmd:. pwmci (1637 8.08 5.96) (583 6.84 5.08) (26 8.56 5.21)}
{p_end}


{title:Saved results}

{pstd}
{cmd:pwmc} saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
{synoptset 16 tabbed}{...}
{synopt:{cmd:r(k)}}number of groups{p_end}
{synopt:{cmd:r(ks)}}number of pairwise comparisons{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}

{pstd}
Macros{p_end}
{synoptset 16 tabbed}{...}
{synopt:{cmd:r(cmd)}}{cmd:pwmc}{p_end}
{synopt:{cmd:r(cmd2)}}{cmd:pwmci} (immediate command only){p_end}
{synopt:{cmd:r(depvar)}}{it:varname} from which means are 
computed{p_end}
{synopt:{cmd:r(over)}}{it:varname} from {opt over()}{p_end}
{synopt:{cmd:r(mcmethod_vs)}}{it:method} from {opt mcompare()}{p_end}

{pstd}
Matrices{p_end}
{synoptset 16 tabbed}{...}
{synopt:{cmd:r(table_vs)}}table of pairwise differences, standard 
errors, test statistics, unadjusted p-values, and unadjusted 
confidence intervals{p_end}


{title:References}

{pstd}
Dunnett, C. W. 1980. Pairwise Multiple Comparisons in the Unequal Variance 
Case, Journal of the American Statistical Association, 75(372), 796--800.

{pstd}
Games, P. A., & Howell, J. F. 1976. Pairwise Multiple Comparison 
Procedures with Unequal N's and/or Variances: A Monte Carlo study, 
Journal of Educational Statistics, 1(2), 113--125.

{pstd}
Satterthwaite, F. E. 1946. An approximate distribution of estimates of 
variance components. Biometrics Bulletin, 2(6), 110--114.

{pstd}
Tamhane, A. C. 1979. A Comparison of Procedures for Multiple Comparisons 
of Means with Unequal Variances, Journal of the American Statistical 
Association, 74(366), 471--480.

{pstd}
Welch, B. L. 1947. The generalization of 'student's' problem when several different population variances are involved. Biometrika, 34(1/2), 28--35.


{title:Acknowledgments}

{pstd}
Andreas Franken and David Kremelberg 
reported a bug on Linux OS. 
{break}
Earlier versions of the software 
borrowed from Matthew K. Lau's DTK package for R.


{title:Support}

{pstd}
Daniel Klein{break}
klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {helpb pwmean}, {helpb pwcompare}, {helpb oneway}, {helpb ttest}
{p_end}

{psee}
if installed: {help dunnett}, {help prcomp}
{p_end}
