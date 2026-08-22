{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{vieweralsosee "gvar datasets" "help gvar_datasets"}{...}
{viewerjumpto "Syntax" "gvar##syntax"}{...}
{viewerjumpto "Description" "gvar##description"}{...}
{viewerjumpto "The workflow" "gvar##workflow"}{...}
{viewerjumpto "Subcommands" "gvar##subcommands"}{...}
{viewerjumpto "A first session" "gvar##example"}{...}
{viewerjumpto "What the model is" "gvar##model"}{...}
{viewerjumpto "Sources" "gvar##sources"}{...}
{title:Title}

{phang}
{bf:gvar} {hline 2} Global Vector Autoregressive modelling: estimation,
inference and dynamic analysis


{marker syntax}{...}
{marker subcommands}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar} {it:subcommand} {ifin} [{cmd:,} {it:options}]

{pstd}
Every analysis follows the same order. Each step needs the one before it, and
{cmd:gvar} says so plainly if you skip one.

{synoptset 26 tabbed}{...}
{synopthdr:data and setup}
{synoptline}
{synopt:{helpb gvar_setup:gvar setup}}declare the panel, the units, the
domestic and global variables{p_end}
{synopt:{helpb gvar_weights:gvar weights}}build or load the link weights{p_end}
{synopt:{helpb gvar_foreign:gvar foreign}}construct the foreign-specific
variables {it:x*}{p_end}
{synopt:{helpb gvar_describe:gvar describe}}what is in memory, and the order
of the global vector{p_end}

{synopthdr:pre-estimation testing}
{synoptline}
{synopt:{helpb gvar_unitroot:gvar unitroot}}ADF, weighted-symmetric, ADF-GLS,
KPSS, Phillips-Perron{p_end}
{synopt:{helpb gvar_lags:gvar lags}}select {it:p} and {it:q} for each country
model{p_end}
{synopt:{helpb gvar_coint:gvar coint}}Johansen trace and maximal-eigenvalue
tests with Pesaran-Shin-Smith critical values{p_end}

{synopthdr:estimation}
{synoptline}
{synopt:{helpb gvar_estimate:gvar estimate}}reduced-rank ML of every VECMX*
country model{p_end}
{synopt:{helpb gvar_bayes:gvar bayes}}Bayesian alternative to
{cmd:gvar estimate}: Minnesota, spike-and-slab or Normal-Gamma{p_end}
{synopt:{helpb gvar_dominant:gvar dominant}}dominant-unit / global exogenous
model, estimated before the country models are solved{p_end}
{synopt:{helpb gvar_solve:gvar solve}}stack the country models and solve the
GVAR{p_end}

{synopthdr:specification testing}
{synoptline}
{synopt:{helpb gvar_wetest:gvar wetest}}weak exogeneity of the foreign
variables{p_end}
{synopt:{helpb gvar_contemp:gvar contemp}}contemporaneous effects of foreign
on domestic variables{p_end}
{synopt:{helpb gvar_avgcorr:gvar avgcorr}}average pairwise cross-section
correlations{p_end}
{synopt:{helpb gvar_diag:gvar diag}}residual diagnostics, univariate and
system-wide{p_end}
{synopt:{helpb gvar_stability:gvar stability}}structural stability battery,
with bootstrap critical values{p_end}
{synopt:{helpb gvar_overid:gvar overid}}LR test of over-identifying
restrictions on beta{p_end}
{synopt:{helpb gvar_gc:gvar gc}}Granger and instantaneous causality{p_end}
{synopt:{helpb gvar_bconv:gvar bconv}}Geweke convergence diagnostic for the
chains from {cmd:gvar bayes}{p_end}
{synopt:{helpb gvar_bforecast:gvar bforecast}}predictive density over the
retained draws, so the interval carries parameter uncertainty{p_end}
{synopt:{helpb gvar_bdic:gvar bdic}}deviance information criterion, for
comparing priors on the same data{p_end}

