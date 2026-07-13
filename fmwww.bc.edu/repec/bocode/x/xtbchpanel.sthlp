{smcl}
{* *! version 2.0.0  12jul2026  Dr Merwan Roudane}{...}
{vieweralsosee "xtbchpanel methods" "help xtbchpanel_methods"}{...}
{vieweralsosee "xtmg" "help xtmg"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{vieweralsosee "xtpmg" "help xtpmg"}{...}
{viewerjumpto "Syntax" "xtbchpanel##syntax"}{...}
{viewerjumpto "Description" "xtbchpanel##description"}{...}
{viewerjumpto "Options" "xtbchpanel##options"}{...}
{viewerjumpto "Estimators" "xtbchpanel##estimators"}{...}
{viewerjumpto "Examples" "xtbchpanel##examples"}{...}
{viewerjumpto "Stored results" "xtbchpanel##results"}{...}
{viewerjumpto "References" "xtbchpanel##refs"}{...}
{viewerjumpto "Author" "xtbchpanel##author"}{...}
{title:Title}

{phang}
{bf:xtbchpanel} {hline 2} Bias-corrected mean-group long-run estimators for dynamic
heterogeneous panels (ARDL), with an optional climate-deviation mode

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtbchpanel}
{it:depvar} {it:indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt lag:s(p q)}}ARDL orders: p lags of {it:depvar}, q lags of each regressor;
default {cmd:lags(1 4)}{p_end}
{synopt:{opt diff:erence}}first-difference {it:depvar} and all regressors before
estimation (e.g. growth models){p_end}
{synopt:{opt cce}}add a lagged cross-section average of {it:depvar} as a common-correlated-
effects control{p_end}
{synopt:{opt world(varname)}}use this series (lagged) as the CCE control instead of the CSA{p_end}

{syntab:Climate-deviation mode (optional)}
{synopt:{opt ma(numlist)}}apply the annualized deviation transform with these norm window(s) m{p_end}
{synopt:{opt mavars(varlist)}}regressors to transform to (2/(m+1))|x - MA_m(x)|; default all{p_end}

