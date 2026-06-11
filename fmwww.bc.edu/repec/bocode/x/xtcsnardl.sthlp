{smcl}
{* *! version 1.0.0 28may2026}{...}
{cmd:help xtcsnardl}{right:also see:  {help xtpmg}  {help pnardl}  {help xtdcce2}  {help xtcspqardl}}
{hline}

{title:Title}

{phang}
{bf:xtcsnardl} {hline 2} Cross-Sectionally Augmented Panel Nonlinear ARDL (CS-NARDL)

{title:Navigate this help}

{phang}
{bf:Main reference (this page):} syntax, options, and quick start.{break}
{bf:Other pages:}
   {help xtcsnardl_methodology:Methodology & equations} {hline 2} theoretical foundations, CCE corrections, asymmetric decomposition{break}
   {help xtcsnardl_postestimation:Post-estimation} {hline 2} {cmd:e()} returns, {cmd:test}, {cmd:predict}, custom multipliers{break}
   {help xtcsnardl_examples:Worked examples} {hline 2} EURO-4 CO{sub:2} replication, BRICS REC, Monte Carlo, synthetic DGP{break}
   {help xtcsnardl_graph:Graphs} {hline 2} publication-quality plots produced with {opt graph}


{title:Syntax}

{p 8 17 2}
{cmd:xtcsnardl}
{depvar} [{it:sr_regressors}] {ifin}{cmd:,}
{cmdab:lr(}{it:lr_y_lag lr_regressors}{cmd:)}
{cmdab:asym:metric(}{it:varlist}{cmd:)}
[{it:options}]


{synoptset 28 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Estimator / engine  (every engine is the {ul:nonlinear} extension of the canonical method)}
{synopt :{opt pmg}}{ul:Nonlinear Panel ARDL} -- pooled mean group via xtpmg (default){p_end}
{synopt :{opt mg}}{ul:Nonlinear Panel ARDL} -- mean group via xtpmg{p_end}
{synopt :{opt dfe}}{ul:Nonlinear Panel ARDL} -- dynamic fixed effects via xtpmg{p_end}
{synopt :{opt engine(csardl)}}{ul:Nonlinear CS-ARDL} via {help xtdcce2:xtdcce2} (Chudik-Pesaran 2015){p_end}
{synopt :{opt engine(csdl)}}{ul:Nonlinear CS-DL} via {help xtdcce2:xtdcce2} (direct LR){p_end}
{synopt :{opt engine(dcce)}}{ul:Nonlinear DCCE} via {help xtdcce2:xtdcce2} (mean-group with dynamics){p_end}
{synopt :{opt engine(cce)}}{ul:Nonlinear CCE} via {help xtdcce2:xtdcce2} (static, Pesaran 2006){p_end}
{synopt :{opt pooled(varlist)}}variables to pool across panels (xtdcce2 engines){p_end}
{synopt :{opt recursive}}Chudik-Pesaran (2015) recursive bias correction (xtdcce2 engines){p_end}
{synopt :{opt jackknife}}jackknife bias correction (xtdcce2 engines){p_end}
{synopt :{opt lr_options(string)}}options passed to xtdcce2's lr_options() (advanced){p_end}
{synopt :{opt ec(name)}}name for the EC term variable; default {bf:ECT} (pmg/mg/dfe only){p_end}
{synopt :{opt replace}}overwrite previously generated {it:_pos}, {it:_neg}, {bf:ECT}{p_end}

