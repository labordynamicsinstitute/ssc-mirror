{smcl}
{* *! midas_het.sthlp  v1.0.0  Ben Adarkwa Dwamena  2026}{...}
{vieweralsosee "midas_mle"    "help midas_mle"}{...}
{vieweralsosee "midas_qrsim"  "help midas_qrsim"}{...}
{vieweralsosee "midas_mh"     "help midas_mh"}{...}
{vieweralsosee "midas_hmc"    "help midas_hmc"}{...}
{vieweralsosee "midas_inla"   "help midas_inla"}{...}
{vieweralsosee "midas_assess" "help midas_assess"}{...}
{viewerjumpto "Syntax"       "midas_het##syntax"}{...}
{viewerjumpto "Description"  "midas_het##description"}{...}
{viewerjumpto "Options"      "midas_het##options"}{...}
{viewerjumpto "Workflow"     "midas_het##workflow"}{...}
{viewerjumpto "Methods"      "midas_het##methods"}{...}
{viewerjumpto "Estimators"   "midas_het##estimators"}{...}
{viewerjumpto "Stored results" "midas_het##stored"}{...}
{viewerjumpto "Tabular output" "midas_het##tabular"}{...}
{viewerjumpto "Forest plot"  "midas_het##forest"}{...}
{viewerjumpto "Examples"     "midas_het##examples"}{...}
{viewerjumpto "References"   "midas_het##references"}{...}
{viewerjumpto "Author"       "midas_het##author"}{...}
{hline}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:midas_het} {hline 2}}Post-estimation heterogeneity decomposition
for meta-analytical integration of diagnostic accuracy studies{p_end}
{p2colreset}{...}
{hline}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas_het}
[{cmd:,}
{opt sav:egraph(filename)}
{opt nog:raph}
{opt for:mat(fmt)}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Output}
{synopt:{opt sav:egraph(filename)}}save forest plot to {it:filename}{bf:.pdf}
    and {it:filename}{bf:.eps}; no extension in {it:filename}{p_end}
{synopt:{opt nog:raph}}suppress the forest plot; tabular output still
    produced{p_end}
{synopt:{opt for:mat(fmt)}}Stata numeric display format for I{c 178} columns;
    default {bf:%6.4f}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas_het} is a post-estimation command in the MIDAS suite.  It
decomposes overall heterogeneity into study-specific contributions using
Burke-weighted apportionment and presents results as a formatted table and
a forest-plot style chart.

