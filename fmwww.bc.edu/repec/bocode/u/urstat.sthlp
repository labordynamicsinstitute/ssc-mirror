{smcl}
{* *! version 1.3.0  11mar2026}{...}
{viewerjumpto "Syntax" "urstat##syntax"}{...}
{viewerjumpto "Description" "urstat##description"}{...}
{viewerjumpto "Options" "urstat##options"}{...}
{viewerjumpto "Tables" "urstat##tables"}{...}
{viewerjumpto "Interpretation" "urstat##interpretation"}{...}
{viewerjumpto "Graphs" "urstat##graphs"}{...}
{viewerjumpto "Requirements" "urstat##requirements"}{...}
{viewerjumpto "Examples" "urstat##examples"}{...}
{viewerjumpto "References" "urstat##references"}{...}
{viewerjumpto "Author" "urstat##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:urstat} {hline 2}}Comprehensive Unified Unit Root & Stationarity Testing{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:urstat}
{varlist}
{ifin}
[{cmd:,}
{it:options}]

{pstd}
{it:varlist} must contain time-series variables. Data must be {cmd:tsset} before
running {cmd:urstat}. Multiple variables are tested simultaneously and results
are displayed in aligned, publication-ready tables.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Test Selection}
{synopt:{opt test(testlist)}}tests to run; default is {cmd:ALL}; individual tests: 
{cmd:ADF PP KPSS ZA CLEMAO1 CLEMAO2 CLEMIO1 CLEMIO2 ERS BSRW KM}{p_end}
{synopt:{opt none}}include "no constant, no trend" (None) specification column in Table 1{p_end}
{synopt:{opt stra:tegy}}show Elder-Kennedy decision summary (Tables 5 & 6){p_end}

