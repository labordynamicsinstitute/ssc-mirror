{smcl}
{* *! version 1.0.0 17jan2026}{...}
{cmd:help xtselfe}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{cmd:xtselfe} {hline 2}}Fixed-effects estimation with sample selection correction{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Estimation

{p 8 16 2}
{cmd:xtselfe}
{depvar}
{indepvars}
{ifin}{cmd:,}
{cmdab:sel:ect(}{it:{help depvar:depvar_s}}
[{cmd:=}]
{it:{help varlist:varlist_s}}
[{cmd:,} {it:{help xtselfe##sel_options:sel_options}}]{cmd:)}
[{it:{help xtselfe##options:options}}]


{phang}
Prediction

{p 8 16 2}
{cmd:predict}
[{it:{help data_types:type}}]
{newvar}
{ifin}
[{cmd:,} {it:{help xtselfe##statistic:statistic}}]


{synoptset 24 tabbed}{...}
{marker options}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent :* {opt sel:ect()}}specify selection equation: dependent and independent variables{p_end}
{synopt :{opt rho:type(type)}}{it:type} may be {cmdab:u:nrestricted}, {cmdab:s:tationary}, or {cmdab:c:ommon} (equivalent to {cmdab:exc:hangeable});
{cmd:unrestricted} places no restriction on the intertemporal correlations, {cmd:stationary} imposes stationarity across lags, and {cmd:common} assumes exchangeability;
default is {cmd:stationary}{p_end}
{synopt :{opt nointer:act}}use bias-correction term that is not interacted with period dummies{p_end}

{syntab:SE/Robust}
{synopt :{opt vce(vcetype)}}{it:vcetype} may be {cmdab:r:obust}, {cmdab:d:elta} {it:#.#}, {cmdab:unadj:usted}, or {cmdab:unadj:usted} {cmdab:cl:uster} {it:clustvar};
{cmd:delta} {it:#.#} uses cluster variance estimation at {it:panelvar} adjusted for the generated regressors, where {it:#.#} is the perturbation size for numerical differentiation;
default is {cmd:robust}, equivalent to {cmd:delta 1e-4};
{cmd:unadjusted cluster} {it:clustvar} does not adjust for the generated regressors;
{cmd:unadjusted} is identical to {cmd:unadjusted cluster} {it:panelvar}{p_end}

{syntab:Reporting}
{synopt :{opt f:irst}}report the first-stage probit regression results{p_end}
{synopt :{opt nolog}}suppress the intermediate messages;
{cmd:nolog} is ignored if both {cmd:first} and {cmd:nolog} are given{p_end}
{synopt :{opt debug}}report some information if an error occurs{p_end}
{synoptline}
{p 4 6 2}
* {opt select()} is required.{p_end}
{p 4 6 2}
{it:indepvars} and {it:varlist_s} may contain factor variables; see {help fvvarlist}.{p_end}

{synoptset 24 tabbed}{...}
{marker sel_options}{...}
{synopthdr :sel_options}
{synoptline}
{synopt :{opt m:undlak}[({it:varlist})]}use the Mundlak device to account for correlated random effects in probit regression;
apply the device only to {it:varlist} when specified;
default is {cmd:mundlak}{p_end}
{synopt :{opt c:hamberlain}[({it:varlist})]}use the Chamberlain device instead of the Mundlak device{p_end}
{synopt :{opt n:one}}suppress the inclusion of any device;
equivalent to {cmd:mundlak()} or {cmd:chamberlain()}{p_end}
{synopt :{opt p:ool}}use pooled probit regression;
not allowed with the Chamberlain device{p_end}
{synoptline}

{synoptset 24 tabbed}{...}
{marker statistic}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt xb}}calculate the linear prediction of a + xb;
the default{p_end}
{synopt :{opt u}}calculate the prediction of the fixed effects, u(i){p_end}
{synopt :{opt e}}calculate the prediction of the errors, e(it){p_end}
{synopt :{opt ue}}calculate the prediction of u(i) + e(it){p_end}
{synopt :{opt xbu}}calculate the prediction of a + xb + u(i){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtselfe} fits a fixed-effects linear regression model with sample selection.
It is a pooled weighted least squares estimation based on pairwise differences that eliminate fixed effects.
Correction terms for sample selection are constructed from probit regression and plug-in maximum likelihood estimation.
Standard errors obtained via the delta method are robust to the generated regressors problem.
{cmd:xtselfe} requires Stata 16 or later, with version 16.1 conservatively specified as the minimum requirement, as it relies on {help frames} introduced in Stata 16.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse wagework, clear}{p_end}
{phang2}{cmd:. xtset personid year}{p_end}
{phang2}{cmd:. global x "c.age##c.age tenure"}{p_end}
{phang2}{cmd:. global z "c.age##c.age market"}{p_end}

{pstd}Fixed-effects estimation with sample selection correction{p_end}
{phang2}{cmd:. xtselfe wage ${x}, select(working = ${z})}{p_end}
{phang2}{cmd:. xtselfe wage ${x}, select(working = ${z}, chamberlain)}{p_end}
{phang2}{cmd:. xtselfe wage ${x}, select(working = ${z}) rhotype(unrestricted)}{p_end}
{phang2}{cmd:. xtselfe wage ${x}, select(working = ${z}) vce(delta 0.00001)}{p_end}
{phang2}{cmd:. xtselfe wage ${x}, select(working = ${z}) vce(unadjusted)}{p_end}
{phang2}{cmd:. xtselfe wage ${x}, select(working = ${z}, mundlak(market)) first}{p_end}

{pstd}Joint test for the correction terms{p_end}
{phang2}{cmd:. test [correction]}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtselfe} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_selected)}}number of selected observations{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(N_pairs)}}number of pairwise-differenced observations{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(k_correct)}}number of correction terms{p_end}
{synopt:{cmd:e(k_rho)}}number of serial corrections{p_end}
{synopt:{cmd:e(n_probit_}{it:t}{cmd:)}}number of observations in probit for time {it:t}{p_end}
{synopt:{cmd:e(k_probit_}{it:t}{cmd:)}}number of parameters in probit for time {it:t}{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtselfe}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(seldep)}}name of dependent variable in selection equation{p_end}
{synopt:{cmd:e(ivar)}}variable denoting groups{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(device)}}{cmd:mundlak}, {cmd:chamberlain}, or {cmd:none}{p_end}
{synopt:{cmd:e(rhotype)}}{it:type} specified in {cmd:rhotype()}{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:robust}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtselfe_p}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(V_unadj)}}unadjusted variance{p_end}
{synopt:{cmd:e(b_rho)}}estimated serial corrections{p_end}
{synopt:{cmd:e(b_probit_}{it:t}{cmd:)}}coefficient vector in probit for time {it:t}{p_end}
{synopt:{cmd:e(V_probit_}{it:t}{cmd:)}}variance-covariance matrix in probit for time {it:t}{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Authors}

{pstd}
Chirok Han{break}
Department of Economics{break}
Korea University{break}
Seoul, Republic of Korea{break}
chirokhan@korea.ac.kr
{p_end}

{pstd}
Goeun Lee{break}
Department of Economics{break}
Kookmin University{break}
Seoul, Republic of Korea{break}
goeunlee@kookmin.ac.kr
{p_end}
