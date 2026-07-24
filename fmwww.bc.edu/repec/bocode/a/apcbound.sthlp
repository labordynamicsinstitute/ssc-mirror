{smcl}
{* *! version 2.0 ||23.7.2026 || Gordey Yastrebov}{...}
{hi:help apcbound}{...}
{right:also see: {helpb apcdescribe}, {helpb apcest}, {helpb apcplot}}
{hline}


{title:Title}

{pstd} {hi:apcbound} {hline 2} A tool for optimizing the identification bounds on APC effects to facilitate the Fosse-Winship bounding approach to APC analysis 
(part of the {cmd:apcbound} package).


{title:Syntax}

{p 8 15 2}{cmd:apcbound,} {help apcbound##options:{it:options}}

{synoptset 30 tabbed}
{synopthdr:options}
{synoptline}

{syntab:{help apcbound##assumptions:{it:Linear component assumptions}}}
{synopt:{opt a(# #)}}bounds on {cmd:age} effect component (α){p_end}
{synopt:{opt p(# #)}}bounds on {cmd:period} effect component (π){p_end}
{synopt:{opt c(# #)}}bounds on {cmd:cohort} effect component (γ){p_end}

{syntab:{help apcbound##estimates:{it:Custom estimates}}}
{syntab:[only one set can be specified]}
{synopt:{opt ac(# #)}}linear {cmd:age} and {cmd:cohort} effect estimates{p_end}
{synopt:{opt ap(# #)}}linear {cmd:age} and {cmd:period} effect estimates{p_end}
{synopt:{opt pc(# #)}}linear {cmd:period} and {cmd:cohort} effect estimates{p_end}

{syntab:{help apcbound##other:{it:Options}}}
{synopt:{opt ci(#)}}confidence interval setting{p_end}
{synopt:{opt f:ormat}({help format:format})}value display format{p_end}

{synoptline}


{title:Description}

{pstd}{cmd:apcbound} is a tool for optimizing the identification bounds on 
the linear components of APC effects to facilitate the Fosse-Winship bounding 
approach to APC analysis ({browse "https://doi.org/10.1146/annurev-soc-073018-022616":{it:Fosse & Winship}, 2019}). It 
optimizes a bounded-range solution using specified assumptions and available 
estimates. It is intended for use directly after the {helpb apcest} wrapper 
estimation command, from which it will assume estimates θ₁ = α + π and 
θ₂ = γ + π by default. The command can also be used autonomously, 
provided a set of custom estimates is specified.


{marker options}{title:Options}
{marker assumptions}{dlgtab:Assumptions}

{pstd}Options {opt a(# #)}, {opt p(# #)}, and {opt c(# #)} specify 
assumptions about the linear components of {cmd:age} (α), {cmd:period} (π), 
and {cmd:cohort} (γ) effects, respectively.

{pstd}Each option accepts two values for the lower and the upper bound,
respectively. For example, if the linear component of {cmd:age} effects (α) is 
assumed to range from –0.5 to 1.5, the option must be specified as {cmd:a(-.5 1.5)}.

{pstd}If a bound is not assumed, it is equivalent to assuming 
it to be either minus or plus infinity, and in this case the respective 
bound must be explicitly specified as "." (i.e., the missing value). For example, 
if the linear component of {cmd:period} effects (π) is assumed to range 
from minus infinity to zero, the option must be specified as {cmd:p(. 0)}.

{pstd}If an option is not specified, a respective parameter is assumed
unbounded both from above and below.

{marker estimates}{dlgtab:Custom estimates}

{pstd}Options {opt ac(# #)}, {opt ap(# #)}, or {opt pc(# #)} allow specifying
custom estimates for the linear components of respective APC effects. If
this option is specified, the command will not accept the estimates from
the previous call of {helpb apcest} (its default behavior). 

{pstd}Only one of the three options can be specified. The letters in 
the name of the option define which two estimates are assumed and in which
order they are to be accepted. The command transforms the supplied estimates
into θ₁ = α + π and θ₂ = γ + π as follows: {opt ac(a c)} gives θ₁ = a and
θ₂ = c; {opt ap(a p)} gives θ₁ = a + p and θ₂ = p; and {opt pc(p c)} gives
θ₁ = p and θ₂ = p + c.

{pstd}Specifying custom estimates cannot be combined with {opt ci(#)}, because
no standard errors or variance-covariance matrix are supplied.

{marker other}{dlgtab:Other options}

{pstd}{opt ci(#)} sets the desired confidence level for presenting the bounding solution
which takes confidence intervals into account. The number must be any reasonable value 
(e.g., 95 for 95% confidence level). If the option is not specified, a 
confidence-interval-adjusted solution will be suppressed in the output.

{pstd}{opt format}({help format}) sets the formatting style for the values to 
appear in the output window of Stata after running the command. The default is {bf:%9.3g}.


{title:Examples}

{pstd}Load sample data and estimate a model:

	. {stata webuse nlswork, clear}
	. {stata "apcest, a(age^2) p(i.year) c(birth_yr): regress ln_wage"}

{pstd}A simple call to apcbound implementing assumptions π > -.03 and γ > 0:

	. {stata apcbound, p(-.03 .) c(0 .)}

{pstd}The previous call, enhanced with confidence intervals and a formatting option:

	. {stata apcbound, p(-.03 .) c(0 .) ci(95) format(%9.4f)}

{pstd}An autonomous call (no data or estimation needed) implementing the same assumptions but using a custom set of estimates {bf:θ₁ = α + π = -.5} and {bf:θ₂ = γ + π = .5}:

	. {stata apcbound, p(-.03 .) c(0 .) ac(-.5 .5)}


{title:Stored results}

{pstd} {cmd:apcbound} stores the following in {cmd:e()}:

{p 4}Scalars{p_end}
{p2colset 7 30 25 2}{...}
{p2col : {cmd:e(peAmin)}} lower bound of the linear component of {cmd:age} effects{p_end}
{p2col : {cmd:e(peAmax)}} upper bound of the linear component of {cmd:age} effects{p_end}
{p2col : {cmd:e(pePmin)}} lower bound of the linear component of {cmd:period} effects{p_end}
{p2col : {cmd:e(pePmax)}} upper bound of the linear component of {cmd:period} effects{p_end}
{p2col : {cmd:e(peCmin)}} lower bound of the linear component of {cmd:cohort} effects{p_end}
{p2col : {cmd:e(peCmax)}} upper bound of the linear component of {cmd:cohort} effects{p_end}
{p2col : {cmd:e(ciAmin)}} same as {cmd:e(peAmin)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciAmax)}} same as {cmd:e(peAmax)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciPmin)}} same as {cmd:e(pePmin)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciPmax)}} same as {cmd:e(pePmax)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciCmin)}} same as {cmd:e(peCmin)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciCmax)}} same as {cmd:e(peCmax)} but CI-adjusted{p_end}
{p2col : {cmd:e(pe_bounded_solution)}} a binary for whether a fully bounded solution exists{p_end}
{p2col : {cmd:e(ci_bounded_solution)}} same as above but using CI-adjusted estimates{p_end}


{title:Author}

{p 4} {cmd:Gordey Yastrebov} {p_end}
{p 4} {it:University of Cologne} {p_end}
{p 4} {browse "mailto:gordey.yastrebov@gmail.com":gordey.yastrebov@gmail.com} {p_end}


{title:Citation}

{pstd}
When referring to {cmd:apcbound}, {cmd:apcest}, {cmd:apcplot}, or
{cmd:apcdescribe} in published work, please consider citing the software package
and the article implementing the bounding approach:
{p_end}

{phang}
{cmd:Yastrebov, G.} (2026). "APCBOUND: Stata module for the Fosse-Winship bounding
approach to age-period-cohort analysis (Version 2.0)" [Computer software].
Boston College Department of Economics, Statistical Software Components. 
{browse "https://ideas.repec.org/c/boc/bocode/s459449.html":https://ideas.repec.org/c/boc/bocode/s459449.html}
{p_end}

{phang}
{cmd:Yastrebov, G., Trinidad, A., and Leopold, T.} (2025). A Bounding Approach to Age-Period-Cohort Analysis: A Demonstration Using Public Crime Concerns in Germany. {it:Journal of Quantitative Criminology}.
{browse "https://doi.org/10.1007/s10940-025-09633-7":https://doi.org/10.1007/s10940-025-09633-7}
{p_end}
