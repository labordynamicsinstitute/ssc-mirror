{smcl}
{* *! version 1.0.0 18Aug2026}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{hi:onemean_rtm} {hline 2}} Power analysis for a regression to the mean-adjusted one-sample mean test{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Compute sample size{p_end}

{p 8 15 2}
{cmd:power onemean_rtm ,}
{opth mu(numlist)}
{opth sd(numlist)}
{opth corr(numlist)}
{opth cut:off(numlist)}
{cmd:{{opth diff(numlist)} | {opth delta(numlist)}{cmd:}}}
{opth p:ower(numlist)}
[{it:{help onemean_rtm##options:options}}]


{pstd}
Compute power{p_end}

{p 8 15 2}
{cmd:power onemean_rtm ,}
{opth mu(numlist)}
{opth sd(numlist)}
{opth corr(numlist)}
{opth cut:off(numlist)}
{cmd:{{opth diff(numlist)} | {opth delta(numlist)}{cmd:}}}
{opth n(numlist)}
[{it:{help onemean_rtm##options:options}}]


{pstd}
Compute effect size ({cmd:diff} and {cmd:delta} are both reported){p_end}

{p 8 15 2}
{cmd:power onemean_rtm ,}
{opth mu(numlist)}
{opth sd(numlist)}
{opth corr(numlist)}
{opth cut:off(numlist)}
{opth n(numlist)}
{opth p:ower(numlist)}
[{it:{help onemean_rtm##options:options}}]

{pstd}
Only one of {cmd:diff()} or {cmd:delta()} may be specified.
Exactly two of {cmd:{diff()/delta()}}, {cmd:n()}, and
{cmd:power()} (or {cmd:beta()} in place of {cmd:power()}) must be specified;
the third is what gets solved for. {cmd:mu()}, {cmd:sd()}, {cmd:corr()}, and
{cmd:cutoff()} are always required.{p_end}


{marker options}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:* {opth mu(numlist)}}baseline population mean{p_end}
{p2coldent:* {opth sd(numlist)}}baseline population SD{p_end}
{p2coldent:* {opth corr(numlist)}}correlation between baseline and follow-up measurements{p_end}
{p2coldent:* {opth cutoff(numlist)}}baseline cutoff defining study eligibility{p_end}

{syntab:Solve-for triple (specify exactly two)}
{synopt:{opth diff(numlist)}}anticipated total pre-post effect size including the portion attributable to RTM; may not be combined with {cmd:delta()}{p_end}
{synopt:{opth delta(numlist)}}the RTM-adjusted "clean" effect size; may not be combined with {cmd:diff()}{p_end}
{synopt:{opth n(numlist)}}analyzable sample size{p_end}
{synopt:{opth power(numlist)}}desired power; default {cmd:power(0.8)} when applicable, per {cmd:power}'s own convention{p_end}
{synopt:{opth beta(numlist)}}alternative to {cmd:power()}: type II error rate ({cmd:power} = 1-{cmd:beta}); may not be combined with {cmd:power()}{p_end}

{syntab:Optional}
{synopt:{opt select(above|below)}}whether study eligibility is above or below baseline {cmd:cutoff()}; default {cmd:select(above)}.{p_end}
{synopt:{opth sd1(numlist)}}follow-up SD, if different from {cmd:sd()}; default is equal-variance ({cmd:sd1}={cmd:sd}).{p_end}
{synopt:{opth dropout(numlist)}}anticipated attrition proportion, in [0,1); inflates the reported {cmd:Nenroll} but does not change {cmd:N} itself; default {cmd:dropout(0)}{p_end}
{synopt:{opth alpha(numlist)}}significance level; default {cmd:alpha(0.05)}{p_end}
{synopt:{opt onesided}}request a one-sided test; default is two-sided{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:* required}{p_end}



{marker description}{...}
{title:Description}

{pstd}
{cmd:onemean_rtm} computes power for a pre-post study to detect 
the portion of the anticipated effect that cannot be explained by
regression to the mean (RTM). 



{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:diff} is the {it:raw anticipated total effect} -- what you expect the
group's average to shift by, before any RTM adjustment. {cmd:delta} is 
the {it:RTM-adjusted, "clean" effect size}.{p_end}



{title:Examples}

{pstd}Compute power, specifying {cmd:diff}{p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(65) diff(8) n(150)}{p_end}

{pstd}Compute power, specifying {cmd:delta} (the clean effect){p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(65) delta(8) n(150)}{p_end}

{pstd}Compute sample size{p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(65) diff(8) power(0.8)}{p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(65) delta(8) power(0.8)}{p_end}

{pstd}Compute effect size ({cmd:diff} and {cmd:delta}){p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(65) n(150) power(0.8)}{p_end}

{pstd}Specify multiple cutoffs {p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(60 65 70) diff(8) power(0.8)}{p_end}

{pstd}A negative treatment component ({cmd:diff} smaller than RTM) {p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(65) diff(5) n(150)}{p_end}

{pstd}Unequal follow-up variance and attrition inflation {p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(65) diff(12) n(150) sd1(9) dropout(0.15)}{p_end}

{pstd}Unequal variance producing a negative RTM{p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.9) cutoff(65) diff(8) power(0.8) sd1(20)}{p_end}

{pstd}One-sided test{p_end}

{phang2}{cmd:. power onemean_rtm, mu(50) sd(10) corr(0.6) cutoff(65) diff(8) n(150) onesided}{p_end}



{marker results}{title:Stored results}

{pstd}
{cmd:power onemean_rtm} follows {cmd:power}'s standard r-class result
conventions; see {help power usermethod:[PSS-2] power usermethod}. In
addition to {cmd:r(alpha)}, {cmd:r(power)}, and {cmd:r(N)}, it stores:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(mu)}}baseline population mean{p_end}
{synopt:{cmd:r(sd)}}baseline population SD{p_end}
{synopt:{cmd:r(corr)}}baseline-follow-up correlation{p_end}
{synopt:{cmd:r(cutoff)}}eligibility cutoff{p_end}
{synopt:{cmd:r(diff)}}anticipated total change ({it:M}, signed) -- given directly, or derived as {cmd:delta+RTM} if {cmd:delta()} was specified instead{p_end}
{synopt:{cmd:r(sd1)}}follow-up SD used (equals {cmd:sd()} if not separately specified){p_end}
{synopt:{cmd:r(dropout)}}anticipated attrition proportion{p_end}
{synopt:{cmd:r(z)}}standardized cutoff distance, {cmd:|cutoff-mu|/sd}{p_end}
{synopt:{cmd:r(lambda)}}tail-adjustment factor, {it:lambda(z)}{p_end}
{synopt:{cmd:r(RTM)}}estimated RTM (signed){p_end}
{synopt:{cmd:r(delta)}}the RTM-adjusted treatment component, {cmd:diff-RTM} (signed) -- given directly, or derived, depending on which was specified{p_end}
{synopt:{cmd:r(sigmaD)}}SD of the change score, conditional on cutoff selection{p_end}
{synopt:{cmd:r(pctRTM)}}percent of {cmd:diff} attributable to RTM{p_end}
{synopt:{cmd:r(Nenroll)}}enrollment size accounting for {cmd:dropout()}{p_end}
{p2colreset}{...}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(select)}}{cmd:above} or {cmd:below}, echoed back{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Khan M, Olivier J. 2025. Regression to the mean for bivariate distributions. 
{it:Biometrics} 81(1):ujaf033.{p_end}

{p 4 8 2}
Linden A. 2013. Assessing regression to the mean effects in health care initiatives. 
{it:BMC Medical Research Methodology} 13(119):1-7.{p_end}

{p 4 8 2}
Linden A. 2026. Regression to the mean-adjusted sample-Size determination for cutoff-selected single-arm pre-post studies.
Preprint: arXiv {p_end}



{marker citation}{title:Citation of {cmd:power onemean_rtm}}

{p 4 8 2}
{cmd:power onemean_rtm} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. 2026. POWER ONEMEAN_RTM: Stata module to compute power for a regression to the mean-adjusted one-sample mean test. Statistical
Software Components SXXXXXX, Boston College Department of Economics.



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}


{title:Also see}

{p 4 8 2} Help: {helpb power}, {helpb rtmci} (if installed) {p_end}
