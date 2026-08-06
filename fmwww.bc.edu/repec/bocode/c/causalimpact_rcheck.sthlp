{smcl}
{* *! version 1.0.0  05aug2026}{...}
{vieweralsosee "causalimpact" "help causalimpact"}{...}
{vieweralsosee "causalimpact methods" "help causalimpact_methods"}{...}
{vieweralsosee "causalimpact interpretation" "help causalimpact_interpretation"}{...}
{vieweralsosee "causalimpact postestimation" "help causalimpact_postestimation"}{...}
{viewerjumpto "Why not bit-for-bit" "causalimpact_rcheck##why"}{...}
{viewerjumpto "How the check was run" "causalimpact_rcheck##how"}{...}
{viewerjumpto "Results" "causalimpact_rcheck##results"}{...}
{viewerjumpto "The dynamic-regression gap" "causalimpact_rcheck##dynamic"}{...}
{viewerjumpto "Documented deviations" "causalimpact_rcheck##deviations"}{...}
{viewerjumpto "Running the check yourself" "causalimpact_rcheck##rerun"}{...}
{viewerjumpto "What counts as a discrepancy" "causalimpact_rcheck##verdict"}{...}
{viewerjumpto "Author" "causalimpact_rcheck##author"}{...}

{title:Title}

{phang}
{bf:causalimpact rcheck} {hline 2} Verification against the R package
{cmd:CausalImpact} 1.4.1


{marker why}{...}
{title:Why the two cannot agree exactly}

{pstd}
{cmd:causalimpact} is a port of the R package {cmd:CausalImpact} 1.4.1, whose
complete source is at
{browse "https://github.com/google/CausalImpact":github.com/google/CausalImpact}
and can be compared line by line against the step-to-equation map in
{helpb causalimpact_methods:help causalimpact methods}.

{pstd}
The model, the priors, the sampler and every reported statistic follow the R
package. What cannot be reproduced is the arithmetic itself, because both are
{bf:Monte Carlo} procedures: R draws from its own random-number stream through
C++ code in {cmd:Boom}, Stata draws from Mata's. Two correct implementations of
the same posterior will land on slightly different numbers, and the difference
shrinks as {cmd:niter()} grows. Even in R, two runs with different seeds
disagree.

{pstd}
So the standard of proof is not equality. It is: {bf:given the same data, the
same model and the same priors, do the two land in the same place to within
Monte Carlo error, and do they reach the same conclusion every time?}

{pstd}
One thing {it:is} matched exactly and deliberately. Quantiles use R's default
type-7 definition, h = (n-1)p + 1 with linear interpolation, so that given
identical draws the interval endpoints would be identical too. Any remaining gap
is sampling, not convention.


{marker how}{...}
{title:How the check was run}

{pstd}
The weak version of this check is to simulate in R, simulate separately in
Stata, and compare. That confounds two things: differences in the estimator and
differences in the simulated data.

{pstd}
The check used during development avoids that. Every dataset was
{bf:generated in R, exported to CSV, and read back into Stata}, so both programs
saw byte-identical data. The only remaining source of difference is the MCMC
stream. The verification materials -- the R driver script, the full R log, the
shared CSVs, and the side-by-side Stata do-file -- are in the project repository
at
{browse "https://github.com/merwanroudane":github.com/merwanroudane}, and are not
part of the installed package, which ships only code, help and the self-test.


{marker results}{...}
{title:Results}

{pstd}
Static regression -- the branch the paper's own empirical sections use, and the
default here:

{cmd}
    quantity                        Stata          R     diff
    ------------------------------------------------------------
    vignette, cumulative          315.430    315.340    0.03%
    vignette, pointwise            10.514     10.511    0.03%
    vignette, relative              9.872%     9.873%   0.01%
    vignette, counterfactual sum 3196.026   3196.115    0.00%
    selection, cumulative         175.709    176.249    0.31%
    seasonal, cumulative          298.885    298.487    0.13%
    seasonal, relative             11.097%    11.052%   0.41%
    no covariates, cumulative     134.683    134.354    0.24%
    placebo, cumulative           -13.973    -12.843    both null
{txt}

{pstd}
Variable selection, ten candidate controls of which only two are informative:

{cmd}
    covariate     Stata P(incl)     R P(incl)
    -----------------------------------------
    x1                    1.000         1.000
    x2                    1.000         1.000
    x3 ... x10          <=0.012       <=0.019
{txt}

{pstd}
Significance verdicts agree in every section, including the placebo, where both
correctly fail to find an effect (Stata p = 0.160, R p = 0.185).

{pstd}
Two remarks on reading that table. The placebo row shows an 8.8% relative gap,
which looks large until you notice both numbers are near zero -- a percentage
difference between two near-zero quantities is not informative, and the verdict
is what matters. And on the vignette design {bf:neither} program recovers the
true cumulative effect of 300; both return about 315. That is a property of the
data, not of either implementation: the covariate is an AR(0.999) and the
counterfactual level is genuinely uncertain. The published R vignette reports
the same overshoot.