{synopthdr:dynamic analysis}
{synoptline}
{synopt:{helpb gvar_irf:gvar irf}}generalized, orthogonalised and structural
impulse responses{p_end}
{synopt:{helpb gvar_fevd:gvar fevd}}forecast error variance
decomposition{p_end}
{synopt:{helpb gvar_pp:gvar pp}}persistence profiles of the cointegrating
relations{p_end}
{synopt:{helpb gvar_spillover:gvar spillover}}Diebold-Yilmaz
connectedness{p_end}
{synopt:{helpb gvar_hd:gvar hd}}historical decomposition{p_end}
{synopt:{helpb gvar_forecast:gvar forecast}}point and conditional
forecasts{p_end}
{synopt:{helpb gvar_tcdecomp:gvar tcdecomp}}Beveridge-Nelson trend/cycle
decomposition{p_end}

{synopthdr:reporting and model state}
{synoptline}
{synopt:{helpb gvar_report:gvar report}}one specification audit of the fitted
model{p_end}
{synopt:{helpb gvar_import:gvar import}}read a GVAR Toolbox 2.0 workbook, one
sheet per variable{p_end}
{synopt:{helpb gvar_save:gvar save}}write the fitted model to disk{p_end}
{synopt:{helpb gvar_use:gvar use}}read it back{p_end}
{synopt:{helpb gvar_clear:gvar clear}}drop the model from memory{p_end}
{synoptline}

{pstd}
Subcommands may be abbreviated. {cmd:gvar est} is {cmd:gvar estimate},
{cmd:gvar diag} is {cmd:gvar diagnostics}. The four state commands
({cmd:save}, {cmd:use}, {cmd:clear}, and {cmd:gc}) must be spelled out, so
that they cannot be reached by a slip of the keyboard.


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar} fits and analyses the Global Vector Autoregressive model of
Pesaran, Schuermann and Weiner (2004) and Dees, di Mauro, Pesaran and Smith
(2007). It is a faithful Stata port of three reference implementations:

{p 8 12 2}
{bf:GVAR Toolbox 2.0} (L. Vanessa Smith and Alessandro Galesi, August 2014),
MATLAB{break}
{bf:GVARX 1.2} (Ho Tsung-wu), R{break}
{bf:BGVAR 2.6.0} (Boeck, Feldkircher and Huber), R

{pstd}
Every routine names the file and, where it matters, the line of the source it
follows. {helpb gvar_methods:gvar methods} carries the equations, the
step-to-source map, and a record of the places where the sources disagree
with each other or contain defects, with the evidence that settled each one.


{marker workflow}{...}
{title:The workflow}

{pstd}
A GVAR is built in stages, and each stage has to succeed before the next is
meaningful:

{p 8 12 2}
1. {bf:setup} tells {cmd:gvar} which variable belongs to which unit, which
variables are global, and how each country model is specified.{p_end}
{p 8 12 2}
2. {bf:weights} supply the link matrices {it:W_i}. Trade flows are the usual
choice; financial flows and equal weights are also supported.{p_end}
{p 8 12 2}
3. {bf:foreign} builds {it:x*_it = W_i x_t}, the weighted average of the other
units' variables that each country model treats as weakly exogenous.{p_end}
{p 8 12 2}
4. {bf:estimate} fits each VECMX* by reduced-rank ML, conditional on the
foreign variables being weakly exogenous.{p_end}
{p 8 12 2}
5. {bf:solve} stacks the country models into
{it:G0 x_t = sum H_l x(t-l) + zeta_t}
and inverts {it:G0} to get the reduced form.{p_end}

{pstd}
Only after {bf:solve} do the dynamic subcommands become available. Before
it, the testing subcommands work on the country models individually.


{marker example}{...}
{title:A first session}

