{smcl}
{* 12feb2026}{...}
{cmd:help xtpmg} {right:version 2.0.1}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi:xtpmg} {hline 2}}Pooled Mean-Group, Mean-Group, and
Dynamic Fixed Effects Models with Lag Selection, Short-Run Tables,
Half-Life & Impulse Response{p_end}
{p2colreset}{...}

{title:Version}

{pstd}
Version 2.0.1, 12 February 2026

{pstd}
{bf:Updated by:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{pstd}
{bf:Original authors:} Edward F. Blackburne III and Mark W. Frank, Sam Houston State University (2007)

{pstd}
{bf:What's new in version 2.0.1:}{p_end}
{p 8 12 2}- {bf:Automatic Lag Selection}: New {opt maxlag()} and {opt lagsel()} options for optimal ARDL lag order via AIC/BIC{p_end}
{p 8 12 2}- {bf:Per-Panel Short-Run Table}: New {opt srtable} option displays heterogeneous SR coefficients with significance stars{p_end}
{p 8 12 2}- {bf:Half-Life of Adjustment}: New {opt halflife} option computes ln(2)/|phi_i| for each panel{p_end}
{p 8 12 2}- {bf:Impulse Response Simulation}: New {opt irf()} option traces shock propagation through EC mechanism{p_end}
{p 8 12 2}- {bf:Graph Visualizations}: New {opt graph} option generates publication-quality Stata graphs{p_end}
{p 8 12 2}- {bf:Enhanced Display}: Box-drawn sections, ARDL order notation, improved formatting{p_end}

{pstd}
{bf:What was fixed in version 2.0.0:}{p_end}
{p 8 12 2}- Fixed {err:r(110)} "invalid new variable name" error that occurred in Stata 15.1+{p_end}
{p 8 12 2}- Root cause: Stata's {cmd:_predict} update (Feb 2019) disallows output variable names matching estimation result names{p_end}
{p 8 12 2}- Default EC variable name changed from {cmd:__ec} to {cmd:ECT} for readability{p_end}


{title:Syntax}

{p 8 16 2}{cmd:xtpmg} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opth lr:(varlist)}}terms to be included in long-run cointegrating vector{p_end}
{synopt :{opt nocons:tant}}suppresses constant term{p_end}
{synopt :{opth cl:uster(varname)}}adjust standard errors for intragroup
correlation{p_end}
{synopt :{opth ec:(name)}}name of newly created error-correction term; default is {cmd:ECT}{p_end}
{synopt :{opth const:raints(string)}}constraints to be applied to the model{p_end}
{synopt :{opt replace}}overwrite error correction term, if it exists{p_end}
{synopt :{opt full}}display all panel regressions for MG and PMG models{p_end}
{synopt :{opt pmg|mg|fe}}estimation method. Default is {opt pmg}.{p_end}

