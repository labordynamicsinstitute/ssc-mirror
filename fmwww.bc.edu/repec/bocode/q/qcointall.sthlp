{smcl}
{* February 2026}{...}
{cmd:help qcointall}
{hline}

{title:Title}

{phang}
{bf:qcointall} {hline 2} Master command: runs the complete library of quantile
cointegration tests and estimators on a single dataset, with combined verdict
table.


{title:Syntax}

{p 8 17 2}
{cmd:qcointall} {depvar} {indepvars} {ifin}{cmd:,}
{opt tau(numlist)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tau(numlist)}}quantile levels in (0,1); required{p_end}
{synopt :{opt z:var(varname)}}stationary covariate for tuqcoint and liqcoint_fc{p_end}
{synopt :{opt p:order(#)}}polynomial order for qpolycoint; default 3{p_end}
{synopt :{opt ardlpq(p q)}}ARDL(p,q) orders to enable qardl (SSC) call{p_end}
{synopt :{opt graph}}produce combined comparison graph{p_end}
{synopt :{opt nocomb:ined}}skip combined graph (with {cmd:graph}){p_end}
{synopt :{opt skipxq}}skip xqcoint{p_end}
{synopt :{opt skippoly}}skip qpolycoint{p_end}
{synopt :{opt skipfurno}}skip fqardl, type(qcoint) (Furno){p_end}
{synopt :{opt skiptu}}skip tuqcoint{p_end}
{synopt :{opt skiplifc}}skip liqcoint_fc{p_end}
{synopt :{opt skipqardl}}skip qardl{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:qcointall} runs the complete battery of quantile cointegration tests and
estimators on a single dataset. It calls:

{phang2}1. {help xqcoint}      — Xiao (2009) FM + Kuriyama (2016) CUSUM test{p_end}
{phang2}2. {help qpolycoint}   — Li, Zheng & Guo (2016) polynomial + Wald linearity test{p_end}
{phang2}3. {help fqardl}{bf:, type(qcoint)} — Furno (2020) residual-based aux-QR test{p_end}
{phang2}4. {help tuqcoint}     — Tu et al. (2022) NP local-constant (if {cmd:zvar()} given){p_end}
{phang2}5. {help liqcoint_fc}  — Li et al. (2025) functional-coefficient (if {cmd:zvar()} given){p_end}
{phang2}6. {help qardl}        — Cho, Kim & Shin (2015) QARDL SSC command (if {cmd:ardlpq()} given){p_end}

{pstd}
After running, it displays a combined verdict table cross-referencing the test
statistics from xqcoint, qpolycoint, and Furno at each quantile, with significance
asterisks. The matrices from each sub-command are stored in {cmd:r()}.


{title:Combined verdict table interpretation}

{phang2}{bf:**}  reject H0 of NO-cointegration at 1%{p_end}
{phang2}{bf:*}   reject at 5%{p_end}
{phang2}{bf:.}   fail to reject (or test does not apply){p_end}

{pstd}
Note that the three columns test different nulls:{p_end}
{phang2}- {bf:xqcoint CUSUM}: H0 = cointegration (rejection = NO cointegration){p_end}
{phang2}- {bf:qpolycoint Wald}: H0 = linearity (rejection = nonlinear cointegration){p_end}
{phang2}- {bf:Furno aux-QR}: H0 = NO-cointegration (rejection = cointegration){p_end}


{title:Examples}

{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. qcointall y x, tau(0.25 0.5 0.75) porder(3)}{p_end}

{phang2}{cmd:. qcointall y x, tau(0.1 0.5 0.9) zvar(z) porder(2) graph}{p_end}

{phang2}{cmd:. qcointall y x1 x2, tau(0.5) ardlpq(2 2)}{p_end}


{title:Stored results}

{pstd}{cmd:qcointall} stores in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(xq_beta)}}xqcoint FM coefficients (ntau × k){p_end}
{synopt:{cmd:r(xq_cs)}}xqcoint CUSUM statistics (ntau × 1){p_end}
{synopt:{cmd:r(poly_coef)}}qpolycoint coefficients{p_end}
{synopt:{cmd:r(poly_q)}}qpolycoint Wald statistics{p_end}
{synopt:{cmd:r(poly_pval)}}qpolycoint p-values{p_end}
{synopt:{cmd:r(furno_res)}}Furno test results (α̂_2, t, cv5, cv1){p_end}
{synopt:{cmd:r(tu_mhat)}}tuqcoint fitted surface (if zvar given){p_end}
{synopt:{cmd:r(lfc_beta)}}liqcoint_fc β̂(z) curve (if zvar given){p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
February 2026


{title:Also see}

{psee}
{help xqcoint}, {help qpolycoint}, {help tuqcoint}, {help liqcoint_fc},
{help fqardl}, {help qardl}
