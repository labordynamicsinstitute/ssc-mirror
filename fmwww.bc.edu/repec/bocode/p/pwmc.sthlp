{smcl}
{* *! version 3.0.0  24mar2025}{...}
{vieweralsosee "[R] pwmean" "help pwmean"}{...}
{vieweralsosee "[R] pwcompare" "help pwcompare"}{...}
{vieweralsosee "[R] oneway" "help oneway"}{...}
{vieweralsosee "[R] ttest" "help ttest"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "dunnett" "help dunett"}{...}
{vieweralsosee "prcomp" "help prcomp"}{...}
{viewerjumpto "Syntax" "pwmc##syntax"}{...}
{viewerjumpto "Description" "pwmc##description"}{...}
{viewerjumpto "Options" "pwmc##options"}{...}
{viewerjumpto "Remarks" "pwmc##remarks"}{...}
{viewerjumpto "Examples" "pwmc##examples"}{...}
{viewerjumpto "Stored results" "pwmc##results"}{...}
{viewerjumpto "References" "pwmc##references"}{...}
{viewerjumpto "Support" "pwmc##support"}{...}
{...}
{title:Title}

{p 5 29 2}
{bf:[COMMUNITY-CONTRIBUTED] pwmc} {hline 2} 
Pairwise multiple comparisons of means with unequal variances


{...}
{marker syntax}{...}
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

