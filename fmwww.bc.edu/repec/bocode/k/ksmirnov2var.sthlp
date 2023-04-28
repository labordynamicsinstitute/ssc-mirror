{smcl}
{p2colset 1 21 23 2}{...}
{p2col:{bf:[R] ksmirnov2var} {hline 2}}Kolmogorov-Smirnov equality-of-distributions test for 2 variables{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:ksmirnov2var} {varname:1} {varname:2} {ifin} {cmd:,} [{opt e:xact}]

{marker description}{...}
{title:Description}

{cmd:ksmirnov2var} performs the Kolmogorov-Smirnov test of the equality of distributions for two variables. 

By contrast, {cmd:ksmirnov} will test the equality of distributions of two groups of one variable.

{cmd:ksmirnov2var} is similar to comparing the means of two variables with {cmd:ttest} {varname:1} == {varname:2}, except {cmd:ksmirnov2var} will compare their distributions.

{cmd:ksmirnov2var} is a wrapper for {cmd:ksmirnov}, so it has the same output and stored results.

See also {cmd:distcomp2var}.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 100}{p_end}
{phang2}{cmd:. generate sample1 = rnormal()}{p_end}
{phang2}{cmd:. generate sample2 = rnormal()}{p_end}
{phang2}{cmd:. generate sample3 = runiform()}{p_end}

{pstd}ksmirnov2var test{p_end}
{phang2}{cmd:. ksmirnov2var sample1 sample2, exact}{p_end}
{phang2}{cmd:. ksmirnov2var sample1 sample3, exact}{p_end}

{marker author}{...}
{title:Author}

{pstd}Michael Makovi mbmakovi@gmail.com{p_end}
