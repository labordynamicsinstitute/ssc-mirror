{smcl}
{* *! version 1.0.1  27may2026}{...}
{vieweralsosee "dnqrlib (package TOC)"   "help dnqrlib"}{...}
{vieweralsosee "nqar"                    "help nqar"}{...}
{vieweralsosee "dnqr"                    "help dnqr"}{...}
{vieweralsosee "dnqr_plot"               "help dnqr_plot"}{...}
{vieweralsosee "dnqr_impulse"            "help dnqr_impulse"}{...}
{vieweralsosee "dnqr_postestimation"     "help dnqr_postestimation"}{...}
{viewerjumpto "Syntax"            "dnqr_simulate##syntax"}{...}
{viewerjumpto "Description"       "dnqr_simulate##description"}{...}
{viewerjumpto "Options"           "dnqr_simulate##options"}{...}
{viewerjumpto "Examples"          "dnqr_simulate##examples"}{...}
{viewerjumpto "Returned"          "dnqr_simulate##returned"}{...}
{viewerjumpto "Also see"          "dnqr_simulate##alsosee"}{...}

{title:Title}

{p2colset 5 22 26 2}{...}
{p2col :{bf:dnqr_simulate} {hline 2}}Monte Carlo data simulator for NQAR / DNQR{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:dnqr_simulate} {cmd:,} {opth n(#)} {opth t(#)} [{it:options}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Required}
{synopt :{opth n(#)}}cross-sectional dimension{p_end}
{synopt :{opth t(#)}}time-series dimension (after burn-in){p_end}

{syntab :Network}
{synopt :{opt wt:ype(string)}}{bf:powerlaw} (default), {bf:block}, {bf:dyad} or {bf:asym}{p_end}
{synopt :{opt wp:aram(#)}}topology parameter (default 2.5){p_end}
{synopt :{opt wname(string)}}name under which to store the network matrix (default {bf:Wsim}){p_end}
{synopt :{opt mata}}store the network as a Mata matrix instead of a Stata matrix{p_end}

{syntab :Parameters}
{synopt :{opt b:urnin(#)}}burn-in length (default 50){p_end}
{synopt :{opt err:ordist(string)}}innovation: {bf:normal} (default), {bf:t} or {bf:chi}{p_end}
{synopt :{opt errordf(#)}}degrees of freedom (for t / chi); default 5{p_end}
{synopt :{opt gam:ma1(#)}}contemporaneous network coefficient (default 0.20){p_end}
{synopt :{opt gam:ma2(#)}}lagged-network coefficient (default 0.30){p_end}
{synopt :{opt gam:ma3(#)}}own-lag coefficient (default 0.30){p_end}
{synopt :{opt z(#)}}number of time-invariant nodal covariates to add (default 0){p_end}
{synopt :{opt f:actors(#)}}number of time-varying common factors (default 0){p_end}
{synopt :{opt s:eed(#)}}RNG seed (default 1234){p_end}

{syntab :Output}
{synopt :{opt clear}}drop all variables before writing the simulated data{p_end}
{synopt :{opt gen:var(string)}}name of the dependent variable (default {bf:y}){p_end}
{synopt :{opt idvar(string)}}name of the panel id (default {bf:id}){p_end}
{synopt :{opt t:imevar(string)}}name of the time variable (default {bf:t}){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dnqr_simulate} generates an N x T panel that follows the DNQR data
generating process:

{phang2}
Y{sub:it} = gamma{sub:1} sum_j w_{ij} Y{sub:jt} +
            gamma{sub:2} sum_j w_{ij} Y_{j,t-1} +
            gamma{sub:3} Y_{i,t-1} +
            Z{sub:i}'beta_z + sum_k F_{tk} beta_f +
            epsilon{sub:it}{p_end}

{pstd}
where the network W is drawn from one of four common topologies (power
law, block, dyad-symmetric or simple asymmetric).  The user controls the
innovation distribution ({bf:normal}, Student-{bf:t} or centred {bf:chi^2})
and the true parameter vector.  After burn-in, the simulator writes the
long-form panel to the current dataset, {help xtset}s it and stores the
network matrix under a user-chosen name (Stata or Mata) ready for
{cmd:nqar} / {cmd:dnqr}.


{marker options}{...}
{title:Options}

{phang}{opt n(#)} and {opt t(#)} set the panel dimensions.

{phang}{opt wtype()} selects the network topology.  See
{help dnqr_simulate##gen:Network generators} below.

{phang}{opt wparam(#)} a scalar parameter of the chosen generator:

{p 12 16 2}
{bf:powerlaw}: the tail exponent (smaller = denser);{break}
{bf:block}:    the number of blocks;{break}
{bf:dyad}:     the dyadic edge density (fraction of all pairs);{break}
{bf:asym}:     half-width of the adjacency band.{p_end}

{phang}{opt wname()} the name under which the network is stored. Pair
with {opt mata} to receive a Mata matrix.

{phang}{opt burnin(#)} discards the first {it:#} simulated time periods.

{phang}{opt errordist()} and {opt errordf(#)} control the innovation
distribution.

{phang}{opt gamma1 gamma2 gamma3} set the true coefficients used by the
DGP.

{phang}{opt z(#)} adds {it:#} time-invariant nodal covariates named
{cmd:Z1, Z2, ...}; similarly {opt factors(#)} adds {cmd:F1, F2, ...}
common factors.

{phang}{opt seed(#)} sets the Mata random-number seed.

{phang}{opt clear} drops all variables before writing simulated data.


{marker examples}{...}
{title:Examples}

{phang}{cmd}. * 1. small Monte Carlo replication{txt}{p_end}
{phang}{cmd}. dnqr_simulate, n(60) t(40) gamma1(0.25) z(2) factors(2) clear wname(W){p_end}
{phang}{cmd}. dnqr y, network(W) rowstd q(0.1 0.5 0.9) z(Z1 Z2) factors(F1 F2){p_end}

{phang}{cmd}. * 2. heavy-tailed innovations and block network{txt}{p_end}
{phang}{cmd}. dnqr_simulate, n(100) t(60) wtype(block) wparam(5) errordist(t) errordf(5) clear wname(W){p_end}

{phang}{cmd}. * 3. store W as a Mata matrix and call dnqr with -mata-{txt}{p_end}
{phang}{cmd}. dnqr_simulate, n(80) t(40) wname(Wm) mata clear{p_end}
{phang}{cmd}. dnqr y, network(Wm) mata rowstd q(0.1 0.5 0.9){p_end}


{marker returned}{...}
{title:Returned results}

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(N)}}cross-section size{p_end}
{synopt:{cmd:r(T)}}time-series length{p_end}
{synopt:{cmd:r(Wd)}}network density (share of nonzero entries off-diagonal){p_end}
{synopt:{cmd:r(wname)}}name under which W is stored{p_end}


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Package TOC: {help dnqrlib}{break}
Estimators: {help nqar}, {help dnqr}{break}
Plotting / impulse: {help dnqr_plot}, {help dnqr_impulse}{p_end}

{p 4 4 2}
{bf:Author:} Dr Merwan Roudane {c -}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