{syntab:ADF / PP / ERS Options}
{synopt:{opt max:lag(#)}}maximum lag order for ADF information-criterion lag selection; default is {cmd:12}{p_end}
{synopt:{opt crit(string)}}information criterion for lag selection: {cmd:BIC} (default), {cmd:AIC}, or {cmd:SIC} (alias for BIC){p_end}
{synopt:{opt pplag(#)}}Phillips-Perron Newey-West bandwidth (truncation lag); default is {cmd:4}{p_end}
{synopt:{opt ersmethod(string)}}ERS/DF-GLS lag selection method: {cmd:SIC} (default), {cmd:AIC}, {cmd:FIX}, {cmd:GTS05}, {cmd:GTS10}{p_end}

{syntab:Structural Break Options}
{synopt:{opt ztrim(#)}}Zivot-Andrews trimming proportion (fraction of sample excluded from each end); default is {cmd:0.15}{p_end}
{synopt:{opt clemtrim(#)}}Clemente-Montanes-Reyes trimming fraction; default is {cmd:0.05}{p_end}
{synopt:{opt clemmaxlag(#)}}Clemente maximum lag order; default is {cmd:12}{p_end}

{syntab:Bootstrap Options}
{synopt:{opt bsreps(#)}}number of bootstrap replications for {cmd:bsrwalkdrift}; default is {cmd:500}. Higher values increase accuracy but slow computation{p_end}

{syntab:KM Test Options}
{synopt:{opt kmlags(#)}}AR lags for Kobayashi-McAleer test; default is {cmd:0}{p_end}
{synopt:{opt nodr:ift}}use U1/U2 test statistics (no drift) instead of V1/V2 (with drift). Use when the series is believed to have no drift component{p_end}

{syntab:Display Options}
{synopt:{opt nostar:s}}suppress significance stars (***, **, *) from all tables{p_end}
{synopt:{opt level(#)}}significance level for confidence intervals; default is {cmd:95}{p_end}
{synopt:{opt title(string)}}custom title for Table 1 header{p_end}

{syntab:Graph Options}
{synopt:{opt graph}}produce and export PNG visualizations for each variable (time series panels, ACF/PACF correlograms, structural break plots, integration order bar chart){p_end}
{synopt:{opt graphdir(string)}}output directory for PNG files; default is {cmd:urstat_graphs}. Directory is created if it does not exist{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:urstat} performs comprehensive unit root and stationarity testing on one or
more time series variables simultaneously. It produces up to six
publication-quality tables and optional high-resolution PNG graphs, consolidating 
the most widely used tests into a single command.

{pstd}
All tests are applied at {bf:Level}, {bf:First Difference}, and {bf:Second Difference} 
to determine the integration order of each variable.

{pstd}
The following tests are supported:

{p2colset 5 28 30 2}{...}
{p2col:{bf:Test}}{bf:Null Hypothesis}{p_end}
{p2line}
{p2col:ADF}Augmented Dickey-Fuller: H0 = unit root (non-stationary){p_end}
{p2col:PP}Phillips-Perron: H0 = unit root (non-stationary){p_end}
{p2col:KPSS}Kwiatkowski et al.: H0 = stationarity (opposite null!){p_end}
{p2col:ZA}Zivot-Andrews: H0 = unit root with structural break{p_end}
{p2col:CLEMAO1/AO2}Clemente AO: H0 = unit root with 1 or 2 additive outlier breaks{p_end}
{p2col:CLEMIO1/IO2}Clemente IO: H0 = unit root with 1 or 2 innovational outlier breaks{p_end}
{p2col:ERS/DF-GLS}Elliott-Rothenberg-Stock: H0 = unit root (more powerful than ADF){p_end}
{p2col:BSRW}Bootstrap Random Walk: H0 = random walk with drift{p_end}
{p2col:KM}Kobayashi-McAleer: tests linear vs logarithmic transformation{p_end}
{p2colreset}{...}

{pstd}
{bf:Important:} ADF, PP, ERS, ZA, Clemente, and BSRW test the null of a unit root 
(non-stationarity). KPSS tests the {it:opposite} null: stationarity. This means:

{phang2}
{c -} ADF/PP/ERS/ZA/BSRW: {bf:Reject} H0 => series is {bf:stationary}{p_end}
{phang2}
{c -} KPSS: {bf:Reject} H0 => series is {bf:non-stationary} (has unit root){p_end}

{pstd}
Using both types together provides confirmatory evidence: if ADF rejects (stationary) 
and KPSS fails to reject (stationary), you have strong evidence of stationarity.


{marker tables}{...}
{title:Output Tables}

{dlgtab:Table 1. Standard Unit Root Tests (ADF / PP / KPSS)}

{pstd}
Shows test statistics for each variable across three blocks: {bf:Level}, 
{bf:1st Difference}, and {bf:2nd Difference}. Within each block, columns show 
results under different deterministic specifications:

{phang2}{bf:Const} — constant only (intercept){p_end}
{phang2}{bf:Const+Trend} — constant plus linear time trend{p_end}
{phang2}{bf:None} — no deterministic terms (only shown with {opt none} option){p_end}

{pstd}
{bf:Panel A (ADF):} Test statistics with p-values (MacKinnon, 1996) in parentheses. 
Lags selected automatically via BIC or AIC.

{pstd}
{bf:Panel B (PP):} Phillips-Perron statistics with p-values. Uses Newey-West 
bandwidth set by {opt pplag()}.

{pstd}
{bf:Panel C (KPSS):} KPSS statistics compared to asymptotic critical values 
(no p-values available). Stars indicate rejection of the stationarity null.

{pstd}
{bf:KPSS critical values (5% level):} Constant = 0.463; Constant+Trend = 0.146.

{dlgtab:Table 2. Structural Break Tests (ZA / Clemente)}

{pstd}
Shows structural break test statistics with estimated break dates in brackets 
for {bf:Level}, {bf:1st Difference}, and {bf:2nd Difference}. Three rows per variable 
(L., d., d2.).

{pstd}
{bf:ZA columns:} Zivot-Andrews test under two models:{p_end}
{phang2}ZA(Intercept) — Model A: allows break in intercept only{p_end}
{phang2}ZA(Both) — Model C: allows break in both intercept and trend{p_end}

{pstd}
{bf:Clemente columns:} Four variants:{p_end}
{phang2}ClemAO1/AO2 — Additive Outlier model with 1 or 2 breaks{p_end}
{phang2}ClemIO1/IO2 — Innovational Outlier model with 1 or 2 breaks{p_end}

{pstd}
{bf:ZA critical values (5%):} Intercept(Model A) = -4.80; Both(Model C) = -5.08.{p_end}
{pstd}
{bf:Clemente critical values (5%):} AO1 = -3.56; IO1 = -4.27; AO2/IO2 = -5.49.

{pstd}
{bf:Interpretation:} If ZA rejects at level, the apparent unit root in ADF may be 
due to a structural break rather than genuine non-stationarity. The series may 
actually be {it:stationary around a broken trend}.

{dlgtab:Table 3. Advanced Tests (ERS / Bootstrap)}

{pstd}
{bf:ERS/DF-GLS:} Six columns organized in three blocks (Level | 1st Diff | 2nd Diff), 
each with Const (C) and Const+Trend (C+T) specifications. The DF-GLS test is 
generally more powerful than ADF against near-unit-root alternatives.

{pstd}
{bf:Bootstrap RW:} Three columns (Level | 1st Diff | 2nd Diff). The bootstrap unit 
root test of Park (2003) is nonparametric and robust to non-normal errors.

{dlgtab:Table 4. Kobayashi-McAleer Test}

{pstd}
Tests whether a series should be modeled in levels (linear) or in logarithms. 
Only applies to {bf:strictly positive} variables. Variables with zero or negative 
values are automatically skipped.

{pstd}
{bf:Decision rule:} Reject H0:Linear + Fail to reject H0:Log => use LOGS.
Reject H0:Log + Fail to reject H0:Linear => use LEVELS.

{dlgtab:Table 5. Integration Order & Decision (Elder-Kennedy)}

{pstd}
Implements the Elder & Kennedy (2001) three-step testing procedure with additional
confirmatory evidence from ERS and Zivot-Andrews tests.

{pstd}
{bf:Columns:} ADF(L.ct), ADF(d.c), ADF(d2.c), PP(L.ct), KPSS(L.c), ERS(L.c), 
ERS(d.c), ZA(L), Trend, Order, Process.

{pstd}
{bf:Elder-Kennedy Decision Steps:}

{phang2}
{bf:Step 1.} Test ADF with constant+trend at level. If rejected AND trend is 
significant => {bf:Trend Stationary (TS)}. Treatment: detrend the series.{p_end}

{phang2}
{bf:Step 2.} If step 1 fails, test ADF with constant on 1st difference. If 
rejected => {bf:I(1) Difference Stationary (DS)}. Treatment: first-difference.{p_end}

{phang2}
{bf:Step 3.} If step 2 fails, test ADF with constant on 2nd difference. If 
rejected => {bf:I(2) DS}. Treatment: difference twice.{p_end}

{phang2}
{bf:Step 4.} If all steps fail => {bf:I(>2)}. The series is non-stationary at 
all tested orders. Consider fractional integration or additional differencing.{p_end}

{dlgtab:Table 6. Comprehensive Integration Order Summary}

{pstd}
Shows the integration order decision from {bf:each test independently}:

{p2colset 8 22 24 2}{...}
{p2col:{bf:Column}}{bf:Description}{p_end}
{p2line}
{p2col:ADF}Integration order from ADF test (Level->D->D2){p_end}
{p2col:PP}Integration order from PP test (Level->D->D2){p_end}
{p2col:KPSS}Integration order from KPSS test (reversed null){p_end}
{p2col:ERS}Integration order from ERS/DF-GLS test{p_end}
{p2col:ZA}Integration order from Zivot-Andrews test{p_end}
{p2col:Consensus}Majority vote across all available tests (count/total){p_end}
{p2col:Process}Recommended treatment for the series{p_end}
{p2colreset}{...}

{pstd}
{bf:Possible outcomes per test:}

{phang2}{bf:TS} = Trend Stationary. Series is stationary around a deterministic trend. 
{bf:Treatment:} detrend (regress on time trend and use residuals).{p_end}

{phang2}{bf:I(0)} = Stationary. Series is stationary in levels with no trend. 
{bf:Treatment:} use directly, no transformation needed.{p_end}

{phang2}{bf:I(1)} = Integrated of order 1. Series has one unit root. 
{bf:Treatment:} take first differences (D.variable).{p_end}

{phang2}{bf:I(2)} = Integrated of order 2. Series has two unit roots. 
{bf:Treatment:} take second differences (D2.variable).{p_end}

{phang2}{bf:I(>2)} = Non-stationary at any tested order. No amount of differencing 
(up to 2) achieves stationarity. 
{bf:Treatment:} consider fractional integration, structural breaks, or 
nonlinear models. This may indicate a misspecified model or explosive behavior.{p_end}

{pstd}
{bf:Color coding in Stata output:}

{phang2}Green (result text) = TS or I(0) — stationary{p_end}
{phang2}Default text = I(1) — common for economic series{p_end}
{phang2}Red (error text) = I(2) or I(>2) — requires attention{p_end}


{marker interpretation}{...}
{title:How to Interpret Results}

{dlgtab:Reading Test Statistics}

{pstd}
{bf:ADF, PP, ERS, ZA, Clemente (Null = unit root):}

{phang2}
A {it:more negative} test statistic provides stronger evidence against the unit root 
null. Compare to critical values or check p-values.{p_end}

{phang2}
{bf:Reject H0} (p < 0.05 or stat < critical value) => series is {bf:stationary}.{p_end}

{phang2}
{bf:Fail to reject H0} => insufficient evidence; series may have a unit root.{p_end}

{pstd}
{bf:KPSS (Null = stationarity):}

{phang2}
A {it:larger} test statistic provides stronger evidence against the stationarity 
null. Compare to critical values (no p-values available).{p_end}

{phang2}
{bf:Reject H0} (stat > critical value) => series is {bf:non-stationary}.{p_end}

{phang2}
{bf:Fail to reject H0} => series is {bf:stationary} (or insufficient evidence 
against stationarity).{p_end}

{dlgtab:Significance Stars}

{phang2}{bf:***} = significant at 1% level (very strong evidence){p_end}
{phang2}{bf:**} = significant at 5% level (strong evidence){p_end}
{phang2}{bf:*} = significant at 10% level (weak evidence){p_end}
{phang2}No star = not significant (fail to reject null){p_end}

{pstd}
For KPSS, stars indicate rejection of the {it:stationarity} null, meaning the 
series appears non-stationary. This is the {bf:opposite} interpretation from ADF/PP.

{dlgtab:Confirmatory Analysis Strategy}

{pstd}
The recommended workflow is:

{phang2}
1. Run ADF and PP as primary unit root tests.{p_end}
{phang2}
2. Use KPSS as confirmatory (opposite null hypothesis).{p_end}
{phang2}
3. If ADF/PP and KPSS agree => strong conclusion.{p_end}
{phang2}
4. If they disagree => series may be near the boundary; use ERS (more powerful) 
and ZA (accounts for structural breaks) to resolve.{p_end}
{phang2}
5. Table 6 consensus vote provides the final recommendation.{p_end}

{dlgtab:Common Scenarios}

{pstd}{bf:Scenario 1: All tests agree on I(1)}{p_end}
{pstd}ADF=I(1), PP=I(1), KPSS=I(1), ERS=I(1), ZA=I(1) => Strong evidence of I(1). 
First-difference the series before regression.

{pstd}{bf:Scenario 2: ADF says I(1) but ZA says I(0)}{p_end}
{pstd}The apparent unit root in ADF may be caused by a structural break. 
The series may be stationary around a broken trend. Consider modeling with 
break dummies instead of differencing.

{pstd}{bf:Scenario 3: ADF says I(0) but KPSS rejects stationarity}{p_end}
{pstd}Conflicting evidence. The series may be near the unit root boundary. 
Check ERS for a more powerful result. Consider the sample size — short samples 
reduce power of all tests.

{pstd}{bf:Scenario 4: I(>2) for all tests}{p_end}
{pstd}The series is not rendered stationary by first or second differencing. 
Possible causes: explosive behavior, structural breaks, long memory (fractional 
integration), or measurement issues. Check data for outliers or regime changes.


{marker graphs}{...}
{title:Graphs}

{pstd}
When the {opt graph} option is specified, the following PNG files are exported 
per variable to the directory specified by {opt graphdir()} (default: {cmd:urstat_graphs/}):

{p2colset 5 38 40 2}{...}
{p2col:{bf:File}}{bf:Description}{p_end}
{p2line}
{p2col:{it:var}_timeseries.png}Three-panel plot: Level, 1st Diff, 2nd Diff{p_end}
{p2col:{it:var}_level_vs_diff.png}Dual-axis overlay comparing Level and 1st Diff{p_end}
{p2col:{it:var}_correlogram.png}ACF and PACF for Level and 1st Difference{p_end}
{p2col:{it:var}_structural_break.png}Three-panel structural break plot with ZA break lines (Level, 1st Diff, 2nd Diff){p_end}
{p2col:integration_order_summary.png}Bar chart of integration orders (all variables){p_end}
{p2colreset}{...}

{pstd}
Graphs also remain in Stata memory as named graphs ({cmd:_urs_ts_*}, {cmd:_urs_cmp_*}, 
{cmd:_urs_corr_*}, {cmd:_urs_brk_*}, {cmd:_urs_decision}). Use {cmd:graph display <name>} 
to re-display any graph.


{marker requirements}{...}
{title:Requirements & Installation}

{dlgtab:Required Stata Version}

{pstd}
{cmd:urstat} requires Stata 14.0 or later. The data must be {cmd:tsset} before use.

{dlgtab:Required User-Written Packages}

{pstd}
{cmd:urstat} depends on several community-contributed packages. Missing packages 
are detected automatically and a warning is displayed. Install them from SSC:

{phang2}{cmd:. ssc install kpss}{space 12}(KPSS stationarity test){p_end}
{phang2}{cmd:. ssc install zandrews}{space 8}(Zivot-Andrews structural break test){p_end}
{phang2}{cmd:. ssc install clemao_io}{space 8}(Clemente-Montanes-Reyes AO/IO tests){p_end}
{phang2}{cmd:. ssc install ersur}{space 11}(Elliott-Rothenberg-Stock DF-GLS test){p_end}
{phang2}{cmd:. ssc install kmtest}{space 10}(Kobayashi-McAleer linear vs log test){p_end}

{pstd}
The {cmd:bsrwalkdrift} package is from the Stata Journal and may need manual
installation. See {browse "https://www.stata-journal.com/"}.

{pstd}
{bf:Note:} If a required package is not installed, {cmd:urstat} will display "N/A" 
for that test and continue with the remaining tests. No error is thrown.

{dlgtab:Warnings & Known Limitations}

{pstd}
{bf:1. Small samples:} All unit root tests have low power in small samples (T < 50). 
Results should be interpreted with caution. The ERS/DF-GLS test is generally more 
powerful than ADF in small samples.

{pstd}
{bf:2. KPSS no p-values:} The KPSS test does not produce p-values. Compare the 
test statistic to the critical values shown in the table footnotes. Stars are 
assigned based on asymptotic critical values from Kwiatkowski et al. (1992).

{pstd}
{bf:3. Structural breaks:} Standard ADF/PP tests are biased toward non-rejection 
(finding unit roots) when the true DGP is stationary with structural breaks. 
Always check ZA and Clemente results when ADF suggests a unit root.

{pstd}
{bf:4. Multiple testing:} Running many tests increases the chance of conflicting 
results. Table 6 uses majority voting to resolve conflicts, but the researcher 
should exercise judgment, particularly weighting tests with better power properties 
(ERS > ADF) and considering sample size.

{pstd}
{bf:5. Deterministic terms:} The choice of deterministic specification (none, constant, 
constant+trend) affects results. ADF with constant+trend has lower power when the 
true DGP has no trend. Table 5 follows Elder-Kennedy's sequential procedure which 
addresses this issue systematically.

{pstd}
{bf:6. Program caching:} After editing the {cmd:urstat.ado} file, you must run 
{cmd:discard} at the Stata command prompt to clear cached programs before 
re-running {cmd:urstat}.

{pstd}
{bf:7. ZA break dates:} The {cmd:zandrews} command returns an observation index 
for the break date. {cmd:urstat} converts this to the time variable value. If the 
break date appears empty, verify that the time variable is properly formatted.

{pstd}
{bf:8. Bootstrap computation time:} The {cmd:bsrwalkdrift} test with {cmd:bsreps(500)} 
can be slow for long series. Reduce {cmd:bsreps()} or omit {cmd:BSRW} from the 
test list for faster execution.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Example 1:} Full analysis with all tests and strategy decision:{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. urstat ln_inv ln_inc ln_consump, strategy}{p_end}

{pstd}{bf:Example 2:} All tests with graphs and custom output directory:{p_end}
{phang2}{cmd:. urstat ln_inv ln_inc ln_consump, strategy graph graphdir("my_plots")}{p_end}

{pstd}{bf:Example 3:} ADF only with "None" deterministic specification:{p_end}
{phang2}{cmd:. urstat ln_inv ln_inc, test(ADF) none}{p_end}

{pstd}{bf:Example 4:} Standard tests (ADF + PP + KPSS):{p_end}
{phang2}{cmd:. urstat ln_inv ln_inc, test(ADF PP KPSS)}{p_end}

{pstd}{bf:Example 5:} Structural break tests only:{p_end}
{phang2}{cmd:. urstat ln_inv, test(ZA CLEMAO1 CLEMAO2 CLEMIO1 CLEMIO2)}{p_end}

{pstd}{bf:Example 6:} KM transformation test for positive variables:{p_end}
{phang2}{cmd:. urstat ln_inv ln_inc, test(KM) kmlags(2)}{p_end}

{pstd}{bf:Example 7:} Custom ADF settings (AIC criterion, max 8 lags):{p_end}
{phang2}{cmd:. urstat ln_inv, test(ADF ZA) maxlag(8) crit(AIC) ztrim(0.10) strategy}{p_end}

{pstd}{bf:Example 8:} ERS test only with GTS method:{p_end}
{phang2}{cmd:. urstat ln_inv ln_inc, test(ERS) ersmethod(GTS05)}{p_end}

{pstd}{bf:Example 9:} Quick test without significance stars:{p_end}
{phang2}{cmd:. urstat ln_inv, test(ADF PP) nostars}{p_end}

{pstd}{bf:Example 10:} After running, re-display a saved graph:{p_end}
{phang2}{cmd:. graph display _urs_decision}{p_end}
{phang2}{cmd:. graph display _urs_ts_ln_inv}{p_end}


{marker references}{...}
{title:References}

{phang}Clemente, J., A. Montanes, and M. Reyes. 1998. Testing for a unit root in 
variables with a double change in the mean. {it:Economics Letters} 59: 175-182.{p_end}

{phang}Dickey, D.A. and W.A. Fuller. 1979. Distribution of the estimators for 
autoregressive time series with a unit root. {it:Journal of the American Statistical Association} 74: 427-431.{p_end}

{phang}Elder, J. and P.E. Kennedy. 2001. Testing for unit roots: What should 
students be taught? {it:Journal of Economic Education} 32(2): 137-146.{p_end}

{phang}Elliott, G., T.J. Rothenberg, and J.H. Stock. 1996. Efficient tests for 
an autoregressive unit root. {it:Econometrica} 64(4): 813-836.{p_end}

{phang}Kobayashi, M. and M. McAleer. 1999. Tests of linear and logarithmic 
transformations for integrated processes. {it:Journal of the American Statistical Association} 94(447): 860-868.{p_end}

{phang}Kwiatkowski, D., P.C.B. Phillips, P. Schmidt, and Y. Shin. 1992. Testing 
the null hypothesis of stationarity against the alternative of a unit root. 
{it:Journal of Econometrics} 54: 159-178.{p_end}

{phang}MacKinnon, J.G. 1996. Numerical distribution functions for unit root and 
cointegration tests. {it:Journal of Applied Econometrics} 11: 601-618.{p_end}

{phang}Park, J.Y. 2003. Bootstrap unit root tests. {it:Econometrica} 71(6): 
1845-1895.{p_end}

{phang}Perron, P. and T.J. Vogelsang. 1992. Nonstationarity and level shifts with 
an application to purchasing power parity. {it:Journal of Business and Economic Statistics} 10: 301-320.{p_end}

{phang}Phillips, P.C.B. and P. Perron. 1988. Testing for a unit root in time 
series regression. {it:Biometrika} 75: 335-346.{p_end}

{phang}Zivot, E. and D.W.K. Andrews. 1992. Further evidence on the great crash, 
the oil-price shock, and the unit-root hypothesis. {it:Journal of Business and Economic Statistics} 10: 251-270.{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr. Merwan Roudane{p_end}
{pstd}Email: merwanroudane920@gmail.com{p_end}

{pstd}
{bf:Version:} 1.3.0 (11 March 2026){p_end}

{pstd}
{bf:Required user-written commands:} 
{cmd:kpss}, {cmd:zandrews}, {cmd:clemao1}, {cmd:clemao2}, {cmd:clemio1}, 
{cmd:clemio2}, {cmd:ersur}, {cmd:bsrwalkdrift}, {cmd:kmtest}.
Install from SSC: {stata ssc install kpss}, {stata ssc install zandrews}, 
{stata ssc install clemao_io}, {stata ssc install ersur}, {stata ssc install kmtest}.
{p_end}

{pstd}
{bf:Suggested citation:} Roudane, M. (2026). URSTAT: Stata module for comprehensive 
unified unit root and stationarity testing. Statistical Software Components.
{p_end}
