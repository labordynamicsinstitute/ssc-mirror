{smcl}
{* 14mar2026}{...}
{cmd:help xtgets} {right:version 1.0.0}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi:xtgets} {hline 2}}Panel General-to-Specific (GETS) Indicator
Saturation for Structural Break Detection{p_end}
{p2colreset}{...}

{title:Version}

{pstd}
Version 1.0.0, 14 March 2026

{pstd}
{bf:Author:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{pstd}
{bf:Based on:} Pretis, F. and Schwarz, M. (2022/2026). "Discovering What Mattered:
Detecting Unknown Treatment as Breaks in Panel Models". SSRN 4022745.{p_end}

{pstd}
{bf:R implementation:} getspanel package ({browse "https://CRAN.R-project.org/package=getspanel":CRAN})
by Felix Pretis and Moritz Schwarz.{p_end}

{pstd}
{bf:Original time-series gets.ado:} Damian C. Clarke, University of Oxford (2013).{p_end}


{title:Syntax}

{p 8 16 2}{cmd:xtgets} {depvar} [{indepvars}] {ifin} [{it:weight}] {cmd:,}
{it:saturation_methods} [{it:options}]

{pstd}
At least one saturation method ({opt iis}, {opt jiis}, {opt jsis}, {opt fesis},
{opt csis}, {opt cfesis}, or {opt tis}) is required.  You may combine multiple
methods in a single call (e.g. {cmd:fesis iis}).  When multiple methods are
specified the command uses a two-stage GETS selection: structural indicators
(FESIS/JSIS/CSIS/CFESIS/TIS) are selected first, then outlier indicators
(IIS/JIIS) are selected conditional on the retained structural indicators.

{pstd}
{bf:Default significance:} t.pval = 0.001 (matching the R getspanel default), which
gives tlimit = {cmd:invnormal(1 - 0.001/2)} = 3.291.  At this strict threshold,
the expected share of spuriously retained indicators is 0.1%.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Indicator Saturation Methods (at least one required)}
{synopt :{opt iis}}Impulse Indicator Saturation (unit-specific outlier detection){p_end}
{synopt :{opt jiis}}Joint Impulse Indicators (common outliers = time FE selection){p_end}
{synopt :{opt jsis}}Joint Step Indicators (common structural breaks across units){p_end}
{synopt :{opt fesis}}Fixed-Effect Step Indicator Saturation (unit-specific step-shifts){p_end}
{synopt :{opt csis}}Coefficient Step Indicators (common coefficient structural change){p_end}
{synopt :{opt cfesis}}Coefficient-FE Step Indicators (unit-specific coefficient breaks){p_end}
{synopt :{opt tis}}Trend Indicator Saturation (unit-specific broken trends){p_end}

