{smcl}
{* 12Sep2025}{...}


{title:Title}

{p2colset 5 25 26 2}{...}
{p2col :{hi:power_arima_itsa} {hline 2}}Power analysis for an interrupted time series intervention evaluated using ARIMA with AR(1) Errors {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:power_arima_itsa}{cmd:,}
{cmdab:nt:ime(}{it:#}{cmd:)}
{cmdab:eff:ect}({it:{help numlist}})
[ {cmdab:tr:period(}{it:#}{cmd:)}
{cmdab:type(}{it:string}{cmd:)}
{cmdab:ac:orr(}{it:#}{cmd:)}
{cmdab:alp:ha(}{it:#}{cmd:)} 
{cmdab:onesid:ed}
{cmdab:know:nmean}
{cmdab:raw}
{opt for:mat}({it:{help format:%fmt}}) ]



{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt nt:ime}{cmd:(}{it:#}{cmd:)}}specify the number of time periods in the series{p_end}
{p2coldent:* {opt eff:ect}{cmd:(}{it:{help numlist}}{cmd:)}}effect size{p_end}
{synopt:{opt tr:period}{cmd:(}{it:#}{cmd:)}}the time period when the intervention begins; default is halfway in the time series {cmd:ntime()} {p_end}
{synopt:{opt type}{cmd:(}{it:string}{cmd:)}}type of intervention effect: "step", "pulse", or "ramp"; default is {cmd:type(step)}{p_end}
{synopt:{opt ac:orr}{cmd:(}{it:#}{cmd:)}}specify the correlation coefficient between adjacent (autoregressive) error terms; default is {cmd:acorr(0)}{p_end}
{synopt:{opt a:lpha}{cmd:(}{it:#}{cmd:)}}significance level; default is {cmd:alpha(0.05)}{p_end}
{synopt:{opt onesid:ed}}one-sided test; default is two-sided{p_end}
{synopt:{opt know:nmean}}the pre-intervention mean is known; default is that the pre-intervention mean is estimated {p_end}
{synopt:{opt raw}}{cmd:effects()} are unstandardized values; default is that {cmd:effects()} are standardized {p_end}
{synopt:{opt for:mat}{cmd:(}{it:{help format:%fmt}}{cmd:)}}display numeric format for values in the output; default is format({opt %-6.3f}){p_end}
{synoptline}
{p 4 6 2}* {opt ntime()} and {opt effect()} are required. {p_end}
{p2colreset}{...}



{title:Description}

{pstd}
{cmd:power_arima_itsa} computes power for a single-group interrupted time series analysis (ITSA) that will ultimately be evaluated using 
an Autoregressive Integrated Moving Average (ARIMA) model (McLeod and Vingilis 2005). Power is determined for an intervention that is 
expected have a "step" (level), "pulse" (single-period), or "ramp" (trend) effect. The results can be computed for actual effects, or 
as standardized effects (the intervention effect in units corresponding to standard deviations of the pre-intervention series). 



{title:Remark}

{pstd}
It is important to note that when evaluating a single-group ITSA using ARIMA, the effects ("step", "pulse" and "ramp") represent the 
predicted treatment period observations versus the counterfactual (the time series trajectory assuming no intervention). For the "step" effect, 
this is similar to how ITSA using time series regression would evaluate a level change. However, the "trend" effect in ITSA analyses using time 
series regression differs from the "ramp" effect in ARIMA in that it represents the difference between the pre-intervention and post-intervention 
trends. Therefore, a researcher may use {cmd:power_arima_itsa} for computing power for a "step" effect if they ultimately will use time series regression
for evaluating a "level" change, but should not use {cmd:power_arima_itsa} for computing power for a "ramp" effect if they ultimately will use time 
series regression for evaluating a difference in pre- to post-intervention "trends".



{title:Options}

{phang}
{cmd:ntime(}{it:integer}{cmd:)} specifies the number of time periods to generate in the series; {cmd:ntime() is required}. 

{phang}
{cmd:effect(}{it:numlist}{cmd:)} specifies the effect size; {cmd:effect() is required}.

{phang}
{cmd:trperiod(}{it:integer}{cmd:)} specifies the time period when the intervention begins; the default is the halfway point in the time series.

{phang}
{cmd:type(}{it:string}{cmd:)} specifies the effect type as "step", "pulse", or "ramp"; the default is {cmd: type(step)}.

{phang}
{cmd:acorr(}{it:#}{cmd:)} specifies the correlation coefficient between adjacent (autoregressive) error terms; the default is {cmd:acorr(0)}.

{phang}
{cmd:alpha(}{it:#}{cmd:)} sets the significance level of the test. The default is {cmd:alpha(0.05)}. 

{phang}
{cmd:onesided} one-sided test; default is two-sided. 

{phang}
{cmd:knownmean} the pre-intervention mean is known; default is that the pre-intervention mean is estimated. 

{phang}
{cmd:raw} indicates that the effect(s) specified in {cmd:effect()} are actual values; default is that values specified in {cmd:effect()}
are standardized (the intervention effect in units corresponding to standard deviations of the pre-intervention series). 

{phang}
{opth format(%fmt)} specifies the numeric format for displaying power in the output. The default is {cmd:format(%-6.3f)}.



{title:Examples}

{pstd}
This example is taken from Table 5 in McLeod and Vingilis (2005), where there is an expected "step" effect (level), there are 60 periods, 
the intervention is introduced at time 36, the effects are standardized, the autcorrelation coefficient is 0.50, and the test is one-sided.

{pmore2}{cmd:. power_arima_itsa , n(60) effect(0(0.25)2) tr(36) ac(0.5) onesided}{p_end}

{pstd}
Same as above but assume the intervention will have a "pulse" effect.

{pmore2}{cmd:. power_arima_itsa , n(60) effect(0(0.25)2) tr(36) ac(0.5) onesided type(pulse)}{p_end}

{pstd}
In this example, we assume that the intervention will produce a "ramp" effect (trend), there will be 10 total periods and the intervention
will commence at period 5. We test raw (unstandardized) effects ranging from 0 to 0.90 and assume the autocorrelation is 0.5.

{pmore2}{cmd:. power_arima_itsa , n(10) effect(0(0.05)0.9)  tr(5) ac(0.5) type(ramp) raw}{p_end}

{pstd}
Same as above but specify a one-sided test and specify that the pre-intervention mean in known.

{pmore2}{cmd:. power_arima_itsa , n(10) effect(0(0.05)0.9)  tr(5) ac(0.5) type(ramp) raw onesided knownmean}{p_end}




{marker results}{...}
{title:Stored results}

{pstd}
{cmd:power_arima_itsa} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 18 19 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}table of results{p_end}
{p2colreset}{...}



{title:References}

{phang}
McLeod, A. I. and E. R. Vingilis. 2005.
Power Computations for Intervention Analysis.
{it:Technometrics} 47: 174-181.



{marker citation}{title:Citation of {cmd:power_arima_itsa}}

{p 4 8 2}{cmd:power_arima_itsa} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). POWER_ARIMA_ITSA: Stata module to compute power for an interrupted time series intervention evaluated using ARIMA with AR(1) Errors.


{title:Author}

{pstd}Ariel Linden{p_end}
{pstd}Linden Consulting Group, LLC{p_end}
{pstd}alinden@lindenconsulting.org{p_end}
       
 
{p 7 14 2}Help: {helpb arima}, {helpb power_step} (if installed) {p_end}
