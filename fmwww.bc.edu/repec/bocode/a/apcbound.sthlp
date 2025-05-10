{smcl}
{* *! version 1.1 || 08.05.2025 || Gordey Yastrebov}{...}
{hi:help apcbound}{...}
{right:also see: {helpb apcest}, {helpb apcplot}}
{hline}


{title:Title}

{pstd} {hi:apcbound} {hline 2} A tool for optimizing the identificaiton bounds on APC effects 
to facilitate Fosse-Winship bounding approach to APC analysis 
(part of {cmd:apcbound} package).


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
{synopt:{opt ac}(# #)}linear {cmd:age} and {cmd:cohort} effect estimates{p_end}
{synopt:{opt ap}(# #)}linear {cmd:age} and {cmd:period} effect estimates{p_end}
{synopt:{opt pc}(# #)}linear {cmd:period} and {cmd:cohort} effect estimates{p_end}

{syntab:{help apcbound##other:{it:Options}}}
{synopt:{opt ci}(#)}confidence interval setting{p_end}
{synopt:{opt f:ormat}({help format:format})}value display format{p_end}

{synoptline}


{title:Description}

{pstd}{cmd:apcbound} is a tool for optimizing the identificaiton bounds on 
the linear components of APC effects to facilitate Fosse-Winship bounding 
approach to APC analysis ({browse "https://doi.org/10.1146/annurev-soc-073018-022616":{it:Fosse & Winship}, 2019}). It 
optimizes a bounded-range solution using specified assumptions and available 
estimates. It is intended for use directly after {helpb apcest} wrapper 
estimation command, from which it will assume estimates θ₁ = α + π and 
θ₂ = γ + π by default. The command can also be used autonomously, 
provided a set of custom estimates is specified.


{marker options}{title:Options}
{marker assumptions}{dlgtab:Assumptions}

{pstd}Options {opt a(# #)}, {opt p(# #)}, and {opt c(# #)} specify 
assumptions about the linear component of {cmd:age} (α), {cmd:period} (π), 
and {cmd:cohort} (γ) effect respectively.

{pstd}The option accepts two values for the lower and the upper bound
respectively. For example, if the linear component of {cmd:age} effects (α) is 
assumed to range from –0.5 to 1.5, the option must be specified as {cmd:a(-.5 1.5)}

{pstd}If a bound is not assumed, it is equivalent to assuming 
it being either minus or plus infinity, and in this case the respective 
bound must be explicitly specified as "." (i.e., the missing value). For example, 
if the linear component of {cmd:period} effects (π) is assumed to range 
from minus infinity to zero, the option must be specified as {cmd:p(. 0)}.

{pstd}If an option is not specified, a respective parameter is assumed
unbounded both from above and below.

{marker estimates}{dlgtab:Custom estimates}

{pstd}Options {opt ac(# #)}, {opt ap(# #)}, or {opt pa(# #)} allow specifying
custom estimates for the linear components of respective APC effects. If
this option is specified, the command will not accept the estimates from
the previous call of {helpb apcest} (its default behavior). 

{pstd}Only a single one of the three options can be specified. The letters in 
the name of the option define which two estimates are assumed and in which
order they are to be accepted. For example, if the user wishes to specify
the estimates for the linear components of {cmd:age} and {cmd:cohort} effects
(i.e., α-hat = θ₁ and γ-hat = θ₂), the option {opt ac(# #)} needs to be specified,
with the first value setting α-hat and the second value setting γ-hat. For 
all other options, the values θ₁ and θ₂ are calculated indirectly.

{pstd}Specifying custom estimates blocks the calculation of confidence intervals
and, accordingly, the output of bounded solutions taking confidence intervals 
into account (since the intervals require an appropriate variance-covariance matrix
to be calculated precisely).

{marker other}{dlgtab:Other options}

{pstd}{opt ci}(#) sets the desired confidence level to present the bounding solution
which takes confidence intervals into account. The number must be any reasonable value 
(e.g., 95 for 95% confidence level). If the option is not specified, a 
confidence-interval-adjusted solution will be suppressed in the output.

{pstd}{opt f:ormat}({help format:format}) sets the formatting style for the values to 
appear in the output window of Stata after running the command. The default is {bf:%9.3g}.


{title:Examples}

{pstd}Load sample data and estimate a model:

	. {stata webuse nlswork, clear}
	. {stata apcest regress ln_wage, a(age^2) p(i.year) c(birth_yr)}

{pstd}A simple call of apcbound implementing assumptions π > -.03 and γ > 0:

	. {stata apcbound, p(-.03 .) c(0 .)}

{pstd}Previous call but enhanced with confidence intervals and formatting option specified:
	
	. {stata apcbound, p(-.03 .) c(0 .) ci(95) format(%9.4f)}

{pstd}An autonomous call (no data or estimation needed) implementing the same assumptions 
but using a custom set of estimates {bf:θ₁ = α + π = -.5} and {bf:θ₂ = γ + π = .5}:

	. {stata apcbound, p(0 .) c(0 .) ac(-.5 .5)}


{title:Stored results}

{pstd} {cmd:apcbound} stores the following in {cmd:e()}:

{p 4}Scalars{p_end}
{p2colset 7 17 25 2}{...}
{p2col : {cmd:e(Amin)}} lower bound of the linear component of {cmd:age} effects{p_end}
{p2col : {cmd:e(Amax)}} upper bound of the linear component of {cmd:age} effects{p_end}
{p2col : {cmd:e(Pmin)}} lower bound of the linear component of {cmd:period} effects{p_end}
{p2col : {cmd:e(Pmax)}} upper bound of the linear component of {cmd:period} effects{p_end}
{p2col : {cmd:e(Cmin)}} lower bound of the linear component of {cmd:cohort} effects{p_end}
{p2col : {cmd:e(Cmax)}} upper bound of the linear component of {cmd:cohort} effects{p_end}
{p2col : {cmd:e(ciAmin)}} same as {cmd:e(Amin)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciAmax)}} same as {cmd:e(Amax)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciPmin)}} same as {cmd:e(Pmin)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciPmax)}} same as {cmd:e(Pmax)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciCmin)}} same as {cmd:e(Cmin)} but CI-adjusted{p_end}
{p2col : {cmd:e(ciCmax)}} same as {cmd:e(Cmax)} but CI-adjusted{p_end}


{title:Author}

{p 4} {cmd:Gordey Yastrebov} {p_end}
{p 4} {it:University of Cologne} {p_end}
{p 4} {browse "mailto:gordey.yastrebov@gmail.com":gordey.yastrebov@gmail.com} {p_end}
