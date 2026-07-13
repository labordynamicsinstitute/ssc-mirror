{smcl}
{* *! version 1.0.0  11jul2026}{...}
{vieweralsosee "hpcm methods" "help hpcm_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "var" "help var"}{...}
{vieweralsosee "vargranger" "help vargranger"}{...}
{vieweralsosee "tsset" "help tsset"}{...}
{viewerjumpto "Syntax" "hpcm##syntax"}{...}
{viewerjumpto "Description" "hpcm##desc"}{...}
{viewerjumpto "Options" "hpcm##opts"}{...}
{viewerjumpto "Interpretation" "hpcm##interp"}{...}
{viewerjumpto "Remarks" "hpcm##remarks"}{...}
{viewerjumpto "Examples" "hpcm##ex"}{...}
{viewerjumpto "Stored results" "hpcm##results"}{...}
{viewerjumpto "References" "hpcm##refs"}{...}
{viewerjumpto "Author" "hpcm##author"}{...}
{title:Title}

{phang}
{bf:hpcm} {hline 2} Hosoya (2001) partial measures of causality by one-way-effect elimination


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:hpcm} {it:xvar} {it:yvar} {it:zvar} {ifin} [{cmd:,} {it:options}]

{p 8 15 2}
{cmd:hpcm} {cmd:(}{it:xvars}{cmd:)} {cmd:(}{it:yvars}{cmd:)} {cmd:(}{it:zvars}{cmd:)} {ifin} [{cmd:,} {it:options}]

