{smcl}
{* *! version 1.0.1  21may2026}{...}
{cmd:help mixi12_unit}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_unit} {hline 2} Cross-variable integration-order summary
(delegates to {helpb dptest})

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_unit} {it:varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt te:st(name)}}sub-test to run via dptest: {bf:dp}, {bf:hf}, {bf:hz} or {bf:all} (default){p_end}
{synopt :{opt det(spec)}}{bf:none}, {bf:const} (default), {bf:trend}, {bf:qtrend}{p_end}
{synopt :{opt maxl:ag(#)}}ADF/HF/HZ max lag (−1 = Schwert rule, default){p_end}
{synopt :{opt maxd:iff(#)}}max differencing order for DP t* (default 3){p_end}
{synopt :{opt band:width(#)}}Bartlett bandwidth for Haldrup Z(F*) (−1 = Schwert){p_end}
{synopt :{opt le:vel(#)}}1, 5 (default) or 10{p_end}
{synopt :{opt crit(name)}}{bf:bic} (default) or {bf:aic}{p_end}
{synopt :{opt saving(file)}}save the verdict table to {it:file}.dta{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:mixi12_unit} runs the I(2) unit-root battery on every variable in
{it:varlist} by calling {helpb dptest} once per series, then prints a
clean cross-variable summary table with the Dickey-Pantula t*, the
Hasza-Fuller joint F, the Haldrup semiparametric Z(F*) and the consensus
integration order.

{pstd}
All per-variable computation, critical-value tables and lag selection
are performed by {bf:dptest} (Roudane 2026) - the package the user
authored as the canonical I(2) unit-root toolbox.  This wrapper exists
so {cmd:mixi12} produces a single tidy multi-series table instead of a
long per-series printout.

{title:Stored results}

{phang}Matrices{p_end}
{synoptset 22 tabbed}{...}
{synopt :{cmd:r(order)}}p x 1 consensus integration order{p_end}
{synopt :{cmd:r(DPd)}}p x 1 Dickey-Pantula d{p_end}
{synopt :{cmd:r(HFF) / r(HFd)}}Hasza-Fuller F statistic / verdict{p_end}
{synopt :{cmd:r(HZZ) / r(HZd)}}Haldrup Z(F*) statistic / verdict{p_end}

{title:Examples}

{phang}{bf:1.  Classify every variable in a 4-variable system}{p_end}
{p 8 16 2}{stata "mixi12_unit m2 mb p rd, det(const) level(5)"}{p_end}

{phang}{bf:2.  Only the semiparametric Haldrup test}{p_end}
{p 8 16 2}{stata "mixi12_unit m2 mb p rd, test(hz) det(const)"}{p_end}

{phang}{bf:3.  Save the integration-order matrix for downstream use}{p_end}
{p 8 16 2}{stata "mixi12_unit m2 mb p rd, det(trend) saving(orders.dta)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_haldrup}, {helpb mixi12_johansen},
{helpb mixi12_trans}, {helpb mixi12_sw}, {helpb mixi12_sim},
{helpb mixi12_graph}, {helpb mixi12_cv}.
Engine: {helpb dptest}.