{syntab:Model specification}
{synopt :{opt eff:ect(string)}}Fixed effects type: {cmd:twoways} (default), {cmd:individual}, {cmd:time}, {cmd:none}{p_end}
{synopt :{opt t_pval(#)}}Two-sided p-value threshold for indicator retention; default {cmd:0.001}{p_end}
{synopt :{opt tlimit(#)}}Absolute t-statistic threshold (overrides t_pval if > 0){p_end}
{synopt :{opt nums:earch(#)}}Number of independent search paths; default {cmd:1}{p_end}
{synopt :{opth vce:(vcetype)}}Variance-covariance estimator (e.g. {cmd:robust}, {cmd:cluster}){p_end}
{synopt :{opt cluster(varname)}}Cluster variable for clustered standard errors{p_end}
{synopt :{opt nopart:ition}}Skip out-of-sample partition tests{p_end}
{synopt :{opt ar(#)}}Include autoregressive lags of the dependent variable; default {cmd:0}{p_end}

{syntab:Subset restrictions}
{synopt :{opt fesis_id(numlist)}}Restrict FESIS to specific panel units{p_end}
{synopt :{opt fesis_time(numlist)}}Restrict FESIS to specific time periods{p_end}
{synopt :{opt tis_id(numlist)}}Restrict TIS to specific panel units{p_end}
{synopt :{opt tis_time(numlist)}}Restrict TIS to specific time periods{p_end}
{synopt :{opt csis_var(varlist)}}Restrict CSIS to specific regressors (default: all){p_end}
{synopt :{opt csis_time(numlist)}}Restrict CSIS to specific time periods{p_end}
{synopt :{opt cfesis_id(numlist)}}Restrict CFESIS to specific panel units{p_end}
{synopt :{opt cfesis_var(varlist)}}Restrict CFESIS to specific regressors (default: all){p_end}
{synopt :{opt cfesis_time(numlist)}}Restrict CFESIS to specific time periods{p_end}

{syntab:Display}
{synopt :{opt v:erbose}}Display detailed screening and refinement progress{p_end}
{synopt :{opt nodiag:nostic}}Suppress diagnostics and false discovery rate table{p_end}
{synopt :{opt plot}}Automatically produce default plot after estimation{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtgets}; see {helpb xtset}.{p_end}
{p 4 6 2}
{cmd:pweight}s, {cmd:fweight}s, {cmd:aweight}s, and {cmd:iweight}s are allowed;
see {help weight}.{p_end}
{p 4 6 2}
The data must be a balanced or unbalanced panel identified by {cmd:xtset panelvar timevar}.{p_end}


{title:Description}

{pstd}
{cmd:xtgets} implements {bf:Indicator Saturation} methods for
panel data using automated General-to-Specific (GETS) model selection.
The command detects when and where structural breaks occurred in panel
fixed-effects models, without requiring the researcher to pre-specify
the timing or location of any break.

{pstd}
{bf:Why use xtgets?}  Traditional panel estimators (e.g. TWFE, diff-in-diff)
require the researcher to specify exactly which units were treated and when.
{cmd:xtgets} reverses this logic: it starts from the outcome and
{it:discovers} treatment timing, magnitude, and assignment by searching over
a large set of candidate break indicators and retaining only those that are
statistically significant.  This is what Pretis and Schwarz (2022) call the
{bf:reverse causal} approach.

{pstd}
{bf:How does it work?}

{p 8 11 2}1.  A {bf:candidate indicator matrix} is constructed from thousands of
potential break dummies.  The type of dummies depends on the saturation method
chosen (e.g. FESIS creates step-shifts per unit, IIS creates impulse dummies per
observation).{p_end}

{p 8 11 2}2.  Each candidate indicator is pre-screened by an {bf:individual t-test}
against the base model (regressors + fixed effects).  Only indicators whose
|t| >= tlimit survive screening.{p_end}

{p 8 11 2}3.  All surviving indicators enter a {bf:joint regression} and are
iteratively eliminated one by one (backward elimination), dropping the least
significant indicator at each step, until all remaining indicators satisfy
|t| >= tlimit.{p_end}

{p 8 11 2}4.  The {bf:final model} is estimated with regressors + fixed effects +
retained indicators, and results are displayed in the standard Stata regression
table together with a formatted summary of detected breaks.{p_end}

{pstd}
{bf:Important design feature:  Two-stage selection.}  When structural indicators
(FESIS/CSIS/CFESIS/TIS/JSIS) are combined with outlier indicators (IIS/JIIS),
selection occurs in two stages:

{p 8 11 2}{bf:Stage 1:} Structural break indicators are selected first.
These capture permanent level shifts or coefficient changes.{p_end}

{p 8 11 2}{bf:Stage 2:} Outlier indicators (IIS/JIIS) are then selected conditional
on the Stage 1 retained indicators.  This prevents impulse dummies from absorbing
structural breaks that should be captured as parsimonious step-shifts.{p_end}

{pstd}
{bf:Connection to difference-in-differences.}  Pretis and Schwarz (2022, Theorem 1)
prove that a TWFE model saturated with FESIS indicators nests the standard
staggered diff-in-diff (DID) estimator as a special case.  If treatment is a simple
step-shift in the intercept for a subset of units, FESIS recovers exactly the same
estimator as a correctly specified DID design.  The advantage of {cmd:xtgets} is
that it does not require prior knowledge of which units are treated or when
treatment occurred.


{title:Indicator Saturation Methods in Detail}

{pstd}
This section explains each indicator saturation method in depth, including
what it detects, how the indicator matrix is constructed, how to interpret
retained indicators, and when to use each method.


{dlgtab:IIS - Impulse Indicator Saturation}

{pstd}
{bf:What it detects:}  Unit-specific one-time outliers (abnormal values at a single
observation).  These can be measurement errors, one-off shocks (e.g. a natural
disaster), crises, or unusual data points.

{pstd}
{bf:Indicator matrix:}  IIS creates one 0/1 impulse dummy for every observation in
the panel.  In a panel with N units and T time periods, this produces
N x T candidate indicators.  For example, the indicator _iis_3_2008 equals 1 only
for unit 3 in year 2008 and 0 everywhere else.

{pstd}
{bf:Interpretation:}  A retained IIS indicator {cmd:iis}{it:i.t} with coefficient
beta means that the dependent variable for unit {it:i} at time {it:t} was
unexpectedly high (beta > 0) or low (beta < 0) by that magnitude, conditional on
the model.  Think of it as a cleaned residual: the model could not explain this
observation without a special dummy.

{pstd}
{bf:Relationship to robust estimation:}  IIS is mathematically equivalent to a
Huber-skip robust estimator (Hendry, Johansen, and Santos, 2008; Johansen and
Nielsen, 2009).  It identifies observations with large residuals and effectively
down-weights them.

{pstd}
{bf:When to use:}  Always consider using IIS in combination with structural methods
(FESIS, CSIS, etc.).  This ensures that outliers do not distort the detection of
permanent structural breaks.  IIS alone does not distinguish between a one-time
shock and the first period of a permanent shift.

{pstd}
{bf:Practical tip:}  With large panels, IIS adds many candidates (N*T), which
increases the false discovery rate.  Use stricter thresholds (smaller t_pval).

{pstd}
{bf:Example:}  An impulse in 2002 for country 4 (iis4.2002) with coefficient -0.14
means that country 4's dependent variable was 0.14 units below what the model
predicted for that single year, possibly due to a recession or data anomaly.


{dlgtab:FESIS - Fixed-Effect Step Indicator Saturation}

{pstd}
{bf:What it detects:}  Permanent level shifts (step-changes) in a unit's intercept.
This is the most commonly used method.  It answers: "Did unit {it:i} experience a
permanent upward or downward shift in its outcome starting at time {it:t}?"

{pstd}
{bf:Indicator matrix:}  FESIS creates one step dummy for every unit x time-period
combination, excluding the first time period (since a step at t=1 spans the entire
sample and is collinear with the unit fixed effect).  In a panel with N units and
T periods, this yields N x (T-1) candidate indicators.  For example,
_fesis_3_2008 equals 1 for unit 3 from year 2008 onward, and 0 before 2008.

{pstd}
{bf:Interpretation:}  A retained FESIS indicator {cmd:fesis}{it:i.t} with
coefficient tau means that unit {it:i} experienced a permanent change in its
intercept of magnitude tau starting from period {it:t}.  This is exactly the causal
treatment effect in a staggered DID framework:

{p 8 8 2}{c -} tau > 0: unit {it:i}'s outcome permanently {it:increased} by tau units from
period {it:t} onward, compared to the counterfactual (no break).{p_end}

{p 8 8 2}{c -} tau < 0: unit {it:i}'s outcome permanently {it:decreased} by |tau| units.{p_end}

{pstd}
{bf:Equivalence to diff-in-diff:}  Under the parallel trends assumption, a retained
FESIS coefficient is exactly the Average Treatment Effect on the Treated (ATT) for
unit {it:i} starting at time {it:t}.  The advantage over standard DID is that
{cmd:xtgets} discovers which units were treated and when, rather than requiring
this information ex ante.

{pstd}
{bf:When to use:}  Use FESIS whenever you suspect permanent (or long-lasting) level
changes in individual units, for example due to policy interventions, regime changes,
economic shocks, or any event that permanently shifts the mean of the outcome.

{pstd}
{bf:Practical examples from the literature:}

{p 8 8 2}Koch et al. (2022, Nature Energy) used FESIS to detect when EU countries
reduced road CO2 emissions, attributing reductions to specific policy mixes without
pre-specifying treatment dates.{p_end}

{p 8 8 2}Pretis and Schwarz (2022) applied FESIS to EU emissions data to detect
permanent level shifts in log(transport emissions) as a function of log(GDP) and
log(population).{p_end}

{pstd}
{bf:Example:}  fesis3.2008 with coef 0.48 and fesis7.2010 with coef -0.40 means
country 3 experienced a permanent 0.48-unit increase from 2008, while country 7
experienced a permanent 0.40-unit decrease from 2010.


{dlgtab:CSIS - Coefficient Step Indicator Saturation}

{pstd}
{bf:What it detects:}  Structural change in slope (regression) coefficients common
to all units.  While FESIS detects shifts in the {it:intercept} (level), CSIS
detects shifts in the {it:slope} (the marginal effect of a regressor on the
outcome).

{pstd}
{bf:Indicator matrix:}  For each regressor X specified in {opt csis_var()} and each
time period t (excluding the first), CSIS creates an interaction: step(t>=q) x X.
With K regressors and T periods, this yields K x (T-1) candidate indicators.  If
{opt csis_var()} is not specified, all regressors are tested.

{pstd}
{bf:Interpretation:}  A retained CSIS indicator {cmd:csis.}{it:X.t} with coefficient
delta means that the slope of variable X on the dependent variable changed by delta
for {bf:all units} starting at period {it:t}.  The total slope after the break is
the original beta + delta.  For example:

{p 8 8 2}csis.lgdp.2005 with coef -0.19 means that from 2005 onward, the elasticity
of emissions with respect to GDP decreased by 0.19 for all countries.  If the
original GDP coefficient was 0.80, then the effective coefficient from 2005 is
0.80 - 0.19 = 0.61.{p_end}

{pstd}
{bf:When to use:}  Use CSIS when you suspect that the {it:relationship} between
variables has changed over time for all units simultaneously (e.g. a global policy
shift, technological change, or structural transformation).

{pstd}
{bf:Important note:}  CSIS tests for {it:common} coefficient changes across all
units.  For {it:unit-specific} coefficient changes, use CFESIS instead.


{dlgtab:CFESIS - Coefficient-FE Step Indicator Saturation}

{pstd}
{bf:What it detects:}  Unit-specific structural change in slope coefficients.  This
is the unit-specific analogue of CSIS: it allows the marginal effect of a regressor
to change differently across individual units.

{pstd}
{bf:Indicator matrix:}  For each unit i, each candidate regressor X (from
{opt cfesis_var()}), and each time period t > 1, CFESIS creates an interaction:
I(unit=i) x step(t>=q) x X.  With N units, K regressors, and T periods, this
produces N x K x (T-1) candidate indicators, which can be very large.

{pstd}
{bf:Interpretation:}  A retained CFESIS indicator {cmd:cfesis.}{it:X.i.t} with
coefficient delta means that for unit {it:i} specifically, the slope of variable X
changed by delta starting at period {it:t}.

{pstd}
{bf:When to use:}  Use CFESIS when the effect of a variable might change differently
for different units, e.g. country-specific policy responses.  Because of the large
number of candidates (N x K x T), consider restricting to specific variables
({opt cfesis_var()}) or units ({opt cfesis_id()}) to keep computation manageable.


{dlgtab:TIS - Trend Indicator Saturation}

{pstd}
{bf:What it detects:}  Broken linear trends for specific units from specific dates.
While FESIS detects a permanent {it:level} shift (a one-time jump), TIS detects a
{it:trend} break (a gradual, linearly increasing or decreasing divergence over
time).

{pstd}
{bf:Indicator matrix:}  For each unit i and each time period t > 1, TIS creates:
trend_indicator = I(unit=i & time>=q) x (time - q + 1).  This variable equals 0
before q and increases linearly from 1, 2, 3, ... from period q onward.  Total
candidates: N x (T-1).

{pstd}
{bf:Interpretation:}  A retained TIS indicator {cmd:tis}{it:i.t} with coefficient
delta means that from period {it:t} onward, unit {it:i} had a linear trend in the
outcome that grew by delta per period.  After s periods post-break, the cumulative
effect is delta x s.

{pstd}
{bf:Example:}  tis5.2008 with coefficient 0.02 means that from 2008, unit 5's
outcome increased by 0.02 per year (cumulative: +0.02 in 2008, +0.04 in 2009,
+0.06 in 2010, etc.).

{pstd}
{bf:When to use:}  Use TIS when you expect gradual, progressive treatment effects
rather than abrupt level shifts.  For example, a new technology that diffuses
gradually, or a policy whose impact accumulates over time.  Follow
Castle, Doornik, and Hendry (2025) for the theoretical foundations.


{dlgtab:JIIS - Joint Impulse Indicator Saturation}

{pstd}
{bf:What it detects:}  Common one-time shocks affecting {bf:all} units simultaneously
at a specific time period.  Equivalent to selecting time fixed effects.

{pstd}
{bf:Indicator matrix:}  One impulse dummy per time period, common to all units.
Total candidates: T indicators.

{pstd}
{bf:Interpretation:}  A retained JIIS indicator at time {it:t} means all units
experienced a common shock (e.g. a global recession, a pandemic) at that time.

{pstd}
{bf:Collinearity warning:}  JIIS is collinear with time fixed effects.  Do {bf:not}
use {opt jiis} with {opt effect(twoways)} or {opt effect(time)} {c -} the command
will error out.  Use {opt effect(individual)} or {opt effect(none)} instead.

{pstd}
{bf:When to use:}  Use JIIS when you want to {it:select} which time effects are
significant rather than including all time effects mechanically.  This is useful
when you have many time periods and most are uninformative.


{dlgtab:JSIS - Joint Step Indicator Saturation}

{pstd}
{bf:What it detects:}  Common permanent structural breaks affecting all units
simultaneously.  This is the "joint" analogue of FESIS: instead of unit-specific
shifts, it tests for breaks common to all units at the same time.

{pstd}
{bf:Indicator matrix:}  One step dummy per time period (from t onward), common to
all units.  Total candidates: T-1 indicators.

{pstd}
{bf:Interpretation:}  A retained JSIS indicator at time {it:t} means all units
experienced a common permanent level shift starting at {it:t} (e.g. a regulatory
change affecting an entire market).

{pstd}
{bf:Collinearity note:}  JSIS indicators are typically absorbed by time fixed effects
when {opt effect(twoways)} or {opt effect(time)} is used.  The command issues a
warning, but does not error out.  Consider using {opt effect(individual)} if JSIS
is your primary interest.


{title:Fixed Effects Options}

{pstd}
The {opt effect()} option controls which fixed effects are included in the base
model.  The choice interacts with the selection of indicators and affects
collinearity.

{synoptset 18 tabbed}{...}
{synopthdr:effect()}
{synoptline}
{synopt:{cmd:twoways}} {bf:(default)} Include both unit and time fixed effects.
The first unit dummy and first time dummy are dropped to avoid collinearity with
the intercept.  This is the standard TWFE specification.  Use this in most
applications.{p_end}

{synopt:{cmd:individual}}Include only unit (individual) fixed effects.  Use when
time effects are unimportant or you want to test for common time effects via
JIIS.{p_end}

{synopt:{cmd:time}}Include only time fixed effects.{p_end}

{synopt:{cmd:none}}No fixed effects.  Useful when working with pre-demeaned data
or when fixed effects are not appropriate.{p_end}
{synoptline}


{title:Selection Threshold: t_pval and tlimit}

{pstd}
The selection threshold determines how aggressively indicators are retained.  Two
equivalent parameters control it:

{pstd}
{opt t_pval(#)} specifies a two-sided p-value.  The t-limit is computed as
tlimit = invnormal(1 - t_pval/2).  Common values:

{p 8 8 2}t_pval(0.001) -> tlimit = 3.291  (strict; R getspanel default){p_end}
{p 8 8 2}t_pval(0.01)  -> tlimit = 2.576  (moderate; commonly used){p_end}
{p 8 8 2}t_pval(0.05)  -> tlimit = 1.960  (liberal; more false positives){p_end}

{pstd}
{opt tlimit(#)} directly specifies the absolute t-statistic threshold.  If
specified (> 0), it overrides t_pval.

{pstd}
{bf:How to choose?}  Stricter thresholds (t_pval = 0.001) reduce false positives
but may miss small genuine breaks.  Looser thresholds (t_pval = 0.01 or 0.05)
detect more breaks but include more false positives.

{pstd}
{bf:Recommendation:}  Start with the default (0.001) for a conservative analysis.
Then repeat with t_pval(0.01) as a sensitivity check to see whether additional
breaks are detected.  Interpret the results jointly.


{title:False Discovery Rate Control}

{pstd}
The selection framework guarantees control of the false positive (Type I error)
rate.  Under the null hypothesis of no structural break, the probability that an
indicator is spuriously retained converges to:

{p 8 8 2}gamma_c = 2 * (1 - Phi(tlimit)){p_end}

{pstd}
where Phi() is the standard normal CDF.  This is reported after estimation as the
False Discovery Rate (FDR) section.

{pstd}
{bf:Key quantities displayed:}

{p 8 11 2}{bf:gamma_c (eq.36):} The per-indicator false positive rate.  Equals
t_pval when tlimit is derived from t_pval.{p_end}

{p 8 11 2}{bf:Total candidate indicators:} The total number of candidate indicators
generated (depends on N, T, and selected methods).{p_end}

{p 8 11 2}{bf:E[spurious retained] (eq.37):} Expected number of false positives =
gamma_c x (total candidates).  Compare this to the number of retained indicators
to judge reliability.{p_end}

{p 8 11 2}{bf:P(unit falsely treated) (eq.45):} Probability that a unit is falsely
classified as ever-treated = 1 - (1 - gamma_c)^(T-1).  With T-1 candidate break
dates per unit, the more periods you have, the higher the chance of at least one
false positive per unit.{p_end}

{pstd}
{bf:Practical guidance:}  If E[spurious retained] is close to or exceeds the number
of retained indicators, the results may be unreliable.  Tighten the threshold.


{title:Algorithm Details}

{pstd}
The GETS selection algorithm in {cmd:xtgets} proceeds as follows:

{p 8 11 2}{bf:Step 1: Fixed effects generation.}  Unit and/or time dummy variables
are created using {cmd:tab, gen()}.  For {opt effect(twoways)}, the first unit
dummy and the first time dummy are dropped to ensure identification.{p_end}

{p 8 11 2}{bf:Step 2: Indicator matrix generation.}  Mata functions construct the
candidate indicator matrices according to the selected saturation methods.  The
naming convention is: _fesis_{it:unit}_{it:year}, _iis_{it:unit}_{it:year},
_csis_{it:var}_{it:year}, etc.{p_end}

{p 8 11 2}{bf:Step 3: Two-stage GETS selection.}{p_end}

{p 12 14 2}Stage 1 (structural indicators): Each FESIS/CSIS/CFESIS/TIS/JSIS
indicator is individually tested against the base model (y = X beta + FE).
Indicators with |t| >= tlimit pass screening.  Then all screened indicators
enter a joint regression and are iteratively reduced by backward elimination
until all retain |t| >= tlimit.{p_end}

{p 12 14 2}Stage 2 (outlier indicators): Each IIS/JIIS indicator is individually
tested against the base model {it:augmented with retained structural indicators}.
Screened indicators are then jointly refined as in Stage 1.{p_end}

{p 8 11 2}{bf:Step 4: Final model.}  The final regression includes regressors,
fixed effects, and all retained indicators.  Standard OLS output is displayed,
followed by a formatted table of detected breaks with significance stars.{p_end}


{title:Interpreting Results}

{pstd}
After estimation, {cmd:xtgets} displays:

{pstd}
{bf:1. Standard regression output:}  The full OLS table with all regressors, fixed
effects, and retained indicators.  The coefficients on the regressors (e.g. lgdp,
lpop) are the estimated effects conditional on the detected structural breaks.
These are typically more reliable than uncorrected estimates because structural
breaks have been absorbed by the retained indicators.

{pstd}
{bf:2. Detected Structural Breaks table:}  A summary listing each retained
indicator with its coefficient, standard error, t-statistic, p-value, and
significance stars (*** < 0.001, ** < 0.01, * < 0.05, . < 0.10).

{pstd}
{bf:3. Diagnostics:}  SE of regression, R-squared, log-likelihood, and the
False Discovery Rate table.

{pstd}
{bf:Naming convention for retained indicators:}

{col 8}{bf:Name}{col 35}{bf:Meaning}
{col 8}{hline 60}
{col 8}fesis{it:I}.{it:Y}{col 35}Unit {it:I} had a step-shift from year {it:Y}
{col 8}iis{it:I}.{it:Y}{col 35}Unit {it:I} had an outlier at year {it:Y}
{col 8}csis.{it:X}.{it:Y}{col 35}Slope of {it:X} changed at year {it:Y} (all units)
{col 8}cfesis.{it:X}.{it:I}.{it:Y}{col 35}Slope of {it:X} changed for unit {it:I} at {it:Y}
{col 8}tis{it:I}.{it:Y}{col 35}Unit {it:I} had a trend break from {it:Y}
{col 8}jsis.{it:Y}{col 35}Common step-shift at year {it:Y} (all units)
{col 8}jiis.{it:Y}{col 35}Common impulse at year {it:Y} (all units)


{title:Choosing the Right Method}

{pstd}
The following decision guide helps you select the appropriate indicator saturation
method for your research question:

{p 8 8 2}{bf:Question 1: Do you suspect permanent level shifts for individual units?}
{break}Yes -> Use {opt fesis}.  This is the workhorse method for detecting
unknown treatment effects in a diff-in-diff framework.{p_end}

{p 8 8 2}{bf:Question 2: Do you suspect the effect of a regressor changed over time?}
{break}Yes, common to all units -> Use {opt csis}.
{break}Yes, unit-specific -> Use {opt cfesis}.{p_end}

{p 8 8 2}{bf:Question 3: Do you suspect outliers or one-time shocks?}
{break}Unit-specific -> Use {opt iis}.
{break}Common to all -> Use {opt jiis} (requires no time FE).{p_end}

{p 8 8 2}{bf:Question 4: Do you suspect gradual (trend) treatment effects?}
{break}Yes -> Use {opt tis}.{p_end}

{p 8 8 2}{bf:Question 5: Do you suspect a common structural break for all units?}
{break}Yes -> Use {opt jsis} (works best without time FE).{p_end}

{pstd}
{bf:Recommended workflow:}

{p 8 11 2}1. Start with {opt fesis} alone using the default threshold.  This
provides a baseline analysis of unit-specific level shifts.{p_end}

{p 8 11 2}2. Add {opt iis} to control for outliers: {cmd:fesis iis}.  Compare
results.  If some FESIS indicators disappear, they may have been driven by
outliers rather than genuine breaks.{p_end}

{p 8 11 2}3. If theory suggests coefficient instability, add {opt csis} or
{opt cfesis}.{p_end}

{p 8 11 2}4. Conduct sensitivity analysis by varying t_pval (0.001, 0.01, 0.05)
and comparing which breaks are robust across thresholds.{p_end}


{title:Requirements}

{pstd}
{bf:Stata version:}  Stata 15.1 or later.

{pstd}
{bf:Required setup:}  {cmd:xtset panelvar timevar} must be called before
{cmd:xtgets}.  The data must be panel data with a valid panel variable (the unit
identifier) and a valid time variable.

{pstd}
{bf:Balanced vs unbalanced panels:}  {cmd:xtgets} works with both balanced and
unbalanced panels.  However, balanced panels are recommended for FESIS and TIS
because unbalanced panels may create partially collinear indicators.

{pstd}
{bf:Sample size:}  The number of candidate indicators grows rapidly with N and T.
With large panels, computation may be slow.  Consider restricting analysis to
subsets using {opt fesis_id()}, {opt csis_var()}, etc.

{pstd}
{bf:Collinearity constraints:}

{p 8 8 2}{c -} JIIS cannot be used with {opt effect(twoways)} or {opt effect(time)}
because JIIS indicators are collinear with time dummies.{p_end}

{p 8 8 2}{c -} JSIS is typically not retained with time fixed effects for the same
reason.{p_end}


{title:Examples}

{pstd}{bf:Example 1: Basic FESIS (detecting unit-specific level shifts)}{p_end}

{pstd}This is the simplest and most common use case.  The command tests whether any
unit experienced a permanent change in its intercept:{p_end}

{phang}{cmd:. xtset country year}{p_end}
{phang}{cmd:. xtgets emissions lgdp lpop, fesis effect(twoways)}{p_end}

{pstd}This uses the default t_pval = 0.001 (=tlimit 3.291), which is very strict.
Only highly significant breaks will be retained.{p_end}

{pstd}{bf:Example 2: FESIS with moderate significance (t.pval = 0.01)}{p_end}

{pstd}A slightly looser threshold to detect more breaks:{p_end}

{phang}{cmd:. xtgets emissions lgdp lpop, fesis effect(twoways) t_pval(0.01)}{p_end}

{pstd}{bf:Example 3: Combined FESIS + IIS (two-stage selection)}{p_end}

{pstd}This adds outlier detection.  Structural breaks (FESIS) are found first,
then outliers (IIS) are detected conditional on the breaks.  This prevents
outliers from masking genuine structural shifts:{p_end}

{phang}{cmd:. xtgets emissions lgdp lpop, fesis iis effect(twoways) t_pval(0.01)}{p_end}

{pstd}{bf:Example 4: Coefficient stability testing (CSIS)}{p_end}

{pstd}Test whether the effect of GDP on emissions changed over time for all
countries:{p_end}

{phang}{cmd:. xtgets emissions lgdp lpop, csis csis_var(lgdp) effect(twoways) t_pval(0.01)}{p_end}

{pstd}{bf:Example 5: Unit-specific coefficient change (CFESIS)}{p_end}

{pstd}Test whether individual countries experienced different changes in the
GDP effect:{p_end}

{phang}{cmd:. xtgets y x1 x2, cfesis cfesis_var(x1) effect(twoways)}{p_end}

{pstd}{bf:Example 6: Trend indicator saturation (TIS)}{p_end}

{pstd}Detect gradual (linear trend) treatment effects:{p_end}

{phang}{cmd:. xtgets y x1 x2, tis effect(twoways) tlimit(2.5)}{p_end}

{pstd}{bf:Example 7: Kitchen-sink approach with verbose output}{p_end}

{pstd}Use multiple methods simultaneously with detailed output:{p_end}

{phang}{cmd:. xtgets y x1 x2, fesis iis csis csis_var(x1) effect(twoways) t_pval(0.01) verbose}{p_end}

{pstd}{bf:Example 8: Restricting FESIS to specific units}{p_end}

{pstd}Test only specific countries for structural breaks (saves computation):{p_end}

{phang}{cmd:. xtgets y x1 x2, fesis fesis_id(1 2 3) effect(twoways)}{p_end}

{pstd}{bf:Example 9: Using weights and alternative variance estimators}{p_end}

{phang}{cmd:. xtgets y x1 x2 [pw=w], fesis effect(twoways) vce(robust)}{p_end}


{title:Postestimation: Visualizations (xtgets_plot)}

{pstd}
After running {cmd:xtgets}, use {cmd:xtgets_plot} for visualizations that replicate
the R getspanel package plotting functions.

{pstd}
{bf:Syntax:}{p_end}
{p 8 16 2}{cmd:xtgets_plot} [{cmd:,} {opt type(string)} {opt sav:ing(filename)}
{opt scheme(schemename)} {opt title(string)}]


{dlgtab:type(breaks) - Break Detection Timeline}

{pstd}
Scatter plot showing the timing of detected breaks by unit.  Each dot represents
a retained indicator.  Different marker shapes and colours distinguish indicator
types (FESIS = circle, IIS = diamond, CSIS = triangle, TIS = square).

{pstd}
{it:R equivalent:} {cmd:plot(is1)}{p_end}

{phang}{cmd:. xtgets_plot, type(breaks)}{p_end}
{phang}{cmd:. xtgets_plot, type(breaks) saving(mybreaks)}{p_end}


{dlgtab:type(heatmap) - Effect Heatmap}

{pstd}
Heatmap showing the effect magnitude (coefficient) of retained indicators over
time for each unit.  Blue shades indicate positive effects; red shades indicate
negative effects.  Darker colours represent larger magnitudes.  For FESIS, the
effect extends from the break date to the end of the sample.

{pstd}
{it:R equivalent:} {cmd:plot(is1)} (heatmap view){p_end}

{phang}{cmd:. xtgets_plot, type(heatmap)}{p_end}


{dlgtab:type(grid) - Fitted vs Actual Grid}

{pstd}
A grid of small-multiple line plots, one per unit.  Each panel shows:

{p 8 8 2}{bf:Black line with + markers:} Actual values of the dependent variable.{p_end}
{p 8 8 2}{bf:Blue line:} Fitted values from the final model (including retained indicators).{p_end}
{p 8 8 2}{bf:Red vertical lines:} Dates of detected breaks.{p_end}

{pstd}
This plot helps visually assess model fit and whether breaks align with visible
changes in the data.

{pstd}
{it:R equivalent:} {cmd:plot_grid(is1)}{p_end}

{phang}{cmd:. xtgets_plot, type(grid) saving(mygrid)}{p_end}


{dlgtab:type(counter) - Counterfactual Analysis}

{pstd}
For each unit that experienced a detected break, shows the actual vs counterfactual
(predicted values without break indicators) trajectories.  The shaded area between
them represents the estimated treatment effect.

{p 8 8 2}{bf:Black line with + markers:} Actual values.{p_end}
{p 8 8 2}{bf:Red dashed line:} Counterfactual (what would have happened without the break).{p_end}
{p 8 8 2}{bf:Blue line:} Fitted values (with breaks).{p_end}
{p 8 8 2}{bf:Red shaded area:} Difference = estimated treatment effect.{p_end}

{pstd}
{it:R equivalent:} {cmd:plot_counterfactual(is1)}{p_end}

{phang}{cmd:. xtgets_plot, type(counter)}{p_end}


{dlgtab:type(residuals) - Residual Analysis}

{pstd}
Grid of residual plots by unit.  Shows residuals from the final model (including
retained indicators).  Well-behaved residuals should be centred around zero with
no visible patterns.

{pstd}
{it:R equivalent:} {cmd:plot_residuals(is1)}{p_end}

{phang}{cmd:. xtgets_plot, type(residuals)}{p_end}


{title:Stored Results}

{pstd}
{cmd:xtgets} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(n_indicators)}}Total number of candidate indicators generated{p_end}
{synopt:{cmd:e(n_retained)}}Number of retained (significant) indicators{p_end}
{synopt:{cmd:e(tlimit)}}Absolute t-statistic threshold used for selection{p_end}
{synopt:{cmd:e(t_pval)}}Two-sided p-value corresponding to tlimit{p_end}
{synopt:{cmd:e(gamma_c)}}Per-indicator false positive rate = 2*(1-Phi(tlimit)){p_end}
{synopt:{cmd:e(N_units)}}Number of panel units (N){p_end}
{synopt:{cmd:e(T_periods)}}Number of time periods (T){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtgets}{p_end}
{synopt:{cmd:e(effect)}}Fixed effects specification used{p_end}
{synopt:{cmd:e(depvar)}}Name of the dependent variable{p_end}
{synopt:{cmd:e(xvars)}}Names of the regressors{p_end}
{synopt:{cmd:e(ivar)}}Panel (unit) variable name{p_end}
{synopt:{cmd:e(tvar)}}Time variable name{p_end}
{synopt:{cmd:e(retained)}}Space-separated list of retained indicator variable names{p_end}
{synopt:{cmd:e(fesis)}}"yes" if FESIS method was activated{p_end}
{synopt:{cmd:e(iis)}}"yes" if IIS method was activated{p_end}
{synopt:{cmd:e(csis)}}"yes" if CSIS method was activated{p_end}
{synopt:{cmd:e(cfesis)}}"yes" if CFESIS method was activated{p_end}
{synopt:{cmd:e(tis)}}"yes" if TIS method was activated{p_end}
{synopt:{cmd:e(jiis)}}"yes" if JIIS method was activated{p_end}
{synopt:{cmd:e(jsis)}}"yes" if JSIS method was activated{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}Coefficient vector from the final regression{p_end}
{synopt:{cmd:e(V)}}Variance-covariance matrix from the final regression{p_end}

{pstd}
{bf:Accessing retained indicators programmatically:}{p_end}
{phang}{cmd:. local breaks `e(retained)'}{p_end}
{phang}{cmd:. foreach b of local breaks {c -(}}{p_end}
{phang}{cmd:.     di "`b':  " _b[`b']}{p_end}
{phang}{cmd:. {c )-}}{p_end}


{title:Mathematical Background}

{pstd}
The base panel model estimated by {cmd:xtgets} is:

{p 8 8 2}y_it = alpha_i + gamma_t + X_it * beta + Z_it * delta + u_it{p_end}

{pstd}
where:

{p 8 8 2}{c -} y_it is the dependent variable for unit i at time t{p_end}
{p 8 8 2}{c -} alpha_i are unit fixed effects{p_end}
{p 8 8 2}{c -} gamma_t are time fixed effects{p_end}
{p 8 8 2}{c -} X_it are the specified regressors{p_end}
{p 8 8 2}{c -} Z_it are the retained indicator variables (selected by GETS){p_end}
{p 8 8 2}{c -} u_it is the error term{p_end}

{pstd}
The indicator matrix Z contains only the indicators that survived the GETS
selection procedure.  Under the null that Z_it = 0 for all i,t (no breaks),
the probability of spuriously retaining indicator k is:

{p 8 8 2}P(|t_k| > c) = 2 * (1 - Phi(c)) = gamma_c{p_end}

{pstd}
For m total candidate indicators, the expected number of false positives is
m * gamma_c.  This is the gauge of the test.  Pretis and Schwarz (2022, eq. 37)
show that this provides asymptotic control analogous to Bonferroni-type corrections
but with higher power due to the sequential elimination procedure.

{pstd}
{bf:Theorem 1 (Pretis and Schwarz 2022):}  In a TWFE model, FESIS-saturated panel
GETS nests the standard staggered DID estimator.  If treatment is a clean
step-shift, the FESIS coefficient exactly equals the ATT.


{title:References}

{phang}
Pretis, F. and Schwarz, M. (2022/2026). Discovering What Mattered: Detecting Unknown
Treatment as Breaks in Panel Models.
{it:Available at SSRN}: {browse "https://ssrn.com/abstract=4022745":https://ssrn.com/abstract=4022745}.{p_end}

{phang}
Schwarz, M. and Pretis, F. (2026). getspanel: General-to-Specific Modelling of
Panel Data. R package version 0.2.1.
{browse "https://CRAN.R-project.org/package=getspanel":CRAN}.{p_end}

{phang}
Castle, J.L., Doornik, J.A. and Hendry, D.F. (2015). Detecting Location Shifts
during Model Selection by Step-Indicator Saturation.
{it:Econometrics} 3(2): 240-264.{p_end}

{phang}
Castle, J.L., Doornik, J.A. and Hendry, D.F. (2025). Trend-Indicator Saturation.
{it:Oxford Bulletin of Economics and Statistics}.{p_end}

{phang}
Clarke, D.C. (2013). gets: General to Specific algorithm for model selection.
Stata package, University of Oxford.{p_end}

{phang}
Hendry, D.F., Johansen, S. and Santos, C. (2008). Automatic Selection of
Indicators in a Fully Saturated Regression. {it:Computational Statistics} 23: 317-335.{p_end}

{phang}
Johansen, S. and Nielsen, B. (2009). An Analysis of the Indicator Saturation
Estimator as a Robust Regression Estimator. In Castle, J.L. and Shephard, N. (eds.)
{it:The Methodology and Practice of Econometrics}. Oxford University Press.{p_end}

{phang}
Koch, N., Naumann, L., Pretis, F., Schwarz, M. and zu Ermgassen, S. (2022).
Attributing agnostically detected large reductions in road CO2 emissions to
policy mixes. {it:Nature Energy} 7: 844-853.{p_end}

{phang}
Wooldridge, J.M. (2025). Two-Way Fixed Effects, the Two-Way Mundlak Regression,
and Difference-in-Differences Estimators. {it:Econometric Review}.{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{p_end}
{pstd}{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:Also see}

{psee}
{helpb xtreg}, {helpb regress}, {helpb xtset}
{p_end}
