{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_graph}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_graph} {hline 2} Diagnostic plots for mixed I(1) / I(2) systems

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_graph} {it:subcmd} [{it:varlist}] [{cmd:,} {it:options}]

{p 4 4 2}
Subcommands:

{phang2}
{bf:levels} {it:varlist} - 3-panel plot: levels (top), first differences with
a 4-period moving average overlay (middle), second differences (bottom).
The visual signature of I(2) is the {it:smoothness} of levels combined
with persistent first differences and roughly white second differences.{p_end}

{phang2}
{bf:cointspace} - after {helpb mixi12_johansen}, plot the cointegration
relations {beta}'X_t.  This is the Juselius (2006) diagnostic for
checking that the supposedly stationary relations actually look
stationary.{p_end}

{phang2}
{bf:trends} - cumulated-variable proxies for the common stochastic trends
spanned by {alpha}_{perp}.{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt save(file)}}export the combined plot{p_end}
{synopt :{opt name(string)}}base name for the graphs{p_end}
{synopt :{opt scheme(name)}}graph scheme (default s2color){p_end}
{synoptline}

{title:Examples}

{phang}{bf:1. Visual I(2) signature on raw data}{p_end}
{p 8 16 2}{stata "mixi12_graph levels m2 mb p, save(levels.png)"}{p_end}

{phang}{bf:2. Cointegration relations after estimation}{p_end}
{p 8 16 2}{stata "mixi12_johansen m2 mb p rd, lags(3) rank(1) s1(1)"}{p_end}
{p 8 16 2}{stata "mixi12_graph cointspace, save(beta_X.png)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_unit}, {helpb mixi12_haldrup},
{helpb mixi12_johansen}, {helpb mixi12_trans}, {helpb mixi12_sw},
{helpb mixi12_sim}, {helpb mixi12_cv}.
