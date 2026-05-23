{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_gl}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_gl} {hline 2} Granger-Lee (1989, 1990) two-step
multicointegration test (delegates to {helpb multicoint, test(gl)})

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_gl} {it:y_flow} {it:x_flowlist} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt est(name)}}stage-1 estimator: {bf:ols} (default), {bf:fmols}, {bf:dols}, {bf:ccr}, {bf:imols}, {bf:taols}{p_end}
{synopt :{opt tr:end(spec)}}{bf:none}, {bf:c} (default), {bf:ct}, {bf:ctt}{p_end}
{synopt :{opt autol:ag(crit)}}{bf:bic} (default), {bf:aic}, {bf:hqic}, {bf:fixed}{p_end}
{synopt :{opt maxl:ags(#)}}cap on auto-selected lag (default 8){p_end}
{synopt :{opt le:ads(#)}}lead order (default 2){p_end}
{synopt :{opt dl:ags(#)}}lag order (default 2){p_end}
{synopt :{opt ker:nel(name)}}{bf:bartlett}, {bf:parzen}, {bf:qs}{p_end}
{synopt :{opt k(#)}}TAOLS basis dimension (default 12){p_end}
{synopt :{opt le:vel(#)}}confidence level (default 95){p_end}
{synoptline}

{title:Description}

{pstd}
The original multicointegration test of Granger & Lee (1989, JAE; 1990,
{it:Advances in Econometrics} 8).  Two stages:

{phang2}
1. Regress {it:y_t} on {it:x_t} and save residual {it:Z_t}.{p_end}
{phang2}
2. Cumulate {it:Z_t} into {it:S_t} = Σ{it:Z_s}, regress {it:S_t} on
{it:x_t} and apply an ADF test to the stage-2 residual.{p_end}

{pstd}
Rejection of the unit-root null supports multicointegration.

{title:Stored results}

{phang}{cmd:r(stat)} GL statistic, {cmd:r(cv05)} 5% critical value,
{cmd:r(verdict)} reject / do-not-reject sentence.{p_end}

{title:Examples}

{phang}{bf:1.  Default OLS-based GL test}{p_end}
{p 8 16 2}{stata "mixi12_gl y x, trend(c)"}{p_end}

{phang}{bf:2.  Use FM-OLS in stage 1}{p_end}
{p 8 16 2}{stata "mixi12_gl y x, est(fmols) trend(ct)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Multicointegration commands: {helpb mixi12_mco}, {helpb mixi12_egh},
{helpb mixi12_mco_compare}.
Engine: {helpb multicoint}.