{pstd}
{cmd:midas_het} must be called immediately after one of the five MIDAS
estimation commands:
{helpb midas_mle}, {helpb midas_qrsim}, {helpb midas_mh},
{helpb midas_hmc}, or {helpb midas_inla}.
It reads matrices and scalars from {cmd:e()} and does not modify the
original estimation results except to add the decomposition matrices
listed under {help midas_het##stored:Stored results}.

{pstd}
{cmd:midas_het} is distinct from {helpb midas_assess}, which is a
{it:pre-estimation} exploratory command for data quality evaluation,
threshold analysis, SROC shape assessment, and publication bias checks.
{cmd:midas_het} is strictly post-estimation.


{marker options}{...}
{title:Options}

{dlgtab:Output}

{phang}
{opt savegraph(filename)} exports the forest plot in two formats:
{it:filename}{bf:.pdf} for screen and print, and {it:filename}{bf:.eps}
for import into LaTeX (via {cmd:\includegraphics}).  Specify the path
without an extension.  Example: {cmd:savegraph("plots/i2_forest")}.
Existing files are silently replaced.

{phang}
{opt nograph} suppresses the forest plot entirely.  Useful in batch
processing or when only the {cmd:e()} matrices are required.

{phang}
{opt format(fmt)} sets the Stata display format applied to I{c 178}
contribution columns in the tabular output.  The default {bf:%6.4f}
gives four decimal places.  Use {bf:%8.6f} for higher precision or
{bf:%5.1f} for a more compact table.


{marker workflow}{...}
{title:Workflow}

{pstd}
The standard MIDAS analysis sequence is:

{p 8 12 2}
{bf:Step 1 — Pre-estimation diagnostics}

{phang2}{cmd:. midas_assess} {it:tp fp fn tn} [{cmd:,} {it:options}]

{p 8 12 2}
{bf:Step 2 — Estimation}

{phang2}{cmd:. midas_mle} {it:tp fp fn tn} [{cmd:,} {it:options}]
{p_end}
{phang2}(or {cmd:midas_qrsim}, {cmd:midas_mh}, {cmd:midas_hmc},
{cmd:midas_inla})

{p 8 12 2}
{bf:Step 3 — Post-estimation heterogeneity decomposition}

{phang2}{cmd:. midas_het} [{cmd:,} {it:options}]

{pstd}
{cmd:midas_het} requires an active {cmd:e()} from Step 2.  If another
estimation command is run between Steps 2 and 3, {cmd:e()} will be
overwritten and {cmd:midas_het} will exit with an error.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{ul:Burke-weighted apportionment}

{pstd}
Let n be the number of primary studies and let
W be the n{c 215}3 matrix of Burke weights posted by the estimator in
{cmd:e(studyweights)}, with columns indexing sensitivity (j=1),
specificity (j=2), and the bivariate composite (j=3).

{pstd}
Let I{c 178}(j) denote the overall heterogeneity statistic for
component j, stored in {cmd:e(bIsquared)}.

{pstd}
The apportioned I{c 178} contribution of study i to component j is:

{pmore}
H[i,j]  =  ( W[i,j] / {c -(}sum_i W[i,j]{c )-} )  {c 215}  I{c 178}(j)

{pstd}
where the sum in the denominator runs over all n studies.  H[i,j]
is expressed in percentage points and sums exactly to I{c 178}(j)
over studies.

{pstd}
The percentage share of study i in component j is:

{pmore}
Hpct[i,j]  =  100 {c 215} H[i,j] / I{c 178}(j)

{pstd}
which sums to 100 over studies for each j.

{pstd}
{ul:I{c 178} computation — Zhou-Dendukuri method}

{pstd}
The overall I{c 178}(j) values in {cmd:e(bIsquared)} are computed
uniformly across all five MIDAS estimators using the Zhou-Dendukuri
method for quantifying heterogeneity in bivariate meta-analyses of
binary data.  This method accounts for the bivariate structure of
sensitivity and specificity and is applied consistently regardless of
the estimation approach (MLE, quadrature, Bayesian MH, HMC, or INLA).

{pstd}
{bf:Reference}: Zhou Y, Dendukuri N. Statistics for quantifying
heterogeneity in univariate and bivariate meta-analyses of binary
data: the case of meta-analyses of diagnostic accuracy.
{it:Statistics in Medicine.} 2014;33(16):2701{c -}2717.

{pstd}
{ul:Weight column sums}

{pstd}
The audit matrix {cmd:e(wtcheck)} records the raw column sums of W
before normalisation.  Under normalised weights these equal 1; under
raw precision weights they equal the total precision for each component
and serve as a consistency check.


{marker estimators}{...}
{title:Weight provenance by estimator}

{pstd}
The Burke weights differ across estimators in their derivation method.
The I{c 178} target is uniform across all five estimators: the
Zhou-Dendukuri method (2014).  {cmd:midas_het} records weight
provenance in its tabular footer.

{synoptset 10}{...}
{synopt:{bf:mle}}Model-based posterior precision weights from the
bivariate GLMM fitted via {cmd:meglm}.  Three adaptive
Gauss-Hermite integration methods are supported:
mean-variance adaptive ({bf:mvaghermite}, default),
mode-curvature adaptive ({bf:mcaghermite}), and
Pinheiro-Chao mode-curvature adaptive ({bf:pcaghermite}).
Weights are the inverse conditional variance of study-specific
random effects at the AGH estimates; see
Pinheiro and Chao (2006).{p_end}

{synopt:{bf:qrsim}}Model-based posterior precision weights from the
bivariate GLMM fitted by maximum simulated likelihood using
quasi-random Monte Carlo simulation with Halton sequences.
Weights are the inverse conditional variance of study-specific
random effects at the MSL estimates.  Convergence to the true
posterior precision improves with the number of simulation
draws.{p_end}

{synopt:{bf:mh}}Posterior mean precision weights from the Bayesian
Metropolis-Hastings model fitted via {cmd:bayesmh}.  Weights are
derived from Metropolis-Hastings draws; between-study covariance
enters through the prior structure rather than a GLMM variance
component.{p_end}

{synopt:{bf:hmc}}Full posterior precision weights from Hamiltonian Monte
Carlo chains via CmdStan.  These weights integrate over the full
posterior of the between-study covariance matrix, whereas {bf:mle}
conditions on point estimates of variance components.  For small n the
two can differ materially.{p_end}

{synopt:{bf:inla}}Marginal posterior precision weights from the INLA
Laplace approximation.  The I{c 178} target is computed by the same
Zhou-Dendukuri method as all other estimators.{p_end}
{p2colreset}{...}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:midas_het} adds the following matrices to {cmd:e()}.  All
pre-existing estimation results are preserved.