{pstd}
The shipped demo reproduces the GVAR Toolbox's own 26-unit example: 33
countries with the euro area aggregated from its eight members, quarterly
from 1979Q2 to 2013Q1, six domestic variables and three commodity prices.
See {helpb gvar_datasets:gvar datasets}.

        {cmd:. use gvar_demo26}

        {cmd:. gvar setup y Dp eq ep r lr, unit(country) time(quarter) ///}
                {cmd:global(poil pmat pmetal) gendog(poil=usa pmat=usa pmetal=usa) ///}
                {cmd:spec(gvar_demospec.dta)}

        {cmd:. gvar weights using gvar_flows.dta, flow(trade) source(partner) ///}
                {cmd:destination(home) year(year) years(2009 2011) type(1) ///}
                {cmd:map(gvar_demoagg.dta)}

        {cmd:. gvar foreign}
        {cmd:. gvar estimate, vce(nwest)}
        {cmd:. gvar solve}

{pstd}
Then, for instance, the response of output everywhere to a US interest-rate
shock, with bootstrap bands:

        {cmd:. gvar irf, shock(usa:r) response(y) step(24) reps(200) shuffle}

{pstd}
or the connectedness of the system:

        {cmd:. gvar spillover, step(24) by(unit)}

{pstd}
{bf:The whole thing, annotated.} {bf:net get gvar} is the
complete worked analysis: every stage on the shipped data, with the reasoning
for each choice alongside it. Select the code and run it, or copy it into a
do-file.

{pmore}
It shipped as {cmd:gvar_example.do} through version 1.0.0. SSC caps a package
description at 100 lines, so the example became a help page -- the same one
line in the package, but reachable by name and copyable from the viewer.

{pstd}
Once the model is fitted, {helpb gvar_report:gvar report} gives you the
specification audit in one command, and {helpb gvar_save:gvar save} stores the
solved model so later sessions do not have to re-estimate it.


{marker model}{...}
{title:What the model is}

{pstd}
Each unit {it:i} has {it:k_i} domestic variables {it:y_it} and {it:k*_i}
weakly exogenous foreign variables {it:y*_it}, built as a weighted average of
the other units' variables using weights {it:w_ij} that sum to one:

        {it:y*_it = sum_j w_ij y_jt}

{pstd}
The country model is a VECMX*, a vector error-correction model with the
foreign variables entering as I(1) weakly exogenous regressors:

        {it:D y_it = c_i + alpha_i beta_i' z_i(t-1) + Lambda_i0 D y*_it}
                {it: + sum Gamma_il D z_i,t-l + eps_it}

{pstd}
where {it:z_it = (y_it', y*_it')'}. Stacking all units through the link
matrices {it:W_i} gives the global model

        {it:G0 x_t = h0 + h1 t + sum_l H_l x(t-l) + zeta_t}

{pstd}
which is solved for the reduced form
{it:x_t = d0 + d1 t + sum_l F_l x(t-l) + eta_t}
with {it:F_l = G0^-1 H_l} and {it:eta_t = G0^-1 zeta_t}. The
distinction between {it:zeta} and {it:eta} matters throughout and is a
frequent source of error; see {helpb gvar_methods:gvar methods}.


{marker sources}{...}
{title:Sources}

{phang}
Pesaran, M. H., T. Schuermann and S. M. Weiner. 2004. Modeling regional
interdependencies using a global error-correcting macroeconometric model.
{it:Journal of Business and Economic Statistics} 22: 129-162.

{phang}
Dees, S., F. di Mauro, M. H. Pesaran and L. V. Smith. 2007. Exploring the
international linkages of the euro area: a global VAR analysis.
{it:Journal of Applied Econometrics} 22: 1-38.

{phang}
Pesaran, M. H. and Y. Shin. 1996. Cointegration and speed of convergence to
equilibrium. {it:Journal of Econometrics} 71: 117-143.

{phang}
Pesaran, M. H. and Y. Shin. 1998. Generalized impulse response analysis in
linear multivariate models. {it:Economics Letters} 58: 17-29.

{phang}
Smith, L. V. and A. Galesi. 2014. {it:GVAR Toolbox 2.0 User Guide}.
University of Cambridge.

{phang}
Diebold, F. X. and K. Yilmaz. 2014. On the network topology of variance
decompositions. {it:Journal of Econometrics} 182: 119-134.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
