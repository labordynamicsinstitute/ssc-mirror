{smcl}
{* *! version 1.0.0  29may2026}{...}
{vieweralsosee "qqr" "help qqr"}{...}
{vieweralsosee "qqribbon" "help qqribbon"}{...}
{vieweralsosee "qqdiff" "help qqdiff"}{...}
{vieweralsosee "qqheat" "help qqheat"}{...}
{vieweralsosee "qqr package overview" "help qqr_package"}{...}
{viewerjumpto "Syntax" "qqtest##syntax"}{...}
{viewerjumpto "Description" "qqtest##desc"}{...}
{viewerjumpto "Workflow" "qqtest##flow"}{...}
{viewerjumpto "The hypotheses" "qqtest##hyp"}{...}
{viewerjumpto "The statistics" "qqtest##stat"}{...}
{viewerjumpto "Options" "qqtest##opts"}{...}
{viewerjumpto "Stored results" "qqtest##saved"}{...}
{viewerjumpto "Examples" "qqtest##exa"}{...}
{viewerjumpto "References" "qqtest##refs"}{...}
{title:Title}

{p 4 19 2}
{hi:qqtest} {hline 2} Formal tests on the QQR surface {it:β(τ,θ)} (joint bootstrap)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:qqtest} {cmd:using} {it:drawsfile} [{cmd:,} {opt test(name)} {opt dim(name)}]

{p 4 4 2}
where {it:drawsfile} is the long-format bootstrap-draws dataset written by
{help qqr:qqr ..., bsave(}{it:drawsfile}{help qqr:)} (variables
{bf:rep tau theta beta}).

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt test(name)}}hypothesis to test: {bf:zero} (default){bf:, symmetry, constancy}{p_end}
{synopt:{opt dim(name)}}for {bf:constancy} only: {bf:tau} (default) or {bf:theta}{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{p 4 4 2}
{cmd:qqtest} turns the quantile-on-quantile {it:picture} into formal
inference.  A single QQR run gives an M×L grid of slopes {it:β(τ,θ)}; the eye
can suggest that the surface is non-zero, asymmetric, or varies across
quantiles, but a hypothesis test is needed to make the claim.  {cmd:qqtest}
provides three families of tests, each evaluated with three complementary
test statistics, using the {bf:joint bootstrap} draws so that the
{it:correlation across cells} of the surface is respected.{p_end}

{p 4 4 2}
The joint bootstrap is the key design choice: a single resample index is
reused across the {it:whole} grid in each replication, so the B draws
preserve the cross-cell covariance of {it:β(τ,θ)}.  This is what makes a
{it:simultaneous} (sup-type) test over the surface valid, rather than testing
each cell in isolation.{p_end}


{marker flow}{...}
{title:Workflow}

{p 4 4 2}
{cmd:qqtest} never re-estimates anything; it consumes a draws file.  Produce
that file once with {help qqr:qqr}:{p_end}

{phang2}{cmd:. qqr y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) nboot(500) ///}{p_end}
{phang2}{cmd:.     bci bsave(draws.dta) saving(qq.dta) replace}{p_end}

{p 4 4 2}
then run as many tests as you like against {bf:draws.dta}.  The same file
also feeds {help qqribbon:qqribbon} and {help qqdiff:qqdiff}.  More bootstrap
replications ({opt nboot()} in {cmd:qqr}) give more stable bootstrap
p-values; 500–1000 is recommended for final results.{p_end}


{marker hyp}{...}
{title:The hypotheses}

{phang}
{bf:test(zero)} {space 2}H0: {it:β(τ,θ) = 0} for every (τ,θ).  A global test
that the predictor has no quantile-on-quantile effect anywhere on the grid.
Rejection means there is some region of the (τ,θ) plane with a genuine
effect.  (q = M·L restrictions.)

{phang}
{bf:test(symmetry)} {space 2}H0: {it:β(τ,θ) = β(1−τ,θ)}.  Tests whether the
effect is symmetric in the response quantile about the median.  Rejection is
evidence of {it:tail asymmetry} — e.g. the predictor matters more in the
lower tail of {it:y} than in the upper tail.  (q = ⌊M/2⌋·L restrictions.)

{phang}
{bf:test(constancy)} {space 2}H0: the slope does not vary along one quantile
dimension.  With {opt dim(tau)} it tests {it:β(τ,θ) = β(τ′,θ)} for all τ
within each θ (no variation across response quantiles); with
{opt dim(theta)} it tests constancy across predictor quantiles.  Rejection
means the relationship is genuinely quantile-dependent — the central
justification for using QQR over a single quantile or OLS regression.
(q = (M−1)·L or M·(L−1) restrictions.)


{marker stat}{...}
{title:The statistics}

{p 4 4 2}
Each hypothesis is written as a set of linear restrictions {it:Rβ = 0} and
evaluated three ways.  Reading several together guards against any one
statistic's quirks:{p_end}

{phang}
{bf:KS (sup-t)} {space 2}the largest standardised restriction,
max|{it:Rβ}/sd|.  A {it:sup}-type statistic — sensitive to a strong
violation in even a single region.  p-value from the re-centred bootstrap.

{phang}
{bf:Cramér–von Mises} {space 2}the {it:sum} of squared standardised
restrictions.  An {it:integrated} statistic — sensitive to many small,
diffuse violations spread over the surface.  p-value from the bootstrap.

{phang}
{bf:Wald} {space 2}the quadratic form {it:(Rβ)′ V⁻¹ (Rβ)} using the full
bootstrap covariance {it:V} of the restrictions.  Reported with both a
bootstrap p-value and the χ²(q) asymptotic p-value.

{p 4 4 2}
In every case a {bf:small p-value rejects H0}.  Prefer the bootstrap
p-values; the χ² column is a convenience cross-check for the Wald statistic
and can be unreliable when q is large relative to B.{p_end}


{marker opts}{...}
{title:Options}

{phang}
{opt test(name)} selects the hypothesis: {bf:zero} (default), {bf:symmetry},
or {bf:constancy}.

{phang}
{opt dim(name)} applies only to {bf:test(constancy)} and picks the dimension
held constant under H0: {bf:tau} (default, vary the response quantile) or
{bf:theta} (vary the predictor quantile).


{marker saved}{...}
{title:Stored results}

{p 4 4 2}{cmd:qqtest} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(q)}}number of restrictions{p_end}
{synopt:{cmd:r(KS)}}KS sup-t statistic{p_end}
{synopt:{cmd:r(p_KS)}}bootstrap p-value for KS{p_end}
{synopt:{cmd:r(CvM)}}Cramér–von Mises statistic{p_end}
{synopt:{cmd:r(p_CvM)}}bootstrap p-value for CvM{p_end}
{synopt:{cmd:r(Wald)}}Wald statistic{p_end}
{synopt:{cmd:r(p_Wald_boot)}}bootstrap p-value for Wald{p_end}
{synopt:{cmd:r(p_Wald_chi2)}}χ²(q) asymptotic p-value for Wald{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(test)}}the hypothesis tested{p_end}
{synopt:{cmd:r(dim)}}the constancy dimension{p_end}