{synoptset 22 tabbed}{...}
{syntab:Matrices}
{synopt:{cmd:e(studyweights)}}n{c 215}3 matrix of Burke weights; columns
are {it:wt_sens}, {it:wt_spec}, {it:wt_biv}; rows labelled by study
identifier{p_end}
{synopt:{cmd:e(bIsquared)}}1{c 215}3 row vector of overall I{c 178}
values; columns are {it:I2_sens}, {it:I2_spec}, {it:I2_biv}{p_end}
{synopt:{cmd:e(studyI2)}}n{c 215}3 matrix of apportioned I{c 178}
contributions in percentage points; columns are {it:I2_sens_contrib},
{it:I2_spec_contrib}, {it:I2_biv_contrib}{p_end}
{synopt:{cmd:e(studyI2pct)}}n{c 215}3 matrix of percentage shares;
columns are {it:I2_sens_pctpt}, {it:I2_spec_pctpt},
{it:I2_biv_pctpt}{p_end}
{synopt:{cmd:e(wtcheck)}}1{c 215}3 row vector of weight column sums for
audit; columns are {it:wt_sens_sum}, {it:wt_spec_sum},
{it:wt_biv_sum}{p_end}
{p2colreset}{...}


{marker tabular}{...}
{title:Tabular output}

{pstd}
The table displays one row per study with six numeric columns grouped
into three pairs — one pair per component (sensitivity, specificity,
bivariate).  Within each pair the first column gives the absolute
I{c 178} contribution in percentage points and the second gives the
study's percentage share of the overall I{c 178} for that component.

{pstd}
The footer rows show:

{phang2}{bf:Overall I{c 178}} — the target values being apportioned;
each percentage share column reads 100.

{phang2}{bf:Weight column sums} — raw sum of Burke weights per
component; serves as an arithmetic audit.

{pstd}
The footer notes record the weight source, the I{c 178} source, and
any estimation-specific caveats (currently applied to {bf:inla} only).


{marker forest}{...}
{title:Forest plot}

{pstd}
The forest plot displays, for each study, three horizontal spike-and-dot
series — one per component — offset vertically by {c +/-}0.22 units so
the three series are legible without overlap.  Studies are ordered top
to bottom in the order they appear in the data (study 1 at top).

{pstd}
Each spike runs from zero to the study's I{c 178} contribution
({cmd:rcap}, horizontal).  The filled marker at the tip encodes the
component: circle (sensitivity), diamond (specificity), triangle
(bivariate).

{pstd}
Three dashed vertical reference lines mark the overall I{c 178} for
each component.  The overall values are annotated at the top of each
reference line.

{pstd}
The subtitle records the estimator name and a note about the reference
lines.

{pstd}
Colors: sensitivity = blue (51 105 173); specificity = coral
(205 92 55); bivariate = green (67 135 80).  These match the
MIDAS house palette used in {cmd:midas_bvsroc} and {cmd:midas_bivbox}.


{marker examples}{...}
{title:Examples}

{pstd}
{ul:Basic usage after MLE}

{phang2}{cmd:. use fdgpet_axillary, clear}{p_end}
{phang2}{cmd:. midas_mle tp fp fn tn, id(author) year(year)}{p_end}
{phang2}{cmd:. midas_het}{p_end}