{pstd}
where the three groups are the pair of processes of interest, {it:x} and {it:y},
and the conditioning ("third") process {it:z}.  Each group may be a single series
or, in parentheses, a vector of series.  The data must be {helpb tsset} as a single
time series (no gaps).{p_end}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt var(#)}}order {it:p} of the VAR fitted to (x,y,z); if omitted it is
chosen by an information criterion{p_end}
{synopt:{opt maxv:ar(#)}}maximum order searched when {cmd:var()} is omitted; default {cmd:maxvar(8)}{p_end}
{synopt:{opt ic(string)}}selection criterion: {cmd:aic} (default), {cmd:bic}, or {cmd:hqic}{p_end}
{synopt:{opt d:ifference(#)}}difference each series {it:#} times first (Section 5 reduction for I(1) data){p_end}

{syntab:Spectral computation}
{synopt:{opt grid(#)}}number of frequency points on [0,{&pi}]; default {cmd:grid(300)}{p_end}
{synopt:{opt ml:ag(#)}}order {it:m} of the auxiliary VAR used for the canonical
factorization of the cleaned pair; default {cmd:mlag(20)}{p_end}
{synopt:{opt mat:runc(#)}}MA truncation used for the autocovariances; default {cmd:matrunc(1200)}{p_end}
{synopt:{opt band(lo hi)}}frequency band (radians, 0{&le}lo<hi{&le}{&pi}) for the band
measures and Wald tests; default is the full band {cmd:band(0} {it:pi}{cmd:)}{p_end}

{syntab:Inference}
{synopt:{opt nowald}}suppress the Wald non-causality tests (Section 6){p_end}
{synopt:{opt breps(#)}}parametric-bootstrap replications for CIs of the band measures{p_end}
{synopt:{opt seed(string)}}random-number seed for the bootstrap{p_end}
{synopt:{opt lev:el(#)}}confidence level for the bootstrap CIs; default {cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt:{opt nodec:ompose}}report only the two directional measures{p_end}
{synopt:{opt plot}}draw the frequency-domain measure curves{p_end}
{synopt:{opt name(string)}}name for the graph(s); default {cmd:hpcm}{p_end}
{synopt:{opt nodraw}}build but do not display the graph{p_end}
{synopt:{opt noheader}}suppress the header block{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{pstd}
{cmd:hpcm} implements the partial measures of causality of Hosoya (2001) for a
pair of (vector) time series {it:x} and {it:y} observed together with a third
(vector) series {it:z}.  Ordinary conditioning on the whole history of {it:z}
(as in Granger's partial cross-spectrum or Geweke's conditional measures) distorts
the feedback between {it:x} and {it:y} and can manufacture the spurious causality of
Hsiao (1982).  Instead, Hosoya eliminates from {it:x} and {it:y} only the
{it:one-way-effect} component of {it:z} -- the part of {it:z} that drives (x,y)
without suffering feedback from them -- and defines the partial causal relations
between {it:x} and {it:y} as the simple one-way-effect measures between the two
cleaned series {it:u} and {it:v}.{p_end}

{pstd}
Four measures are reported, each as a frequency-wise curve M({&lambda}) and as an
overall value (the integral (1/2{&pi}){&int}M({&lambda})d{&lambda}, Theorem 4.1):{p_end}

{p2colset 8 34 36 2}{...}
{p2col:{bf:PM(y{&rarr}x:z)}}one-way effect from {it:y} to {it:x} given {it:z}  (eq 4.4, 4.5){p_end}
{p2col:{bf:PM(x{&rarr}y:z)}}one-way effect from {it:x} to {it:y} given {it:z}{p_end}
{p2col:{bf:PM(x:y:z)}}reciprocity / instantaneous feedback  (eq 4.7){p_end}
{p2col:{bf:PM(x,y:z)}}association (total interdependence)  (eq 4.6){p_end}

{pstd}
These satisfy the exact decomposition (Theorem 4.2){p_end}

{p 12 12 2}{bf:PM(x,y:z) = PM(x{&rarr}y:z) + PM(x:y:z) + PM(y{&rarr}x:z)}{p_end}

{pstd}
which {cmd:hpcm} uses internally: the reciprocity term is obtained from this
identity, so {cmd:association} always equals the sum of the other three.  All four
measures are non-negative; a directional measure is zero if and only if there is no
partial causality in that direction (Theorem 4.3).  The full equation-by-equation
derivation is in {helpb hpcm_methods:help hpcm methods}.{p_end}


{marker opts}{...}
{title:Options}

{dlgtab:Model}

{phang}{opt var(#)} sets the order {it:p} of the VAR fitted to the joint process
(x,y,z).  With a finite VAR the canonical (Wold) factorization needed by the
measures is available in closed form, which is what makes the computation feasible
(the Yao-Hosoya 1998 route).  If {cmd:var()} is omitted the order is chosen by the
{cmd:ic()} criterion over 1..{cmd:maxvar()}.

{phang}{opt difference(#)} differences every series {it:#} times before fitting the
VAR.  This is the Section-5 reduction for reproducible (e.g. I(1)) processes: the
partial measures of the differenced-stationary generating process equal those of the
original nonstationary process.  Use {cmd:difference(1)} for I(1) series.

{dlgtab:Spectral computation}

{phang}{opt grid(#)} controls the frequency resolution.  {opt mlag(#)} is the order
of the long auxiliary VAR that reproduces the canonical factor of the cleaned pair
(u,v); increase it if the (x,y,z) VAR order is large.  {opt band(lo hi)} restricts
the overall measures and the Wald tests to a frequency window (e.g. low frequencies
for long-run causality).

{dlgtab:Inference}

{phang}{opt nowald} turns off the Section-6 Wald tests of partial non-causality.
By default {cmd:hpcm} tests H0: PM(y{&rarr}x:z)=0, H0: PM(x{&rarr}y:z)=0 and the
joint null, using the band measure(s) as G({&theta}), a numerical Jacobian
D{&theta}G, and the VAR parameter covariance; the statistic is
{it:G'(D{&theta}G V D{&theta}G'){c 94}-1 G} ~ {&chi}{c 178}.

{phang}{opt breps(#)} adds percentile bootstrap CIs for the two directional band
measures by parametric resampling of the fitted VAR.


{marker interp}{...}
{title:Interpreting the output}

{pstd}
{bf:What the numbers mean.}  Every measure is a {it:log prediction-error variance
ratio} in {bf:nats} (natural-log units), so it is {&ge}0 and unbounded above, and it
is 0 exactly when the effect it measures is absent.  A measure {it:M} converts to an
easily read effect size:{p_end}

{p 10 10 2}{it:exp(M)} = factor by which the source improves prediction of the
target; {break}
{it:1 - exp(-M)} = fraction of the target's one-step-ahead prediction-error variance
attributable to the source's one-way effect.{p_end}

{pstd}Rough guide (single-equation targets):{p_end}
{p2colset 10 26 28 2}{...}
{p2col:{it:M} (nats)}variance share {it:1 - e{c 94}-M}{p_end}
{p2col:0.01}  1%   (negligible){p_end}
{p2col:0.05}  5%{p_end}
{p2col:0.10}  10%  (modest){p_end}
{p2col:0.22}  20%{p_end}
{p2col:0.49}  39%  (strong){p_end}
{p2col:0.69}  50%{p_end}
{p2col:1.00}  63%  (dominant){p_end}

{pstd}
{bf:Overall measures table} -- decode each row.  Columns give the measure integrated
over the full band [0,{&pi}] and over the requested {cmd:band()} (equal when no
{cmd:band()} is set).{p_end}

{p2colset 8 26 28 2}{...}
{p2col:{bf:PM(y{&rarr}x:z)}}Strength of the one-way (Granger-type) effect running from
{it:y} to {it:x}, {it:after} removing the one-way effect of {it:z}. Large value =
{it:y}'s own past helps predict {it:x} beyond {it:x}'s past and beyond {it:z}.{p_end}
{p2col:{bf:PM(x{&rarr}y:z)}}The reverse one-way effect, {it:x} to {it:y} given {it:z}.{p_end}
{p2col:{bf:PM(x:y:z)}}Reciprocity / instantaneous feedback -- the {it:directionless}
contemporaneous association between {it:x} and {it:y} that survives the z-cleaning.{p_end}
{p2col:{bf:PM(x,y:z)}}Association: the {it:total} partial interdependence, and by
Theorem 4.2 exactly the sum of the three rows above.{p_end}

{pstd}
{bf:Reading the pattern.}  A large {bf:PM(y{&rarr}x:z)} with a near-zero
{bf:PM(x{&rarr}y:z)} is clean one-way partial causality {it:y}=>{it:x}. Two comparable
directional values indicate partial feedback (both directions). A large
{bf:PM(x:y:z)} with small directional terms means the link is essentially
contemporaneous, not lead-lag. Compare directions by their magnitudes, not by their
p-values.{p_end}

{pstd}
{bf:Full band vs band.}  The {cmd:band()} column integrates only over the chosen
frequencies; dividing it by the band width and comparing with the full-band value
tells you {it:where} in the spectrum the effect concentrates. A low-frequency band
(small {&lambda}) isolates persistent / long-run causality; higher frequencies capture
short-run co-movement.{p_end}

{pstd}
{bf:Wald table.}  {it:chi2}, {it:df} and {it:p}-value for each non-causality null,
starred {res}*{txt}/{res}**{txt}/{res}***{txt} at 10/5/1%. The statistic tests
whether the {it:band} measure is zero. Because every measure is {&ge}0, the null sits
on the {it:boundary} of the parameter space, so the {&chi}{c 178} approximation is
{it:conservative} (true size below nominal, verified by Monte Carlo). Practical rule:
{it:a starred result is trustworthy evidence of causality}; a non-rejection means "no
evidence", not "proven absence". The statistic grows with the sample size under a true
effect, so with several thousand observations a genuine effect can produce a very
large {it:chi2} -- read the effect {it:size} from the measure, and the {it:evidence}
from the p-value.{p_end}

{pstd}
{bf:Bootstrap CIs} ({cmd:breps()}).  A percentile interval for each directional band
measure. An interval clearly above 0 corroborates the Wald rejection; an interval whose
lower limit is essentially 0 signals a weak or absent effect (and reflects the boundary
at 0).{p_end}

{pstd}
{bf:Frequency plot} ({cmd:plot}).  The directional panel plots M({&lambda}) for both
directions against frequency {&omega}/2{&pi} in cycles (0 = long run, 0.5 = highest
frequency); the {cmd:band()} limits are marked. Peaks locate the frequencies
(business-cycle, seasonal, ...) at which the partial causality operates. The second
panel overlays association and reciprocity. The area under a curve (over [0,{&pi}],
scaled by 1/{&pi}) equals the corresponding overall measure.{p_end}

{pstd}
{bf:Worked reading} (Example 2.2, y=>x by construction):
{bf:PM(y{&rarr}x:z)}=0.493 means {it:y}'s one-way effect cuts the prediction-error
variance of {it:x} by 1-exp(-0.493), about 40%, a strong effect; the Wald rejects at 1%.
{bf:PM(x{&rarr}y:z)}=0.000 with p=0.79 confirms no reverse causality. The tiny
{bf:PM(x:y:z)} shows the link is lead-lag, not contemporaneous.{p_end}


{marker remarks}{...}
{title:Remarks and practical guidance}

{phang}o {bf:Sample and order.}  Fit the smallest VAR order that whitens the
residuals ({helpb varlmar}); an over-short order leaves structure in {it:z} that the
one-way elimination cannot remove.  Several hundred observations are advisable for
reliable band measures.{p_end}

{phang}o {bf:Vector blocks.}  {it:x}, {it:y}, {it:z} may each be multivariate; use the
parenthesized form.  Determinants of the block spectra are then compared, exactly as
in the scalar case.{p_end}

{phang}o {bf:Nonstationary data.}  For I(1) series use {cmd:difference(1)}.  Full
Johansen/cointegrated-ARMA inference in levels (Yao and Hosoya 1998) is beyond the
scope of this version and is documented as a limitation, following the paper, which
itself only sketches it.{p_end}

{phang}o {bf:Reproducibility.}  Results depend on {cmd:var()}, {cmd:grid()} and
{cmd:mlag()}; report them.  The measures are invariant to the ordering within the
(x,y,z) system and to the choice of innovation square root.{p_end}


{marker ex}{...}
{title:Examples}

{pstd}Basic use, VAR order chosen by AIC:{p_end}
{phang2}{cmd:. hpcm gdp inflation moneysupply}{p_end}

{pstd}Fixed order, low-frequency band, with the frequency plot:{p_end}
{phang2}{cmd:. hpcm x y z, var(3) band(0 0.5) plot}{p_end}

{pstd}I(1) series, differenced once, no Wald tests:{p_end}
{phang2}{cmd:. hpcm lgdp lcons linv, difference(1) nowald}{p_end}

{pstd}Vector x-block, bootstrap CIs:{p_end}
{phang2}{cmd:. hpcm (y1 y2) (c) (r), var(2) breps(499) seed(101)}{p_end}

{pstd}A full self-test on the paper's examples ships with the package:{p_end}
{phang2}{cmd:. do hpcm_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:hpcm} stores the following in {cmd:r()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}
{synopt:{cmd:r(p)}}VAR order fitted{p_end}
{synopt:{cmd:r(m)}}auxiliary factorization VAR order{p_end}
{synopt:{cmd:r(grid)}}frequency grid size{p_end}
{synopt:{cmd:r(stable)}}1 if the fitted VAR is stable{p_end}
{synopt:{cmd:r(PM_yx)}}overall PM(y{&rarr}x:z){p_end}
{synopt:{cmd:r(PM_xy)}}overall PM(x{&rarr}y:z){p_end}
{synopt:{cmd:r(PM_recip)}}overall reciprocity{p_end}
{synopt:{cmd:r(PM_assoc)}}overall association{p_end}
{synopt:{cmd:r(PM_yx_band)}, {cmd:r(PM_xy_band)}}band-restricted directional measures{p_end}
{synopt:{cmd:r(chi2_yx)}, {cmd:r(p_yx)}}Wald statistic and p-value, H0: PM(y{&rarr}x:z)=0{p_end}
{synopt:{cmd:r(chi2_xy)}, {cmd:r(p_xy)}}Wald statistic and p-value, H0: PM(x{&rarr}y:z)=0{p_end}
{synopt:{cmd:r(chi2_joint)}, {cmd:r(p_joint)}}joint Wald statistic and p-value{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:hpcm}{p_end}
{synopt:{cmd:r(xvars)}, {cmd:r(yvars)}, {cmd:r(zvars)}}the three groups{p_end}
{synopt:{cmd:r(ic)}}selection criterion used{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(overall)}}2x4 overall measures (rows: full band, band){p_end}
{synopt:{cmd:r(curve)}}frequency-domain measures: {&lambda}, PM(y{&rarr}x), PM(x{&rarr}y), recip, assoc{p_end}
{synopt:{cmd:r(wald)}}3x3 Wald table (chi2, df, p){p_end}


{marker refs}{...}
{title:References}

{phang}Geweke, J. 1984. Measures of conditional linear dependence and feedback
between time series. {it:Journal of the American Statistical Association} 79: 907-915.{p_end}

{phang}Granger, C. W. J. 1969. Investigating causal relations by cross-spectrum
methods. {it:Econometrica} 37: 424-438.{p_end}

{phang}Hosoya, Y. 1991. The decomposition and measurement of the interdependency
between second-order stationary processes. {it:Probability Theory and Related
Fields} 88: 429-444.{p_end}

{phang}Hosoya, Y. 2001. Elimination of third-series effect and defining partial
measures of causality. {it:Journal of Time Series Analysis} 22: 537-554.{p_end}

{phang}Hsiao, C. 1982. Time series modelling and causal ordering of Canadian money,
income and interest rates. In {it:Time Series Analysis: Theory and Practice I},
ed. O. D. Anderson, 671-698. Amsterdam: North-Holland.{p_end}

{phang}Yao, F., and Y. Hosoya. 1998. Inference on one-way effect and evidence in
Japanese macroeconomic data. {it:Journal of Econometrics} 98: 225-255.{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
