{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar bayes" "help gvar_bayes"}{...}
{vieweralsosee "gvar diag" "help gvar_diag"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar bforecast" "help gvar_bforecast"}{...}
{vieweralsosee "gvar bdic" "help gvar_bdic"}{...}
{viewerjumpto "Syntax" "gvar_bconv##syntax"}{...}
{viewerjumpto "Description" "gvar_bconv##description"}{...}
{viewerjumpto "Options" "gvar_bconv##options"}{...}
{viewerjumpto "Remarks" "gvar_bconv##remarks"}{...}
{viewerjumpto "Examples" "gvar_bconv##examples"}{...}
{viewerjumpto "Stored results" "gvar_bconv##results"}{...}
{title:Title}

{phang}
{bf:gvar bconv} {hline 2} Geweke's convergence diagnostic for the sampled chains


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar bconv} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt crit:ical(#)}}two-sided normal cutoff. Default 1.96.{p_end}
{synopt:{opt frac1(#)}}leading share of each chain. Default 0.1.{p_end}
{synopt:{opt frac2(#)}}trailing share of each chain. Default 0.5.{p_end}
{synopt:{opt byunit}}one row per unit.{p_end}
{synopt:{opt gr:aph}}bar chart of the share exceeding, by unit.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}

{pstd}
{helpb gvar_bayes:gvar bayes} must have run first: this reads the retained draws
and has nothing to say about a model fitted by
{helpb gvar_estimate:gvar estimate}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar bconv} computes Geweke's (1992) convergence diagnostic for every
sampled coefficient of every unit and reports how many exceed the cutoff.

{pstd}
The test compares the mean of the first part of a chain with the mean of the last
part. If the draws come from the stationary distribution the two are equal, and

{p 8 8 2}{it:Z = (m1 - m2) / sqrt(s1/n1 + s2/n2)}{p_end}

{pstd}
is asymptotically standard normal, where {it:s} is the {bf:spectral density at
zero} rather than the sample variance.


{marker options}{...}
{title:Options}

{phang}
{opt critical(#)} is the two-sided normal cutoff. 1.96 is the 5% point and is
what BGVAR's {cmd:conv.diag} uses.

{phang}
{opt frac1(#)} and {opt frac2(#)} are the leading and trailing shares of each
chain, 10% and 50% by default, as in {cmd:coda}'s {cmd:geweke.diag}. They must be
positive and sum to no more than one: overlapping windows would compare a stretch
of the chain with itself.

{phang}
{opt byunit} adds a table with one row per unit. Worth reading whenever the
overall share is high, because a single badly identified country model often
accounts for all of it.

{phang}
{opt graph} draws the share exceeding the cutoff for each unit, with a reference
line at 5% -- the share the null implies. Without that line there is no way to
tell an ordinary chain from a bad one by eye.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The test can only fail to reject.} A share near 5% is evidence that nothing
is visibly wrong, not evidence that the chain has converged. No diagnostic
establishes convergence; they only ever catch some of the ways it fails.

{pstd}
{bf:Why the spectral density at zero and not the sample variance.} An MCMC chain
is autocorrelated. The variance of its sample mean is the {it:long-run} variance
divided by the number of draws, and the spectral density at zero is exactly that
long-run variance. Substituting the sample variance would understate the standard
error, inflate every {it:Z}, and reject far too often -- which a reader would
naturally blame on the sampler rather than on the diagnostic.

{pstd}
{bf:It slightly over-rejects, and that is inherent.} The spectral density is
estimated by an AR fit chosen by AIC, and Yule-Walker coefficient estimates are
biased towards zero in finite samples. That makes {it:1 - sum(phi)} a little too
large and the estimated density a little too small, so {it:Z} is a little too
big. Measured on this implementation: about 2.5% low on the density across
{it:phi} from -0.4 to 0.8, giving {it:sd(Z)} of roughly 1.07 and a rejection rate
near 7.5% where 5% is nominal. {cmd:coda} has the same property, since it is the
same estimator. Read a share of 7 or 8% as unremarkable.

{pstd}
{bf:Coefficients that never moved have no Z.} {cmd:prior(ssvs)} and the shrinkage
priors hold coefficients at zero by design, and a chain with no variation has no
Geweke statistic. Those are counted separately and excluded from the
denominator, not recorded as passes -- treating them as passes would make a
heavily shrunk model look better converged the more it shrank.

{pstd}
{bf:Not from the BGVAR source.} {cmd:conv.diag} delegates to
{cmd:coda::geweke.diag}, and {cmd:coda} is a dependency rather than part of the
package, so the diagnostic was written from the algorithm -- the same situation as
{cmd:GIGrvg} for {cmd:prior(ng)}. It is therefore gated on its own test rather
than on a comparison with another implementation: the spectral density against
its closed form {it:sigma^2/(1-phi)^2} for an AR(1), the {bf:size} of the test on
i.i.d. chains, and the {bf:power} of it on a drifting chain and on a random walk.
A diagnostic that never rejects is as useless as one that always does, and only
the last of those separates them.

{pstd}
{bf:One deliberate difference from BGVAR.} It runs the diagnostic on
{it:A_large}, the stacked coefficients; this runs it on the per-unit draws, which
are the parameters the sampler actually moves. The stacked matrix is a
deterministic function of them, so nothing is lost, and {opt byunit} can then
name the unit responsible.


{marker examples}{...}
{title:Examples}

{pstd}
Sample, then check the chains before reading anything from them:{p_end}
{phang2}{cmd:. gvar bayes, prior(mn) prmean(0) noeigentrim draws(4000) burnin(4000) seed(20260811)}{p_end}
{phang2}{cmd:. gvar bconv}{p_end}

{pstd}
When the share is high, find out which units are responsible:{p_end}
{phang2}{cmd:. gvar bconv, byunit}{p_end}
{phang2}{cmd:. gvar bconv, graph}{p_end}

{pstd}
A stricter cutoff, and a longer trailing window:{p_end}
{phang2}{cmd:. gvar bconv, critical(2.58) frac1(0.2) frac2(0.5)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar bconv} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(table)}}unit, examined, exceeding, no-Z; one row per unit{p_end}
{synopt:{cmd:r(n)}}coefficients examined{p_end}
{synopt:{cmd:r(nexceed)}}how many exceeded the cutoff{p_end}
{synopt:{cmd:r(pexceed)}}that as a percentage{p_end}
{synopt:{cmd:r(nskipped)}}coefficients with no Z{p_end}
{synopt:{cmd:r(critical)}}the cutoff used{p_end}
{synopt:{cmd:r(draws)}}retained draws per chain{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
BGVAR {it:R/helpers.R} {cmd:conv.diag}; {cmd:coda}'s {cmd:geweke.diag} and
{cmd:spectrum0.ar}. Geweke, J. (1992), Evaluating the accuracy of sampling-based
approaches to calculating posterior moments, {it:Bayesian Statistics 4}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
