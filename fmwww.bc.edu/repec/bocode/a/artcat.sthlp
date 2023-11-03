{smcl}
{* *! version 1.2.1.1 2jun2023}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help artbin (if installed)" "help artbin"}{...}
{vieweralsosee "Help artsurv (if installed)" "help artsurv"}{...}
{viewerjumpto "Syntax" "artcat##syntax"}{...}
{viewerjumpto "Description" "artcat##description"}{...}
{viewerjumpto "Which method?" "artcat##methods"}{...}
{viewerjumpto "artcat for observational studies" "artcat##obs"}{...}
{viewerjumpto "Examples" "artcat##examples"}{...}
{viewerjumpto "Stored results" "artcat##stored"}{...}
{viewerjumpto "References" "artcat##refs"}{...}
{viewerjumpto "Citation" "artcat##citation"}{...}
{viewerjumpto "Author and updates" "artcat##updates"}{...}
{title:Title}

{phang}
{bf:artcat} {hline 2} A Stata program to calculate sample size or power for a 2-group trial with ordered categorical outcome.


{marker syntax}{...}
{title:Syntax}
{* latex \label{sec:syntax}}
{p 8 17 2}
{cmd:artcat,}
{opt pc(numlist)}  {opt pe(numlist)}|{opt or(exp)}|{opt rr(exp)}  {opt power(#)}|{opt n(#)} 
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Control group options}
{synopt:{opt pc(numlist)}} Required. Probabilities in each outcome level; the right-most level may be omitted.{p_end}
{synopt:{opt cum:ulative}} The probabilities in {opt pc(numlist)} are cumulative probabilities. {p_end}
{synopt:{opt unf:avourable}} The left-most outcome level represents the least favourable outcome. The spelling unfavorable is also allowed.{p_end}
{synopt:{opt fav:ourable}} The left-most outcome level represents the most favourable outcome. The spelling favorable is also allowed.{p_end}

{syntab:Experimental group options}
{p 6}{it:One of {opt pe(numlist)}, {opt or(exp)} and {opt rr(exp)} must be specified.}{p_end}
{synopt:{opt pe(numlist)}} Probabilities in each outcome level, specified as for {opt pc(numlist)}; or cumulative probabilities, if the {opt cumulative} option is used. {p_end}
{synopt:{opt or(exp)}} Odds ratio at each outcome level. 
An odds ratio less than one means that the distribution in the experimental group is shifted towards the right-most level compared with the control group.{p_end}
{synopt:{opt rr(exp)}} Risk ratio at each outcome level except the right-most. 
A risk ratio less than one means that the experimental group has lower probability at every level except the right-most level compared with the control group. {p_end}

{syntab:Trial type options}
{synopt:{opt mar:gin(#)}} Specifies the margin, as an odds ratio, for a non-inferiority or substantial superiority trial. 
If the {cmd:unfavourable} option is specified 
then #>1 specifies a non-inferiority trial,
and #<1 specifies a substantial-superiority trial.
If the {cmd:favourable} option is specified then it's the other way round.
If {opt margin(#)} is not specified, or #=1, then a superiority trial is assumed.{p_end}

{syntab:Sample size options}
{synopt:{opt po:wer(#)}} Power required: sample size will be computed. The default is {cmd:power(0.8)} 
if neither {cmd:power(#)} 
nor {cmd:n(#)} is specified.{p_end}
{synopt:{opt n(#)}} Total sample size: power will be computed. {p_end}
{synopt:{opt ar:atio(# #)}} Allocation ratio: e.g. {opt aratio(1 2)} means 2 participants in the experimental group for every 1 participant in the control group. {p_end}
{synopt:{opt al:pha(#)}} Significance level. Default is 0.05.{p_end}
{synopt:{opt ones:ided}} The level specified by {opt alpha(#)} is the one-sided significance level. Default is two-sided.{p_end}

{syntab:Method options}
{synopt:{opt ologit(type)}} Use the {cmd:ologit} (new) method. 
{it:type} may be NN, NA or AA. 
The default is {cmd:ologit(NA)}.
See {help artcat##methods:Which method?} below.{p_end}
{synopt:{opt ologit}} Same as {cmd:ologit(NA)}.{p_end}
{synopt:{opt white:head}} Use the {help artcat##Whitehead93:Whitehead method}. This option requires {opt or(exp)} to be specified and is not available with {opt margin(#)}. {p_end}

{syntab:Output options}
{synopt:{opt noprobt:able}} Do not display table of anticipated probabilities (probabilities at each level in control and experimental group). {p_end}
{synopt:{opt probf:ormat(string)}} Format for displaying table of anticipated probabilities (default is %-5.1f). {p_end}
{synopt:{opt form:at(string)}} Format for displaying calculated sample sizes (default is %6.1f) or powers (default is %6.3f). {p_end}
{synopt:{opt nor:ound}} Do not round sample size to next largest integer. {p_end}
{synopt:{opt nohead:er}} Do not print header describing the program. {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}
{title:Description}

{pstd}{cmd:artcat} calculates sample size given power, or power given sample size, for a 2-group randomised controlled trial with an ordered categorical outcome. 
Superiority, non-inferiority and substantial-superiority (also called super-superiority) trial types are all supported.

{pstd}We assume the trial will be analysed under the proportional odds model, and treatment effects are expressed on the odds ratio scale. 
However, the proportional odds model does not have to be true.
The anticipated treatment effect may instead be expressed as a common risk ratio or by specifying the outcome distribution.
In these cases, an odds ratio is fitted to the anticipated data and referred to as the average odds ratio.

{pstd}{cmd:artcat} is an immediate command: it does not use the data in memory.

{pstd}
This is a user-written command: please cite {help artcat##citation:our paper}, which also gives more details of the methods.

{marker methods}
{title:Which method?}

{pstd}All the methods are similar for moderate anticipated treatment effects - for example, for odds ratios between 0.7 and 1.4.

{pstd}With large anticipated treatment effects, our simulations show that the default method, {cmd:ologit(NA)}, is the most reliable.
The Whitehead method, which gives exactly the same results as {cmd:ologit(NN)}, 
tends to underestimate sample size and overestimate power.
Conversely, {cmd:ologit(AA)} tends to overestimate sample size and underestimate power.

{pstd}The theoretical explanation is that {cmd:ologit(NA)} correctly uses both the null and the alternative variances of the log odds ratio, 
whereas {cmd:ologit(NN)} uses only the null variance of the log odds ratio (which is smaller)
and {cmd:ologit(AA)} uses only the alternative variance of the log odds ratio (which is larger).

{marker obs}
{title:artcat for observational studies}

{pstd}{cmd:artcat} can also be used to design observational studies to explore a protective or harmful factor.
The trial types and outcome levels may need to be re-interpreted as shown in the table below.
Because clinical trials always aim to improve health, an observational study of a beneficial factor is most easily re-interpreted.
It is convenient to re-express an observational study of a harmful factor (risk factor) as one of a beneficial factor
by reversing the control and experimental groups. 
If this is not possible then it is necessary to invert unfavourable and favourable: for example, if the left-most outcome level is the most favourable outcome, then specify the {cmd:unfavourable} option.
The calculation ignores confounding: it may be reasonable in the presence of moderate confounding, but not with substantial confounding.

{col 5}{dup 70:{c -}}
{col 5}Trial type {col 30}Corresponding type for observational study
{col 5}as in program output{col 30}of benefit    {col 51}of harm (invert 
{col 5} {col 30}  {col 51}unfavourable/favourable)
{col 5}{dup 70:{c -}}
{col 5}Superiority{col 30}Benefit {col 51}Harm
{col 5}Non-inferiority{col 30}Non-harm  {col 51}Non-benefit
{col 5}Substantial-superiority{col 30}Substantial-benefit  {col 51}Substantial-harm
{col 5}{dup 70:{c -}}

{marker examples}
{title:Examples}

{pstd}We reproduce the sample size calculation for the FLU-IVIG trial ({help artcat##Davey++19:Davey et al 2019}). 
The control group was anticipated to have a 1.8% probability of the least favourable outcome (death), 
a 3.6% probability of the next least favourable outcome (admission to an intensive care unit), 
and so on up to 25.9% probability of the most favourable outcome (discharged with full resumption of normal activities). 
The trial was designed to have 80% power if the treatment achieves an odds ratio of 1.77 for a favourable outcome. 

{pstd}We can express this either by setting the left-most level as the least favourable outcome and inverting the odds ratio:

{pin}{stata artcat, pc(.018 .036 .156 .141 .390 .259) or(1/1.77) power(.8) unfavourable}

{pstd}or by setting the left-most level as the most favourable outcome:

{pin}{stata artcat, pc(.259 .390 .141 .156 .036 .018) or(1.77) power(.8) favourable}

{pstd}Note that the tables of anticipated probabilities from these two commands are the same (but inverted).

{pstd}We don't need to specify favourable or unfavourable, as the program can infer this, but note the warning message printed:

{pin}{stata artcat, pc(.018 .036 .156 .141 .390 .259) or(1/1.77) power(.8)}

{pstd}The right-most probability could be omitted in the syntax above, and we do this from now on. 
We next check that the power is very close to 80% if we recruit the required 322 participants:

{pin}{stata artcat, pc(.018 .036 .156 .141 .39) or(1/1.77) n(322) unfavourable}

{pstd}We compare the new methods with the Whitehead method:

{pin}{stata artcat, pc(.018 .036 .156 .141 .390) or(1/1.77) power(.8) whitehead unfavourable}

{pstd}We design a subsequent non-inferiority trial, using the above treatment (assumed successful with OR=1/1.77 as expected) as the control group, and setting a margin that retains half the effect (sqrt(1.77)=1.33):

{pin}{stata artcat, pc(.010 .021 .099 .103 .384) or(1) margin(1.33) power(.8) unfavourable}

{marker stored}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Scalars - Sample size (if calculated)}{p_end}
{synopt:{cmd:r(n)}} Sample size{p_end}
{synopt:{cmd:r(n_whitehead)}} Sample size by Whitehead method{p_end}
{synopt:{cmd:r(n_ologit_NN)}} Sample size by ologit NN method{p_end}
{synopt:{cmd:r(n_ologit_NA)}} Sample size by ologit NA method{p_end}
{synopt:{cmd:r(n_ologit_AA)}} Sample size by ologit AA method{p_end}

{p2col 5 15 19 2: Scalars - Power (if calculated)}{p_end}
{synopt:{cmd:r(power)}} Power{p_end}
{synopt:{cmd:r(power_whitehead)}} Power by Whitehead method{p_end}
{synopt:{cmd:r(power_ologit_NN)}} Power by ologit NN method{p_end}
{synopt:{cmd:r(power_ologit_NA)}} Power by ologit NA method{p_end}
{synopt:{cmd:r(power_ologit_AA)}} Power by ologit AA method{p_end}

{marker refs}
{title:References}

{phang}{marker Davey++19}
Davey RT, Fernández-Cruz E, Markowitz N, Pett S, Babiker AG, Wentworth D, et al. 
Anti-influenza hyperimmune intravenous immunoglobulin for adults with influenza A or B infection (FLU-IVIG): 
a double-blind, randomised, placebo-controlled trial. Lancet Respir Med 2019;7:951–63. 
{browse "https://doi.org/10.1016/S2213-2600(19)30253-X"}

{phang}{marker Whitehead93}
Whitehead J. Sample size calculations for ordered categorical data. Stat Med 1993;12:2257–71. 
{browse "http://doi.wiley.com/10.1002/sim.4780122404"}

{marker citation}
{title:Citation}

{phang}If you find this command useful, please cite it as below (and please check for updates): 

{phang}Ian R. White, Ella Marley-Zagar, Tim P Morris, Mahesh K. B. Parmar, Patrick Royston, Abdel G. Babiker.
Sample size calculation for an ordered categorical outcome.
Stata Journal 2023:1;3-23.
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X231161934"}

{phang}The author (below) would love to hear from you about how you are using the package.

{marker updates}
{title:Author and updates}

{pstd}The program was written by Ian White with input and support from Ella Marley-Zagar, Tim Morris, Max Parmar, Patrick Royston and Ab Babiker.
All authors are at the MRC Clinical Trials Unit at UCL, London, UK. 

{pstd}Email {browse "mailto:ian.white@ucl.ac.uk":ian.white@ucl.ac.uk}.

{pstd}You can get the latest version of this software from {browse "https://github.com/UCL/artcat"}
or within Stata by running 
{stata "net from https://raw.githubusercontent.com/UCL/artcat/master/package/"}.

{pstd}You can browse my other Stata software using 
{stata "net from http://www.homepages.ucl.ac.uk/~rmjwiww/stata/"}.


{title:See Also}

{pstd}{help artbin} (if installed)

{pstd}{help artsurv} (if installed)

