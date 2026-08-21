{smcl}
{* *! version 1.0.0  09aug2026}{...}
{vieweralsosee "xtasym" "help xtasym"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{viewerjumpto "Notation" "xtasym_methods##notation"}{...}
{viewerjumpto "S1 first differences" "xtasym_methods##s1"}{...}
{viewerjumpto "S2 thresholded decomposition" "xtasym_methods##s2"}{...}
{viewerjumpto "S3 partial sums" "xtasym_methods##s3"}{...}
{viewerjumpto "Equivalence of the conventions" "xtasym_methods##equiv"}{...}
{viewerjumpto "Why accumulate" "xtasym_methods##why"}{...}
{viewerjumpto "S4 frequency table" "xtasym_methods##s4"}{...}
{viewerjumpto "S5 within and between" "xtasym_methods##s5"}{...}
{viewerjumpto "S6 CD statistic" "xtasym_methods##s6"}{...}
{viewerjumpto "S7 CIPS" "xtasym_methods##s7"}{...}
{viewerjumpto "Step to equation map" "xtasym_methods##map"}{...}
{viewerjumpto "Choosing an estimator" "xtasym_methods##choose"}{...}
{viewerjumpto "Limitations" "xtasym_methods##limits"}{...}
{hi:help xtasym methods}{right:Version 1.0.0  9 August 2026}
{hline}

{title:Title}

{phang}
{bf:xtasym methods} {hline 2} the algebra behind {helpb xtasym}, step by step,
and how each step maps onto the source papers


{marker notation}{title:Notation}

{pstd}
Panels are indexed by i = 1, ..., n and periods by t = 1, ..., T. x(i,t) is the
value of a variable for panel i in period t. c >= 0 is the threshold set by
{cmd:threshold()}. Increases are written with a plus superscript and decreases
with a minus superscript.


{marker s1}{title:S1. First differences}

{pstd}
The command forms

{p 8 8 2}dx(i,t) = x(i,t) - x(i,t-1)

{pstd}
using Stata's {cmd:D.} operator, so the panel and time structure declared by
{helpb xtset} is respected. dx is missing in the first period of every panel and
across any gap in the time variable. Missing first differences contribute
nothing anywhere below: they are not treated as zeros.

{pstd}
This last point is a deliberate difference from the replication code circulated
with Allison (2019) and with Thombs et al. (2022), which sets the missing first
difference to zero with {cmd:replace dx = 0 if dx == .} before accumulating.
The two are numerically identical when the panel is balanced with no gaps,
because Stata's {cmd:sum()} treats missing as zero anyway. They differ when the
time variable has gaps, and treating a gap as a period of no change would be
wrong.


{marker s2}{title:S2. Thresholded decomposition}

{pstd}
The first difference is split into an increase part and a decrease part around
a symmetric dead band of half-width c:

{p 8 8 2}dx{c 43}(i,t) = dx(i,t){space 3}if dx(i,t) >  {c 43}c,{space 3}otherwise 0

{p 8 8 2}dx{c 45}(i,t) = dx(i,t){space 3}if dx(i,t) <  {c 45}c,{space 3}otherwise 0

{pstd}
so that a change lying in [-c, c] is classified as no change and contributes to
neither part. With c = 0 this is exactly eq. (13) of Thombs et al. (2022) and
the definition in section 3 of Allison (2019), and

{p 8 8 2}dx(i,t) = dx{c 43}(i,t) + dx{c 45}(i,t)

{pstd}
identically. With c > 0 the identity holds only up to the changes absorbed by
the dead band, which is the intended behaviour.

{pstd}
{bf:A note on the threshold.} Applying c to only one arm — counting a change as
a decrease whenever it is less than {c 43}c rather than less than {c 45}c —
puts small {it:positive} changes into the negative part. {cmd:xtasym} always
uses the symmetric band above. This is the one place where its output differs
from {bf:xtasysum} when {cmd:threshold()} is not zero.

{pstd}
The contribution of a change that clears the band is the whole first
difference, not the excess over c. That is the convention in this literature
and it keeps the sum of the two arms equal to the total movement of the series.

{pstd}
The {cmd:fdm} option stores dx{c 43} and dx{c 45} themselves, as
{it:var}{cmd:_pfd} and {it:var}{cmd:_nfd}. These are the regressors of the
first-difference method of York and Light (2017) and Allison (2019, sec. 3),
in which the dependent variable is also differenced.


{marker s3}{title:S3. Partial sums}

{pstd}
{bf:S3a. Shin, Yu and Greenwood-Nimmo (2014)}, the default. The two arms are
accumulated with their own signs:

{p 8 8 2}x{c 43}(i,t) = sum over j <= t of max(dx(i,j), 0)

{p 8 8 2}x{c 45}(i,t) = sum over j <= t of min(dx(i,j), 0)

{pstd}
This is eq. (14) of Thombs et al. (2022). x{c 43} is non-decreasing and
non-negative; x{c 45} is non-increasing and non-positive. They are stored as
{it:var}{cmd:_p} and {it:var}{cmd:_n}.

{pstd}
{bf:S3b. Allison (2019, sec. 6).} The negative arm is accumulated in absolute
value:

{p 8 8 2}Z{c 43}(i,t) = sum over j <= t of dx{c 43}(i,j)

{p 8 8 2}Z{c 45}(i,t) = sum over j <= t of -dx{c 45}(i,j)

{pstd}
Both are non-decreasing and non-negative. When x is a dummy, Z{c 43} counts the
transitions from 0 to 1 up to t and Z{c 45} counts the transitions from 1 to 0
— Allison's "number of previous marriages" and "number of previous divorces".
Selected with {cmd:convention(allison)}.


{marker equiv}{title:Equivalence of the two conventions}

{pstd}
The two constructions carry the same information:

{p 8 8 2}x{c 43}(i,t) = Z{c 43}(i,t){space 8}x{c 45}(i,t) = -Z{c 45}(i,t)

{pstd}
Fit y on x{c 43} and x{c 45} with coefficients b{c 43} and b{c 45}, and y on
Z{c 43} and Z{c 45} with coefficients g{c 43} and g{c 45}. Then

{p 8 8 2}g{c 43} = b{c 43}{space 10}g{c 45} = -b{c 45}

{pstd}
The fitted values, the residuals and every test statistic that does not
reference the sign of the negative arm are identical. What changes is the
symmetry restriction:

{p 8 8 2}under Shin:{space 5}H0: b{c 43} = b{c 45}

{p 8 8 2}under Allison: H0: g{c 43} = -g{c 45}

{pstd}
Both say the same thing — a unit increase and a unit decrease move y by equal
and opposite amounts — but the {cmd:test} command you type is different, and
typing the wrong one tests a hypothesis nobody wants. {cmd:xtasym} prints the
applicable restriction in its header.

{pstd}
The reading of a coefficient also flips. Under the Shin convention a positive
coefficient on x{c 45} means that a fall in x lowers y, because x{c 45} itself
falls. This is the meaning of the note to Table 5 of Thombs et al. (2022).


{marker why}{title:Why accumulate at all}

{pstd}
Allison (2019, sec. 6) supplies the data-generating model that justifies the
accumulation. Suppose

{p 8 8 2}y(i,t) = m(t) + b{c 43} Z{c 43}(i,t) + b{c 45} Z{c 45}(i,t) + a(i) + e(i,t)

{pstd}
with a(i) an arbitrary panel effect. First-differencing gives

{p 8 8 2}dy(i,t) = m(t) - m(t-1) + b{c 43} dx{c 43}(i,t) + b{c 45} dx{c 45}(i,t) + de(i,t)

{pstd}
because Z{c 43}(i,t) - Z{c 43}(i,t-1) = dx{c 43}(i,t) and likewise for the
negative arm. So the levels model in the accumulated variables and the
first-difference model in the period-by-period components have the same
parameters. Allison's Appendix 1 shows that when b{c 43} = -b{c 45} the model
collapses back to a symmetric model in x itself, so the symmetric specification
is nested.

{pstd}
Two consequences matter in practice. First, the effect of a change persists
until it is offset by a change in the other direction — Lieberson's irreversible
process. Second, because the levels form does not difference the dependent
variable, it extends directly to non-linear models: Allison (2019, sec. 7)
estimates an asymmetric fixed-effects logit by putting Z{c 43} and Z{c 45} into
{helpb clogit}. Use {cmd:convention(allison)} for that.

{pstd}
Thombs et al. (2022) additionally show that partial sums, unlike the
period-by-period components, allow {it:long-run} effects to be identified once
the model is written as an autoregressive distributed lag; the components alone
support only short-run effects.


{marker s4}{title:S4. Directional frequency table}

{pstd}
For each variable the command counts

{p 8 8 2}n{c 43} = #{ dx > {c 43}c },{space 3}n{c 45} = #{ dx < {c 45}c },{space 3}n0 = #{ -c <= dx <= c }

{pstd}
over the estimation sample, excluding missing first differences, and reports
each as a percentage of n{c 43} + n{c 45} + n0. This is Table 1 of Thombs et
al. (2022). Counts are obtained with {helpb count} rather than by reading a
cross-tabulation, so a variable in which some direction never occurs is handled
correctly rather than shifting the columns.


{marker s5}{title:S5. Within and between dispersion}

{pstd}
{helpb xtsum} decomposes the variation in each partial sum into a between-panel
part and a within-panel part. Fixed-effects, mean-group and common-correlated-
effects estimators all identify from the within part. A partial sum whose
within standard deviation is close to zero is collinear with the panel effect
and cannot carry an asymmetric coefficient, whatever the estimator; the remedy
is usually a larger threshold, following the suggestion in note 10 of Thombs et
al. (2022).


{marker s6}{title:S6. Pesaran (2015) CD statistic}

{pstd}
For a single series, let r(i,j) be the sample correlation between panels i and
j computed over their T(i,j) common non-missing periods. The statistic is

{p 8 8 2}CD = sqrt( 2 / (n(n-1)) ) * sum over i<j of sqrt(T(i,j)) * r(i,j)

{pstd}
which is standard normal under the null of weak cross-sectional dependence.
{cmd:xtasym} computes this internally in Mata, so no other package is required.
Pairs sharing fewer than three periods, or in which either series is constant,
are dropped from the sum; the number of usable pairs is reported. The table
also gives the mean correlation and the mean absolute correlation, which
distinguish a large CD driven by a few strong links from one driven by
pervasive dependence.

{pstd}
The exponent of cross-sectional dependence alpha (Bailey, Kapetanios and
Pesaran 2016) is not computed here; when {helpb xtcse2} is installed its
estimate is read and displayed. Values of alpha in [0.5, 1) indicate strong
dependence, which is what makes a common-correlated-effects estimator
preferable to time dummies.


{marker s7}{title:S7. Pesaran (2007) CIPS}

{pstd}
The {cmd:cips()} option is a wrapper: it calls {helpb xtcips} for each partial
sum and reformats the statistic, the critical values and a verdict into one
table. The test is left-tailed, so the null of a homogeneous unit root is
rejected when CIPS falls below the critical value. Nothing is recomputed here,
so results agree with {cmd:xtcips} exactly.

{pstd}
Partial sums of an I(1) series are ordinarily non-stationary. That is expected,
not a defect: it is one reason Thombs et al. (2022) work in autoregressive
distributed lag or error-correction form rather than in a static regression.


{marker map}{title:Step to equation map}

{p2colset 8 20 22 2}{...}
{p2col :{bf:Step}}{bf:Source}{p_end}
{p2col :S1}first difference; {cmd:D.} operator under {helpb xtset}{p_end}
{p2col :S2}Allison (2019) sec. 3; Thombs et al. (2022) eq. (13){p_end}
{p2col :S3a}Shin et al. (2014); Thombs et al. (2022) eq. (14){p_end}
{p2col :S3b}Allison (2019) sec. 6, Z{c 43} and Z{c 45}{p_end}
{p2col :equivalence}Allison (2019) eq. (3) and Appendix 1{p_end}
{p2col :S4}Thombs et al. (2022) Table 1{p_end}
{p2col :S5}Thombs et al. (2022) Table 2{p_end}
{p2col :S6}Pesaran (2015); Thombs et al. (2022) Table 3{p_end}
{p2col :S7}Pesaran (2007); Thombs et al. (2022) Table 3{p_end}
{p2colreset}{...}


{marker choose}{title:Choosing an estimator for the partial sums}

{pstd}
The Monte Carlo evidence in Thombs et al. (2022) is a decision rule. Their
findings, in short:

{phang}o A {bf:static} model is dynamically misspecified whenever the process
is autoregressive. Their Experiment 1 finds bias above 25 per cent on the
positive arm and above 50 per cent on the negative arm at every combination of
n and T they consider. Start from an autoregressive distributed lag or an
error-correction specification and restrict it only if the data allow.

{phang}o Under {bf:slope heterogeneity}, dynamic fixed effects give long-run
effects that are wildly unstable and do not improve as T grows — bias reaching
several thousand per cent in their Experiment 2 — because the numerator and the
denominator of the long-run formula both tend to zero. The mean-group estimator
of Pesaran and Smith (1995) fixes this. Pre-test with {helpb xthst}.

{phang}o Under {bf:cross-sectional dependence} with homogeneous slopes, two-way
fixed effects performed well in their design, occasionally better than the
pooled common-correlated-effects estimator; but with both problems present the
common-correlated-effects estimator of Pesaran (2006), in the dynamic form of
Chudik and Pesaran (2015), is the one to use. Pre-test with the {cmd:csd}
option of this command.

{pstd}
Note that Thombs et al. (2022, note 9) disagree with Allison's recommendation
of generalized least squares for the multi-period case: GLS treats
autocorrelation as a nuisance to be corrected, whereas in the large-T setting
it is usually a symptom of misspecified dynamics, which no correction to the
error structure can repair. Allison's GLS route remains the right one when T is
small and the model really is static.


{marker limits}{title:Limitations}

{phang}o {cmd:xtasym} builds and describes regressors. It does not estimate a
model and does not test asymmetry; the restriction to test is stated in the
header and you impose it with {helpb test}, {helpb nlcom} or the equivalent
after your own estimation command.

{phang}o The CIPS option depends on {helpb xtcips}; its critical values are
unreliable with unbalanced panels, as that command documents.

{phang}o The CD statistic is a large-n result and should not be read
literally with a handful of panels.

{phang}o Dynamic multipliers in the sense of Shin et al. (2014) are a property
of an estimated model, not of the partial sums, and so are outside the scope of
this command.


{title:Author}

{pstd}Dr Merwan Roudane{p_end}
{pstd}Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}


{title:Also see}

{psee}Help: {helpb xtasym}{p_end}
{psee}Manual: {helpb xtset}, {helpb xtsum}, {helpb xtreg}{p_end}