{marker dynamic}{...}
{title:The one place they part company}

{pstd}
The dynamic-regression branch does {bf:not} match R closely, and this is expected
rather than discovered:

{cmd}
    quantity                        Stata          R
    -------------------------------------------------
    paper Sec. 3, cumulative      135.798     45.008
    paper Sec. 3, relative          8.165%     2.989%
    paper Sec. 3, p                 0.153      0.372
{txt}

{pstd}
The cause is deviation 4 below: {cmd:Boom} places a hierarchical Gamma prior on
the innovation precisions of the time-varying coefficients, shared across
coefficients, whereas this command implements eq. (2.6) as the {it:paper} writes
it, with an independent inverse-Gamma per coefficient. Different priors, different
posteriors.

{pstd}
Both nonetheless reach the {bf:same conclusion}: the effect is not detected,
p well above 0.05 in each, and both 95% intervals cover the true +10%. On that
draw Stata's +8.2% is in fact nearer the truth than R's +3.0%, but this is one
replication and should not be read as evidence that either prior is better.

{pstd}
If exact agreement with R on the dynamic branch matters more to you than
following the paper, use the static branch, which is faithful to both.


{marker deviations}{...}
{title:The four documented deviations}

{pstd}
These are stated in advance rather than discovered afterwards. The full
discussion is in {helpb causalimpact_methods:help causalimpact methods}.

{phang}
{bf:1. The Zellner g default.} Sec. 2.2 of the paper states g = 1. The R package
never passes {cmd:prior.information.weight} to {cmd:SpikeSlabPrior()}, so it
inherits that function's default of 0.01. Since compatibility with R is the
stated goal, {cmd:ginfo()} defaults to {bf:0.01}. Use {cmd:ginfo(1)} to follow
the printed paper instead. The effect on results is small because the prior
carries only a hundredth of one observation's worth of information either way.

{phang}
{bf:2. The exponent in eq. (2.13).} The typeset marginal in the paper carries
the exponent (N/2) - 1 on S. The conjugate normal-inverse-Gamma marginal, for
the prior actually stated in eq. (2.11), has exponent -N/2, which is what
{cmd:BoomSpikeSlab} computes. This command uses -N/2, following the reference
implementation.

{phang}
{bf:3. The observation-variance prior with no covariates.} With a regression
present, the residual variance comes from the spike-and-slab block exactly as in
R. With no covariates at all, the R package relies on a {cmd:bsts()} internal
default that the published source does not make explicit. A very diffuse prior
is used here -- guess = sd(y), nu = 0.01, upper = 1.2 sd(y) -- which has
essentially no influence on standardised data. The empirical check above shows
the no-covariate case agreeing with R to 0.24%.

{phang}
{bf:4. The dynamic-regression innovation prior.} As described above. The dynamic
branch is {bf:paper-faithful and R-approximate}; the static branch is faithful to
both.


{marker rerun}{...}
{title:Running the check yourself}

{pstd}
The installed package carries a self-testing harness that validates the command
{bf:without needing R at all}. Every example has a known truth, and the last
section runs the paper's own Monte Carlo design for interval coverage and power:

{phang2}{cmd:. net get causalimpact}{p_end}
{phang2}{cmd:. do causalimpact_example.do}{p_end}

{pstd}
To repeat the head-to-head against R, take the verification materials from the
project repository at
{browse "https://github.com/merwanroudane":github.com/merwanroudane}. They
contain the R driver script, the shared CSVs, the full R log and a do-file that
prints R's number beside Stata's on every line. Regenerating the R half needs R
with {cmd:CausalImpact} 1.4.1 and {cmd:bsts} installed; re-running the Stata half
needs only the CSVs, which are included there.


{marker verdict}{...}
{title:What counts as a real discrepancy}

{pstd}
When comparing your own run against R, judge agreement as:

{phang2}
o cumulative and pointwise effects within a few percent{p_end}
{phang2}
o relative effects within a few tenths of a percentage point{p_end}
{phang2}
o the same significance verdict in every case{p_end}
{phang2}
o inclusion probabilities near 1 for genuinely informative controls and near 0
for noise{p_end}
{phang2}
o a placebo that is null in both{p_end}

{pstd}
Expect more disagreement, in both directions, when the post-period is long, when
the controls are weak or near-integrated, when {cmd:niter()} is small, or on the
dynamic branch. A gap far larger than Monte Carlo error, or a {bf:reversed
verdict}, is a real discrepancy and worth reporting as a bug.

{pstd}
Finally, do not use closeness to R as evidence that the {it:answer} is right.
Both programs share the same assumptions, and if the controls were contaminated
by the intervention, the two will agree precisely on the wrong number. Agreement
with R validates the implementation, not the design. For that, see the checklist
in {helpb causalimpact_interpretation:help causalimpact interpretation}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane


{title:Also see}

{psee}
Help:  {helpb causalimpact},
{helpb causalimpact_methods:causalimpact methods},
{helpb causalimpact_interpretation:causalimpact interpretation},
{helpb causalimpact_postestimation:causalimpact postestimation}
{p_end}