{syntab:Lag Selection (New in 2.0.1)}
{synopt :{opt maxlag(#)}}maximum lag order to search; default is {cmd:4}, range 1-8{p_end}
{synopt :{opt lagsel(string)}}lag selection criterion: {cmd:aic}, {cmd:bic}, or {cmd:both}{p_end}

{syntab:Diagnostics (New in 2.0.1)}
{synopt :{opt srtable}}display per-panel short-run coefficient table{p_end}
{synopt :{opt halflife}}compute and display half-life of adjustment per panel{p_end}
{synopt :{opt irf(#)}}simulate impulse response for {it:#} periods (e.g., {cmd:irf(20)}){p_end}
{synopt :{opt gr:aph}}generate publication-quality Stata graphs for ECT, half-life, IRF, and SR coefficients{p_end}

{syntab:Maximum Likelihood Options}
{p 6 6 2} {it:Only valid with} {cmd:pmg}.{p_end}
{synopt :{opt tech:nique(algorithm)}}specifies the {cmd:ml} maximization technique{p_end}
{synopt :{opt diff:icult}}will use a different stepping algorithm in non-concave
regions of the likelihood{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:xtpmg}; see {helpb tsset}.{p_end}
{p 4 6 2}
{it:varlists} may contain time-series operators; see
{help tsvarlist}.{p_end}



{title:Description}

{pstd}
{cmd:xtpmg} aids in the estimation of large {it:N} and large {it:T} panel-data models where
nonstationarity may be a concern. In addition to the traditional dynamic fixed effects models,
{cmd:xtpmg} allows for the pooled mean group and mean group estimators.

{pstd}
{bf:Version 2.0.1} introduces automatic lag selection, per-panel diagnostics, and 
impulse response analysis — tools frequently needed by researchers working with 
Panel ARDL models.


{title:New Features in 2.0.1}

{dlgtab:Automatic Lag Selection}

{pstd}
The {opt lagsel()} option automates the process of finding optimal ARDL lag orders 
using information criteria. For each panel unit, {cmd:xtpmg} tests all lag orders 
from 1 to {opt maxlag()} and selects the optimal using AIC or BIC (Schwarz criterion).

{pstd}
The selected lag order is reported in {cmd:ARDL(p,q1,q2,...)} notation. The modal 
(most frequent) lag across panels is used for pooled estimation.

{dlgtab:Per-Panel Short-Run Table}

{pstd}
The {opt srtable} option displays a formatted table showing heterogeneous short-run 
coefficients for each panel unit. In PMG estimation, long-run coefficients are 
constrained to be equal, but short-run dynamics differ across panels. This table 
reveals those differences with significance indicators (***, **, *).

{dlgtab:Half-Life of Adjustment}

{pstd}
The {opt halflife} option computes the half-life of adjustment to long-run equilibrium 
for each panel using the formula:

{p 8 12 2}half_life_i = ln(2) / |phi_i|{p_end}

{pstd}
where phi_i is the panel-specific error correction coefficient. Also reports the 
speed of adjustment (% of disequilibrium corrected per period) and convergence status.

{dlgtab:Impulse Response Simulation}

{pstd}
The {opt irf(#)} option simulates the dynamic response to a one-unit shock, tracing 
the adjustment path through the error-correction mechanism for {it:#} periods. Reports 
cumulative adjustment percentage and remaining gap with a visual ASCII display.


{title:Options}

{dlgtab:Model}

{phang}
{opt constraints(constraints)}, {opt noconstant}; see {help estimation options}.

{phang}
{opth lr(varlist)} specifies the variables to be included in the cointegrating vector.

{phang}
{opth ec(name)} specifies the name of the error-correction variable. Default is {cmd:ECT}.

{phang}
{opth cluster(varname)}; see {help estimation options##robust:estimation options}.

{phang}
{opt replace} replaces the error correction variable in memory, if it exists.

{phang}
{opt full} displays all panel estimation output.
 
{phang}
{cmd:pmg|mg|fe} selects the estimation procedure. {cmd:pmg} is the default.

{dlgtab:Lag Selection}

{phang}
{opt maxlag(#)} maximum lag to search. Default is 4, range 1-8.

{phang}
{opt lagsel(string)} criterion: {cmd:aic} (Akaike), {cmd:bic} (Schwarz/Bayesian), 
or {cmd:both} (report both, use AIC for selection).

{dlgtab:Diagnostics}

{phang}
{opt srtable} displays a table of short-run coefficients for each panel ID.

{phang}
{opt halflife} computes half-life = ln(2)/|phi_i| for each panel.

{phang}
{opt irf(#)} simulates impulse response for # periods. Typically 10-30.

{dlgtab:Visualization}

{phang}
{opt graph} generates publication-quality Stata graphs. When specified, the following
graphs are produced:{p_end}

{p 8 12 2}1. {bf:xtpmg_ect}: Error correction term bar chart by panel, color-coded by convergence strength (green = strong, amber = moderate, red = non-convergent){p_end}
{p 8 12 2}2. {bf:xtpmg_halflife}: Horizontal bar chart of half-life of adjustment per panel with mean reference line{p_end}
{p 8 12 2}3. {bf:xtpmg_irf}: Impulse response area chart showing shock adjustment path with half-life marker (requires {opt irf(#)}){p_end}
{p 8 12 2}4. {bf:xtpmg_sr_combined}: Combined panel of per-panel short-run coefficients with 95% confidence intervals (requires {opt full}){p_end}

{pstd}
Graphs are stored in memory and can be saved using {cmd:graph export}. For example:{p_end}
{phang}{cmd:. graph export xtpmg_irf.png, name(xtpmg_irf) replace}{p_end}
{title:Examples}

{pstd}{bf:Basic PMG estimation:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) full}{p_end}

{pstd}{bf:PMG with automatic lag selection (AIC):}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) maxlag(4) lagsel(aic) replace}{p_end}

{pstd}{bf:PMG with lag selection (both AIC and BIC):}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) maxlag(6) lagsel(both) replace}{p_end}

{pstd}{bf:PMG with per-panel short-run table:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) srtable replace}{p_end}

{pstd}{bf:PMG with half-life computation:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) halflife replace}{p_end}

{pstd}{bf:PMG with impulse response (20 periods):}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) irf(20) replace}{p_end}

{pstd}{bf:Full analysis — all new features:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) maxlag(4) lagsel(aic) srtable halflife irf(20) full replace}{p_end}

{pstd}{bf:Mean Group with diagnostics:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) mg halflife replace}{p_end}

{pstd}{bf:DFE estimation:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) fe replace}{p_end}

{marker graph_examples}{...}
{pstd}{bf:{ul:Graph Examples}}{p_end}

{pstd}{bf:Basic graphs (ECT + Half-Life charts):}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) graph full replace}{p_end}
{pstd}Produces: {cmd:xtpmg_ect} (ECT bar chart) and {cmd:xtpmg_halflife} (half-life chart).{p_end}

{pstd}{bf:Graphs with impulse response plot:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) irf(20) graph full replace}{p_end}
{pstd}Produces: {cmd:xtpmg_ect}, {cmd:xtpmg_halflife}, and {cmd:xtpmg_irf} (IRF area chart).{p_end}

{pstd}{bf:All graphs including short-run coefficient plot:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) irf(15) graph full replace}{p_end}
{pstd}Produces all 4 graphs: {cmd:xtpmg_ect}, {cmd:xtpmg_halflife}, {cmd:xtpmg_irf}, 
and {cmd:xtpmg_sr_combined} (requires {opt full}).{p_end}

{pstd}{bf:Complete workflow with lag selection, diagnostics, and graphs:}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) maxlag(4) lagsel(both) srtable halflife irf(20) graph full replace}{p_end}