{marker exa}{...}
{title:Examples}

{p 4 4 2}{bf:Build the draws file once, then test}{p_end}
{phang2}{cmd:. qqr y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) nboot(500) bsave(draws.dta) replace}{p_end}
{phang2}{cmd:. qqtest using draws.dta, test(zero)}{p_end}
{phang2}{cmd:. qqtest using draws.dta, test(symmetry)}{p_end}
{phang2}{cmd:. qqtest using draws.dta, test(constancy) dim(tau)}{p_end}
{phang2}{cmd:. qqtest using draws.dta, test(constancy) dim(theta)}{p_end}

{p 4 4 2}{bf:Grab a stored p-value}{p_end}
{phang2}{cmd:. qqtest using draws.dta, test(zero)}{p_end}
{phang2}{cmd:. display "reject no-effect? " (r(p_Wald_boot) < 0.05)}{p_end}


{marker refs}{...}
{title:References}

{phang}Sim, N. and Zhou, H. (2015). Oil prices, US stock return, and the
dependence between their quantiles. {it:Journal of Banking & Finance} 55:1-12.{p_end}

{phang}Koenker, R. (2005). {it:Quantile Regression}. Cambridge University Press.{p_end}


{title:Author}

{p 4 4 2}Merwan Roudane.  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:See also}

{p 4 8 2}{help qqr},  {help qqribbon},  {help qqdiff},  {help qqheat},
{help qqsurf3d},  {help qqr_package}{p_end}