{syntab:Cross-section augmentation (CCE / DCCE)}
{synopt :{opt cr_lags(#)}}number of lags of cross-sectional averages (CSA); default = floor(T{sup:1/3}) per Chudik & Pesaran (2015){p_end}
{synopt :{opt csavars(varlist)}}override default CSA target list (default: depvar + every LR substantive regressor, including {it:_pos}/{it:_neg}){p_end}
{synopt :{opt nocsa}}turn off CCE augmentation {hline 2} reduces to plain Panel NARDL{p_end}
{synopt :{opt keepcsa}}retain generated CSA variables after estimation{p_end}
{synopt :{opt showcsa}}print Table 4 with CSA loadings{p_end}

{syntab:Asymmetry diagnostics}
{synopt :{opt noasymtest}}suppress Table 5 (LR/SR Wald asymmetry tests){p_end}
{synopt :{opt asytable}}print Table 6 (asymmetry comparison: {&beta}{sup:+}/{&beta}{sup:-} and {&gamma}{sup:+}/{&gamma}{sup:-}){p_end}
{synopt :{opt panelcoef}}print Table 7 (per-panel {&phi}{sub:i} with half-life){p_end}
{synopt :{opt multip(#)}}horizon for cumulative dynamic multipliers (Table 8){p_end}
{synopt :{opt irfshock(#)}}horizon for impulse responses to {bf:+} and {bf:-} shocks (Table 9){p_end}
{synopt :{opt hausman}}MG vs PMG Hausman specification test{p_end}
{synopt :{opt nocdtest}}suppress Table 10 (Pesaran CD test on residuals){p_end}

{syntab:Estimation control}
{synopt :{opt full}}display per-panel coefficients from xtpmg{p_end}
{synopt :{opt level(#)}}confidence level; default 95{p_end}
{synopt :{opt nocons:tant}}suppress the constant in the cointegrating vector{p_end}
{synopt :{opt tech:nique(spec)}}maximisation technique passed to xtpmg{p_end}
{synopt :{opt difficult}}difficult-search starting values{p_end}
{synopt :{opt constraints(numlist)}}linear constraints passed to xtpmg{p_end}
{synopt :{opt cluster(clustvar)}}cluster-robust SE (DFE only){p_end}

{syntab:Output control}
{synopt :{opt graph}}generate publication-quality plots; see {help xtcsnardl_graph:graph help}{p_end}
{synopt :{opt notab:le}}suppress Tables 1-3{p_end}
{synoptline}

{p 4 6 2}
{cmd:by}, {cmd:rolling}, {cmd:statsby}, and {cmd:xi} are allowed; see {help prefix}.{p_end}
{p 4 6 2}
The data must be {help xtset:xtset} as panel data before invoking {cmd:xtcsnardl}.{p_end}


{title:Description}

{pstd}
{cmd:xtcsnardl} is a unified suite of {ul:nonlinear} panel estimators with cross-section
augmentation.  {bf:Every estimator in this package is the nonlinear (asymmetric)
extension of a canonical CCE/ARDL method.}  The asymmetric decomposition (Shin, Yu and
Greenwood-Nimmo 2014) is applied {ul:before} the chosen engine is called, so each of the
seven estimators delivered by {opt engine()} / {opt pmg|mg|dfe} is:

{p2col 5 32 33 2:Engine}Nonlinear extension of{p_end}
{p2col 5 32 33 2:{hline 32}}{hline 33}{p_end}
{p2col 5 32 33 2:{cmd:pmg / mg / dfe} (default)}Panel ARDL (Pesaran-Shin-Smith 1999){p_end}
{p2col 5 32 33 2:{opt engine(csardl)}}CS-ARDL (Chudik-Pesaran 2015){p_end}
{p2col 5 32 33 2:{opt engine(csdl)}}CS-DL (Chudik-Pesaran 2015){p_end}
{p2col 5 32 33 2:{opt engine(dcce)}}Dynamic CCE (Chudik-Pesaran 2015){p_end}
{p2col 5 32 33 2:{opt engine(cce)}}Static CCE (Pesaran 2006){p_end}

{pstd}
The package blends three complementary ingredients of the modern macro-panel toolkit:

{phang}
1. {bf:Asymmetric decomposition} (Shin, Yu and Greenwood-Nimmo 2014).  Each regressor flagged in
{opt asymmetric()} is replaced by its positive and negative cumulative partial sums
{p_end}

{p 12 12 2}
        x{sup:+}{sub:it} = {&Sigma}{sub:s{c <=}t} max({&Delta}x{sub:is}, 0),     x{sup:-}{sub:it} = {&Sigma}{sub:s{c <=}t} min({&Delta}x{sub:is}, 0).
{p_end}

{phang}
2. {bf:Cross-section augmentation} (Pesaran 2006; Chudik and Pesaran 2015).  The long-run
equation is augmented with cross-sectional averages z{c -}{sub:t} of the dependent variable
and {ul:every} regressor (including the asymmetric components), plus {opt cr_lags(#)} lags
of those averages.  This absorbs unobserved common factors and corrects for cross-section
dependence in both the long-run and short-run dynamics.
{p_end}

{phang}
3. {bf:Nonlinear CCE} (Kapetanios, Mitchell and Shin 2014; Hacioglu-Hoke and Kapetanios 2020).
Their key result {hline 2} the Pesaran rank condition becomes harder to satisfy when the
conditional mean is non-linear, but is restored once CSA of the nonlinear-transformed
regressors is added to the proxy set.  In CS-NARDL, the positive and negative partial sums
{ul:are} the nonlinear transforms; including their CSA (the default in {cmd:xtcsnardl}) is
therefore not an option but a requirement for consistency.
{p_end}

{pstd}
The resulting estimating equation, in error-correction form, is

{p 8 8 2}
{&Delta}y{sub:it} = {&phi}{sub:i}[y{sub:i,t-1} {c -} {&beta}{sup:+}x{sup:+}{sub:i,t-1} {c -} {&beta}{sup:-}x{sup:-}{sub:i,t-1}
 {c -} {&beta}{sub:c}c{sub:i,t-1} {c -} {&psi}{sub:0}z{c -}{sub:t-1} {c -} {&Sigma}{sub:k}{&psi}{sub:k}L{sup:k}z{c -}{sub:t-1}]{break}
+ {&Sigma}{sub:j} {&gamma}{sub:ij} {&Delta}y{sub:i,t-j}
+ {&Sigma}{sub:j} ({&omega}{sup:+}{sub:ij} {&Delta}x{sup:+}{sub:i,t-j} + {&omega}{sup:-}{sub:ij} {&Delta}x{sup:-}{sub:i,t-j})
+ {&Sigma}{sub:j} {&delta}{sub:ij} {&Delta}c{sub:i,t-j} + {&eta}{sub:i} {&Delta}z{c -}{sub:t} + {&epsilon}{sub:it}.
{p_end}

{pstd}
Estimation is delegated to {help xtpmg} (PMG/MG/DFE).  See {help xtcsnardl_methodology}
for the full derivation and the link between the ARDL ECM and CS-DL/CS-ARDL/DCCE forms.


{title:Output: tables produced}

{p2col 5 25 25 2: Table 1}Long-run cointegrating parameters with {&beta}{sup:+}/{&beta}{sup:-} pairs.{p_end}
{p2col 5 25 25 2: Table 2}Speed-of-adjustment {&phi}, half-life, convergence class.{p_end}
{p2col 5 25 25 2: Table 3}Short-run {&Delta}-coefficients (asymmetric pairs).{p_end}
{p2col 5 25 25 2: Table 4}CSA nuisance loadings ({opt showcsa}).{p_end}
{p2col 5 25 25 2: Table 5}Wald tests of long-run and short-run asymmetry.{p_end}
{p2col 5 25 25 2: Table 6}Asymmetry comparison ({opt asytable}).{p_end}
{p2col 5 25 25 2: Table 7}Per-panel {&phi}{sub:i} and half-lives ({opt panelcoef}).{p_end}
{p2col 5 25 25 2: Table 8}Cumulative dynamic multipliers ({opt multip}).{p_end}
{p2col 5 25 25 2: Table 9}Asymmetric impulse responses ({opt irfshock}).{p_end}
{p2col 5 25 25 2: Table 10}Pesaran (2004/2015) CD test on residuals.{p_end}


{title:Quick start}

{pstd}
EURO-4 carbon-emissions specification (Mehta & Derbeneva 2024){p_end}

{phang2}{cmd:. webuse pig, clear} {hline 2} replace with real panel data{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtcsnardl D.omega L.omega D.rho D.gamma D.pi D.psi D.theta, ///}{break}
{phang2}{cmd:    lr(L.omega rho gamma pi psi theta) asymmetric(rho gamma) ///}{break}
{phang2}{cmd:    pmg cr_lags(2) multip(15) irfshock(15) graph asytable panelcoef showcsa}{p_end}

{pstd}
This reproduces the methodological core of Mehta & Derbeneva (2024) {it:Int. J. Thermofluids}: it
decomposes the carbon-tax ({&rho}) and environmental-spending ({&gamma}) into positive and
negative partial sums, augments the cointegrating vector with the cross-sectional averages of
all six variables and two of their lags, and reports both long-run and short-run asymmetry
Wald tests plus cumulative dynamic multipliers and asymmetric IRFs.

{pstd}
See {help xtcsnardl_examples} for more worked examples (BRICS REC, Monte Carlo data, custom
CSA list, MG vs PMG Hausman).


{title:Options (detailed)}

{dlgtab:Estimator}

{phang}{opt pmg} requests the {it:pooled mean group} estimator of Pesaran, Shin and Smith (1999).
Long-run coefficients are constrained to be equal across panels; short-run dynamics and the
intercept are panel-specific.  Default.

{phang}{opt mg} requests the {it:mean group} estimator of Pesaran and Smith (1995).  All
coefficients are heterogeneous and the reported estimates are simple averages.

{phang}{opt dfe} requests {it:dynamic fixed effects}.  All slopes are pooled and panel-specific
fixed effects absorb unit heterogeneity.

{phang}{opt ec(name)} specifies the name of the error-correction coefficient.  Default {bf:ECT}.
The associated cointegrating equation in {cmd:xtpmg} output is labelled with this name.

{phang}{opt replace} overwrites any pre-existing {it:varname_pos}, {it:varname_neg} and {it:ECT}
variables generated by a previous {cmd:xtcsnardl} run.


{dlgtab:Cross-section augmentation}

{phang}{opt cr_lags(#)} controls the number of lags of the cross-sectional averages added to the
long-run equation.  The default {hline 2} {opt cr_lags(-1)}, internally remapped to
floor(T{sup:1/3}) per the Chudik and Pesaran (2015) optimality result {hline 2} is appropriate
for most panels.  Set {opt cr_lags(0)} to use contemporaneous CSA only.  Set {opt cr_lags(0)}
together with {opt nocsa} to revert to classical Panel NARDL.

{phang}{opt csavars(varlist)} overrides the default CSA target set.  By default {cmd:xtcsnardl}
takes CSA of the dependent variable {it:and} every substantive long-run regressor (including
the {it:_pos}/{it:_neg} components produced by {opt asymmetric()}).  Use this option only when
you have a theoretical reason to restrict the proxy set.

{phang}{opt nocsa} switches off cross-section augmentation completely.  The estimator then
reduces to the Panel NARDL of Shin, Yu and Greenwood-Nimmo (2014), without correction for
cross-section dependence.  Provided for diagnostic comparisons only {hline 2} the residual
CD test ({opt nocdtest} not set) will normally reject independence in this mode.

{phang}{opt keepcsa} retains the generated CSA variables in the dataset after estimation.  By
default they are dropped to keep the workspace clean; the {it:_pos}/{it:_neg} partial-sum
variables are always retained.

{phang}{opt showcsa} prints Table 4 (CSA nuisance loadings).  CSA coefficients are not of
substantive interest and are suppressed by default.


{dlgtab:Asymmetry diagnostics}

{phang}{opt asymmetric(varlist)} is {ul:required}.  Lists the variables to be subjected to
asymmetric decomposition.  Each variable will appear twice in the long-run equation, once as
its positive partial sum and once as its negative partial sum.  All variables in this list
{ul:must} appear in {opt lr()}; they may, but need not, appear in the short-run regressor list.

{phang}{opt noasymtest} suppresses Table 5.  The default Wald tests are H{sub:0}: {&beta}{sup:+}={&beta}{sup:-}
(long-run symmetry) and H{sub:0}: {&gamma}{sup:+}={&gamma}{sup:-} (short-run symmetry) for every
variable in {opt asymmetric()}.

{phang}{opt asytable} prints a compact side-by-side comparison of long-run and short-run
asymmetry coefficients (Table 6).

{phang}{opt panelcoef} prints per-panel {&phi}{sub:i} estimates with their standard errors,
half-lives, convergence flags and adjustment speeds (Table 7).

{phang}{opt multip(#)} computes the cumulative dynamic asymmetric multipliers
m{sup:+}(h) and m{sup:-}(h) for h=0,...,#, together with the asymmetry curve m{sup:+}(h){c -}m{sup:-}(h)
(Table 8).  See {help xtcsnardl_methodology##multipliers:methodology} for the recursion.

{phang}{opt irfshock(#)} computes asymmetric impulse responses {hline 2} the trajectory of y
following a {bf:+1} and a {bf:-1} shock (Table 9).

{phang}{opt hausman} estimates both MG and PMG specifications and performs the Hausman test of
long-run pooling.  Rejection means PMG is inconsistent and MG should be preferred.

{phang}{opt nocdtest} suppresses Table 10 (Pesaran 2004 CD test on residuals).  By default the
test runs after estimation and a warning is printed if residual CSD is detected, advising the
user to increase {opt cr_lags()} or extend {opt csavars()}.


{title:Stored results}

{pstd}{cmd:xtcsnardl} stores the following in {cmd:e()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(npanels)}}number of cross-sections{p_end}
{synopt:{cmd:e(avg_T)}}average number of time observations per panel{p_end}
{synopt:{cmd:e(cr_lags)}}CSA lags used (Chudik-Pesaran p_T){p_end}
{synopt:{cmd:e(n_csa_orig)}}number of base CSA variables{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtcsnardl}{p_end}
{synopt:{cmd:e(estimator)}}{cmd:cs_nardl_pmg}, {cmd:cs_nardl_mg}, or {cmd:cs_nardl_dfe}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(asymmetric)}}variables decomposed asymmetrically{p_end}
{synopt:{cmd:e(pos_vars)}}generated positive partial-sum variable names{p_end}
{synopt:{cmd:e(neg_vars)}}generated negative partial-sum variable names{p_end}
{synopt:{cmd:e(lr_x)}}substantive long-run regressors (after decomposition){p_end}
{synopt:{cmd:e(csa_vars)}}variables whose CSA was added as proxies{p_end}
{synopt:{cmd:e(sr_vars)}}short-run regressors used{p_end}
{synopt:{cmd:e(ivar)}}panel identifier{p_end}
{synopt:{cmd:e(tvar)}}time identifier{p_end}
{synopt:{cmd:e(ec_name)}}name of the error-correction equation{p_end}
{synopt:{cmd:e(model)}}{bf:PMG}, {bf:MG}, or {bf:DFE}{p_end}

{pstd}
Plus all matrices and scalars returned by {help xtpmg}; see {help xtcsnardl_postestimation}.


{title:References}

{phang}Chudik, A. and Pesaran, M.H. (2015).  Common Correlated Effects Estimation of
Heterogeneous Dynamic Panel Data Models with Weakly Exogenous Regressors.  {it:Journal of
Econometrics} {bf:188}: 393-420.

{phang}Hacioglu-Hoke, S. and Kapetanios, G. (2020).  Common correlated effect cross-sectional
dependence corrections for nonlinear conditional mean panel models.  {it:Journal of Applied
Econometrics} {bf:36}: 125-150.

{phang}Kapetanios, G., Mitchell, J. and Shin, Y. (2014).  A nonlinear panel data model of
cross-sectional dependence.  {it:Journal of Econometrics} {bf:179}: 134-157.

{phang}Mehta, D. and Derbeneva, V. (2024).  Impact of environmental fiscal reforms on carbon
emissions of EURO-4 countries: CS-NARDL approach.  {it:International Journal of Thermofluids}
{bf:21}: 100550.

{phang}Pesaran, M.H. (2004).  General diagnostic tests for cross section dependence in
panels.  Cambridge Working Papers in Economics 0435.

{phang}Pesaran, M.H. (2006).  Estimation and inference in large heterogeneous panels with a
multifactor error structure.  {it:Econometrica} {bf:74}: 967-1012.

{phang}Pesaran, M.H. (2015).  Testing weak cross-sectional dependence in large panels.
{it:Econometric Reviews} {bf:34}: 1089-1117.

{phang}Pesaran, M.H., Shin, Y. and Smith, R.P. (1999).  Pooled mean group estimation of dynamic
heterogeneous panels.  {it:Journal of the American Statistical Association} {bf:94}: 621-634.

{phang}Shin, Y., Yu, B. and Greenwood-Nimmo, M. (2014).  Modelling Asymmetric Cointegration and
Dynamic Multipliers in a Nonlinear ARDL Framework.  In {it:Festschrift in Honor of Peter Schmidt}.
Springer, 281-314.

{phang}Wang, L., Huang, Y., Ghafoor, A., Hafeez, M. and Salahodjaev, R. (2022).  Asymmetric
macroeconomic determinants of renewable energy consumption in BRICS.  {it:Environmental Science
and Pollution Research} {bf:30}: 9841-9851.


{title:Author and version}

{pstd}
{cmd:xtcsnardl} v1.0.0, 28 May 2026.{p_end}

{pstd}
Author:  {bf:Dr Merwan Roudane}{break}
Contact: {bf:merwanroudane920@gmail.com}{p_end}

{pstd}
Built on {help xtpmg} v2.0.1+ and {help pnardl} v1.1.0+, with optional {help xtdcce2}
(Ditzen) for engines csardl / csdl / dcce / cce.


{title:Also see}

{psee}
Online: {help xtcsnardl_methodology},  {help xtcsnardl_examples},  {help xtcsnardl_postestimation},  {help xtcsnardl_graph}{p_end}
{psee}
Related: {help xtpmg},  {help pnardl},  {help xtdcce2},  {help xtcspqardl},  {help xtcd2},  {help xtcse2}{p_end}