{...}
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
{synopt:{cmd:{ul:mcomp}are(}{it:{help pwmc##method:method}}{cmd:)}}adjust 
for multiple comparisons; 
default is {cmd:mcompare(gh)}
{p_end}
{synopt:{cmd:se({it:{help pwmc##se_type:se_type}}{cmd:)}}}type of 
standard error; default is {cmd:se(hc2)}
{p_end}
{synopt:{cmd:df(}{it:{help pwmc##df_method:df_method}}{c |}{it:#}{cmd:)}}degrees of freedom 
for computing confidence intervals and {it:p}-values;
default is {cmd:df(satterthwaite)}
{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is 
{cmd:level({ccl level})}
{p_end}
{synopt:{opt ci:effects}}display confidence intervals; the default
{p_end}
{synopt:{opt pv:effects}}display test statistics and {it:p}-values
{p_end}
{synopt:{opt eff:ects}}display test statistics, {it:p}-values, and 
confidence intervals
{p_end}
{synopt:{opt varl:abel}}display variable labels{p_end}
{synopt:{opt novall:abel}}do not display value labels{p_end}
{synopt:{it:{help pwmc##fmtopts:format_options}}}control column formats
{p_end}
{synopt:{opt su:mmarize}}display table of summary statistics
{p_end}
{synopt:{opt zstd}}report z-standardized 
coefficients, standard errors, and confidence intervals 
{p_end}
{synopt:{opt notab:le}}suppress coefficient table
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 8 2}* {opt over(varname)} is not allowed with the 
immediate command and required otherwise.


{marker method}{...}
{synoptset 20 tabbed}{...}
{synopthdr:method}
{synoptline}
{synopt:{opt gh}}Games and Howell's method; 
synonyms {opt gam:es} or {opt how:ell}; the default
{p_end}
{synopt:{opt c:ochran}}Dunnett's C method
{p_end}
{synopt:{opt tam:hane}}Tamhane's method; 
synonym {opt t2}
{p_end}
{synopt:{opt noadj:ust}}do not adjust for multiple comparisons
{p_end}
{synoptline}
{p2colreset}{...}


{marker se_type}{...}
{synoptset 20 tabbed}{...}
{synopthdr:se_type}
{synoptline}
{synopt:{opt hc2}}robust HC2 standard errors
(see {help regress}); the default 
{p_end}
{synopt:{opt hc3}}robust HC3 standard errors
(see {help regress})
{p_end}
{synopt:{opt ols}}ordinary least-squares standard errors
(see {help regress})
{p_end}
{synoptline}
{p2colreset}{...}


{marker df_method}{...}
{synoptset 20 tabbed}{...}
{synopthdr:df_method}
{synoptline}
{synopt:{opt sat:terthwaite}}Satterthwaite's approximation; the default
{p_end}
{synopt:{opt w:elch}}Welch's approximation
{p_end}
{synopt:{opt bm}}Bell and McCaffrey's adjustment
(see {help regress})
{p_end}
{synopt:{opt r:esidual}}residual degrees of freedom
{p_end}
{synoptline}
{p2colreset}{...}


{*  ____________________________________________________  Description  }{...}
{...}
{marker description}{...}
{title:Description}

{pstd}
{cmd:pwmc} 
performs pairwise comparisons of means. 
It computes pairwise differences of the means of {varname} 
over the levels of {opt over(varname)}. 
{cmd:pwmc} 
adjusts the {it:p}-values and confidence intervals for multiple comparisons. 
Tests and confidence intervals 
do not assume equal variances across groups. 

{pstd}
{cmd:pwmc} supports all combinations of 
{help pwmc##method:methods},
{help pwmc##se_type:standard errors},
and (approximate) {help pwmc##df_method:degrees of freedom}. 
However, most of these combinations lack rigorous theoretical justification. 
It is your responsibility to ensure their validity 
and interpret the results correctly.

{pstd}
{cmd:pwmci} 
is the immediate form of {cmd:pwmc}; see {help immed}.


{*  ________________________________________________________  Options  }{...}
{...}
{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt over(varname)} 
is required with {cmd:pwmc} 
and it specifies that means are computed for each level of {it:varname}. 
The option is not allowed with {cmd:pwmci}.

{...}
{dlgtab:Reporting}

{phang}
{opt mcompare(method)} 
specifies the method for computing confidence intervals and {it:p}-values. 
Confidence intervals are computed as 

{p 24 24 2}
{it:CI} = {it:d} +/- {it:c_a}*{it:se}

{phang2}
where {it:d} is the difference between means, 
{it:c_a} is the critical value, adjusted according to {it:method}, 
and {it:se} is the standard error of the mean difference.

{...}
{phang2}
{cmd:mcompare(gh)} 
implements the method discussed in Games and Howell (1976). 
This is the default.

{p 24 24 2}
{it:c_a} = inv_q({it:k},{it:nuhat},{it:alpha}) / {help sqrt:sqrt(2)}

{phang3}
where inv_q() is the
inverse cumulative {help f_invtukeyprob:studentized range distribution}
with {it:k} means, 
{it:nuhat} degrees of freedom, 
and {it:alpha} = {ccl level}/100 (see option {opt level()}).
{it:nuhat} is the approximate degrees of freedom 
from Satterthwaite's (1946) formula.

{phang3}
The adjusted {it:p}-value is computed as 

{p 24 24 2}
{it:p}_adj = 1 - q[{it:k},{it:nuhat},{c |}{it:t}_0{c |}*sqrt{c -(}2{c )-}]

{phang3}
where q[] is the 
cumulative {help f_tukeyprob:studentized range distribution}
and {c |}{it:t}_0{c |} denotes the absolute value {help abs:abs({it:d}/{it:se})}. 

{phang3}
{opt gam:es} and {opt how:ell} are synonyms for {opt gh}.

{...}
{phang2}
{cmd:mcompare(cochran)} 
implements Dunnett's (1980) C method. 

{p 24 24 2}
{it:c_a} = inv_q' / sqrt(2)

{phang3}
where inv_q' is a weighted averaged
inverse cumulative studentized range distribution 
that is computed as follows. 
Let {it:i} = 1, 2, ..., {it:k} denote the {it:k} groups. 
Let {it:n_i} denote the number of observations in group {it:i} 
and let {it:V_i} denote the variance of the mean in group {it:i}. 
Further, let inv_q_{it:i} be short for inv_q_{it:i}({it:k},{it:n_i}-1,{it:alpha})
and denote the inverse cumulative studentized range distribution 
with {it:k} means, 
{it:n_i}-1 degrees of freedom, 
and {it:alpha} defined as above.
Then, 

{p 24 24 2}
inv_q' = (inv_q_{it:i}*{it:V_i} + inv_q_{it:j}*{it:V_j}) / ({it:V_i} + {it:V_j})

{phang3}
Dunnett (1980) does not provide a formula for computing adjusted {it:p}-values. 
{cmd:pwmc} computes the adjusted {it:p}-value for Dunnett's C method as

{p 24 24 2}
{it:p}_adj =  1 - (q_{it:i}*{it:V_i} + q_{it:j}*{it:V_j}) / ({it:V_i} + {it:V_j})

{phang3}
where q_{it:i} denotes the 
the cumulative studentized range distribution
with {it:k} means, 
{it:n_i}-1 degrees of freedom,
and test statistic {c |}{it:t}_0{c |}*sqrt(2).

{...}
{phang2}
{cmd:mcompare(tamhane)} implements Tamhane's (1979) T2 method. 

{p 24 24 2}
{it:c_a} = inv_t[{it:nuhat},{c -(}1-(1-{it:alpha}^{c -(}1/{it:kstar}{c )-}){c )-}/2]

{phang3}
where inv_t[] is the 
inverse reverse cumulative (upper tail) {help f_invttail:Student's t distribution},
{it:kstar} = {it:k}*({it:k}-1)/2, the number of comparisons, 
and all other terms are defined as above.

{phang3}
The adjusted {it:p}-value is computed as 

{p 24 24 2}
{it:p}_adj = 1 - (1-{it:p})^{it:kstar}

{phang3}
where {it:p} is the unadjusted {it:p}-value (see below) 
and all other terms are defined as above.

{phang3}
{cmd:t2} is a synonym for {cmd:tamhane}.

{...}
{phang2}
{cmd:mcompare(noadjust)} 
specifies no adjustment for multiple comparisons.

{p 24 24 2}
{it:c_a} = inv_t[{it:nuhat},{c -(}1-{it:alpha}{c )-}/2]

{phang3}
with all terms defined as above.

{phang3}
The unadjusted {it:p}-value is 

{p 24 24 2}
{it:p} = 2 * t({it:nuhat},{c |}{it:t}_0{c |})

{phang3}
where t() is the cumulative (upper tail) {help ttail:Student's t distribution}.

{phang3}
{opt noadj:ust} is a synonym for {cmd:mcompare(noadjust)}.

{...}
{phang}
{cmd:se(}{it:se_type{cmd:)}}
specifies the type of the standard error. 
The following {it:se_types} are available:

{phang2}
{opt hc2}
estimates the robust standard errors 
sqrt[{c -(}({it:s2_i}/{it:n_i})+({it:s2_j}/{it:n_j}){c )-}],
where {it:s2_i} is the estimated variance in group {it:i}. 
These standard errors are equivalent 
to those reported by {cmd:regress} with the option {cmd:vce(hc2)} 
for a model with binary group indicators as predictors. 
The same standard errors are used by {helpb ttest} 
with the {opt unequal} option. 
{cmd:se(hc2)} is the default. 

{phang2}
{opt hc3} 
uses (n-1) as the denominator for computing standard errors. 
The resulting standard errors are equivalent 
to those reported by {cmd:regress} with the option {cmd:vce(hc3)} 
for a model with binary group indicators as predictors. 

{phang2}
{opt ols}
estimates the ordinary least-squares standard errors,
assuming equal variances across groups.  
These standard errors are equivalent 
to those reported by {cmd:regress} by default, 
or with the option {cmd:vce(ols)},
for a model with binary group indicators as predictors. 

{phang2}
Note that {cmd:se()} affects {it:V_i} 
used as weights in {cmd:mcompare(cochran)}
but does not affect {it:V_i} used in {opt df()} (see below).

{...}
{phang}
{cmd:df(}{it:df_method}{c |}{it:#}{cmd:)} 
uses {it:df_method} or {it:#} to compute confidence intervals and {it:p}-values. 
The following {it:df_method}s are available:

{phang2}
{opt satterthwaite}
uses Satterthwaite's (1946) approximate degrees of freedom 
(see {help ttest:ttest, unequal}); this is the default.

{phang3}
{it:nuhat} = ({it:V_i} + {it:V_j})^2 / [{it:V_i}^2/{c -(}{it:n_i}-1{c )-} + {it:V_j}^2/{c -(}{it:n_j}-1{c )-}] 

{phang2}
{opt welch} 
uses Welch's (1947) approximate degrees of freedom

{phang3}
{it:nuhat} = -2 + [{c -(}{it:V_i} + {it:V_j}{c )-}^2 / {c -(}{it:V_i}^2/({it:n_i}+1) + {it:V_j}^2/({it:n_j}+1){c )-}] 

{phang2}
{opt bm} uses Bell and McCaffrey's (2002) adjustment 
as described by Imbens and Kolesar (2016)

{phang3}
{it:nuhat} = [{c -(}{it:n_i}+{it:n_j}{c )-}^2{c -(}{it:n_i}-1{c )-}{c -(}{it:n_j}-1{c )-}] / [{it:n_i}^2{c -(}{it:n_i}-1{c )-} + {it:n_j}^2{c -(}{it:n_j}-1{c )-}]

{phang3}
{cmd:df(bm)} assumes equal variances across groups.

{phang2}
{opt residual}
uses the residual degrees of freedom 
[{c -(}{it:n_i}-1{c )-}+{c -(}{it:n_j}-1{c )-}+{it:...}+{c -(}{it:n_k}-1{c )-}-{it:k}] 
from a linear regression model with {it:k}-1 binary group indicators.

{phang2}
Note that 
{cmd:df(satterthwaite)},
{cmd:df(welch)},
and {cmd:df(bm)}
do not affect {cmd:mcompare(cochran)}.

{...}
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
reports mean differences, standard errors, test statistics, and {it:p}-values.
There is no (adjusted) {it:p}-value for Dunnett's C method.
        
{phang}
{opt effects} 
reports mean differences, standard errors, test statistics, {it:p}-values, and confidence intervals.
There is no (adjusted) {it:p}-value for Dunnett's C method.

{phang}
{opt varlabel} 
displays variable labels instead of variable names. 
This option is not allowed with {cmd:pwmci}.

{phang}
{opt novallabel} 
does not display value labels;
displays numeric codes instead. 
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
(adjusted) {it:p}-values; 
and test statistics, 
respectively.

{phang}
{opt summarize}
displays a table of means, standard deviations, and observations 
for the levels of {opt over(varname)}.

{phang}
{opt zstd}
reports z-standardized coefficients, standard errors, and confidence intervals. 
Results are equivalent to those obtained by standardizing {it:varname},
the outcome, to have mean 0 and unit variance. 
When combined with option {opt summarize}, 
option {opt zstd} additionally reports the standard deviation 
of the (standardized) standard deviations within the levels of {opt over(varname)}. 
Option {opt zstd} is not allowed with {cmd:pwmci}.

{phang}
{opt notable} 
does not report the results; results are still stored in {cmd:r()}.


{*  ________________________________________________________  Remarks  }{...}
{...}
{marker remarks}{...}
{title:Remarks}

{pstd}
As of version 3 of
{cmd:pwmc}, 
the default method for computing confidence intervals and {it:p}-values
is Games and Howell's (1976) method;
old defaults remain available as

{p 8 8 2}
{cmd:pwmc_version 2:} {it:varname} {cmd:,} {opt over(varname)} {it:...}

{pstd}
{cmd:pwmc_version} is a wrapper command for 
{cmd:pwmc}
and
{cmd:pwmci}
designed to facilitate the maintenance of old code. 


{*  _______________________________________________________  Examples  }{...}
{...}
{marker examples}{...}
{title:Examples}

    {hline}
{pstd}
Set up

    {cmd:. sysuse nlsw88}

{pstd}    
Pairwise comparisons of mean wages over race

    {cmd:. pwmc wage , over(race)}

{pstd}
Same as above; immediate form

    {cmd:. pwmci (1637 8.08 5.96) (583 6.84 5.08) (26 8.55 5.21)}

    {hline}
{pstd}
Set up (also, see {help pwmean##examples:pwmean})

    {cmd:. webuse yield}

{pstd}
Pairwise comparisons of mean yields for the fertilizers
(replicate {cmd:pwmean})

    {cmd:. pwmc yield , over(fertilizer) mcompare(noadjust) se(ols) df(residual) effects}

{pstd}
Pairwise comparisons of the mean yields 
replicating Tukey's adjustment for multiple comparisons when computing p-values

    {cmd:. pwmc yield , over(fertilizer) mcompare(gh) se(ols) df(residual) pveffects}

{pstd}
Instead of Tukey's adjustment, use Games and Howell's adjustemt allowing for unequal variances

    {cmd:. pwmc yield, over(fertilizer) mcompare(gh) se(hc2) df(satterthwaite) pveffects}


{*  _________________________________________________  Stores results  }{...}
{...}
{marker results}{...}
{title:Stored results}

{pstd}
{cmd:pwmc} saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of groups{p_end}
{synopt:{cmd:r(ks)}}number of pairwise comparisons{p_end}

{pstd}
Macros{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:r(mcmethod_vs)}}{it:method} from {opt mcompare()}{p_end}
{synopt:{cmd:r(setype)}}{it:se_type} from {opt se()}{p_end}
{synopt:{cmd:r(dfname)}}{opt satterthwaite}, {opt welch}, or {opt bm} from {opt df()}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:pwmc}{p_end}
{synopt:{cmd:r(cmd2)}}{cmd:pwmci} (immediate command only){p_end}
{synopt:{cmd:r(depvar)}}{it:varname} from which means are 
computed{p_end}
{synopt:{cmd:r(over)}}{it:varname} from {opt over()}{p_end}

{pstd}
Matrices{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:r(table_vs)}}pairwise differences, standard 
errors, test statistics, unadjusted {it:p}-values, and unadjusted 
confidence intervals{p_end}
{synopt:{cmd:r(table_vs_}{it:method}{cmd:)}}pairwise differences, standard 
errors, test statistics, adjusted {it:p}-values, and adjusted 
confidence intervals according to {it:method}{p_end}


{*  _____________________________________________________  References  }{...}
{...}
{marker references}{...}
{title:References}

{pstd}
Bell, R. M., & McCaffrey, D. F. 2002. 
Bias reduction in standard errors for linear regression with multi-stage samples. 
Survey Methodology, 28(2), 169--181.

{pstd}
Dunnett, C. W. 1980. 
Pairwise Multiple Comparisons in the Unequal Variance Case. 
Journal of the American Statistical Association, 75(372), 796--800.

{pstd}
Games, P. A., & Howell, J. F. 1976. 
Pairwise Multiple Comparison Procedures with Unequal N's and/or Variances: A Monte Carlo study. 
Journal of Educational Statistics, 1(2), 113--125.

{pstd}
Imbens, G. W., & M. Kolesar. 2016. 
Robust standard errors in small samples: Some practical advice. 
Review of Economics and Statistics, 98(4), 701--712.

{pstd}
Satterthwaite, F. E. 1946. 
An approximate distribution of estimates of variance components. 
Biometrics Bulletin, 2(6), 110--114.

{pstd}
Tamhane, A. C. 1979. 
A Comparison of Procedures for Multiple Comparisons of Means with Unequal Variances.
Journal of the American Statistical Association, 74(366), 471--480.

{pstd}
Welch, B. L. 1947. 
The generalization of 'student's' problem when several different population variances are involved. Biometrika, 34(1/2), 28--35.


{*  ________________________________________________  Acknowledgments  }{...}
{...}
{title:Acknowledgments}

{pstd}
Collaboration with Felix Bittmann resulted in better default settings 
and other improvements.
{break}
Andreas Franken and David Kremelberg 
independently reported a bug on Linux OS. 
{break}
Early versions of the software borrowed from 
Matthew K. Lau's DTK package for R
(https://cran.r-project.org/web/packages/DTK/index.html).


{*  ________________________________________________________  Support  }{...}
{...}
{marker support}{...}
{title:Support}

{pstd}
Daniel Klein{break}
klein.daniel.81@gmail.com


{...}
{title:Also see}

{psee}
Online: {helpb pwmean}, {helpb pwcompare}, {helpb oneway}, {helpb ttest}
{p_end}

{psee}
if installed: {help dunnett}, {help prcomp}
{p_end}
