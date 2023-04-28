{smcl}
{p2colset 1 21 23 2}{...}
{p2col:{bf:[R] distcomp2var} {hline 2}}Compare distributions of two variables{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:distcomp2var} {varname:1} {varname:2} {ifin} {cmd:,} [{opt a:lpha(#)} {opt p:value} {opt noplot}]

{marker description}{...}
{title:Description}

{cmd:distcomp2var} compares the distributions of two variables. 

By contrast, {cmd:ksmirnov} will test the equality of distributions of two groups of one variable.

{cmd:distcomp2var} is similar to comparing the means of two variables with {cmd:ttest} {varname:1} == {varname:2}, except {cmd:distcomp2var} will compare their distributions.

{cmd:distcomp2var} is a wrapper for {cmd:distcomp}, so it has the same output and stored results.

See also {cmd:ksmirnov2var}.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 100}{p_end}
{phang2}{cmd:. generate sample1 = rnormal()}{p_end}
{phang2}{cmd:. generate sample2 = rnormal()}{p_end}
{phang2}{cmd:. generate sample3 = runiform()}{p_end}

{pstd}distcomp2var test{p_end}
{phang2}{cmd:. distcomp2var sample1 sample2}{p_end}
{phang2}{cmd:. distcomp2var sample1 sample3}{p_end}

{pstd}With options{p_end}
{phang2}{cmd:. distcomp2var sample1 sample2, alpha(0.1)}{p_end}
{phang2}{cmd:. distcomp2var sample1 sample2, pvalue}{p_end}
{phang2}{cmd:. distcomp2var sample1 sample2, noplot}{p_end}

{marker author}{...}
{title:Author}

{pstd}Michael Makovi mbmakovi@gmail.com{p_end}

{marker references}
{title:References}

{pstd}
Kaplan, D. M. (2021).
DISTCOMP: Stata module to compare distributions.

{pstd}
Kaplan, David M. (2019).
distcomp: Comparing distributions
The Stata Journal 19(4): 832-848.

