{smcl}
{* 25jul2026}{...}
{vieweralsosee "causalrep ols" "help causalrep ols"}{...}
{vieweralsosee "causalrep iv" "help causalrep iv"}{...}
{vieweralsosee "causalrep did" "help causalrep did"}{...}
{hline}
help for {hi:causalrep}
{hline}

{title:Title}

{phang}
{bf:causalrep} {hline 2} Quantifying the internal validity and representativeness of weighted estimands{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:causalrep} {it:subcommand} ... [{cmd:,} {it:options}]

{synoptset 16}{...}
{synopthdr:subcommand}
{synoptline}
{synopt :{helpb causalrep ols:ols}}ordinary least squares (OLS){p_end}
{synopt :{helpb causalrep iv:iv}}instrumental variables (IV){p_end}
{synopt :{helpb causalrep did:did}}two-way fixed effects (TWFE){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:causalrep} implements diagnostics developed by Poirier and Słoczyński (2026) for selected weighted
estimands: ordinary least squares (OLS), instrumental variables (IV), and two-way fixed effects (TWFE).
{p_end}

{pstd}
A weighted estimand may be representable as the average treatment effect for a possibly latent subpopulation
of a target population.  The measure of internal validity, or MIV, is the largest possible share of the target
population for which such a representation exists.  The measure of representativeness, or MR, is the corresponding
largest share of the entire population.
{p_end}

{pstd}
The population MIV and MR lie between zero and one.  Larger values indicate a larger possible implicit
subpopulation.  When negative estimated weights are detected, {cmd:causalrep} reports the inverse maximum weight
under the MIV label.  If any population weights are negative, the unrestricted-CATE MIV, and the corresponding
MR where applicable, are zero.  See Poirier and Słoczyński (2026) for details.
{p_end}

{pstd}
The relevant target population differs across applications.  For {cmd:causalrep ols}, it is the entire population,
so MIV and MR coincide.  For {cmd:causalrep iv}, the target is the complier population.  For {cmd:causalrep did},
the target is the treated population.
{p_end}

{pstd}
These measures do not test the identifying assumptions required for causal interpretation.  Their interpretation
is conditional on assumptions such as unconfoundedness for OLS, instrument validity and monotonicity for IV,
or parallel trends for TWFE.
{p_end}

{pstd}
This is a companion software package for Poirier and Słoczyński (2026).  Please cite this paper
if you use {cmd:causalrep} in your work.
{p_end}


{marker references}{...}
{title:References}

{phang}
Poirier, Alexandre, and Tymon Słoczyński (2026). "Quantifying the Internal Validity
of Weighted Estimands." arXiv preprint arXiv:2404.14603. Available at {browse "https://arxiv.org/abs/2404.14603"}.{p_end}
