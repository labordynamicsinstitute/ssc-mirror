{smcl}
{* *! version 1.0.0 09jun2026}{...}
{vieweralsosee "xttestpanel" "help xttestpanel"}{...}
{vieweralsosee "xttestpanel het" "help xttestpanel_het"}{...}
{vieweralsosee "xttestpanel serial" "help xttestpanel_serial"}{...}
{vieweralsosee "xttestpanel csd" "help xttestpanel_csd"}{...}
{vieweralsosee "xttestpanel func" "help xttestpanel_func"}{...}
{vieweralsosee "xttestpanel hausman" "help xttestpanel_hausman"}{...}
{title:Title}

{phang}
{bf:xttestpanel vif} {hline 2} Multicollinearity diagnostics for panel-data models

{title:Syntax}

{p 8 17 2}
{cmd:xttestpanel vif} [{depvar} {indepvars}] {ifin}
[{cmd:,} {opt model(fe|re)} {opt graph}]

{pstd}
Postestimation form (no varlist) reuses the last {helpb xtreg}; see
{helpb xttestpanel:the overview}.

{title:Description}

{pstd}
{cmd:xttestpanel vif} reports collinearity diagnostics on the (within-transformed for
{cmd:fe}) design matrix:

{p 8 8 2}o {bf:VIF} {hline 1} the classical variance inflation factor,
{it:VIF_j = 1/(1 - R2_j)}, equivalently the j-th diagonal of the inverse correlation
matrix of the regressors. For {cmd:fe} the regressors are first within-group demeaned,
giving the within-group VIF that is relevant for the FE estimator.{p_end}
{p 8 8 2}o {bf:Robust VIF (RVIF)} {hline 1} the robust diagnostic of {bf:Ismaeel, Midi &
Sani (2021)}. High-leverage collinearity-enhancing observations (HLCEOs) can mask or
manufacture collinearity in the ordinary VIF. The RVIF re-computes the VIF from a
robust (Huber-weighted) correlation matrix that down-weights high-leverage points, so
a gap between VIF and RVIF reveals leverage-driven collinearity.{p_end}

{pstd}
The tolerance {it:1/VIF} is also printed. Rule of thumb: {bf:VIF > 10} (tolerance
< 0.1) indicates serious collinearity.

{title:Options}

{phang}{opt model(fe|re)} design used; {cmd:fe} within-demeans the regressors
(default).{p_end}
{phang}{opt graph} horizontal bar chart of VIF and robust VIF with the threshold line
at 10.{p_end}

{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(vif)}}row vector of VIFs{p_end}
{synopt:{cmd:r(rvif)}}row vector of robust VIFs{p_end}
{synopt:{cmd:r(mean_vif)}}mean VIF{p_end}
{synopt:{cmd:r(mean_rvif)}}mean robust VIF{p_end}

{title:Examples}

{phang2}{cmd:. xttestpanel vif ln_wage age tenure hours, graph}{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, fe}{p_end}
{phang2}{cmd:. xttestpanel vif}{p_end}

{title:References}

{phang}Ismaeel, S.S., H. Midi, and M. Sani. 2021. {it:Malaysian Journal of Fundamental
and Applied Sciences} 17: 636-646.{p_end}

{title:Author}
{pstd}Merwan Roudane {hline 1} merwanroudane920@gmail.com {hline 1}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