{pstd}
{ul:Save graph for LaTeX (plots/ subdirectory)}

{phang2}{cmd:. midas_het, savegraph("plots/i2_forest")}{p_end}

{pstd}
{ul:Tabular output only, higher precision}

{phang2}{cmd:. midas_het, nograph format("%8.6f")}{p_end}

{pstd}
{ul:After HMC estimation}

{phang2}{cmd:. midas_hmc tp fp fn tn, id(author) iter(2000)}{p_end}
{phang2}{cmd:. midas_het, savegraph("plots/i2_hmc")}{p_end}

{pstd}
{ul:Access stored matrices after midas_het}

{phang2}{cmd:. matrix list e(studyI2)}{p_end}
{phang2}{cmd:. matrix list e(studyI2pct)}{p_end}
{phang2}{cmd:. matrix list e(wtcheck)}{p_end}

{pstd}
{ul:Export contribution matrix to dataset}

{phang2}{cmd:. matrix H = e(studyI2)}{p_end}
{phang2}{cmd:. svmat H, names(col)}{p_end}


{marker references}{...}
{title:References}

{phang}
Burke, D. L., Ensor, J., Snell, K. I. E., van der Windt, D., and
Riley, R. D. (2018).
Guidance for deriving and presenting percentage study weights in
meta-analysis of test accuracy studies.
{it:Research Synthesis Methods} 9(2): 163–178.

{phang}
Riley, R. D., Ensor, J., Jackson, D., and Burke, D. L. (2018).
Deriving percentage study weights in multi-parameter meta-analysis
models: with application to meta-regression, network meta-analysis
and one-stage individual participant data models.
{it:Research Synthesis Methods} 9(2): 145–157.

{phang}
Dwamena, B. A. (2009).
{it:MIDAS: Meta-analytical Integration of Diagnostic Accuracy Studies}.
Statistical Software Components, Boston College Department of Economics.
{browse "https://ideas.repec.org/c/boc/bocode/s456880.html"}

{phang}
Harbord, R. M., and Whiting, P. (2009).
metandi: Meta-analysis of diagnostic accuracy using hierarchical
logistic regression.
{it:Stata Journal} 9(2): 211–229.

{phang}
Higgins, J. P. T., Thompson, S. G., Deeks, J. J., and Altman, D. G.
(2003).
Measuring inconsistency in meta-analyses.
{it:BMJ} 327: 557–560.

{phang}
Pinheiro, J. C., and Chao, E. C. (2006).
Efficient Laplacian and adaptive Gaussian quadrature algorithms
for multilevel generalized linear mixed models.
{it:Journal of Computational and Graphical Statistics} 15(1): 58–81.

{phang}
Reitsma, J. B., Glas, A. S., Rutjes, A. W. S., Scholten, R. J. P. M.,
Bossuyt, P. M., and Zwinderman, A. H. (2005).
Bivariate analysis of sensitivity and specificity produces informative
summary measures in diagnostic reviews.
{it:Journal of Clinical Epidemiology} 58(10): 982–990.

{phang}
Rutter, C. M., and Gatsonis, C. A. (2001).
A hierarchical regression approach to meta-analysis of diagnostic
test accuracy evaluations.
{it:Statistics in Medicine} 20(19): 2865–2884.

{phang}
Zhou, Y., and Dendukuri, N. (2014).
Statistics for quantifying heterogeneity in univariate and bivariate
meta-analyses of binary data: the case of meta-analyses of diagnostic
accuracy.
{it:Statistics in Medicine} 33(16): 2701–2717.


{marker author}{...}
{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
Clinical Associate Professor Emeritus of Radiology{break}
(Nuclear Medicine and Molecular Imaging){break}
University of Michigan{break}
East Lansing, Michigan, USA{break}
{browse "mailto:bdwamena@umich.edu":bdwamena@umich.edu}

{pstd}
Please report bugs and suggestions via the MIDAS SSC page or by email.

{pstd}
{it:Also see}: {helpb midas_mle}, {helpb midas_qrsim}, {helpb midas_mh},
{helpb midas_hmc}, {helpb midas_inla}, {helpb midas_assess}
{p_end}
{hline}