{pstd}{bf:Exporting graphs to file:}{p_end}
{phang}{cmd:. graph export xtpmg_irf.png, name(xtpmg_irf) replace width(1200)}{p_end}
{phang}{cmd:. graph export xtpmg_ect.png, name(xtpmg_ect) replace width(1200)}{p_end}
{phang}{cmd:. graph export xtpmg_halflife.pdf, name(xtpmg_halflife) replace}{p_end}
{phang}{cmd:. graph export xtpmg_sr.png, name(xtpmg_sr_combined) replace width(1600)}{p_end}


{title:Stored Results}

{pstd}
{cmd:xtpmg} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(n_g)}}number of groups{p_end}
{synopt:{cmd:e(g_min)}}minimum group size{p_end}
{synopt:{cmd:e(g_avg)}}average group size{p_end}
{synopt:{cmd:e(g_max)}}maximum group size{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(sigma)}}estimated sigma{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpmg}{p_end}
{synopt:{cmd:e(model)}}estimation model ({cmd:pmg}, {cmd:mg}, or {cmd:fe}){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}name of panel variable{p_end}
{synopt:{cmd:e(tvar)}}name of time variable{p_end}
{synopt:{cmd:e(ardl_order)}}ARDL order notation (if {opt lagsel()} used){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(sig2_i)}}panel-specific variance estimates (PMG only){p_end}
{synopt:{cmd:e(phi_i)}}panel-specific ECT coefficients (PMG only){p_end}
{synopt:{cmd:e(irf)}}impulse response function matrix (if {opt irf()} used){p_end}

{title:References}

{phang}
Blackburne, E.F. III and M.W. Frank. 2007. 
Estimation of nonstationary heterogeneous panels. 
{it:Stata Journal} 7(2): 197-208.

{phang}
Pesaran, M.H., Y. Shin, and R.P. Smith. 1999.
Pooled mean group estimation of dynamic heterogeneous panels.
{it:Journal of the American Statistical Association} 94: 621-634.

{phang}
Pesaran, M.H. and R. Smith. 1995.
Estimating long-run relationships from dynamic heterogeneous panels.
{it:Journal of Econometrics} 68: 79-113.

{title:Authors}

{pstd}
{bf:Version 2.0.1 update:}{p_end}
{pstd}Dr Merwan Roudane{p_end}
{pstd}{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
{bf:Original version (1.1.1):}{p_end}
{pstd}Edward F. Blackburne III and Mark W. Frank{p_end}
{pstd}Sam Houston State University{p_end}

{title:Also see}

{psee}
Manual:  {bf:[XT] xt}

{psee}
{helpb xtdata}, {helpb xtdes},
{helpb xtreg}, {helpb xtsum},
{helpb xttab}; {helpb tsset}
{p_end}
