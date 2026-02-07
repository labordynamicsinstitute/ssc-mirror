{smcl}
{* *! version 1.0.0  03Feb2026}{...}

{title:Title}

{p 4 4 2}
{bf:binomci} {hline 2} Confidence intervals for binomial proportions using 12 methods


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:binomci}
{varlist}
[{it:{help if}}]
[{it:{help in}}]
[{it:{help fweight}}]
[{cmd:,}
{it:options}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt m:ethod(method)}}specify confidence interval method; default is {cmd:method(exact)}{p_end}
{synopt:{opt total}}display combined results for all groups when using the {cmd:by} prefix{p_end}
{synopt:{opt sep:arator(#)}}draw separator line after every # observations; default is {cmd:separator(5)}{p_end}

{syntab:Method options (one only)}
{synopt:{opt exact}}exact (Clopper-Pearson) binomial confidence interval; {cmd:the default}{p_end}
{synopt:{opt wald}}Wald confidence interval{p_end}
{synopt:{opt waldcorrected}}Wald confidence interval with continuity correction{p_end}
{synopt:{opt waldblythstill}}Wald-Blyth-Still confidence interval{p_end}
{synopt:{opt agresti}}Agresti-Coull confidence interval{p_end}
{synopt:{opt wilson}}Wilson confidence interval{p_end}
{synopt:{opt jeffreys}}Jeffreys confidence interval{p_end}
{synopt:{opt score}}Score confidence interval{p_end}
{synopt:{opt scorecorrected}}Score confidence interval with continuity correction{p_end}
{synopt:{opt waldlogit}}Wald logit confidence interval{p_end}
{synopt:{opt waldlogitcorrected}}Wald logit confidence interval with continuity correction{p_end}
{synopt:{opt arcsine}}Arcsine confidence interval{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{opt by} is allowed with {cmd:binomci}; see {help prefix}.{p_end}
{p 4 6 2}
{opt fweight}s are allowed with {cmd:binomci}; see {help weight}.{p_end}



{title:Description}

{pstd}
{cmd:binomci} computes confidence intervals for binomial proportions using 12 different
methods (including the 5 already offered by {helpb ci}). The command is designed to provide a 
comprehensive set of confidence interval methods, including both classical
and modern approaches. {cmd:binomci} reports the same 12 methods as those implemented in the
R program {browse "https://cran.r-project.org/web/packages/binomCI/binomCI.pdf":binomCI},
but for several methods, {cmd:binomci} computes the boundary edge cases differently. {cmd:binomci}
follows the recommended approaches discussed in Brown et al (2001), Newcombe (1998), and Vollset (1993).  



{title:Options}

{dlgtab:Main}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals. The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt method(method)} specifies the method for computing confidence intervals.
Available methods are: {cmd:exact}, {cmd:wald}, {cmd:waldcorrected}, {cmd:waldblythstill},
{cmd:agresti}, {cmd:wilson}, {cmd:jeffreys}, {cmd:score}, {cmd:scorecorrected},
{cmd:waldlogit}, {cmd:waldlogitcorrected}, and {cmd:arcsine}. If no method is specified,
the default is {cmd:exact}.

{phang}
{opt total} may be specified only with {cmd:by} and requests that, in addition to
results for each by-group, results for all groups combined be displayed. The combined
results are labeled "Total".

{phang}
{opt separator(#)} specifies how often separator lines are drawn between rows
in the output table. The default is {cmd:separator(5)}, meaning that a separator
line is drawn after every 5 variables. {cmd:separator(0)} suppresses separator lines.

{dlgtab:Method options}

{phang}
These options specify the method for computing confidence intervals. Only one method
option may be specified.

{pmore}
{opt exact} computes the exact (Clopper-Pearson) binomial confidence interval. This
is a conservative method that guarantees the nominal coverage probability but tends
to produce wider intervals than other methods.

{pmore}
{opt wald} computes the standard Wald confidence interval.

{pmore}
{opt waldcorrected} computes the Wald confidence interval with continuity correction.

{pmore}
{opt waldblythstill} computes the Wald-Blyth-Still confidence interval, which adjusts
for small sample sizes.

{pmore}
{opt agresti} computes the Agresti-Coull confidence interval.

{pmore}
{opt wilson} computes the Wilson confidence interval, which performs well for both
small and large sample sizes.

{pmore}
{opt jeffreys} computes the Jeffreys confidence interval, based on the Bayesian
approach with Jeffreys prior.

{pmore}
{opt score} computes the Score confidence interval, based on inverting the score test.

{pmore}
{opt scorecorrected} computes the Score confidence interval with continuity correction.

{pmore}
{opt waldlogit} computes the Wald confidence interval on the logit scale.

{pmore}
{opt waldlogitcorrected} computes the Wald confidence interval on the logit scale
with continuity correction.

{pmore}
{opt arcsine} computes the Arcsine (angular) transformation confidence interval.



{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}Exact binomial confidence interval (default){p_end}
{phang2}{cmd:. binomci foreign}{p_end}

{pstd}Wilson confidence interval{p_end}
{phang2}{cmd:. binomci foreign, method(wilson)}{p_end}

{pstd}Score confidence interval with 90% confidence level{p_end}
{phang2}{cmd:. binomci foreign, method(score) level(90)}{p_end}

{pstd}By foreign with total, using the Wald-Blyth-Still method{p_end}
{phang2}{cmd:. bys rep78: binomci foreign, method(waldblythstill) total}{p_end}

{pstd}Multiple binary variables{p_end}
{phang2}{cmd:. gen high_price = price > 5000}{p_end}
{phang2}{cmd:. gen heavy = weight > 3000}{p_end}
{phang2}{cmd:. binomci high_price heavy foreign}{p_end}



{title:Remarks}

{pstd}
{cmd:binomci} implements 12 different methods for computing confidence intervals for
binomial proportions (see Brown et al [2001], Newcombe [1998] and Vollset [1993] for a comprehensive discussion). The choice of method depends on the sample size, the observed
proportion, and whether boundary cases ({it:p} = 0 or {it:p} = 1) are present.

{pstd}
{cmd:Method Recommendations by Scenario:}

{pstd}
{cmd:Small sample sizes (n < 30):}

{pmore}
• {it:Brown et al. (2001)} recommend the {bf:Wilson} and {bf:Agresti-Coull} methods as
they maintain good coverage properties even with small samples.

{pmore}
• {it:Newcombe (1998)} found that the {bf:Wilson} method performs well across all
sample sizes and is particularly recommended for small samples.

{pmore}
• {it:Vollset (1993)} suggests that the {bf:exact} (Clopper-Pearson) method is appropriate
for very small samples but is conservative, producing wider intervals.

{pstd}
{cmd:Large sample sizes (n ≥ 30):}

{pmore}
• All three references agree that with large samples, most methods perform similarly,
but the {bf:Wilson} and {bf:Agresti-Coull} methods still have advantages in terms of
coverage probability.

{pmore}
• The standard {bf:Wald} interval is adequate for large samples but can be problematic
when {it:p} is near 0 or 1.

{pstd}
{cmd:Boundary cases ({it:p} = 0 or {it:p} = 1):}

{pmore}
• {it:Brown et al. (2001)} strongly recommend against using the {bf:Wald} interval for
boundary cases as it can produce nonsensical intervals (e.g., negative lower bounds).

{pmore}
• {it:Newcombe (1998)} found that the {bf:Wilson} and {bf:score} methods handle boundary
cases well, producing appropriate one-sided intervals.

{pmore}
• {it:Vollset (1993)} notes that the {bf:exact} method naturally produces appropriate
one-sided intervals for boundary cases.

{pstd}
{cmd:Extreme proportions ({it:p} near 0 or 1):}

{pmore}
• {it:Brown et al. (2001)} recommend the {bf:Wilson}, {bf:Agresti-Coull}, and
{bf:Jeffreys} intervals for extreme proportions as they avoid the zero-width problem
of the Wald interval.

{pmore}
• {it:Newcombe (1998)} found that methods based on score tests ({bf:Wilson} and
{bf:score}) perform best for extreme proportions.

{pstd}
{cmd:Overall recommendations:}

{pmore}
• For general use: {bf:Wilson} or {bf:Agresti-Coull} intervals are recommended by all
three references as they perform well across a wide range of sample sizes and
proportions.

{pmore}
• For small samples: {bf:Wilson} is preferred over the exact method as it is less
conservative while maintaining good coverage.

{pmore}
• For boundary/extreme cases: {bf:Wilson}, {bf:score}, or {bf:Jeffreys} methods are
recommended.

{pmore}
• Not recommended: The standard {bf:Wald} interval is generally not recommended,
especially for small samples or extreme proportions, due to poor coverage properties.

{pmore}
• The {bf:exact} method guarantees the nominal coverage but is conservative, producing
wider intervals than necessary. It may be appropriate when strict coverage guarantees
are required.

{pstd}
{cmd:Method-Specific Notes:}

{pmore}
• {bf:Jeffreys} interval: Based on Bayesian reasoning with non-informative prior.
Performs similarly to Wilson interval but is Bayesian in interpretation.

{pmore}
• {bf:Score} intervals: Perform well across all scenarios but are computationally
more complex.

{pmore}
• {bf:Wald variants}: The continuity-corrected versions (waldcorrected, waldlogitcorrected,
scorecorrected) can improve coverage for small samples but may be overly conservative.

{pmore}
• {bf:Arcsine} transformation: Historically used but generally outperformed by Wilson
and Agresti-Coull methods in modern comparisons.



{title:Stored results}

{pstd}
{cmd:binomci} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(ub)}}upper bound of confidence interval{p_end}
{synopt:{cmd:r(lb)}}lower bound of confidence interval{p_end}
{synopt:{cmd:r(se)}}standard error{p_end}
{synopt:{cmd:r(prop)}}proportion{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(x)}}number of successes{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(method)}}method used{p_end}
{p2colreset}{...}

{pstd}
Note: When multiple variables are specified, results are returned for the last variable
in the list.



{title:References}

{phang}
Brown, L. D., T. T. Cai, and A. DasGupta. 2001. Interval estimation for a binomial
proportion. {it:Statistical Science} 16: 101-133.

{phang}
Newcombe, R. G. 1998. Two-sided confidence intervals for the single proportion:
comparison of seven methods. {it:Statistics in Medicine} 17: 857–872.

{phang}
Vollset, S. E. 1993. Confidence intervals for a binomial proportion.
{it:Statistics in Medicine} 12: 809–824.

{phang}
Agresti, A., and B. A. Coull. 1998. Approximate is better than "exact" for interval
estimation of binomial proportions. {it:American Statistician} 52: 119–126.

{phang}
Clopper, C., and E. S. Pearson. 1934. The use of confidence or fiducial limits
illustrated in the case of the binomial. {it:Biometrika} 26: 404–413.

{phang}
Wilson, E. B. 1927. Probable inference, the law of succession, and statistical
inference. {it:Journal of the American Statistical Association} 22: 209–212.




{title:Citation of {cmd:binomci}}

{p 4 8 2}{cmd:binomci} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). BINOMCI: Stata module to compute confidence intervals for binomial proportions using 12 methods



{title:Author}

{p 4 4 2}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also See}

{p 4 4 2}
{help ci} {p_end}
