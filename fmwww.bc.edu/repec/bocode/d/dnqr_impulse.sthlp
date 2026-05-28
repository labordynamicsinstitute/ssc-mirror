{smcl}
{* *! version 1.0.1  27may2026}{...}
{vieweralsosee "dnqrlib (package TOC)"   "help dnqrlib"}{...}
{vieweralsosee "nqar"                    "help nqar"}{...}
{vieweralsosee "dnqr"                    "help dnqr"}{...}
{vieweralsosee "dnqr_plot"               "help dnqr_plot"}{...}
{vieweralsosee "dnqr_simulate"           "help dnqr_simulate"}{...}
{vieweralsosee "dnqr_postestimation"     "help dnqr_postestimation"}{...}
{viewerjumpto "Syntax"            "dnqr_impulse##syntax"}{...}
{viewerjumpto "Description"       "dnqr_impulse##description"}{...}
{viewerjumpto "Options"           "dnqr_impulse##options"}{...}
{viewerjumpto "Examples"          "dnqr_impulse##examples"}{...}
{viewerjumpto "Returned"          "dnqr_impulse##returned"}{...}
{viewerjumpto "References"        "dnqr_impulse##references"}{...}
{viewerjumpto "Also see"          "dnqr_impulse##alsosee"}{...}

{title:Title}

{p2colset 5 22 26 2}{...}
{p2col :{bf:dnqr_impulse} {hline 2}}Tail-event impulse response (post-estimation){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:dnqr_impulse} {cmd:,} {opth network(name)} {opth h:orizon(#)}
[{it:options}]


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Required}
{synopt :{opth network(name)}}adjacency / weights matrix used in estimation{p_end}
{synopt :{opth horizon(#)}}IRF horizon (>= 1){p_end}

{syntab :Quantile and shock}
{synopt :{opt q:uantile(#)}}quantile at which to evaluate; default = the middle column of {cmd:e(quantile)}{p_end}
{synopt :{opt sh:ocknode(#)}}node receiving the unit shock; default {bf:1}{p_end}
{synopt :{opt shocksize(#)}}size of the shock; default {bf:1}{p_end}

{syntab :Network handling}
{synopt :{opt mata}}declare that {it:network()} is a Mata matrix{p_end}
{synopt :{opt rowstd}}row-standardise W{p_end}

{syntab :Plot}
{synopt :{opt p:lot}}draw a line plot of the top nodes by peak |IRF|{p_end}
{synopt :{opt top(#)}}number of nodes plotted (default {bf:6}){p_end}
{synopt :{opt sch:eme(string)}}graphics scheme{p_end}
{synopt :{opt na:me(string)}}graph name (default {bf:dnqrimpulse}){p_end}
{synopt :{opt sav:ing(filename)}}save the graph to disk{p_end}
{synopt :{opt t:itle(string)}}custom title{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dnqr_impulse} computes the tail-event-driven impulse response of the
reduced-form network process at a chosen quantile.  Letting
gamma{sub:1}(tau), gamma{sub:2}(tau), gamma{sub:3}(tau) denote the
contemporaneous, lagged-network and own-lag coefficients from the most
recent {cmd:dnqr} or {cmd:nqar} estimation, the one-step propagation
matrix is

{phang2}
G(tau) = (I - gamma{sub:1}(tau) W){sup:-1} * (gamma{sub:2}(tau) W
         + gamma{sub:3}(tau) I){p_end}

{pstd}
A unit shock v{sub:0} = e_j is applied to the chosen node and propagated
forward for {it:H} periods as G(tau){sup:h} v{sub:0}.  For NQAR the
contemporaneous term drops out so G simplifies to gamma{sub:2} W
+ gamma{sub:3} I.  See Zhu et al. (2019) Section 3 and Xu et al. (2024).


{marker options}{...}
{title:Options}

{phang}{opth network(name)} adjacency / weights matrix; must be the same
W that was used in estimation.

{phang}{opt horizon(#)} number of propagation steps (>= 1).

{phang}{opt quantile(#)} the quantile at which to evaluate the IRF.  Must
be one of the values stored in {cmd:e(quantile)}.  Default = middle
column.

{phang}{opt shocknode(#)} index of the node that receives the initial
shock (1..N).

{phang}{opt shocksize(#)} magnitude of the initial shock (default 1).

{phang}{opt mata} indicates the network matrix is in Mata.

{phang}{opt rowstd} row-standardises W before propagation.

{phang}{opt plot} draws the IRF for the top responding nodes.

{phang}{opt top(#)} controls how many nodes are plotted (sorted by the
peak |IRF| over the horizon).

{phang}{opt scheme/name/saving/title} cosmetic graph options.


{marker examples}{...}
{title:Examples}

{phang}{cmd}. dnqr y, network(W) rowstd q(0.1 0.5 0.9) z(Z1 Z2) factors(F1 F2){p_end}

{phang}{cmd}. * IRF at the upper tail; plot top-5 reactive nodes{txt}{p_end}
{phang}{cmd}. dnqr_impulse, network(W) rowstd horizon(12) quantile(0.9) shocknode(1) plot top(5){p_end}

{phang}{cmd}. * harvest the IRF matrix for custom analysis{txt}{p_end}
{phang}{cmd}. matrix IRF = r(irf){p_end}
{phang}{cmd}. matrix list IRF{p_end}


{marker returned}{...}
{title:Returned results (r-class)}

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(tau)}}quantile used{p_end}
{synopt:{cmd:r(gamma1)}}contemporaneous coefficient{p_end}
{synopt:{cmd:r(gamma2)}}lagged-network coefficient{p_end}
{synopt:{cmd:r(gamma3)}}own-lag coefficient{p_end}
{synopt:{cmd:r(irf)}}N x (H+1) matrix of impulse trajectories{p_end}
{synopt:{cmd:r(norms)}}2 x (H+1) matrix: row 1 = L2 norm of IRF at each horizon, row 2 = max |IRF|{p_end}


{marker references}{...}
{title:References}

{phang}
Xu, X., W. Wang, Y. Shin, and C. Zheng. 2024. {it:Dynamic Network
Quantile Regression Model}. SSRN Working Paper 3690631.

{phang}
Zhu, X., W. Wang, H. Wang, and W. K. H{c a:}rdle. 2019. Network quantile
autoregression. {it:Journal of Econometrics} 212(1): 345-358.


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Package TOC: {help dnqrlib}{break}
Estimators: {help nqar}, {help dnqr}{break}
Plotting: {help dnqr_plot}, {help dnqr_postestimation}{p_end}

{p 4 4 2}
{bf:Author:} Dr Merwan Roudane {c -}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
