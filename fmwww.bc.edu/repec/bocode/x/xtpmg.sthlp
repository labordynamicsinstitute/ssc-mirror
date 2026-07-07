{smcl}
{* 06jul2026}{...}
{vieweralsosee "xtpmg postestimation" "help xtpmg_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{viewerjumpto "Syntax" "xtpmg##syntax"}{...}
{viewerjumpto "Description" "xtpmg##description"}{...}
{viewerjumpto "Options" "xtpmg##options"}{...}
{viewerjumpto "Postestimation" "xtpmg##postestimation"}{...}
{viewerjumpto "Hausman test" "xtpmg##hausman"}{...}
{viewerjumpto "Stored results" "xtpmg##results"}{...}
{viewerjumpto "Examples" "xtpmg##examples"}{...}
{viewerjumpto "References" "xtpmg##refs"}{...}
{cmd:help xtpmg} {right:version 2.1.1}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi:xtpmg} {hline 2}}Pooled Mean-Group, Mean-Group, and
Dynamic Fixed Effects Models with Lag Selection, Short-Run Tables,
Half-Life & Impulse Response{p_end}
{p2colreset}{...}

{title:Version}

{pstd}
Version 2.1.1, 6 July 2026

{pstd}
{bf:Updated by:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{pstd}
{bf:Original authors:} Edward F. Blackburne III and Mark W. Frank, Sam Houston State University (2007)

{pstd}
{bf:What's new in version 2.1.1:}{p_end}
{p 8 12 2}- {bf:Cross-sectional dependence test}: Pesaran (2004, 2015) CD test on the residuals is reported automatically after every estimator (pmg, mg, dfe) and stored in {cmd:e(CD)}, {cmd:e(p_CD)}, {cmd:e(CD_avg)}{p_end}
{p 8 12 2}- {bf:Long-run coefficient plot} and {bf:combined dashboard}: new professional {cmd:xtpmg_lrcoef} (dot-and-whisker with 95% CI) and {cmd:xtpmg_dashboard} graphs{p_end}
{p 8 12 2}- {bf:Diagnostics/graphs now available for mg and dfe}, not only pmg (half-life, IRF and graphs use the stored {cmd:e(phi_i)}){p_end}
{p 8 12 2}- {bf:Corrected half-life} to the exact discrete error-correction formula {cmd:ln(2)/-ln(1+phi_i)}, consistent with the simulated IRF path{p_end}
{p 8 12 2}- {bf:Corrected automatic lag selection}: candidate ARDL orders are now compared on a common (fixed) estimation sample so AIC/BIC are comparable, and BIC uses the effective number of observations{p_end}

{pstd}
{bf:What was new in version 2.0.1:}{p_end}
{p 8 12 2}- {bf:Automatic Lag Selection}: New {opt maxlag()} and {opt lagsel()} options for optimal ARDL lag order via AIC/BIC{p_end}
{p 8 12 2}- {bf:Per-Panel Short-Run Table}: New {opt srtable} option displays heterogeneous SR coefficients with significance stars{p_end}
{p 8 12 2}- {bf:Half-Life of Adjustment}: New {opt halflife} option computes ln(2)/|phi_i| for each panel{p_end}
{p 8 12 2}- {bf:Error-Correction Adjustment Path}: New {opt irf()} option traces the equilibrium-error decay at the mean speed of adjustment{p_end}
{p 8 12 2}- {bf:Graph Visualizations}: New {opt graph} option generates publication-quality Stata graphs{p_end}
{p 8 12 2}- {bf:Enhanced Display}: Box-drawn sections, ARDL order notation, improved formatting{p_end}

{pstd}
{bf:What was fixed in version 2.0.0:}{p_end}
{p 8 12 2}- Fixed {err:r(110)} "invalid new variable name" error that occurred in Stata 15.1+{p_end}
{p 8 12 2}- Root cause: Stata's {cmd:_predict} update (Feb 2019) disallows output variable names matching estimation result names{p_end}
{p 8 12 2}- Default EC variable name changed from {cmd:__ec} to {cmd:ECT} for readability{p_end}


{marker syntax}{...}
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
{synopt :{opt pmg|mg|dfe}}estimation method. Default is {opt pmg}.{p_end}

{syntab:Lag Selection (New in 2.0.1)}
{synopt :{opt maxlag(#)}}maximum lag order to search; default is {cmd:4}, range 1-8{p_end}
{synopt :{opt lagsel(string)}}lag selection criterion: {cmd:aic}, {cmd:bic}, or {cmd:both}{p_end}

{syntab:Diagnostics (New in 2.0.1)}
{synopt :{opt srtable}}display per-panel short-run coefficient table{p_end}
{synopt :{opt halflife}}compute and display half-life of adjustment per panel{p_end}
{synopt :{opt irf(#)}}simulate impulse response for {it:#} periods (e.g., {cmd:irf(20)}){p_end}
{synopt :{opt gr:aph}}generate publication-quality Stata graphs for long-run coefficients, ECT, half-life, IRF, SR coefficients, and a combined dashboard{p_end}

{syntab:Residual diagnostics (New in 2.1.1)}
{synopt :{it:(automatic)}}the Pesaran CD test for cross-sectional dependence is printed after every estimator; no option required{p_end}

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



{marker description}{...}
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
from 0 to {opt maxlag()} for each x-variable and from 1 to {opt maxlag()} for the 
dependent variable, selecting the optimal using AIC or BIC (Schwarz criterion).

{pstd}
A lag order of q=0 for an x-variable means it has no short-run component 
(only the long-run relationship). This allows heterogeneous orders such as 
ARDL(1,2,0) or ARDL(2,1,3).

{pstd}
The selected lag order is reported in {cmd:ARDL(p,q1,q2,...)} notation. The modal 
(most frequent) lag across panels is used for pooled estimation.

{pstd}
{bf:Note:} The {opt lagsel()} option must be explicitly specified to trigger 
automatic lag selection. Specifying {opt maxlag()} alone will display a warning 
but will not trigger selection.

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

{p 8 12 2}half_life_i = ln(2) / -ln(1 + phi_i){p_end}

{pstd}
where phi_i is the panel-specific error correction coefficient. Also reports the 
speed of adjustment (% of disequilibrium corrected per period) and convergence status.

{dlgtab:Error-Correction Adjustment Path}

{pstd}
The {opt irf(#)} option traces the decay of a one-unit deviation from long-run 
equilibrium over {it:#} periods, using the mean error-correction coefficient: 
{cmd:gap(t) = (1 + phibar)^t}. It reports cumulative adjustment and remaining gap 
with a visual display.

{pstd}
{bf:Interpretation:} this is a pure error-correction decay and does {it:not} 
propagate the short-run ARDL lag terms. It is {it:exact} for a partial-adjustment 
model, ARDL(1,0,...,0), and an approximation to the full dynamic impulse response 
when higher-order short-run lags are present.


{marker options}{...}
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
{cmd:pmg|mg|dfe} selects the estimation procedure. {cmd:pmg} is the default.

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
{opt halflife} computes half-life = ln(2)/-ln(1+phi_i) (exact discrete EC decay) for each panel.

{phang}
{opt irf(#)} traces the error-correction adjustment path for # periods (typically 10-30). See the note above on the partial-adjustment assumption.

{dlgtab:Visualization}

{phang}
{opt graph} generates publication-quality Stata graphs. When specified, the following
graphs are produced:{p_end}

{p 8 12 2}1. {bf:xtpmg_ect}: Error correction term bar chart by panel, color-coded by convergence strength (green = strong, amber = moderate, red = non-convergent){p_end}
{p 8 12 2}2. {bf:xtpmg_halflife}: Horizontal bar chart of half-life of adjustment per panel with mean reference line{p_end}
{p 8 12 2}3. {bf:xtpmg_irf}: Error-correction adjustment-path area chart with half-life marker (requires {opt irf(#)}){p_end}
{p 8 12 2}4. {bf:xtpmg_sr_combined}: Combined panel of per-panel short-run coefficients with 95% confidence intervals (requires {opt full}, pmg only){p_end}
{p 8 12 2}5. {bf:xtpmg_lrcoef}: Long-run coefficient dot-and-whisker plot with 95% confidence intervals{p_end}
{p 8 12 2}6. {bf:xtpmg_dashboard}: Combined one-page dashboard (long-run coefficients, ECT, half-life, IRF){p_end}

{pstd}
Graphs are stored in memory and can be saved using {cmd:graph export}. For example:{p_end}
{phang}{cmd:. graph export xtpmg_irf.png, name(xtpmg_irf) replace}{p_end}
{marker examples}{...}
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
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) dfe replace}{p_end}

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


{marker postestimation}{...}
{title:Postestimation}

{pstd}
After {cmd:pmg} or {cmd:mg}, the per-panel (heterogeneous) coefficients can be
visualized and their standard errors bootstrapped with {cmd:estat}:

{synoptset 26 tabbed}{...}
{synopt :{helpb xtpmg_postestimation##graph:estat box}}box plot of the per-panel coefficient distribution{p_end}
{synopt :{helpb xtpmg_postestimation##graph:estat bar}}bar plot of each panel's coefficient(s){p_end}
{synopt :{helpb xtpmg_postestimation##graph:estat rcap}}range (caterpillar) plot: per-panel point estimate and 95% CI with mean-group line{p_end}
{synopt :{helpb xtpmg_postestimation##boot:estat bootstrap}}cross-section (panel) bootstrap standard errors / CIs{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The graph subcommands ({cmd:box}, {cmd:bar}, {cmd:rcap}) are not available
after {cmd:dfe} (no per-panel coefficients). See
{helpb xtpmg_postestimation:help xtpmg postestimation} for the full syntax,
options, stored results and examples.


{marker hausman}{...}
{title:Model selection: the Hausman test}

{pstd}
The three estimators are nested by how much cross-panel homogeneity they impose:

{p 8 14 2}{bf:o mg} {hline 1} all coefficients heterogeneous; always consistent
(large {it:T}), least efficient.{p_end}
{p 8 14 2}{bf:o pmg} {hline 1} long-run coefficients pooled, short-run free;
consistent {it:and} efficient only if long-run homogeneity holds.{p_end}
{p 8 14 2}{bf:o dfe} {hline 1} all slopes and error variances pooled; consistent
{it:and} efficient only if full homogeneity holds.{p_end}

{pstd}
A Hausman test ({helpb hausman}) contrasts a {it:consistent} estimator against a
{it:more efficient} (more restrictive) one. The null hypothesis H0 is that the
extra restriction is valid, so the two coefficient vectors should not differ
systematically. Order the estimators {bf:less-restrictive first}:

{p 8 16 2}{cmd:hausman} {it:consistent_est} {it:efficient_est} [{cmd:, sigmamore}]{p_end}

{pstd}
{ul:Workflow / syntax}

{phang2}{cmd:. xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) pmg replace}{p_end}
{phang2}{cmd:. estimates store pmg}{p_end}
{phang2}{cmd:. xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) mg replace}{p_end}
{phang2}{cmd:. estimates store mg}{p_end}
{phang2}{cmd:. hausman mg pmg, sigmamore}{p_end}

{pstd}
{cmd:hausman} automatically compares the common {bf:long-run} coefficients (the
{cmd:ec} equation). {cmd:sigmamore} bases both covariance matrices on the same
disturbance-variance estimate and is recommended for stability. Use the built-in
{cmd:hausman} on two {cmd:estimates store}d fits; do not hand-code the contrast.

{pstd}
{ul:Which pairing to use}

{synoptset 22 tabbed}{...}
{p2coldent :Command}Tests H0 that ...{p_end}
{synoptline}
{synopt :{cmd:hausman mg pmg}}the long-run coefficients are homogeneous {bf:(standard PMG test)}{p_end}
{synopt :{cmd:hausman mg dfe}}all slope coefficients are homogeneous (the full DFE restriction){p_end}
{synopt :{cmd:hausman pmg dfe}}DFE's extra restrictions hold, given long-run homogeneity{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{ul:Interpretation}

{p 8 14 2}{bf:o Do not reject} H0 (large p-value): the restriction is supported,
so prefer the more efficient (more restrictive) estimator {hline 1} e.g. prefer
{bf:pmg} over {bf:mg}.{p_end}
{p 8 14 2}{bf:o Reject} H0 (small p-value): the restriction is violated, so use
the less-restrictive estimator {hline 1} e.g. {bf:mg}.{p_end}

{pstd}
{bf:Recommended primary test:} {cmd:hausman mg pmg}. This is the test used
throughout Pesaran, Shin and Smith (1999) to decide whether the long run can be
pooled. A typical decision rule:

{p 8 14 2}1. Run {cmd:hausman mg pmg}. If not rejected, pool the long run and
report {bf:pmg}; if rejected, report {bf:mg}.{p_end}
{p 8 14 2}2. Only if step 1 is not rejected and full pooling is of interest,
examine {cmd:hausman pmg dfe} (or {cmd:hausman mg dfe}).{p_end}

{pstd}
{bf:Caution with the dfe pairings.} DFE is biased when slope coefficients are
heterogeneous (Pesaran and Smith 1995), which weakens its role as the efficient
estimator. For the dfe contrasts the difference {cmd:V_b - V_B} is often
near-singular, so the statistic can be sensitive to {cmd:sigmamore}: if the
results with and without {cmd:sigmamore} disagree, treat the dfe-based test as
unreliable and rely on {cmd:hausman mg pmg}.

{pstd}
{ul:Visualizing the test.} After storing the fits, {cmd:estat hausman} draws a
forest plot of the long-run coefficients from each estimator (point estimate and
95% CI) and annotates the test statistic, so overlapping intervals can be read
directly:

{phang2}{cmd:. estat hausman mg pmg dfe, sigmamore}{p_end}

{pstd}
See {helpb xtpmg_postestimation##haus:estat hausman}. A worked Hausman example
is included in {cmd:xtpmg_example.do}.


{marker results}{...}
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
{synopt:{cmd:e(CD)}}Pesaran CD statistic for cross-sectional dependence in residuals{p_end}
{synopt:{cmd:e(p_CD)}}two-sided p-value of the CD statistic{p_end}
{synopt:{cmd:e(CD_avg)}}mean absolute pairwise residual correlation{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpmg}{p_end}
{synopt:{cmd:e(model)}}estimation model ({cmd:pmg}, {cmd:mg}, or {cmd:dfe}){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}name of panel variable{p_end}
{synopt:{cmd:e(tvar)}}name of time variable{p_end}
{synopt:{cmd:e(ardl_order)}}ARDL order notation (always displayed){p_end}
{synopt:{cmd:e(coef_i)}}names of the per-panel coefficients in {cmd:e(b_i)}{p_end}
{synopt:{cmd:e(cmdline)}}the command as typed (used by {cmd:estat bootstrap}){p_end}
{synopt:{cmd:e(estat_cmd)}}{cmd:xtpmg_estat}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(sig2_i)}}panel-specific variance estimates (PMG only){p_end}
{synopt:{cmd:e(phi_i)}}panel-specific ECT coefficients (pmg and mg){p_end}
{synopt:{cmd:e(b_i)}}per-panel coefficient estimates, panels x coefficients (pmg and mg){p_end}
{synopt:{cmd:e(se_i)}}per-panel standard errors, same layout as {cmd:e(b_i)}{p_end}
{synopt:{cmd:e(irf)}}impulse response function matrix (if {opt irf()} used){p_end}

{marker refs}{...}
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
Pesaran, M.H. 2015. Testing weak cross-sectional dependence in large panels.
{it:Econometric Reviews} 34: 1089-1117.

{phang}
Pesaran, M.H. 2004. General diagnostic tests for cross-sectional dependence
in panels. {it:Cambridge Working Papers in Economics} No. 0435.

{phang}
Pesaran, M.H. and R. Smith. 1995.
Estimating long-run relationships from dynamic heterogeneous panels.
{it:Journal of Econometrics} 68: 79-113.

{title:Authors}

{pstd}
{bf:Version 2.1.1 update:}{p_end}
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
