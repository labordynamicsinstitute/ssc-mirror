{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_mco}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_mco} {hline 2} Multicointegration in the I(1) flow / I(2)
stock setting (delegates to {helpb multicoint})

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_mco} {it:y_flow} {it:x_flowlist} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt est(name)}}{bf:ols}, {bf:fmols}, {bf:dols}, {bf:ccr}, {bf:imols}, {bf:taols} (default){p_end}
{synopt :{opt te:st(name)}}{bf:gl}, {bf:egh}, {bf:taols}, {bf:all} (default){p_end}
{synopt :{opt tr:end(spec)}}{bf:none}, {bf:c} (default), {bf:ct}, {bf:ctt}{p_end}
{synopt :{opt noc:onstant}}suppress the intercept{p_end}
{synopt :{opt lags(#)}}fixed ADF lag (0 = use {opt autolag}){p_end}
{synopt :{opt autol:ag(crit)}}{bf:bic} (default), {bf:aic}, {bf:hqic}, {bf:fixed}{p_end}
{synopt :{opt maxl:ags(#)}}cap on auto-selected lag (default 8){p_end}
{synopt :{opt le:ads(#)}}DOLS / TAOLS lead order (default 2){p_end}
{synopt :{opt dl:ags(#)}}DOLS / TAOLS lag order  (default 2){p_end}
{synopt :{opt ker:nel(name)}}{bf:bartlett} (default), {bf:parzen}, {bf:qs}{p_end}
{synopt :{opt bw:idth(#)}}HAC bandwidth (0 = Andrews){p_end}
{synopt :{opt k(#)}}TAOLS basis dimension (default 12){p_end}
{synopt :{opt le:vel(#)}}confidence level (default 95){p_end}
{synopt :{opt graph}}produce diagnostic plot afterwards{p_end}
{synopt :{opt grs:ave(file)}}export the plot{p_end}
{synopt :{opt notab:le}}suppress estimator/test tables (silent mode){p_end}
{synoptline}

{title:Description}

{pstd}
Multicointegration is the special I(1)/I(2) case in which the I(2)
variables are not directly observed but built as cumulants of underlying
I(1) flows.  The actual regression run is

{p 8 8 2}
{bf:Y_t = α + δ_1·t + δ_2·t² + β'·X_t + γ'·x_t + u_t}

{pstd}
with {it:Y_t} = Σ {it:y_s} and {it:X_t} = Σ {it:x_s} both I(2), {it:x_t}
the original I(1) flows, and {it:u_t} ~ I(0) under multicointegration.
Production–sales–inventory (Granger & Lee 1989) and consumption–
income–wealth (Engsted & Haldrup 1999) are the canonical examples.

{pstd}
This command is a thin wrapper around the user's {helpb multicoint}
package (Roudane 2026), which implements all six estimators (OLS,
FM-OLS, DOLS, CCR, IM-OLS, TAOLS) and all three multicointegration tests
(Granger-Lee 1989/1990, Engsted-Gonzalo-Haldrup 1997, Sun et al. 2026
adaptive F).  Use {helpb mixi12_mco} when you want to keep the analysis
inside the mixi12 narrative; use {helpb multicoint} directly when you
need the full option surface.

{title:When to choose this over the other mixi12 sub-commands}

{phang2}
- {bf:mixi12_johansen} - your I(2) variables are observed in {it:levels},
e.g. nominal money, prices, monetary base.  Estimates two reduced ranks
on the levels VAR.  This is the Juselius / Kurita / Majsterek route.{p_end}

{phang2}
- {bf:mixi12_mco} - your I(2) variables are {it:constructed} as cumulants
of I(1) flows (sales -> inventory; investment -> capital stock).  This is
the Granger-Lee / Engsted-Haldrup route.{p_end}

{title:Stored results}

{phang}Forwarded from {bf:multicoint}; see {helpb multicoint##results}.{p_end}

{title:Examples}

{phang}{bf:1.  Adaptive Sun et al. TAOLS test (all-in-one)}{p_end}
{p 8 16 2}{stata "mixi12_mco y x, est(taols) test(all) trend(c)"}{p_end}

{phang}{bf:2.  FM-OLS estimation with EGH one-step test}{p_end}
{p 8 16 2}{stata "mixi12_mco y x, est(fmols) test(egh) trend(ct)"}{p_end}

{phang}{bf:3.  Classical Granger-Lee two-step ADF}{p_end}
{p 8 16 2}{stata "mixi12_mco y x, est(ols) test(gl) trend(c)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_unit}, {helpb mixi12_haldrup},
{helpb mixi12_johansen}, {helpb mixi12_trans}, {helpb mixi12_sw},
{helpb mixi12_sim}, {helpb mixi12_graph}, {helpb mixi12_cv}.
Engine: {helpb multicoint}.
