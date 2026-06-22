{smcl}
{* myinterval.sthlp --- help for myinterval}{...}
{hline}

{title:Title}

{p 4 4 2}
{bf:myinterval} — Confidence intervals for the mean (t-distribution)
{p_end}

{title:Syntax}

{p 4 4 2}
{cmd:myinterval} {it:varlist} [{it:if}] [{it:in}] [, {opt level(#)}]
{p_end}

{title:Description}

{p 4 4 2}
{cmd:myinterval} computes confidence intervals for the population mean of
each variable in {it:varlist}, using the Student's {it:t} distribution.
This is appropriate when the population variance is unknown and the sample
size is small, or when exact t-based inference is desired.
{p_end}

{p 4 4 2}
The confidence interval for a variable {it:X} is given by
{p_end}

{p 8 8 2}
{it:X-bar} +/- {it:t}({it:df}, 1 - {it:a}/2) * {it:SE}
{p_end}

{p 4 4 2}
where {it:X-bar} is the sample mean, {it:SE} = {it:s} / sqrt({it:n})
is the standard error of the mean, and {it:t}({it:df}, 1 - {it:a}/2)
is the critical value from the {it:t} distribution with {it:df} =
{it:n} - 1 degrees of freedom.  {it:a} = 1 - {it:level}/100 is the
significance level.
{p_end}

{title:Options}

{p 4 4 2}
{opt level(#)} specifies the confidence level, as a percentage,
for the confidence intervals.  The default is {opt level(95)}, which
produces 95% confidence intervals.  {it:#} must be strictly between 0
and 100.
{p_end}

{title:Remarks}

{p 4 4 2}
{cmd:myinterval} uses the {it:t} distribution rather than the normal
distribution.  For large samples ({it:n} > 120), the {it:t}-based intervals
are virtually identical to normal-based intervals computed by Stata's
official {help ci} command.
{p_end}

{p 4 4 2}
All observations with complete data on all variables in {it:varlist}
satisfying the optional {opt if} and {opt in} conditions are used.
At least two observations are required to compute the interval.
{p_end}

{title:Comparison with official {cmd:ci} and innovations}

{p 4 4 2}
{cmd:myinterval} differs from Stata's official {help ci} command in several
important respects.  These differences constitute the key innovations of
this program.
{p_end}

{p 4 4 2}
{bf:1.  Default distribution: t versus normal.}
{p_end}
{p 8 8 2}
Stata's {cmd:ci means} defaults to the normal distribution, producing
intervals of the form {it:X-bar} +/- {it:z}(1 - {it:a}/2) * {it:SE}.
The {it:t}-based interval is only available via the {opt ttest} option
or the undocumented {opt level()} suboption.  In contrast,
{cmd:myinterval} always uses the {it:t} distribution.  This is
statistically more conservative and exact for samples drawn from a
normal population with unknown variance.  When the sample size is small
({it:n} < 30), the normal approximation can substantially understate
the true confidence level; {cmd:myinterval} avoids this problem by
construction.
{p_end}

{p 4 4 2}
{bf:2.  Multi-variable processing.}
{p_end}
{p 8 8 2}
Stata's {cmd:ci} processes one variable at a time.  If the user wishes
to obtain confidence intervals for five variables, {cmd:ci} must be
called five times.  {cmd:myinterval} accepts a {it:varlist} and computes
intervals for all specified variables in a single call, displaying them
together in one table.  This is more convenient for exploratory data
analysis and for reporting summary statistics across multiple measures.
{p_end}

{p 4 4 2}
{bf:3.  Simultaneous return of results.}
{p_end}
{p 8 8 2}
Because {cmd:ci} handles only one variable, only the last call's results
are accessible via {cmd:return list}.  {cmd:myinterval} stores results
for {it:all} variables simultaneously using the
{cmd:r(}{it:stat}{cmd:_}{it:varname}{cmd:)} naming convention.  This
enables programmatic post-processing — for example, constructing a custom
table of intervals across multiple variables, or passing results to a
graphing routine, all from a single invocation.
{p_end}

{p 4 4 2}
{bf:4.  Simple and transparent.}
{p_end}
{p 8 8 2}
{cmd:myinterval} is a single-purpose tool with readable source code.
The entire calculation is visible in a few lines, making it easy for
students and researchers to inspect, modify, and learn from.  The
formula is printed in the Description section above, and every
intermediate quantity (mean, SE, df, critical value, bounds) is
displayed or stored.
{p_end}

{p 4 4 2}
{bf:5.  Pedagogical value.}
{p_end}
{p 8 8 2}
The program is designed with teaching in mind.  By showing the degrees
of freedom and the standard error alongside the interval, and by
displaying the exact {it:t}-based formula in the help file,
{cmd:myinterval} helps students connect the abstract formula from the
textbook to the concrete numerical output.  This transparency is absent
from the official {cmd:ci} command, which reports only the interval
endpoints and the sample mean.
{p_end}

{title:Saved results}

{p 4 4 2}
{cmd:myinterval} stores the following in {cmd:r()}:
{p_end}

{p 4 8 2}
{bf:Scalars}
{p_end}

{p 8 8 2}
{cmd:r(N_}{it:varname}{cmd:)}      sample size for each variable
{p_end}
{p 8 8 2}
{cmd:r(mean_}{it:varname}{cmd:)}   sample mean for each variable
{p_end}
{p 8 8 2}
{cmd:r(se_}{it:varname}{cmd:)}     standard error of the mean for each variable
{p_end}
{p 8 8 2}
{cmd:r(df_}{it:varname}{cmd:)}     degrees of freedom for each variable
{p_end}
{p 8 8 2}
{cmd:r(lb_}{it:varname}{cmd:)}     lower bound of the confidence interval
{p_end}
{p 8 8 2}
{cmd:r(ub_}{it:varname}{cmd:)}     upper bound of the confidence interval
{p_end}
{p 8 8 2}
{cmd:r(level)}      confidence level used
{p_end}
{p 8 8 2}
{cmd:r(vars)}       number of variables processed
{p_end}

{title:Examples}

{p 4 4 2}{cmd:. sysuse auto}{p_end}
{p 4 4 2}{cmd:. myinterval mpg}{p_end}
{p 4 4 2}{cmd:. myinterval mpg price, level(99)}{p_end}
{p 4 4 2}{cmd:. myinterval mpg price weight if foreign==1}{p_end}
{p 4 4 2}{cmd:. myinterval mpg price in 1/30}{p_end}

{title:Authors}

{p 4 4 2}
{bf:Wu Lianghai}
{p_end}
{p 8 8 2}
School of Business, Anhui University of Technology (AHUT),{break}
Ma'anshan, China
{p_end}
{p 8 8 2}
Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}
{p_end}

{p 4 4 2}
{bf:Wu Hanyan}
{p_end}
{p 8 8 2}
School of Economics and Management,{break}
Nanjing University of Aeronautics and Astronautics (NUAA), China
{p_end}
{p 8 8 2}
Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}
{p_end}

{p 4 4 2}
{bf:Chen Liwen}
{p_end}
{p 8 8 2}
School of Business, Anhui University of Technology (AHUT),{break}
Ma'anshan, China
{p_end}
{p 8 8 2}
Email: {browse "mailto:2184844526@qq.com":2184844526@qq.com}
{p_end}

{title:Version history}

{p 4 4 2}
{bf:2.0  19jun2026}  Rewritten: corrected t-critical value,{break}
        added r-class returns, improved output, new help file.
{p_end}
{p 4 4 2}
{bf:1.0  16nov2015}  Initial version by Wu Lianghai.
{p_end}

{title:Also see}

{p 4 4 2}
Help:  {help ci}, {help ttest}, {help mean}, {help ameans}
{p_end}
{hline}