{syntab:Estimators}
{synopt:{opt methods(list)}}subset of {cmd:mg hpjmg bc1 bc2 bc3 tmg hpjfe}; default {cmd:all}{p_end}
{synopt:{opt alphat:rim(#)}}TMG trimming exponent, a_n=C_n*n^(-#); default {cmd:1/3}{p_end}
{synopt:{opt reps(#)}}AWB bootstrap replications for BC2; default {cmd:199}{p_end}
{synopt:{opt seed(#)}}RNG seed; default {cmd:12345}{p_end}
{synopt:{opt rho(#)}}AR parameter of the autoregressive wild bootstrap; default {cmd:0.10}{p_end}

{syntab:Subgroups / reporting}
{synopt:{opt by(varname)}}report each estimator within groups of {it:varname}{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:95}{p_end}
{synopt:{opt graph}}distribution and forest plots{p_end}
{synopt:{opt gname(str)}}stub for saved graph names{p_end}
{synopt:{opt plotv:ar(varname)}}regressor used for the plots; default first{p_end}
{synopt:{opt plotma(#)}}window used for the theta-distribution plot{p_end}
{synopt:{opt nodots}}suppress bootstrap progress dots{p_end}
{synoptline}

{pstd}
The panel must be {helpb xtset}. Unbalanced panels and internal gaps are handled.

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtbchpanel} estimates the long-run effect of each regressor in a {it:dynamic
heterogeneous} panel and averages the unit-specific effects with a family of
bias-corrected and trimmed mean-group estimators. For each cross-section unit i it fits,
by OLS, the ARDL(p,q) model

{p 8 8 2}y(i,t) = a(i) + {&Sigma}(l=1..p) {&phi}(i,l) y(i,t-l)
+ {&Sigma}(k) {&Sigma}(l=0..q) {&beta}_k(i,l) x_k(i,t-l) [+ {&gamma}(i) cce(i,t-1)] + u(i,t),{p_end}

{pstd}
and forms the long-run coefficient of each regressor k,
{bf:theta_k(i) = [{&Sigma}_l {&beta}_k(i,l)] / [1 - {&Sigma}_l {&phi}(i,l)]}. These are
general dynamic-panel long-run estimators (Pesaran & Smith 1995; Chudik & Pesaran 2015;
Kiviet & Phillips 1993; Pesaran & Zhao 1999; Pesaran & Yang 2024; Chudik, Pesaran & Yang
2018) and apply to any field, not only climate.

{pstd}
{bf:Climate-macro mode.} Adding {opt difference}, {opt mavars()}+{opt ma()} and {opt cce}
reproduces the climate-growth specification of Centorrino, Massetti, Mohaddes, Raissi &
Yang (2026) and Kahn et al. (2021): {it:depvar} becomes growth, the climate regressor
becomes the annualized deviation from its m-year norm, and the world-growth CCE term is
included. A separate table column is produced per norm window m.

{pstd}
Output layout adapts automatically: without {opt ma()}, columns are the regressors (one
table per group); with {opt ma()}, columns are the norm windows (one table per regressor),
matching the source paper's tables. A pooled homogeneous HPJ-FE benchmark is reported
alongside.

{marker estimators}{...}
{title:Estimators}

{synoptset 20 tabbed}{...}
{synopt:{bf:MG}}Mean Group average of theta_k(i) (Pesaran & Smith 1995){p_end}
{synopt:{bf:HPJ-MG}}Half-Panel Jackknife MG (Chudik & Pesaran 2015){p_end}
{synopt:{bf:BC1}}analytical bias correction (Kiviet & Phillips 1993 COLS; exact for p=1){p_end}
{synopt:{bf:BC2}}bootstrap bias correction (Pesaran & Zhao 1999) via the Autoregressive
Wild Bootstrap (Smeekes & Urbain 2014){p_end}
{synopt:{bf:BC3}}Half-Panel Jackknife on the short-run vector, long-run per unit, averaged{p_end}
{synopt:{bf:TMG}}{it:preferred}: Trimmed Mean Group (Pesaran & Yang 2024){p_end}
{synopt:{bf:HPJ-FE}}pooled homogeneous benchmark with Chudik-Pesaran-Yang (2018) Prop-4 SE{p_end}

{marker options}{...}
{title:Options}

{phang}{opt lags(p q)} sets the ARDL orders. BC1 (Kiviet-Phillips) is exact only for a
single lagged dependent variable (p=1); for p>1 it returns the uncorrected estimate.

{phang}{opt difference} runs the whole model in first differences. {opt cce} / {opt world()}
add the common-factor control (a lagged cross-section average of the dependent, or a
user-supplied series).

{phang}{opt ma(numlist)} + {opt mavars(varlist)} turn on the climate-deviation transform
(2/(m+1))|x - MA_m| on the named regressors, sweeping the listed norm windows. The
transform is applied on levels, before any {opt difference}.

{phang}{opt methods()}, {opt alphatrim()}, {opt reps()}, {opt seed()}, {opt rho()} control
the estimator set and the TMG / AWB tuning. {opt by()} produces subgroup tables.

{marker examples}{...}
{title:Examples}

{pstd}General dynamic panel, long-run effects of two regressors:{p_end}
{phang2}{cmd:. xtset firm year}{p_end}
{phang2}{cmd:. xtbchpanel sales price adspend, lags(1 2)}{p_end}

{pstd}Growth model in first differences with a common-factor control:{p_end}
{phang2}{cmd:. xtbchpanel lgdp inv trade, difference cce lags(1 3)}{p_end}

{pstd}Climate-macro specification (Centorrino et al. 2026):{p_end}
{phang2}{cmd:. xtbchpanel lgdppc temp, difference mavars(temp) ma(20 30 40 50) cce lags(1 4)}{p_end}

{pstd}Subgroups and graphs:{p_end}
{phang2}{cmd:. xtbchpanel lgdppc temp pcp, difference mavars(temp pcp) ma(30) by(zone) graph}{p_end}

{pstd}A self-testing known-truth simulation ships as {cmd:xtbchpanel_example.do}.

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(p)}, {cmd:e(q)}, {cmd:e(kx)}}ARDL orders and number of regressors{p_end}
{synopt:{cmd:e(nma)}, {cmd:e(hasma)}, {cmd:e(ngroups)}}windows, climate-mode flag, groups{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtbchpanel}{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(lrvars)}, {cmd:e(mavars)}}dependent, regressors, transformed vars{p_end}
{synopt:{cmd:e(methods)}, {cmd:e(ma)}, {cmd:e(byvar)}, {cmd:e(difference)}}specification{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b_all)}, {cmd:e(se_all)}}long-run estimates / SEs; rows = group x estimator,
cols = regressor x window{p_end}
{synopt:{cmd:e(hpjfe_b)}, {cmd:e(hpjfe_se)}, {cmd:e(hpjfe_phi)}}pooled benchmark{p_end}
{synopt:{cmd:e(N_g)}}units per cell{p_end}
{synopt:{cmd:e(theta_i)}}per-unit theta for the plot regressor: id, group, MG, HPJ, TMG{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}preferred (TMG) long-run effect of the plot regressor{p_end}

{marker refs}{...}
{title:References}

{phang}Centorrino, S., E. Massetti, K. Mohaddes, M. Raissi, and J.-C. Yang. 2026.
Macroeconomic Consequences of Sustained Warming. Cambridge WP in Economics 2617.{p_end}
{phang}Chudik, A., and M. H. Pesaran. 2015. {it:Journal of Econometrics} 188(2): 393-420.{p_end}
{phang}Chudik, A., M. H. Pesaran, and J.-C. Yang. 2018. {it:J. Applied Econometrics} 33(6): 816-836.{p_end}
{phang}Kiviet, J. F., and G. D. A. Phillips. 1993. {it:Econometric Theory} 9(1): 62-80.{p_end}
{phang}Pesaran, M. H., and R. P. Smith. 1995. {it:Journal of Econometrics} 68(1): 79-113.{p_end}
{phang}Pesaran, M. H., and Z. Zhao. 1999. In {it:Analysis of Panels and LDV Models}, 297-322. CUP.{p_end}
{phang}Pesaran, M. H., and L. Yang. 2024. Trimmed Mean Group Estimation. CWPE 2364.{p_end}
{phang}Smeekes, S., and J.-P. Urbain. 2014. Autoregressive Wild Bootstrap. Maastricht University.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
