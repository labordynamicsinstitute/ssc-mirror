{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_egh}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_egh} {hline 2} Engsted-Gonzalo-Haldrup (1997) one-step
residual ADF test of multicointegration (delegates to
{helpb multicoint, test(egh)})

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_egh} {it:y_flow} {it:x_flowlist} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt est(name)}}cointegrating-regression estimator: {bf:ols} (default), {bf:fmols}, {bf:dols}, {bf:ccr}, {bf:imols}, {bf:taols}{p_end}
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
ADF t-test applied to the residual of the {it:single} multicointegration
regression

{p 8 8 2}
{bf:Y_t = α + δ_1·t + δ_2·t² + β'·X_t + γ'·x_t + u_t}

{pstd}
where {it:Y_t} = Σ{it:y_s} and {it:X_t} = Σ{it:x_s}.  Critical values
follow Engsted-Gonzalo-Haldrup (1997, Tables 1–2) and are interpolated
in the sample size {it:T}.  Use {helpb mixi12_gl} for the older two-step
variant.

{title:Stored results}

{phang}{cmd:r(t)} EGH t-statistic; {cmd:r(cv01)}, {cmd:r(cv025)},
{cmd:r(cv05)}, {cmd:r(cv10)} critical values; {cmd:r(lags)} lag used;
{cmd:r(verdict)} highest rejection level reached.{p_end}

{title:Examples}

{phang}{bf:1.  Default OLS-based EGH test}{p_end}
{p 8 16 2}{stata "mixi12_egh y x, trend(c)"}{p_end}

{phang}{bf:2.  Use the TAOLS regression in stage 1}{p_end}
{p 8 16 2}{stata "mixi12_egh y x, est(taols) trend(ct)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Multicointegration commands: {helpb mixi12_mco}, {helpb mixi12_gl},
{helpb mixi12_mco_compare}.
Engine: {helpb multicoint}.
