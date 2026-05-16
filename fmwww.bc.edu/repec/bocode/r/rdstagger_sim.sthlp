{smcl}
{* *! version 1.0.0 Subir Hait 2026}{...}
{viewerjumpto "Syntax"      "rdstagger_sim##syntax"}{...}
{viewerjumpto "Description" "rdstagger_sim##description"}{...}
{viewerjumpto "Options"     "rdstagger_sim##options"}{...}
{viewerjumpto "Examples"    "rdstagger_sim##examples"}{...}

{title:Title}

{p 4 18 2}
{bf:rdstagger_sim} {hline 2} Simulate staggered RD panel data with network interference
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:rdstagger_sim}{cmd:,}
{opt n(#)}
{opt periods(#)}
{opt cohorts(#)}
[{opt cutoff(#)}
{opt bw(#)}
{opt density(#)}
{opt direct(#)}
{opt spill(#)}
{opt outcome(string)}
{opt seed(#)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt n(#)}}number of units; minimum 10{p_end}
{synopt:{opt periods(#)}}number of time periods; minimum 3{p_end}
{synopt:{opt cohorts(#)}}number of treatment cohorts; minimum 1{p_end}
{syntab:Optional}
{synopt:{opt cutoff(#)}}RD cutoff on the running variable; default 0{p_end}
{synopt:{opt bw(#)}}bandwidth for cohort assignment; default 1{p_end}
{synopt:{opt density(#)}}network edge probability in (0,1); default 0.1{p_end}
{synopt:{opt direct(#)}}true direct ATT; default 0.3{p_end}
{synopt:{opt spill(#)}}true spillover effect; default 0.1{p_end}
{synopt:{opt outcome(string)}}{cmd:continuous} (default), {cmd:binary}, or {cmd:count}{p_end}
{synopt:{opt seed(#)}}random seed for reproducibility; default 42{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rdstagger_sim} generates synthetic panel data suitable for demonstrating
and testing {helpb rdstagger}. The data-generating process includes:

{phang2}
{bf:Running variable}: drawn as x ~ N(0, 1.5). Units with x < cutoff are
treatment-eligible.

{phang2}
{bf:Cohort assignment}: eligible units are assigned to treatment cohorts
based on their position in the running variable distribution below the
cutoff. The total number of cohorts is controlled by {opt cohorts()}.
Units with x >= cutoff are never-treated.

{phang2}
{bf:Network interference}: each unit has a random number of neighbors
drawn from Poisson(density * n). The spillover exposure variable
{cmd:spill_share} records the fraction of a unit's neighbors that are
currently treated.

{phang2}
{bf:Outcome}: the latent outcome is
y* = alpha_i + lambda_t + 0.2*x + direct*treated + spill*spill_share + epsilon,
where alpha_i ~ N(0, 0.5) is a unit fixed effect and lambda_t ~ N(0, 0.3)
is a time fixed effect. For {opt outcome(binary)}, y = 1(invlogit(y*) > U[0,1]).
For {opt outcome(count)}, y ~ Poisson(exp(y*)).

{pstd}
The resulting dataset is in long format with one row per unit per period
and is left in memory (any prior data are replaced).

{marker options}{...}
{title:Options}

{phang}{opt n(#)} total number of units in the cross-section. Must be >= 10.{p_end}

{phang}{opt periods(#)} number of calendar periods (T). Must be >= 3 so that
at least one pre-treatment period exists.{p_end}

{phang}{opt cohorts(#)} number of staggered treatment cohorts. Cohorts adopt
treatment at evenly spaced periods. Must be >= 1 and < periods.{p_end}

{phang}{opt cutoff(#)} threshold on the running variable below which units
are treatment-eligible. Default 0.{p_end}

{phang}{opt bw(#)} controls the range of the running variable assigned to
treatment cohorts below the cutoff. Default 1.{p_end}

{phang}{opt density(#)} probability that any pair of units is connected by
a network edge (Erdos-Renyi model approximation). Must be in (0,1).
Default 0.1 (sparse network).{p_end}

{phang}{opt direct(#)} the true direct ATT used in the data-generating process.
Default 0.3.{p_end}

{phang}{opt spill(#)} the true spillover coefficient on {cmd:spill_share}.
Default 0.1.{p_end}

{phang}{opt outcome(string)} outcome type. {cmd:continuous} (default) produces
a normally distributed outcome. {cmd:binary} produces a 0/1 outcome via a
logistic link. {cmd:count} produces a non-negative integer via a Poisson link.{p_end}

{phang}{opt seed(#)} sets the random-number seed for reproducibility.
Default 42.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Basic simulation:{p_end}
{phang2}{cmd:. rdstagger_sim, n(400) periods(8) cohorts(3) direct(0.3) spill(0.1) seed(42)}{p_end}
{phang2}{cmd:. describe}{p_end}
{phang2}{cmd:. tab g}{p_end}
{phang2}{cmd:. sum y x treated spill_share}{p_end}

{pstd}Binary outcome:{p_end}
{phang2}{cmd:. rdstagger_sim, n(500) periods(6) cohorts(2) outcome(binary) seed(1)}{p_end}

{pstd}Dense network with larger spillovers:{p_end}
{phang2}{cmd:. rdstagger_sim, n(300) periods(6) cohorts(2) density(0.3) spill(0.2) seed(99)}{p_end}

{title:Variables created}

{synoptset 20}{...}
{synopt:{cmd:id}}unit identifier{p_end}
{synopt:{cmd:period}}calendar time period{p_end}
{synopt:{cmd:y}}outcome variable{p_end}
{synopt:{cmd:x}}running variable{p_end}
{synopt:{cmd:g}}cohort (first treated period; {cmd:.} = never-treated){p_end}
{synopt:{cmd:treated}}binary treatment indicator{p_end}
{synopt:{cmd:neighbor_treated}}indicator: at least one neighbor treated{p_end}
{synopt:{cmd:spill_share}}share of neighbors currently treated{p_end}

{title:Also see}

{psee}
{helpb rdstagger}, 
{p_end}
