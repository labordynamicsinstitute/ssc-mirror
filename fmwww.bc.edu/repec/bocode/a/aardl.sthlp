{smcl}
{* *! version 1.2.0  04mar2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] ardl" "help ardl"}{...}
{viewerjumpto "Syntax" "aardl##syntax"}{...}
{viewerjumpto "Description" "aardl##description"}{...}
{viewerjumpto "Methodology" "aardl##methodology"}{...}
{viewerjumpto "Options" "aardl##options"}{...}
{viewerjumpto "Output tables" "aardl##tables"}{...}
{viewerjumpto "Stored results" "aardl##results"}{...}
{viewerjumpto "Examples" "aardl##examples"}{...}
{viewerjumpto "References" "aardl##references"}{...}
{viewerjumpto "Author" "aardl##author"}{...}
{viewerjumpto "Post-estimation" "aardl##postestimation"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:aardl} {hline 2}}Augmented Autoregressive Distributed Lag Model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:aardl}
{depvar}
{indepvars}
{ifin}{cmd:,}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt:{opt type(string)}}model type: {bf:aardl} (default), {bf:baardl}, {bf:faardl}, {bf:fbaardl}, {bf:nardl}, {bf:fanardl}, {bf:banardl}, or {bf:fbanardl}{p_end}
{synopt:{opt dec:ompose(varlist)}}NARDL: variables to decompose into positive/negative partial sums{p_end}
{synopt:{opt maxl:ag(#)}}maximum lag order; default {bf:4}{p_end}
{synopt:{opt maxk(#)}}maximum Fourier frequency; default {bf:3}{p_end}
{synopt:{opt ic(string)}}information criterion: {bf:aic} or {bf:bic} (default){p_end}
{synopt:{opt case(#)}}PSS case: {bf:1}, {bf:2}, {bf:3} (default), {bf:4}, or {bf:5}{p_end}

{syntab:Bootstrap}
{synopt:{opt reps(#)}}bootstrap replications; default {bf:999}{p_end}
{synopt:{opt boot:strap(string)}}bootstrap method: {bf:bvz} (default) or {bf:mcnown}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synopt:{opt hor:izon(#)}}multiplier/persistence horizon; default {bf:20}{p_end}
{synopt:{opt nodiag}}suppress diagnostic tests{p_end}
{synopt:{opt nodyn:mult}}suppress dynamic multipliers{p_end}
{synopt:{opt noadv:anced}}suppress advanced analyses{p_end}
{synopt:{opt not:able}}suppress regression table{p_end}
{synopt:{opt noh:eader}}suppress header{p_end}
{synopt:{opt nog:raph}}suppress graphs{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{bf:Post-estimation:}
{p_end}

{p 8 17 2}
{cmd:aardl_advanced}
[{cmd:,} {opt hor:izon(#)} {opt nog:raph}]

{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:aardl}; see {helpb tsset}.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:aardl} estimates an {bf:Augmented Autoregressive Distributed Lag} (A-ARDL)
model with cointegration testing following the 3-test framework of
Sam, McNown & Goh (2019). It provides eight model types:
{p_end}

{p2colset 10 28 30 2}{...}
{p2col:{bf:aardl}}Augmented ARDL (asymptotic){p_end}
{p2col:{bf:baardl}}Bootstrap Augmented ARDL{p_end}
{p2col:{bf:faardl}}Fourier Augmented ARDL{p_end}
{p2col:{bf:fbaardl}}Fourier Bootstrap Augmented ARDL{p_end}
{p2col:{bf:nardl}}Augmented NARDL (asymptotic){p_end}
{p2col:{bf:fanardl}}Fourier Augmented NARDL{p_end}
{p2col:{bf:banardl}}Bootstrap Augmented NARDL{p_end}
{p2col:{bf:fbanardl}}Fourier Bootstrap Augmented NARDL{p_end}
{p2colreset}{...}

{pstd}
Key features include:
{p_end}

{phang}
{bf:1. 3-test cointegration framework} (Sam, McNown & Goh, 2019): Tests
joint significance of level variables (F_overall), the error correction
term (t_dependent), and independent level variables (F_independent) to
distinguish cointegration from degenerate cases.
{p_end}

{phang}
{bf:2. Fourier approximation:} Low-frequency trigonometric terms capture
smooth structural breaks of unknown form, number, and location
(Enders & Lee, 2012; Yilanci et al., 2020).
{p_end}

{phang}
{bf:3. Bootstrap critical values:} Two bootstrap procedures for finite-sample
inference:
{p_end}

{phang2}
{bf:McNown, Sam & Goh (2018):} Unconditional bootstrap with single
restricted null and residual resampling.
{p_end}

{phang2}
{bf:Bertelli, Vacca & Zoia (2022):} Conditional bootstrap with three
separate nulls and marginal VECM for independent variables.
{p_end}

{phang}
{bf:4. NARDL:} Nonlinear ARDL via partial sum decomposition
(Shin, Yu & Greenwood-Nimmo, 2014).
{p_end}

{phang}
{bf:5. Kripfganz & Schneider (2020) critical values:} For asymptotic
models, response surface finite-sample critical values and approximate
p-values via the {cmd:ardlbounds} program.
{p_end}


{marker methodology}{...}
{title:Methodology}

{pstd}
{ul:The A-ARDL Model (ECM form)}
{p_end}

{pstd}
The ARDL(p, q1, ..., qk) error correction model is:
{p_end}

{p 8 8 2}
D.y_t = c + gamma1*sin(2*pi*k*t/T) + gamma2*cos(2*pi*k*t/T)
{p_end}
{p 12 12 2}
+ alpha*L.y_t + SUM beta_i*L.x_it
{p_end}
{p 12 12 2}
+ SUM(j=1..p) phi_j*L(j).D.y_t + SUM(i,j) theta_ij*L(j).D.x_it + e_t
{p_end}

{pstd}
{ul:Three Cointegration Tests (Sam et al. 2019)}
{p_end}

{phang2}
{bf:F_overall (F_ov):} Joint test: alpha = beta_1 = ... = beta_k = 0.
All lagged level variables.
{p_end}

{phang2}
{bf:t_dependent (t_DV):} t-test on L.depvar: alpha = 0.
{p_end}

{phang2}
{bf:F_independent (F_ind):} Joint test: beta_1 = ... = beta_k = 0.
Detects degenerate cases.
{p_end}

{pstd}
Cointegration is concluded when all three tests are significant.
{p_end}

{pstd}
{ul:NARDL Decomposition}
{p_end}

{pstd}
For variables specified in {opt decompose()}, positive and negative partial
sums are created: x_pos_t = SUM max(D.x_j, 0) and x_neg_t = SUM min(D.x_j, 0).
Wald tests for long-run and short-run asymmetry are reported.
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}
{opt type(string)} sets the model type:
{p_end}

{phang2}
{cmd:type(aardl)} (default): Augmented ARDL with PSS bounds test and
Kripfganz & Schneider (2020) critical values.
{p_end}

{phang2}
{cmd:type(baardl)}: Bootstrap Augmented ARDL.
{p_end}

{phang2}
{cmd:type(faardl)}: Fourier Augmented ARDL with PSS bounds test.
{p_end}

{phang2}
{cmd:type(fbaardl)}: Fourier Bootstrap Augmented ARDL.
{p_end}

{phang2}
{cmd:type(nardl)}: Augmented NARDL with asymptotic inference (requires {opt decompose()}).
{p_end}

{phang2}
{cmd:type(fanardl)}: Fourier Augmented NARDL (requires {opt decompose()}).
{p_end}

{phang2}
{cmd:type(banardl)}: Bootstrap Augmented NARDL (requires {opt decompose()}).
{p_end}

{phang2}
{cmd:type(fbanardl)}: Fourier Bootstrap Augmented NARDL (requires {opt decompose()}).
{p_end}

{phang}
{opt decompose(varlist)} specifies which independent variables to decompose
into positive and negative partial sums for NARDL analysis.
{p_end}

{phang}
{opt maxlag(#)} maximum lag order for ARDL grid search. Default is 4.
{p_end}

{phang}
{opt maxk(#)} maximum Fourier frequency. Default is 3.
The search grid uses increments of 0.1 (k = 0.1, 0.2, ..., maxk).
{p_end}

{phang}
{opt ic(string)} information criterion for lag selection: {cmd:aic} or {cmd:bic}.
Default is {cmd:bic}.
{p_end}

{phang}
{opt case(#)} PSS case number (1-5). Default is 3 (unrestricted intercept,
no deterministic trend).
{p_end}

{dlgtab:Bootstrap}

{phang}
{opt reps(#)} number of bootstrap replications. Default 999.
Recommendations: 99 for exploratory work; 999 for standard analysis;
1999-4999 for publication.
{p_end}

{phang}
{opt bootstrap(string)} bootstrap method: {cmd:bvz} (Bertelli et al. 2022,
default) or {cmd:mcnown} (McNown et al. 2018).
{p_end}

{dlgtab:Reporting}

{phang}
{opt level(#)} confidence level for coefficient intervals.
Default is {cmd:c(level)} (usually 95).
{p_end}

{phang}
{opt horizon(#)} maximum horizon for dynamic multipliers and persistence
profile. Default is 20.
{p_end}

{phang}
{opt nodiag} suppresses diagnostic tests (Table 4).
{p_end}

{phang}
{opt nodynmult} suppresses dynamic multipliers (Table 5).
{p_end}

{phang}
{opt noadvanced} suppresses advanced analyses (Table 6).
{p_end}

{phang}
{opt notable} suppresses the ARDL regression table (Table 2).
{p_end}


{marker tables}{...}
{title:Output tables}

{pstd}
{cmd:aardl} produces up to 6 publication-quality tables:
{p_end}

{phang2}Table 1: Model Selection Summary (ARDL spec, k*, N, R2, IC){p_end}
{phang2}Table 2: ARDL(p,q1,...,qk) regression, EC representation{p_end}
{phang3}ADJ {hline 1} Speed of Adjustment (L.y){p_end}
{phang3}LR {hline 1} Long-Run Coefficients (-beta/alpha, delta method){p_end}
{phang3}SR {hline 1} Short-Run Coefficients (D.x, LD.x, ...){p_end}
{phang2}Table 3: Cointegration Test Results (F_ov, t_DV, F_ind){p_end}
{phang2}Table 4: Diagnostic Tests (JB, BG-LM, ARCH, RESET){p_end}
{phang2}Table 5: Dynamic Multipliers / Asymmetric Dynamic Multipliers{p_end}
{phang2}Table 6: Half-Life, Persistence Profile, Equilibrium Relationship{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:aardl} stores the following in {cmd:e()}:
{p_end}

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(p)}}selected dependent variable lag p{p_end}
{synopt:{cmd:e(kstar)}}selected Fourier frequency k* (0 if no Fourier){p_end}
{synopt:{cmd:e(aic)}}AIC{p_end}
{synopt:{cmd:e(bic)}}BIC{p_end}
{synopt:{cmd:e(ll)}}log-likelihood{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(F)}}overall model F-statistic{p_end}
{synopt:{cmd:e(F_pss)}}F_overall cointegration test statistic{p_end}
{synopt:{cmd:e(t_pss)}}t_dependent cointegration test statistic{p_end}
{synopt:{cmd:e(F_ind)}}F_independent cointegration test statistic{p_end}
{synopt:{cmd:e(case)}}PSS case number{p_end}
{synopt:{cmd:e(total_models)}}number of models evaluated in grid search{p_end}
{synopt:{cmd:e(q_varname)}}selected lag q for each independent variable{p_end}
{synopt:{cmd:e(ecm_coef)}}error correction (speed of adjustment) coefficient{p_end}
{synopt:{cmd:e(horizon)}}multiplier/persistence horizon used{p_end}

{p2col 5 28 32 2: Bootstrap only}{p_end}
{synopt:{cmd:e(Fov_bp)}}bootstrap p-value (F_overall){p_end}
{synopt:{cmd:e(tDV_bp)}}bootstrap p-value (t_dependent){p_end}
{synopt:{cmd:e(Find_bp)}}bootstrap p-value (F_independent){p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}"aardl"{p_end}
{synopt:{cmd:e(cmdline)}}full command line{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}independent variable(s){p_end}
{synopt:{cmd:e(type)}}model type{p_end}
{synopt:{cmd:e(ic)}}information criterion used{p_end}
{synopt:{cmd:e(all_indepvars)}}all independent variables (including decomposed){p_end}
{synopt:{cmd:e(model)}}"ec"{p_end}
{synopt:{cmd:e(coint_status)}}"cointegrated", "not_cointegrated", or "degenerate"{p_end}

{p2col 5 28 32 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector (ADJ/LR/SR equations){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
The following examples use the Lutkepohl (1993) dataset, a classic time-series
dataset containing West German macroeconomic quarterly data (1960q1-1982q4).
{p_end}

{pstd}{bf:Setup: Load sample data}{p_end}
{phang}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang}{cmd:. tsset}{p_end}

{pstd}
The dataset contains variables {cmd:ln_inv} (log investment), {cmd:ln_inc}
(log income), and {cmd:ln_consump} (log consumption). We test for
cointegration among these macroeconomic variables.
{p_end}

{pstd}{bf:Example 1: Augmented ARDL (asymptotic)}{p_end}
{pstd}Basic A-ARDL with asymptotic PSS bounds test and AIC lag selection:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(aardl) maxlag(4) ic(aic) case(3)}{p_end}

{pstd}{bf:Example 2: Bootstrap Augmented ARDL (BVZ method)}{p_end}
{pstd}Bootstrap critical values using the Bertelli, Vacca & Zoia (2022) method:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(baardl) maxlag(4) reps(999) bootstrap(bvz)}{p_end}

{pstd}{bf:Example 3: Fourier Augmented ARDL}{p_end}
{pstd}Fourier terms capture structural breaks; k* selected by minimum SSR:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(faardl) maxlag(4) maxk(3) ic(aic)}{p_end}

{pstd}{bf:Example 4: Fourier Bootstrap Augmented ARDL}{p_end}
{pstd}Combines Fourier approximation with bootstrap inference:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(fbaardl) maxlag(3) maxk(3) reps(999)}{p_end}

{pstd}{bf:Example 5: Augmented NARDL (asymptotic)}{p_end}
{pstd}Asymptotic NARDL with PSS bounds tests and Kripfganz & Schneider critical values:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(nardl) decompose(ln_consump) maxlag(4) ic(aic) case(3)}{p_end}

{pstd}{bf:Example 6: Fourier Augmented NARDL}{p_end}
{pstd}Fourier terms + NARDL with asymptotic inference:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(fanardl) decompose(ln_consump) maxlag(3) maxk(3) ic(aic)}{p_end}

{pstd}{bf:Example 7: Bootstrap Augmented NARDL}{p_end}
{pstd}Decompose {cmd:ln_consump} into positive/negative partial sums to test
for asymmetric effects:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(banardl) decompose(ln_consump) maxlag(3) reps(999)}{p_end}

{pstd}{bf:Example 8: Fourier Bootstrap Augmented NARDL (full model)}{p_end}
{pstd}Combines Fourier + Bootstrap + NARDL:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(fbanardl) decompose(ln_consump) maxlag(3) maxk(3) reps(999)}{p_end}

{pstd}{bf:Example 9: McNown bootstrap method}{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(baardl) maxlag(4) reps(999) bootstrap(mcnown)}{p_end}

{pstd}{bf:Example 10: Minimal output}{p_end}
{pstd}Suppress diagnostics, multipliers, and advanced analysis:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(aardl) maxlag(4) nodiag nodynmult noadvanced}{p_end}

{pstd}{bf:Example 11: Access stored results}{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(baardl) reps(999)}{p_end}
{phang}{cmd:. di e(F_pss)}{space 8}// F_overall statistic{p_end}
{phang}{cmd:. di e(t_pss)}{space 8}// t_dependent statistic{p_end}
{phang}{cmd:. di e(F_ind)}{space 8}// F_independent statistic{p_end}
{phang}{cmd:. di e(coint_status)}{space 1}// Cointegration conclusion{p_end}
{phang}{cmd:. ereturn list}{space 5}// All stored results{p_end}

{pstd}{bf:Example 12: Post-estimation advanced analysis}{p_end}
{pstd}Run {cmd:aardl} with {cmd:noadvanced}, then use {cmd:aardl_advanced} separately:{p_end}
{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(aardl) maxlag(4) ic(aic) case(3) noadvanced}{p_end}
{phang}{cmd:. aardl_advanced}{p_end}
{pstd}Override the horizon:{p_end}
{phang}{cmd:. aardl_advanced, horizon(30)}{p_end}


{marker references}{...}
{title:References}

{phang}
Bertelli, S., Vacca, G. & Zoia, M. (2022). Bootstrap cointegration tests in
ARDL models. {it:Economic Modelling}, 116, 105987.
{p_end}

{phang}
Enders, W. & Lee, J. (2012). The flexible Fourier form and Dickey-Fuller type
unit root tests. {it:Economics Letters}, 117(1), 196-199.
{p_end}

{phang}
Kripfganz, S. & Schneider, D.C. (2020). Response surface regressions for
critical value bounds and approximate p-values in equilibrium correction models.
{it:Oxford Bulletin of Economics and Statistics}, 82, 1456-1481.
{p_end}

{phang}
Lutkepohl, H. (1993). {it:Introduction to Multiple Time Series Analysis}.
2nd ed. Berlin: Springer-Verlag.
{p_end}

{phang}
McNown, R., Sam, C.Y. & Goh, S.K. (2018). Bootstrapping the autoregressive
distributed lag test for cointegration. {it:Applied Economics}, 50(13), 1509-1521.
{p_end}

{phang}
Pesaran, M.H., Shin, Y. & Smith, R.J. (2001). Bounds testing approaches to
the analysis of level relationships. {it:Journal of Applied Econometrics},
16(3), 289-326.
{p_end}

{phang}
Sam, C.Y., McNown, R. & Goh, S.K. (2019). An augmented autoregressive
distributed lag bounds test for cointegration. {it:Economic Modelling}, 80, 130-141.
{p_end}

{phang}
Shin, Y., Yu, B. & Greenwood-Nimmo, M. (2014). Modelling asymmetric
cointegration and dynamic multipliers in a nonlinear ARDL framework.
In R. Sickles & W. Horrace (Eds.), {it:Festschrift in Honor of Peter Schmidt}.
New York: Springer.
{p_end}

{phang}
Yilanci, V., Bozoklu, S. & Gorus, M.S. (2020). Are BRICS countries pollution
havens? Evidence from a bootstrap ARDL bounds testing approach with a Fourier
function. {it:Sustainable Cities and Society}, 55, 102035.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}


{marker postestimation}{...}
{title:Post-estimation}

{pstd}
{cmd:aardl_advanced} runs the advanced analysis as a separate post-estimation
command after {cmd:aardl}. It includes dynamic multipliers, half-life analysis,
persistence profile, Fourier significance test, and long-run equilibrium.
{p_end}

{pstd}
{ul:Syntax}
{p_end}

{p 8 17 2}
{cmd:aardl_advanced}
[{cmd:,} {opt hor:izon(#)} {opt nog:raph}]
{p_end}

{pstd}
{ul:Options}
{p_end}

{phang}
{opt horizon(#)} overrides the horizon from the original {cmd:aardl} estimation.
Default uses the value from the prior estimation (typically 20).
{p_end}

{phang}
{opt nograph} suppresses all graphs (dynamic multipliers, persistence profile).
{p_end}

{pstd}
{ul:Description}
{p_end}

{pstd}
The advanced analysis includes:
{p_end}

{phang2}{bf:Dynamic Multipliers:} For linear ARDL models, displays impact and
cumulative dynamic multipliers for each independent variable. For NARDL models,
displays asymmetric dynamic multipliers (positive and negative paths) following
Shin, Yu & Greenwood-Nimmo (2014).{p_end}

{phang2}{bf:Half-Life Analysis:} Computes the half-life of shocks based on the
ECM coefficient: t_half = -ln(2) / ln(1 + alpha).{p_end}

{phang2}{bf:Persistence Profile:} Shows how shocks dissipate over the specified
horizon, with persistence = (1 + alpha)^h.{p_end}

{phang2}{bf:Fourier Significance Test:} For Fourier models (faardl, fbaardl,
fanardl, fbanardl), reports the joint Wald F-test for the sine and cosine terms
with p-value.{p_end}

{phang2}{bf:Long-Run Equilibrium:} Displays the long-run equilibrium relationship
derived from the estimated coefficients.{p_end}

{pstd}
{ul:Usage}
{p_end}

{pstd}
The advanced analysis runs automatically when cointegration is found (unless
suppressed with {opt noadvanced}). Use {cmd:aardl_advanced} to:
{p_end}

{phang2}1. Re-run the analysis with a different horizon{p_end}
{phang2}2. Run it after suppressing it with {opt noadvanced}{p_end}
{phang2}3. Re-display the results without re-running the full estimation{p_end}

{pstd}
{ul:Example}
{p_end}

{phang}{cmd:. aardl ln_inv ln_inc ln_consump, type(aardl) maxlag(4) noadvanced}{p_end}
{phang}{cmd:. aardl_advanced}{p_end}
{phang}{cmd:. aardl_advanced, horizon(30) nograph}{p_end}
