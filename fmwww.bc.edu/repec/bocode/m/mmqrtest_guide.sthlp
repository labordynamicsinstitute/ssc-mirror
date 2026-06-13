{smcl}
{* *! version 1.0.1 12jun2026}{...}
{vieweralsosee "mmqrtest" "help mmqrtest"}{...}
{vieweralsosee "mmqrtest scalepos" "help mmqrtest_scalepos"}{...}
{vieweralsosee "mmqrtest scalerel" "help mmqrtest_scalerel"}{...}
{vieweralsosee "mmqrtest spec" "help mmqrtest_spec"}{...}
{vieweralsosee "mmqrtest distfe" "help mmqrtest_distfe"}{...}
{vieweralsosee "mmqrtest canay" "help mmqrtest_canay"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{viewerjumpto "Why test an MM-QR model?" "mmqrtest_guide##why"}{...}
{viewerjumpto "The recommended workflow" "mmqrtest_guide##workflow"}{...}
{viewerjumpto "Test 1: scale positivity" "mmqrtest_guide##t1"}{...}
{viewerjumpto "Test 2: scale relevance" "mmqrtest_guide##t2"}{...}
{viewerjumpto "Test 3: location-scale specification" "mmqrtest_guide##t3"}{...}
{viewerjumpto "Test 4: distributional fixed effects" "mmqrtest_guide##t4"}{...}
{viewerjumpto "Test 5: Canay location shift" "mmqrtest_guide##t5"}{...}
{viewerjumpto "Reading the verdicts jointly" "mmqrtest_guide##joint"}{...}
{viewerjumpto "Small samples and short panels" "mmqrtest_guide##smallT"}{...}
{viewerjumpto "Reporting in a paper" "mmqrtest_guide##report"}{...}
{viewerjumpto "FAQ" "mmqrtest_guide##faq"}{...}
{viewerjumpto "References" "mmqrtest_guide##references"}{...}
{title:Title}

{phang}
{bf:mmqrtest guide} {hline 2} A researcher's guide to testing MM-QR panel
quantile models: what each test does, when to run it, and how to interpret
and report the results

{pstd}
(Type {cmd:mmqrtest guide} in Stata to open this page.)


{marker why}{...}
{title:1. Why test an MM-QR model at all?}

{pstd}
Method-of-moments quantile regression (MM-QR; Machado and Santos Silva
2019, henceforth {it:MSS}) has become the workhorse for panel quantile
applications because it allows individual effects to shift the {it:entire}
conditional distribution while remaining as easy to compute as a within
estimator.  That convenience is bought with structure.  MM-QR assumes the
{bf:location-scale} data generating process

{p 8 8 2}
{it:Y_it} = {it:alpha_i} + {it:X_it'beta} +
({it:delta_i} + {it:X_it'gamma}){it:U_it},

{pstd}
with {it:U_it} i.i.d. and independent of the regressors, and with the
fitted scale strictly positive.  Everything an applied paper reports from
MM-QR {hline 2} the quantile coefficient paths, their standard errors,
the non-crossing property {hline 2} is valid {bf:only under these
restrictions}.  MSS are explicit that the restrictions are testable
(their sec. 1, fn. 5, and sec. 7) but do not develop the tests.
{cmd:mmqrtest} provides them.  A referee can reasonably ask for every one
of these diagnostics; running {cmd:mmqrtest all} answers all of them in
one screen.

{pstd}
Three distinct questions are involved, and it helps to keep them apart:

{p 8 12 2}
(a) {bf:Is the model internally coherent on my data?}
(test 1: positivity)

{p 8 12 2}
(b) {bf:Is the location-scale family rich enough for my data?}
(test 3: specification)

{p 8 12 2}
(c) {bf:Within the family, which special cases can I rule out?}
(test 2: any scale effects at all; tests 4-5: are fixed effects more than
location shifters)


{marker workflow}{...}
{title:2. The recommended workflow}

{p 8 12 2}
{bf:Step 1.}  {cmd:mmqreg} {it:y x ...}{cmd:, absorb(}{it:id}{cmd:)}
{cmd:quantile(25 50 75) cluster(}{it:id}{cmd:)}

{p 8 12 2}
{bf:Step 2.}  {cmd:mmqrtest scalepos} {hline 2} if it returns VIOLATION
for more than a handful of observations, stop and respecify (transform
regressors, add scale covariates) before reading anything else.

{p 8 12 2}
{bf:Step 3.}  {cmd:mmqrtest spec} {hline 2} if the location-scale family
itself is rejected, MM-QR quantile paths are misspecified; see section 6
below for what to do.

{p 8 12 2}
{bf:Step 4.}  {cmd:mmqrtest scalerel} {hline 2} establishes whether there
is any distributional story to tell.  If gamma = 0 is not rejected, your
quantile slopes are statistically flat and a conditional-mean model says
it all.

{p 8 12 2}
{bf:Step 5.}  {cmd:mmqrtest distfe} and {cmd:mmqrtest canay} {hline 2}
adjudicate between MM-QR and the simpler location-shift tradition
(Koenker 2004; Canay 2011).

{pstd}
{cmd:mmqrtest all} runs steps 2-5 in this order and prints the verdict
summary.


{marker t1}{...}
{title:3. Test 1 {hline 2} scale positivity ({helpb mmqrtest_scalepos:scalepos})}

{pstd}
{bf:Intuition.}  MM-QR divides each residual by its fitted scale to
recover the standardized error {it:U}.  If the fitted scale
{it:delta_i} + {it:X'gamma} is zero or negative for some observation, the
standardization is meaningless there, the estimated quantile function can
cross, and the asymptotic theory does not apply.  MSS impose
Pr({it:delta_i} + {it:X'gamma} > 0) = 1 as part of the model (eq. 5);
{cmd:mmqreg} itself prints a warning when fitted scales go negative.

{pstd}
{bf:What is computed.}  The fitted scale for every in-sample observation;
counts and shares of violations; the units affected; the unit intercepts
{it:delta_i} that are non-positive.

{pstd}
{bf:Interpreting PASS.}  The model is internally coherent on your sample.
Nothing more {hline 2} positivity does not validate the other assumptions.

{pstd}
{bf:Interpreting VIOLATION.}  Distinguish two cases.  (i) A handful of
observations (well under 1 percent) in extreme regions of the X-space:
results are usually robust, but report the share and re-estimate without
those observations as a robustness check.  (ii) A non-trivial share: the
linear scale specification is wrong for your data.  Common fixes: use
logged or otherwise transformed regressors; remove regressors with
extreme outliers from the scale; or use an exponential scale model
(MSS sec. 3.2 suggest sigma = exp(.), which is positive by construction
{hline 2} note that {cmd:mmqreg}/{cmd:mmqrtest} implement the linear
scale).

{pstd}
{bf:Report as:}  "The fitted MM-QR scale function is strictly positive
for all NT observations (mmqrtest; Roudane 2026), as required by the
location-scale model of Machado and Santos Silva (2019, eq. 5)."


{marker t2}{...}
{title:4. Test 2 {hline 2} scale relevance ({helpb mmqrtest_scalerel:scalerel})}

{pstd}
{bf:Intuition.}  In MM-QR every quantile slope is
{it:beta_l(tau)} = {it:beta_l} + {it:q(tau)gamma_l}.  All the variation
of the coefficients across quantiles {hline 2} the entire reason for
running quantile regression {hline 2} flows through {it:gamma}.  If
{it:gamma} = 0, the tau = 0.25 and tau = 0.75 coefficients are the
{it:same number}, and apparent differences in the output table are pure
sampling noise.

{pstd}
{bf:What is computed.}  A joint Wald test of all scale-equation slopes,
straight from the {cmd:e(b)}/{cmd:e(V)} of your {cmd:mmqreg} fit (so it
automatically uses your analytic, robust, cluster, or jackknife VCE; the
asymptotic justification is MSS Theorem 2).  This is the only member of
the battery whose distribution theory is fully worked out in the paper,
which makes it the safest test to headline.

{pstd}
{bf:Interpreting rejection.}  There are genuine distributional effects:
at least one regressor changes the spread of the outcome, and quantile
slopes truly differ across tau.  Inspect the per-coefficient table to see
{it:which} regressors drive it, and the sign: a positive {it:gamma_l}
means regressor {it:l} raises dispersion (steeper effect at upper
quantiles); a negative one compresses the distribution.

{pstd}
{bf:Interpreting non-rejection.}  Quantile slopes are statistically flat.
This does not mean MM-QR is wrong {hline 2} it means it is unnecessary:
a fixed-effects mean regression summarizes the covariate effects.  If
your research question is specifically about heterogeneity across the
distribution, a non-rejection here is itself a (publishable) finding.

{pstd}
{bf:Report as:}  "A Wald test of the joint nullity of the scale
coefficients (Machado and Santos Silva 2019, Thm. 2; computed with
mmqrtest) rejects at the 1 percent level (chi2(k) = ..., p = ...),
confirming that the covariates affect the dispersion and not merely the
location of the outcome."


{marker t3}{...}
{title:5. Test 3 {hline 2} location-scale specification ({helpb mmqrtest_spec:spec})}

{pstd}
{bf:Intuition.}  Location-scale means covariates may move the
distribution's center and stretch it, but may {it:not} reshape it:
conditional skewness, kurtosis, and all standardized quantiles of
{it:U} must be the same at every value of X.  The overidentifying
content is that {it:U} is independent of X {hline 2} beyond the moments
already used in estimation.  MSS point to Hansen (1982)/Newey (1985)
overidentification tests and to "simpler regression-based procedures"
(fn. 5; sec. 7); {cmd:mmqrtest spec} is that regression-based version.

{pstd}
{bf:What is computed.}  Three blocks of cluster-robust Wald tests of
auxiliary functions w(X) (default: squares and small-k cross-products of
the regressors) in regressions of (A) {it:U}-hat, (B) |{it:U}-hat|-1, and
(C) the quantile indicator residual tau - I({it:U}-hat <= q-hat(tau)) on
w(X) and X.  Block A probes the location specification, block B the scale
specification, block C the shape restriction at each requested tau.  The
overall p-value is a conservative Bonferroni combination.

{pstd}
{bf:Interpreting rejection.}  Look at {it:which} block fired.  Block A:
the conditional mean is misspecified (nonlinearity in X) {hline 2}
consider adding polynomial or interaction terms to the model itself.
Block B: the scale is misspecified (e.g. variance depends on X
nonlinearly) {hline 2} same remedy on the scale side.  Block C alone,
with A and B quiet: a genuine {bf:shape effect}; covariates alter
skewness or tails.  Then no location-scale model fits, and the honest
options are (i) traditional quantile regression with location-shift
fixed effects if tests 4-5 support it, (ii) Chernozhukov-Hansen-type IVQR,
or (iii) reporting MM-QR with an explicit caveat that it approximates only
the location and scale channels (MSS sec. 7 discuss this reading).

{pstd}
{bf:Interpreting non-rejection.}  The data do not contradict the
location-scale family; MM-QR's structure is adequate.  Remember the test
is conservative (Bonferroni) and its power depends on the chosen w(X):
absence of evidence at default w(X) is not proof.  For sensitivity, rerun
with {opt aux()} containing cubes or interactions with suspected drivers.

{pstd}
{bf:Report as:}  "Regression-based overidentification tests of the
location-scale restriction (Machado and Santos Silva 2019, fn. 5;
implemented in mmqrtest) do not reject the specification (Bonferroni
p = ...), supporting the use of MM-QR."


{marker t4}{...}
{title:6. Test 4 {hline 2} distributional fixed effects ({helpb mmqrtest_distfe:distfe})}

{pstd}
{bf:Intuition.}  The quantile-tau fixed effect in MM-QR is
{it:alpha_i(tau)} = {it:alpha_i} + {it:delta_i q(tau)} (MSS eq. 6).
Whether this is a real generalization of the older location-shift
tradition depends entirely on whether {it:delta_i} varies across units.
If {it:delta_i} = {it:delta} for everyone, the term {it:delta q(tau)} is
common to all units and individual heterogeneity reduces to a pure
location shift {hline 2} the world assumed by Koenker (2004) and Canay
(2011).  Note the correct null is {bf:homogeneity}, not
{it:delta_i} = 0: a common positive {it:delta} is in fact required for
scale positivity whenever {it:X'gamma} can be small.

{pstd}
{bf:What is computed.}  The classical fixed-effects equality F statistic
in the Glejser scale regression of |{it:R_it}| on X (Step 3 of the MM-QR
algorithm), comparing a common intercept against unit intercepts; plus
descriptive statistics of the estimated {it:delta_i} and their
correlation with the location effects {it:alpha_i}.

{pstd}
{bf:Interpreting rejection.}  Time-invariant unit characteristics affect
the {it:spread} of the outcome, not just its level.  Substantively this
is often interesting in itself (e.g. some firms/countries are
systematically more volatile).  Econometrically it is decisive: it rules
out location-shift estimators and is the strongest argument for MM-QR in
a paper.  The corr({it:alpha_i}, {it:delta_i}) line tells you whether
high-level units are also high-volatility units.

{pstd}
{bf:Interpreting non-rejection.}  Individual effects act as location
shifters.  MM-QR remains consistent (it nests this case), so nothing is
wrong with your estimates {hline 2} but Canay-type estimators are also
valid and may be more precise (MSS fn. 17 report lower standard errors
for Canay when its restriction is true).

{pstd}
{bf:Caveats.}  {it:delta_i}-hat converges at rate sqrt(T); with very
short panels the F test can be size-distorted, and a warning is printed
when average T < 10.  Borderline p-values (0.01-0.10) in short panels
should be read together with the sd({it:delta_i}) descriptive: a tiny
dispersion with a marginal p is not economic evidence of distributional
fixed effects.

{pstd}
{bf:Report as:}  "An F test of equality of the unit-specific scale
intercepts (mmqrtest) rejects decisively (F(G-1, N-G-k) = ...,
p < 0.01): individual effects are distributional rather than pure
location shifts, motivating MM-QR over the estimators of Koenker (2004)
and Canay (2011)."


{marker t5}{...}
{title:7. Test 5 {hline 2} Canay location-shift validity ({helpb mmqrtest_canay:canay})}

{pstd}
{bf:Intuition.}  Test 4 examines the structural parameter ({it:delta_i});
test 5 examines its {it:consequence}: if fixed effects are location
shifters, the Canay (2011) two-step slopes and the MM-QR slopes estimate
the same quantile coefficients, so their difference should be sampling
noise.  If not, Canay's estimator is inconsistent and the two paths
diverge {hline 2} exactly the pattern in MSS's simulations (their fn. 17)
and in their Table 6 application, where Canay's estimates are flat across
quantiles while MM-QR's vary.

{pstd}
{bf:What is computed.}  Both estimators on your data; the per-tau
contrast Delta(tau); its covariance from a pairs cluster bootstrap that
resamples whole units (no analytic joint distribution exists in either
paper, so the bootstrap is the appropriate route); chi-squared statistics
per tau and a Bonferroni overall p-value.  The {opt graph} option overlays
the two coefficient paths with bootstrap confidence bands {hline 2} a
figure worth putting in an appendix.

{pstd}
{bf:Interpreting rejection.}  Where do the paths separate?  Typically the
divergence is largest at extreme tau and zero near the median (both
estimators agree at the center by construction when the scale is
symmetric); that pattern is itself diagnostic of scale-type fixed
effects.  Conclusion for practice: location-shift estimators understate
the quantile heterogeneity; use MM-QR.

{pstd}
{bf:Interpreting non-rejection.}  The simpler Canay transformation is
not contradicted.  If precision matters more than generality (small G,
many regressors), Canay's estimator becomes a legitimate, often tighter,
alternative {hline 2} and agreement between the two methods is a
robustness result referees value.

{pstd}
{bf:Practical settings.}  Use {opt reps(500)} and {opt seed()} for
reproducible publication numbers; 200 replications are adequate for
exploration.  Slopes only are compared; intercepts are not separately
identified across the two normalizations.

{pstd}
{bf:Report as:}  "A bootstrap Hausman-type contrast between the Canay
(2011) and MM-QR coefficient paths (mmqrtest, 500 cluster-bootstrap
replications) rejects the location-shift restriction at tau = 0.25 and
0.75 (overall Bonferroni p = ...), in line with the heterogeneity of the
scale fixed effects found above."


{marker joint}{...}
{title:8. Reading the verdicts jointly}

{pstd}
The five verdicts are designed to be read as a pattern.  The common
configurations:

{p2colset 5 38 40 2}{...}
{p2col:{bf:Pattern (1,2,3,4,5)}}{bf:Reading}{p_end}
{p2col:PASS, NR, NR, NR, NR}No distributional story: report fixed-effects
mean regression, or MM-QR as a robustness table.  (NR = not rejected.){p_end}
{p2col:PASS, R, NR, NR, NR}Scale effects through covariates only; both
MM-QR and Canay are valid; MM-QR slopes vary with tau and either method
may be reported {hline 2} agreement is a robustness check.{p_end}
{p2col:PASS, R, NR, R, R}The full MM-QR case: distributional fixed
effects present, location-shift estimators invalid.  MM-QR is the right
tool; say so citing tests 4-5.{p_end}
{p2col:PASS, ., R, ., .}The location-scale family itself fails: do not
lean on MM-QR quantile paths.  See section 5 for options.  (Tests 2,4,5
remain interpretable as descriptions of location/scale channels.){p_end}
{p2col:VIOLATION, ., ., ., .}Fix the scale specification first; all other
verdicts are provisional.{p_end}
{p2colreset}{...}

{pstd}
Two consistency checks worth knowing.  First, tests 4 and 5 usually agree
(heterogeneous {it:delta_i} is the structural cause of Canay's failure);
if 4 rejects and 5 does not, suspect low bootstrap power (raise
{opt reps()}, check G).  Second, if test 2 does not reject, tests 4-5 lose
their practical bite even when they reject: with gamma = 0 the quantile
slopes are flat regardless of who estimates them.


{marker smallT}{...}
{title:9. Small samples and short panels}

{p 8 12 2}
{c 149} MM-QR objects carry O(1/T) incidental-parameter biases (MSS,
Theorem 4); all subcommands print a warning when average T < 10.

{p 8 12 2}
{c 149} For short panels prefer {cmd:mmqreg, jknife} (the split-panel
jackknife of Dhaene and Jochmans 2015, integrated in mmqreg v2.4+) for
estimation, and read borderline test p-values (0.01-0.10) with caution.

{p 8 12 2}
{c 149} The distfe F test and the spec Wald tests are asymptotic;
their finite-sample size is close to nominal in our simulation designs
(n = 100, T = 20) but rises as T falls.

{p 8 12 2}
{c 149} For the canay test, power comes from G (number of units): with
G < 50 expect low power and prefer reps(500+).


{marker report}{...}
{title:10. A reporting template}

{pstd}
A compact diagnostics paragraph for the estimation section of a paper:

{p 8 8 2}
{it:"Before turning to the estimates, we verify the assumptions of the}
{it:MM-QR model using the mmqrtest battery (Roudane 2026).  The fitted}
{it:scale function is strictly positive for all observations, and}
{it:regression-based overidentification tests do not reject the}
{it:location-scale specification (Bonferroni p = 0.82).  A Wald test of}
{it:the scale coefficients rejects gamma = 0 (chi2(2) = 45.7, p < 0.01),}
{it:confirming genuine heterogeneity across quantiles.  Finally, the}
{it:unit-specific scale intercepts are strongly heterogeneous}
{it:(F(99, 1899) = 3.01, p < 0.01) and a bootstrap Hausman contrast}
{it:rejects the location-shift restriction of Canay (2011) (p < 0.01),}
{it:so estimators treating individual effects as pure location shifts}
{it:would be inconsistent here.  These results support the MM-QR}
{it:specification used below."}

{pstd}
Pair it with two figures from the battery: the distfe location-scale
fixed-effects map, and the canay coefficient-path comparison.


{marker faq}{...}
{title:11. FAQ}

{pstd}
{bf:Do I need to run mmqreg first?}  No, every subcommand has a
standalone syntax ({cmd:mmqrtest spec y x1 x2, id(ivar)}), but the
postestimation route is recommended because scalerel then inherits your
exact VCE.

{pstd}
{bf:My panel is unbalanced.}  All tests handle unbalanced panels; T in
the warnings refers to the average.

{pstd}
{bf:Can I use factor variables?}  Yes ({cmd:i.}, interactions); they are
expanded internally and base/omitted levels are dropped.

{pstd}
{bf:What about two-way (unit and time) fixed effects?}  Not covered: the
testing theory, like MSS's own results, is for one-way individual
effects (MSS sec. 7 list two-way effects as an open problem).  Including
time dummies as regressors is fine; absorbing a second dimension is not.

{pstd}
{bf:A few observations violate positivity {hline 2} is everything lost?}
No.  Report the share, note that U-based tests exclude them, and show
robustness of the main estimates to dropping them.  Large shares (above
a few percent) do require respecification.

{pstd}
{bf:spec rejects but only in block A.}  That is a location (conditional
mean) misspecification, not a quantile-specific problem: enrich the
regression function and rerun.

{pstd}
{bf:distfe rejects at p = 0.04 with T = 15.}  Borderline: check
sd(delta_i) for economic size, rerun with the jackknifed mmqreg, and
treat the canay test as the tie-breaker.

{pstd}
{bf:How many bootstrap replications?}  200 to explore, 500 for the paper,
1000 if the p-value sits near your significance threshold.


{marker references}{...}
{title:References}

{phang}
Canay, I. A. 2011.  A simple approach to quantile regression for panel
data.  {it:The Econometrics Journal} 14: 368-386.
{browse "https://doi.org/10.1111/j.1368-423X.2011.00349.x"}

{phang}
Dhaene, G., and K. Jochmans. 2015.  Split-panel jackknife estimation of
fixed-effect models.  {it:Review of Economic Studies} 82: 991-1030.
{browse "https://doi.org/10.1093/restud/rdv007"}

{phang}
Glejser, H. 1969.  A new test for heteroskedasticity.
{it:Journal of the American Statistical Association} 64: 316-323.
{browse "https://doi.org/10.1080/01621459.1969.10500976"}

{phang}
Hansen, L. P. 1982.  Large sample properties of generalized method of
moments estimators.  {it:Econometrica} 50: 1029-1054.
{browse "https://doi.org/10.2307/1912775"}

{phang}
Koenker, R. 2004.  Quantile regression for longitudinal data.
{it:Journal of Multivariate Analysis} 91: 74-89.
{browse "https://doi.org/10.1016/j.jmva.2004.05.006"}

{phang}
Machado, J. A. F., and J. M. C. Santos Silva. 2019.  Quantiles via moments.
{it:Journal of Econometrics} 213: 145-173.
{browse "https://doi.org/10.1016/j.jeconom.2019.04.009"}

{phang}
Newey, W. K. 1985.  Generalized method of moments specification testing.
{it:Journal of Econometrics} 29: 229-256.
{browse "https://doi.org/10.1016/0304-4076(85)90154-X"}


{title:Author}

{pstd}
Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane"}
