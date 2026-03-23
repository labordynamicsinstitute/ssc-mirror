{smcl}
{* *! version 1.0.0  22mar2026}{...}
{vieweralsosee "tsset" "help tsset"}{...}
{vieweralsosee "vec" "help vec"}{...}
{vieweralsosee "vecrank" "help vecrank"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{viewerjumpto "Syntax" "fjcoint##syntax"}{...}
{viewerjumpto "Description" "fjcoint##description"}{...}
{viewerjumpto "Tests" "fjcoint##tests"}{...}
{viewerjumpto "Options" "fjcoint##options"}{...}
{viewerjumpto "Models" "fjcoint##models"}{...}
{viewerjumpto "Methodology" "fjcoint##methodology"}{...}
{viewerjumpto "Critical values" "fjcoint##critvals"}{...}
{viewerjumpto "Output interpretation" "fjcoint##output"}{...}
{viewerjumpto "Graph interpretation" "fjcoint##graphs"}{...}
{viewerjumpto "Step-by-step guide" "fjcoint##stepbystep"}{...}
{viewerjumpto "Examples" "fjcoint##examples"}{...}
{viewerjumpto "Stored results" "fjcoint##results"}{...}
{viewerjumpto "References" "fjcoint##references"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{bf:fjcoint} {hline 2}}Johansen-Fourier cointegration tests with
smooth structural breaks{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 18 2}
{cmd:fjcoint} {varlist} {ifin}
[{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:{it:Test specification}}
{synopt:{opt test(testname)}}test to run: {bf:johansen}, {bf:fourier} (default),
{bf:sbc}, or {bf:all}{p_end}

{syntab:{it:Model specification}}
{synopt:{opt mod:el(string)}}deterministic component; see {help fjcoint##models:Models}{p_end}
{synopt:{opt maxl:ag(#)}}max lag order for the VAR; default is {bf:2}{p_end}
{synopt:{opt fr:eq(#)}}Fourier frequency k; default is {bf:1}, range 1-5{p_end}
{synopt:{opt opt:ion(string)}}frequency type: {bf:single} (default) or
{bf:cumulative}{p_end}
{synopt:{opt maxf:req(#)}}max frequency for SBC grid search; default is {bf:3}{p_end}
{synopt:{opt trim:ming(#)}}trimming proportion for SC-VECM; default {bf:0.1}{p_end}

{syntab:{it:Output}}
{synopt:{opt gr:aph}}produce four diagnostic graphs plus a combined panel{p_end}
{synopt:{opt not:able}}suppress table output{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fjcoint} implements the Johansen-type cointegration tests with a Fourier
function, as proposed by Pascalau, Lee, Nazlioglu and Lu (2022).

{pstd}
{bf:Why this test?}  The standard Johansen (1991) test assumes no structural
breaks in the deterministic components of the VECM.  When breaks are present
(e.g. regime changes, policy shifts, crises), the standard test can have
severe size distortion and power loss.

{pstd}
{bf:Key insight:}  A Fourier expansion f(t) = A*cos(2{c pi}kt/T) +
B*sin(2{c pi}kt/T) can approximate virtually {bf:any} smooth deterministic
function, including functions with multiple breaks, nonlinear shifts, and
gradual transitions (Gallant, 1981).  Unlike dummy-variable approaches, this
avoids the need to pre-specify break dates, forms, and numbers.

{pstd}
{bf:When to use each test:}

{p 8 12 2}
{bf:test(johansen)} {hline 2} When you believe there are {bf:no structural breaks}
in the system.  This is the classical benchmark.{p_end}

{p 8 12 2}
{bf:test(fourier)} {hline 2} When you suspect {bf:smooth, gradual breaks} such as
slow policy transitions, demographic changes, or evolving technology.  Best for
trigonometric, ESTAR, LSTAR break patterns.{p_end}

{p 8 12 2}
{bf:test(sbc)} {hline 2} When you are {bf:unsure about the break type}.  The SBC
procedure automatically compares Johansen, SC-VECM (sharp breaks), and Fourier
(smooth breaks) using the Schwarz criterion, then applies the test from the
best-fitting model.  This is the {bf:recommended test for applied work}.{p_end}

{p 8 12 2}
{bf:test(all)} {hline 2} Runs all three tests sequentially for comprehensive
comparison.{p_end}


{marker tests}{...}
{title:Available Tests}

{dlgtab:test(johansen) -- Standard Johansen Test}

{pstd}
The standard Johansen (1991) system-based cointegration rank test.

{pstd}
{bf:Null hypothesis:} H0: rank({bf:{c Pi}}) {c <=} r  (at most r cointegrating
vectors){break}
{bf:Alternative:}  H1: rank({bf:{c Pi}}) > r

{pstd}
{bf:Two test statistics are computed:}

{p 8 12 2}
{bf:Trace statistic:} LR_trace = -T {c sum}(i=r+1 to p) ln(1 - {c lambda}_i){break}
Tests H0: rank {c <=} r against H1: rank = p (full rank).  The Trace test
evaluates all remaining eigenvalues simultaneously.{p_end}

{p 8 12 2}
{bf:Lambda-max statistic:} {c lambda}_max = -T * ln(1 - {c lambda}_{r+1}){break}
Tests H0: rank = r against H1: rank = r+1.  The Lambda-max test evaluates
only the next eigenvalue.{p_end}

{pstd}
{bf:Five model specifications} are available (models 1-5); see 
{help fjcoint##models:Models}.


{dlgtab:test(fourier) -- Johansen-Fourier Test}

{pstd}
Extends the Johansen framework by augmenting the VECM with Fourier
trigonometric terms.  The key equation becomes:

{p 8 8 2}
{c Delta}X_t = {c Pi} * X_{t-k} + {c Gamma}_1*{c Delta}X_{t-1} + ... +
{c mu} + f(t) + e_t

{pstd}
where f(t) = {c sum}(j=1 to n) [A_j * cos(2{c pi}jt/T) + B_j * sin(2{c pi}jt/T)].

{pstd}
{bf:Two frequency options:}

{p 8 12 2}
{bf:option(single)} {hline 2} Uses one frequency k.  The Fourier terms are
sin(2{c pi}kt/T) and cos(2{c pi}kt/T).  Parsimonious: adds only 2 extra
regressors.  Best when you expect one dominant smooth break.{p_end}

{p 8 12 2}
{bf:option(cumulative)} {hline 2} Uses frequencies 1 through k.  The Fourier
terms include all sin(2{c pi}jt/T) and cos(2{c pi}jt/T) for j=1,...,k.
More flexible: can approximate complex break patterns with multiple
inflection points. Uses more degrees of freedom (2k extra regressors).{p_end}

{pstd}
{bf:Choosing the frequency k:}

{p 8 12 2}
k=1: One smooth, gradual shift over the sample (U-shaped, or one regime
change).  {bf:Start here}.{p_end}
{p 8 12 2}
k=2: Two cycles or a V-shaped/W-shaped shift (e.g. pre-crisis, crisis,
recovery).{p_end}
{p 8 12 2}
k=3: Complex patterns with multiple inflection points.{p_end}
{p 8 12 2}
k=4-5: Very complex break structures.  {bf:Use with caution} -- high k
reduces power.{p_end}

{pstd}
{bf:Four model specifications} are available (models 1-4); see 
{help fjcoint##models:Models}.


{dlgtab:test(sbc) -- SBC Model Selection Procedure}

{pstd}
The SBC procedure (Pascalau et al. 2022, Section 4) is a data-driven approach
that selects the best model among three candidates:

{p 8 12 2}
1. {bf:Standard Johansen} {hline 2} No breaks.{p_end}
{p 8 12 2}
2. {bf:SC-VECM} (Harris, Leybourne & Taylor 2016) {hline 2} Sharp/sudden
structural break in the trend function at an unknown date.{p_end}
{p 8 12 2}
3. {bf:Johansen-Fourier} {hline 2} Smooth/gradual structural break via Fourier
function.{p_end}

{pstd}
{bf:How it works:}

{p 8 12 2}
Step 1: For each candidate model, compute the Schwarz Bayesian Criterion
(SBC).{break}
Step 2: For SC-VECM, search over all break dates (within trimming bounds)
and lag orders, selecting the combination with minimum SBC.{break}
Step 3: For Fourier, search over all frequencies (1 to maxfreq) and lag
orders, selecting the combination with minimum SBC.{break}
Step 4: Compare the three SBC values.  The model with the smallest SBC is
selected.{break}
Step 5: The cointegration test statistic from the selected model is used for
inference, with the corresponding critical values.{p_end}

{pstd}
{bf:Advantage:}  The SBC procedure has correct empirical size under {bf:all}
break types, including no breaks, smooth breaks, and sharp breaks.  The
standard Fourier test may lose power for sharp breaks; the SBC procedure
avoids this by switching to SC-VECM when sharp breaks dominate.


{marker options}{...}
{title:Options}

{dlgtab:Test specification}

{phang}
{opt test(testname)} specifies which test to run.  Choose from:
{bf:johansen}, {bf:fourier} (default), {bf:sbc}, or {bf:all}.

{dlgtab:Model specification}

{phang}
{opt model(string)} specifies the deterministic component.  Choose from:

{p 12 16 2}
{bf:rc} {hline 2} Restricted constant (default).  Constant enters only in the
cointegrating vector.  Implies the cointegrating relationship has a nonzero
mean but no linear trend.  {bf:Recommended for most applications.}{p_end}

{p 12 16 2}
{bf:none} {hline 2} No deterministic terms.  Rare in practice; implies the
data have zero mean and no trend.{p_end}

{p 12 16 2}
{bf:constant} or {bf:uc} {hline 2} Unrestricted constant.  Allows a linear
deterministic trend in the levels of the variables.{p_end}

{p 12 16 2}
{bf:rt} {hline 2} Restricted trend.  Linear trend enters the cointegrating
vector only.  Appropriate when you expect a deterministic trend in the
cointegrating relationship (e.g. trend-stationary deviations).{p_end}

{p 12 16 2}
{bf:trend} or {bf:ut} {hline 2} Unrestricted trend.  Allows a quadratic
deterministic trend in the levels.{p_end}

{phang}
{opt maxlag(#)} maximum lag order for the VAR model.  The VECM uses k-1
lagged differences.  Default is 2.  For quarterly data, try 4-8.  For
monthly data, try 12-24.

{phang}
{opt freq(#)} Fourier frequency for test(fourier).  Default is 1.  Range:
1 to 5.  Start with 1 and increase only if there is reason to suspect
complex multi-break patterns.

{phang}
{opt option(single|cumulative)} frequency type.
{bf:single} (default) uses one frequency k.
{bf:cumulative} uses all frequencies 1 through k.

{phang}
{opt maxfreq(#)} maximum frequency for SBC grid search.  Default is 3.
The SBC procedure searches over frequencies 1, 2, ..., maxfreq.

{phang}
{opt trimming(#)} trimming proportion for SC-VECM break point search.
Default is 0.1 (10%).  The first and last (trimming * 100)% of observations
are excluded as candidate break dates.

{phang}
{opt graph} produces four diagnostic graphs plus a combined panel.
See {help fjcoint##graphs:Graph Interpretation}.

{phang}
{opt notable} suppresses the table output.  Useful when you only want
stored results or graphs.


{marker models}{...}
{title:Model Specifications}

{pstd}
{bf:Johansen model numbers (standard test):}

{col 8}Model{col 16}Name{col 44}Deterministic terms
{col 8}{hline 58}
{col 8}1{col 16}None{col 44}No constant, no trend
{col 8}2{col 16}Restricted Constant{col 44}Constant in CI vector only
{col 8}3{col 16}Unrestricted Constant{col 44}Constant in short-run
{col 8}4{col 16}Restricted Trend{col 44}Trend in CI vector only
{col 8}5{col 16}Unrestricted Trend{col 44}Trend in short-run

{pstd}
{bf:Fourier model numbers:}

{col 8}Model{col 16}Name{col 44}Deterministic terms
{col 8}{hline 58}
{col 8}1{col 16}Unrestricted Constant{col 44}Constant + Fourier
{col 8}2{col 16}Unrestricted Trend{col 44}Constant + Trend + Fourier
{col 8}3{col 16}Restricted Constant{col 44}Constant in CI + Fourier
{col 8}4{col 16}Restricted Trend{col 44}Trend in CI + Fourier

{pstd}
{bf:Practical guidance:}

{p 8 12 2}
Use {bf:model(rc)} (restricted constant, the default) for most applications.
This is the most common specification in empirical work and corresponds to
the case where the cointegrating relationship has an intercept but the
individual series do not exhibit deterministic linear trends beyond those
induced by unit roots.{p_end}

{p 8 12 2}
Use {bf:model(constant)} or {bf:model(rt)} if you believe the data have
linear trends in levels, or if the series show trending behavior.{p_end}


{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:1. The Vector Error Correction Model (VECM)}

{p 8 8 2}
{c Delta}X_t = {c Pi}*X_{t-k} + {c sum}(i=1 to k-1) {c Gamma}_i*{c Delta}X_{t-i}
+ {c mu} + e_t

{pstd}
where {c Pi} = {c alpha}*{c beta}' is a (p x p) matrix of rank r.  The
matrix {c beta} contains the r cointegrating vectors, and {c alpha} contains
the adjustment coefficients (loading matrix).

{pstd}
{bf:2. The Fourier Extension}

{p 8 8 2}
{c Delta}X_t = {c Pi}*X_{t-k} + {c sum}(i) {c Gamma}_i*{c Delta}X_{t-i}
+ {c mu} + f(t) + e_t

{pstd}
where f(t) = A*cos(2{c pi}kt/T) + B*sin(2{c pi}kt/T) is the Fourier
approximation of an unknown smooth break function.

{pstd}
{bf:3. Reduced-Rank Regression}

{pstd}
The test is based on solving the eigenvalue problem:

{p 8 8 2}
|{c lambda}*S_kk - S_k0 * S_00^(-1) * S_0k| = 0

{pstd}
where S_00, S_kk, and S_k0 are residual product moment matrices from
regressions of {c Delta}X_t and X_{t-k} on lagged differences and
deterministic terms.  The ordered eigenvalues {c lambda}_1 >= ... >= {c lambda}_p
provide information about the cointegration rank.

{pstd}
{bf:4. Trace and Lambda-max Statistics}

{p 8 12 2}
{bf:Trace:} LR = -T * {c sum}(i=r+1 to p) ln(1 - {c lambda}_i){break}
{it:Tests whether there are at most r cointegrating vectors.}{p_end}

{p 8 12 2}
{bf:Lambda-max:} {c lambda}_max = -T * ln(1 - {c lambda}_{r+1}){break}
{it:Tests whether the rank is exactly r against r+1.}{p_end}

{pstd}
{bf:5. Log-Likelihood}

{p 8 8 2}
logL(r) = -(T/2) * [m*(1+ln(2{c pi})) + ln(det(S_00)) + {c sum}(i=1 to r) ln(1-{c lambda}_i)]

{pstd}
The log-likelihood should be monotonically increasing as the rank r increases,
because each additional cointegrating vector adds parameters to the model.


{marker critvals}{...}
{title:Critical Values}

{pstd}
{bf:Standard Johansen:}  5% critical values from Johansen (1991).  Available
for up to 6 variables and 5 model specifications.

{pstd}
{bf:Fourier-Trace and Fourier-Lambda:}  5% critical values from Pascalau et al.
(2022), Online Appendix Tables 1-8.  Available for 4 models, frequencies 1-5,
single and cumulative, and up to 5 variables (10 variables per system).

{pstd}
{bf:SBC procedure:}  Extended critical value tables from the original GAUSS
code supporting up to 8 variables per system.  Includes both no-break and
break critical values for SC-VECM (the break CVs vary by break location).

{pstd}
{bf:Note:}  All critical values are at the 5% level.  Values are based on
response surface regressions from Monte Carlo simulations with 50,000
replications (Pascalau et al. 2022).


{marker output}{...}
{title:Output Interpretation}

{dlgtab:Johansen Test Table}

{pstd}
The Johansen table has the following columns:

{col 8}{ul:Column}{col 28}{ul:Interpretation}
{col 8}Rank{col 28}Hypothesized cointegration rank (r = 0, 1, ..., p)
{col 8}Eigen Value{col 28}Ordered eigenvalue {c lambda}_r from reduced-rank regression
{col 8}{col 28}Larger values indicate stronger cointegrating relationships
{col 8}Lambda{col 28}Lambda-max test statistic: {c lambda}_max = -T*ln(1-{c lambda}_{r+1})
{col 8}{col 28}Tests H0: rank=r vs H1: rank=r+1
{col 8}Trace{col 28}Trace test statistic: LR = -T*{c sum} ln(1-{c lambda}_i)
{col 8}{col 28}Tests H0: rank<=r vs H1: rank=p (full rank)
{col 8}cv(5%) Trace{col 28}5% critical value for the Trace test
{col 8}Log-Likelihood{col 28}Concentrated log-likelihood at rank r
{col 8}{col 28}Should be monotonically increasing in r

{pstd}
{bf:How to read the table:}

{p 8 12 2}
1. Start at Rank = 0.  This tests H0: no cointegration.{break}
2. Compare the Trace statistic to the cv(5%) value.{break}
3. If Trace > cv(5%), reject H0 (marked with **).  Move to Rank = 1.{break}
4. Continue until the first non-rejection.{break}
5. The estimated cointegration rank is the rank where you first fail to
reject.{p_end}

{pstd}
{bf:Example interpretation:}

{p 8 8 2}
If Rank 0 is rejected (**) and Rank 1 is not rejected, the estimated
cointegration rank is r = 1, meaning there is one long-run equilibrium
relationship among the variables.

{dlgtab:Fourier Test Table}

{pstd}
The Fourier table adds two extra columns compared to Johansen:

{col 8}{ul:Column}{col 32}{ul:Interpretation}
{col 8}Fourier Lambda{col 32}Fourier Lambda-max statistic
{col 8}Fourier Trace{col 32}Fourier Trace statistic
{col 8}cv(5%) Lambda{col 32}5% critical value for Fourier Lambda-max
{col 8}cv(5%) Trace{col 32}5% critical value for Fourier Trace
{col 8}Log-Likelihood{col 32}Concentrated log-likelihood at rank r

{pstd}
{bf:Key differences from standard Johansen:}

{p 8 12 2}
The Fourier critical values are {bf:larger} than standard Johansen CVs because
the Fourier terms use additional degrees of freedom.  This means the Fourier
test is more conservative: it may fail to reject when the standard Johansen
test rejects.  This is the correct behavior when no break exists (the Fourier
terms are nuisance parameters).{p_end}

{p 8 12 2}
When smooth breaks {bf:are} present, the Fourier test controls for them and
provides correctly-sized inference, whereas the standard Johansen test may
spuriously reject or fail to reject.{p_end}

{pstd}
{bf:Comparing Johansen and Fourier results:}

{p 8 12 2}
{bf:Both reject at similar ranks:} Cointegration relationship is robust to
break specification.{break}
{bf:Johansen rejects but Fourier does not:} The Johansen rejection may be
driven by an uncontrolled structural break.  Trust the Fourier result.{break}
{bf:Fourier rejects but Johansen does not:} The structural break was masking
a cointegrating relationship.  The Fourier test recovers it.{p_end}

{dlgtab:SBC Table}

{pstd}
The SBC table compares three models at each rank:

{col 8}{ul:Row}{col 28}{ul:Interpretation}
{col 8}Trace{col 28}Trace statistic from each model
{col 8}SBC{col 28}Schwarz Bayesian Criterion value
{col 8}{col 28}{it:Lower SBC is better} (more parsimonious fit)
{col 8}Lag{col 28}Optimal lag order selected for each model
{col 8}TB & F{col 28}Break date (for SC-VECM) or frequency (for Fourier)
{col 8}{col 28}A dot (.) means no break parameter
{col 8}5% cv{col 28}5% critical value from the selected model
{col 8}Select{col 28}Model selected by minimum SBC

{pstd}
{bf:How to read the SBC table:}

{p 8 12 2}
1. Look at the "SBC" row.  The smallest SBC value determines which model
fits best.{break}
2. Look at the "Select" row to see which model was chosen.{break}
3. If "Johansen" is selected, no structural break was detected.{break}
4. If "SC-VECM" is selected, a sharp structural break was detected at the
date shown in "TB & F".{break}
5. If "Fourier" is selected, a smooth structural break was detected at the
frequency shown in "TB & F".{break}
6. Use the Trace statistic and cv from the selected model for inference.{p_end}


{marker graphs}{...}
{title:Graph Interpretation}

{pstd}
When the {opt graph} option is specified, {cmd:fjcoint} produces four diagnostic
graphs plus a combined panel ({bf:fjc_combined}):

{dlgtab:Graph 1: Time Series with Fourier Fit (fjc_timeseries)}

{pstd}
{bf:What it shows:} The first variable in the system (solid blue line) overlaid
with the fitted Fourier deterministic function (dashed red line).

{pstd}
{bf:How to interpret:}

{p 8 12 2}
- If the Fourier fit (red dashed) tracks the broad movements of the series
well, a smooth structural break is present and the Fourier approach is
appropriate.{p_end}
{p 8 12 2}
- The Fourier fit captures only the {bf:deterministic} component (breaks,
shifts) -- it should follow the slow-moving trend, not the short-run
fluctuations.{p_end}
{p 8 12 2}
- Large deviations between the series and the fit suggest the break may be
sharp rather than smooth (consider SC-VECM instead).{p_end}
{p 8 12 2}
- If the fit is essentially flat (near the mean), the Fourier terms add
little and standard Johansen may suffice.{p_end}

{dlgtab:Graph 2: Fourier Smooth Break Approximation (fjc_fourier)}

{pstd}
{bf:What it shows:} The isolated Fourier component f(t) plotted as a shaded
area chart.  This is the estimated smooth break function, stripped of the
intercept.

{pstd}
{bf:How to interpret:}

{p 8 12 2}
- A smooth sinusoidal wave indicates a {bf:gradual structural shift} in the
data-generating process.{p_end}
{p 8 12 2}
- The {bf:amplitude} (height) shows the magnitude of the break.  Large
amplitude = large structural shift.{p_end}
{p 8 12 2}
- The {bf:number of peaks and troughs} corresponds to the frequency k.
With k=1, there is one complete cycle.  With k=2, there are two cycles.{p_end}
{p 8 12 2}
- If the curve is very close to zero throughout, there is no meaningful
smooth structural break -- standard Johansen is sufficient.{p_end}
{p 8 12 2}
- The {bf:timing of peaks/troughs} indicates when the structural shifts
occur.  A peak followed by a trough suggests a U-shaped or inverted-U
break.{p_end}

{dlgtab:Graph 3: Variables in the Cointegration System (fjc_variables)}

{pstd}
{bf:What it shows:} All variables in the system plotted together on the same
axes, each in a different color.

{pstd}
{bf:How to interpret:}

{p 8 12 2}
- Variables that move together (similar trends, turning points) are likely
to be cointegrated.  They should show {bf:common stochastic trends}.{p_end}
{p 8 12 2}
- Variables that diverge persistently suggest the absence of cointegration
or the presence of structural breaks that disrupt the long-run
relationship.{p_end}
{p 8 12 2}
- This graph helps verify that the variables are indeed I(1) (trending,
non-stationary) -- a prerequisite for cointegration testing.{p_end}
{p 8 12 2}
- Sudden jumps or level shifts visible in one or more series suggest
structural breaks that should be controlled for (via Fourier or SC-VECM).{p_end}

{dlgtab:Graph 4: Regression Residuals (fjc_residuals)}

{pstd}
{bf:What it shows:} The residuals from regressing the first variable on the
Fourier terms (constant, sin, cos).  These are the movements {bf:not}
explained by the smooth break function.

{pstd}
{bf:How to interpret:}

{p 8 12 2}
- Residuals should look roughly stationary (mean-reverting around zero)
if the Fourier terms adequately capture the break.{p_end}
{p 8 12 2}
- {bf:Persistent trends} in the residuals suggest the Fourier frequency k
may be too low -- try increasing k or using cumulative frequencies.{p_end}
{p 8 12 2}
- {bf:Large spikes or outliers} indicate possible sharp breaks or extreme
events not well captured by the smooth Fourier approximation.{p_end}
{p 8 12 2}
- {bf:Heteroskedasticity} (changing variance over time) in the residuals
may affect inference and suggests using robust methods.{p_end}

{dlgtab:Graph 5: Ordered Eigenvalues (fjc_eigenvals)}

{pstd}
{bf:What it shows:} Bar chart of the ordered eigenvalues from the
reduced-rank regression, from largest to smallest.

{pstd}
{bf:How to interpret:}

{p 8 12 2}
- The eigenvalues represent the {bf:strength} of each potential cointegrating
relationship.  Larger eigenvalues = stronger cointegration.{p_end}
{p 8 12 2}
- A sharp drop between eigenvalue i and i+1 visually suggests the
cointegrating rank is i.{p_end}
{p 8 12 2}
- Eigenvalues close to zero correspond to non-cointegrating directions
(common stochastic trends).{p_end}
{p 8 12 2}
- This graph is most useful for visual confirmation of the rank identified
by the formal test statistics.{p_end}


{marker stepbystep}{...}
{title:Step-by-Step Applied Guide}

{pstd}
{bf:Step 1: Check data prerequisites}

{p 8 12 2}
- Declare time series: {cmd:tsset time}{break}
- All variables must be I(1).  Test with: {cmd:dfuller y, lags(4)}. If any
variable is I(0), remove it from the system.  If any variable is I(2), take
first differences.{p_end}

{pstd}
{bf:Step 2: Run the standard Johansen test}

{phang2}{cmd:. fjcoint y x1 x2, test(johansen) model(rc)}{p_end}

{p 8 12 2}
Examine the Trace column.  Identify the cointegration rank (first
non-rejection).  This is your baseline result.{p_end}

{pstd}
{bf:Step 3: Check for structural breaks}

{phang2}{cmd:. fjcoint y x1 x2, test(fourier) model(rc) freq(1) graph}{p_end}

{p 8 12 2}
Examine the Fourier Smooth Break graph.  If the Fourier component is large
(substantial amplitude), breaks are present.  Compare the Fourier test rank
with the Johansen rank from Step 2.{p_end}

{pstd}
{bf:Step 4: Run the SBC procedure (recommended)}

{phang2}{cmd:. fjcoint y x1 x2, test(sbc) model(rc) maxlag(4)}{p_end}

{p 8 12 2}
This is the most robust test.  The SBC procedure automatically selects the
best model (Johansen, SC-VECM, or Fourier) and applies the corresponding
test.  Use the selected model's rank for inference.{p_end}

{pstd}
{bf:Step 5: Report results}

{p 8 12 2}
Report the selected test, the estimated rank, and the test statistic with
its critical value.  For example: "The SBC procedure selects the Fourier
model (k=1).  The Fourier Trace test rejects the null of r=0 at 5% (Trace =
33.06, cv = 29.59) and fails to reject r=1 (Trace = 17.24, cv = 22.20),
indicating one cointegrating vector."{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Basic Johansen-Fourier test}

{phang2}{cmd:. tsset time, monthly}{p_end}
{phang2}{cmd:. fjcoint y x1 x2}{p_end}

{pstd}
{bf:Example 2: Standard Johansen test}

{phang2}{cmd:. fjcoint y x1 x2, test(johansen)}{p_end}

{pstd}
{bf:Example 3: Fourier with restricted constant and frequency 2}

{phang2}{cmd:. fjcoint y x1 x2, test(fourier) model(rc) freq(2)}{p_end}

{pstd}
{bf:Example 4: Cumulative frequencies}

{phang2}{cmd:. fjcoint y x1 x2, test(fourier) option(cumulative) freq(2)}{p_end}

{pstd}
{bf:Example 5: SBC model selection (recommended)}

{phang2}{cmd:. fjcoint y x1 x2, test(sbc) maxlag(4)}{p_end}

{pstd}
{bf:Example 6: All tests with diagnostic graphs}

{phang2}{cmd:. fjcoint y x1 x2, test(all) graph}{p_end}

{pstd}
{bf:Example 7: Replicating the paper application}

{p 8 8 2}
Step 1: Unit root testing{break}
{cmd:dfuller y, lags(4)}{break}
{cmd:dfuller x1, lags(4)}{break}
{cmd:dfuller x2, lags(4)}{p_end}

{p 8 8 2}
Step 2: Standard Johansen{break}
{cmd:fjcoint y x1 x2, test(johansen) model(rc)}{p_end}

{p 8 8 2}
Step 3: Fourier test (single, k=1){break}
{cmd:fjcoint y x1 x2, test(fourier) model(rc) freq(1)}{p_end}

{p 8 8 2}
Step 4: Fourier test (cumulative, k=2){break}
{cmd:fjcoint y x1 x2, test(fourier) model(rc) freq(2) option(cumulative)}{p_end}

{p 8 8 2}
Step 5: SBC model selection{break}
{cmd:fjcoint y x1 x2, test(sbc) model(rc) maxlag(4) graph}{p_end}


{marker results}{...}
{title:Stored Results}

{pstd}
{cmd:fjcoint} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(nobs)}}number of effective observations used{p_end}
{synopt:{cmd:r(nvars)}}number of variables in the system{p_end}
{synopt:{cmd:r(maxlag)}}VAR lag order{p_end}
{synopt:{cmd:r(frequency)}}Fourier frequency k{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:fjcoint}{p_end}
{synopt:{cmd:r(test)}}test name (johansen, fourier, sbc, all){p_end}
{synopt:{cmd:r(model)}}model specification (rc, constant, etc.){p_end}
{synopt:{cmd:r(option)}}frequency option (single, cumulative){p_end}
{synopt:{cmd:r(varlist)}}variable list used{p_end}

{p2col 5 25 29 2: Matrices (Johansen/Fourier tests)}{p_end}
{synopt:{cmd:r(eigenvalues)}}p x 1 vector of ordered eigenvalues{p_end}
{synopt:{cmd:r(lambda)}}p x 1 vector of Lambda-max statistics{p_end}
{synopt:{cmd:r(trace)}}p x 1 vector of Trace statistics{p_end}
{synopt:{cmd:r(cv_trace)}}1 x p vector of 5% Trace critical values{p_end}
{synopt:{cmd:r(cv_lambda)}}1 x p vector of 5% Lambda-max CVs (Fourier only){p_end}
{synopt:{cmd:r(logL)}}(p+1) x 1 vector of log-likelihood values{p_end}


{marker references}{...}
{title:References}

{pstd}
Pascalau, R., J. Lee, S. Nazlioglu, and Y.O. Lu (2022).
Johansen-type cointegration tests with a Fourier function.
{it:Journal of Time Series Analysis} 43(5): 828-852.

{pstd}
Johansen, S. (1991).
Estimation and hypothesis testing of cointegration vectors in Gaussian
vector autoregressive models.
{it:Econometrica} 59(6): 1551-1580.

{pstd}
Johansen, S. and K. Juselius (1990).
Maximum likelihood estimation and inference on cointegration with
applications to the demand for money.
{it:Oxford Bulletin of Economics and Statistics} 52(2): 169-210.

{pstd}
Harris, D., S.J. Leybourne, and A.R. Taylor (2016).
Tests of the co-integration rank in VAR models in the presence of a
possible break in trend at an unknown point.
{it:Journal of Econometrics} 192(2): 451-467.

{pstd}
Enders, W. and J. Lee (2012).
A unit root test using a Fourier series to approximate smooth breaks.
{it:Oxford Bulletin of Economics and Statistics} 74(4): 574-599.

{pstd}
Gallant, A.R. (1981).
On the bias in flexible functional forms and an essentially unbiased form.
{it:Journal of Econometrics} 15: 211-245.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com

{pstd}
Translated from original GAUSS code by Saban Nazlioglu
(snazlioglu@pau.edu.tr).


{title:Also see}

{p 4 14 2}
Online: {helpb tsset}, {helpb dfuller}, {helpb pperron}, {helpb vec},
{helpb vecrank}
{p_end}
