{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_mco_compare}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_mco_compare} {hline 2} Side-by-side comparison of every
multicointegration estimator and every test

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_mco_compare} {it:y_flow} {it:x_flowlist} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tr:end(spec)}}{bf:none}, {bf:c} (default), {bf:ct}, {bf:ctt}{p_end}
{synopt :{opt autol:ag(crit)}}{bf:bic} (default), {bf:aic}, {bf:hqic}, {bf:fixed}{p_end}
{synopt :{opt maxl:ags(#)}}cap on auto-selected lag (default 8){p_end}
{synopt :{opt le:ads(#)}}DOLS / TAOLS lead order (default 2){p_end}
{synopt :{opt dl:ags(#)}}DOLS / TAOLS lag order  (default 2){p_end}
{synopt :{opt ker:nel(name)}}{bf:bartlett} (default), {bf:parzen}, {bf:qs}{p_end}
{synopt :{opt k(#)}}TAOLS basis dimension (default 12){p_end}
{synopt :{opt saving(file)}}save the comparison matrix to {it:file}.dta{p_end}
{synoptline}

{title:Description}

{pstd}
Runs all six estimators currently available via {helpb multicoint}
(OLS, FM-OLS, DOLS, CCR, IM-OLS, TAOLS) and the three multicointegration
tests (Granger-Lee 1989/1990, Engsted-Gonzalo-Haldrup 1997, Sun et al.
2026 adaptive F).  Collects the long-run coefficient on the cumulated
stock regressor β_cum, its standard error, R², and the three test
statistics into a single comparison table.

{title:Stored results}

{phang}Matrices (rows ordered ols, fmols, dols, ccr, imols, taols){p_end}
{synoptset 22 tabbed}{...}
{synopt :{cmd:r(bcum)}}long-run coefficient on the cumulated regressor{p_end}
{synopt :{cmd:r(se)}}standard error{p_end}
{synopt :{cmd:r(r2)}}R²{p_end}
{synopt :{cmd:r(gl)}}Granger-Lee statistic{p_end}
{synopt :{cmd:r(egh)}}EGH t-statistic{p_end}
{synopt :{cmd:r(taols)}}Sun et al. adaptive F{p_end}

{title:Examples}

{phang}{bf:1.  Compare all six estimators on a flow system}{p_end}
{p 8 16 2}{stata "mixi12_mco_compare y x, trend(c) leads(2) dlags(2)"}{p_end}

{phang}{bf:2.  Save the comparison matrix for later analysis}{p_end}
{p 8 16 2}{stata "mixi12_mco_compare y x z, trend(ct) saving(mco_table.dta)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Multicointegration commands: {helpb mixi12_mco},
{helpb mixi12_gl}, {helpb mixi12_egh}.
Companions: {helpb mixi12_unit}, {helpb mixi12_haldrup},
{helpb mixi12_johansen}, {helpb mixi12_trans}, {helpb mixi12_sw},
{helpb mixi12_sim}, {helpb mixi12_graph}, {helpb mixi12_cv}.
Engine: {helpb multicoint}.
