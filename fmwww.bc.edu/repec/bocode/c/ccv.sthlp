{smcl}
{* *! version 1.0.0 January 28, 2024}
{title:Title}

{p 4 4 2}
{cmdab:ccv} {hline 2} The Causal Cluster Variance Estimator 

{marker syntax}{...}
{title:Syntax}

{p 4 4 2}
{opt ccv} {opt depvar} {opt treatment} {opt groupvar} {ifin}{cmd:,} {it:qk(#) pk(#)} [{it:options}]

{synoptset 10 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt qk}({it:#})} proportion of clusters from population which are sampled in data.{p_end}
{synopt :{opt pk}({it:#})} proportion of individuals from population which are sampled in data.{p_end}
{synopt :{opt fe}} indicates that a fixed effects model is desired.{p_end}
{synopt :{opt seed}({it:#})} set random-number seed to #.{p_end}
{synopt :{opt reps}({it:#})} the number of sample split repetitions to increase precision of variance calculation.{p_end}
{pstd}
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:ccv} implements the Causal Cluster Variance (CCV) an analytic variance estimator
 proposed by {help ccv##CCV:Abadie et al. (2023)} for models where average treatment
 effects are desired, and where standard error estimates wish to account for clustering.
 The CCV is a variance estimate which considers both the standard sampling component
 which induces variance in estimated regression coefficients, but also incorporates
 a design-based component, accounting for variability in estimates owing to treatment
 assignment mechanisms (treatment variation between clusters).  This design-based
 component implies that the variance estimate is made with respects to the finite
 population which a researcher is interested in studying, rather than infinite
 data generating processes (DGPs) of this population. When the data which is used to estimate
 treatment effects includes an important proportion of clusters in the full population,
 standard cluster-robust standard errors conceptualized for infinite realizations of
 DGPs can be substantially larger than CCV versions of these standard errors, which explicitly
 account for clustered treatment assignment and treatment effect variation across clusters.
{p_end}

{pstd}
  Following the details laid out fully in {help ccv##CCV:Abadie et al. (2023)}, the CCV is 
  suitable for OLS regressions of an outcome on a single (binary) treatment variable, or
  for OLS regressions of an outcome variable on a single (binary) treatment variable, as
  well as unit fixed effects.  The estimation of the variance requires estimating various
  sub-components, including both residuals and between-cluster variation in
  treatment effects, and if these are estimated on the full sample, correlations between
  estimation errors of sub-components generates biases.  As such, sample splits are
  conducted on data, and these separate variance components are estimaed in different samples.
{p_end}

{pstd}
 {cmd:ccv} generates standard errors based on the CCV estimator for OLS or fixed
 effect models, and for comparison reports (standard) robust and cluster-robust
 standard errors.  The {cmd:ccv} command allows for cases where all clusters are
 observed, or where only some proportion of clusters are observed.  Sampling
 information about the proportion of clusters observed, as well as the proportion
 of individuals sampled from the full population needs to be provided by the user.
{p_end}

{pstd}
 The {cmd:ccv} command is closely related to the {cmd:tscb} (Two-Stage Cluster
 Bootstrap) command. {cmd:tscb} (if installed) implements a bootstrap-version of the cluster
 variance formula of {help ccv##CCV:Abadie et al. (2023)}, and shares quite a
 similar syntax and logic.  {cmd:ccv} requires the user-written {cmd:moremata} command,
 and this should be {help ssc install:installed from the SSC} prior to running {cmd:ccv}.
{p_end}

{pstd}
Some further details related to this command can be found on an accompanying github page located at {browse "https://github.com/Daniel-Pailanir/TSCB-CCV"}.
{p_end}

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt qk}({it:#}) Indicates the proportion of clusters from the population which are
sampled in the data. This value should be strictly greater than 0, and less than
or equal to 1.  Values of 1 imply that all clusters are observed in the data,
whereas values less than 1 imply that only this proportion of clusters were sampled.
This is required.

{pstd}
{p_end}
{phang}
{opt pk}({it:#}) Indicates the proportion of population from a given cluster
which is sampled.  This value should be strictly greater than 0, and less than
or equal to 1.  For example, if a 10% sample from a microdata census is used
as the estimation sample, this value should be indicated as 0.1.  This is a
required option.

{pstd}
{p_end}
 {phang}
{opt fe} Indicates that the underlying estimator desired is a fixed effects estimator
where the dependent variable is regressed on treatment exposure as well as {opt groupvar}
fixed effects.  In this case, the CCV estimator defined in {help ccv##CCV:Abadie et al. (2023)}
section V will be implemented.  If not specified, OLS regressions are implemented.

{pstd}
{p_end}
{phang}
{opt seed}({it:#}) seed define for pseudo-random numbers. This ensures that variance
estimates can be replicated exactly, despite the fact that certain components are
estimated off of (random) splits to the sample.

{pstd}
{p_end}
{phang}
{opt reps}({it:#}) The number of sample splits to be conducted to estimate variance components (refer to {help ccv##CCV:Abadie et al. (2023, section IV.A)} for details). Default is 4.

{pstd}
{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}

{cmd:ccv} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(ATE)}}Average Treatment Effect {p_end}
{synopt:{cmd:e(se_ccv)}}Causal Cluster Variance (CCV) standard error {p_end}
{synopt:{cmd:e(se_robust)}}Heteroskedasticity robust standard error {p_end}
{synopt:{cmd:e(se_cluster)}}Cluster robust standard error {p_end}
{synopt:{cmd:e(reps)}}Number of sample splits {p_end}
{synopt:{cmd:e(N_clust)}}Number of units (groups) observed in the original panel {p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}Returns command name (ccv) {p_end}
{synopt:{cmd:e(cmdline)}}Returns command as typed {p_end}
{synopt:{cmd:e(depvar)}}Lists name of dependent variable {p_end}
{synopt:{cmd:e(clustvar)}}Provides the name of the unit (group) variable {p_end}


{pstd}
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}
Load data from 1% extract from 2000 US Census (20-50 years old) {help ccv##CCV:Abadie et al. (2023)}.

{pstd}
 . {stata webuse set www.damianclarke.net/stata/}
 
{pstd}
 . {stata webuse "census2000_1pc.dta", clear}
 
{pstd}
Run regression without FE.

{pstd}
 . {stata ccv ln_earnings college state, pk(0.01) qk(1)}
 
{pstd}
Using FE at state level.

{pstd}
 . {stata ccv ln_earnings college state, fe pk(0.01) qk(1)}
 
{pstd}
Over another dependent variable.

{pstd}
 . {stata ccv hours college state, pk(0.01) qk(1)}

{pstd}
Using FE at state level.

{pstd}
 . {stata ccv hours college state, fe pk(0.01) qk(1)}
 
{pstd}
Using a bigger sample at 5 percent.

{pstd}
 . {stata webuse "census2000_5pc.dta", clear}
 
{pstd}
 . {stata ccv ln_earnings college state, pk(0.05) qk(1)}

{pstd}
 . {stata ccv ln_earnings college state, fe pk(0.05) qk(1)}

{marker references}{...}
{title:References}

{marker CCV}{...}
{phang} Alberto Abadie, Susan Athey, Guido W Imbens, Jeffrey M Wooldridge (2023).
{browse "https://academic.oup.com/qje/advance-article-abstract/doi/10.1093/qje/qjac038/6750017?redirectedFrom=fulltext&login=false":{it:When Should You Adjust Standard Errors for Clustering?}.} The Quarterly Journal of Economics, 138(1):1-35.
{p_end}


{title:Author}
Damian Clarke, Universidad de Chile.
Email {browse "mailto:dclarke@fen.uchile.cl":dclarke@fen.uchile.cl}
Website {browse "http://www.damianclarke.net/"}

Daniel Pailañir, Universidad de Chile.
Email {browse "mailto:dpailanir@fen.uchile.cl":dpailanir@fen.uchile.cl}
Website {browse "https://daniel-pailanir.github.io/"}

{title:Website}
{cmd:ccv} is maintained at {browse "https://github.com/Daniel-Pailanir/TSCB-CCV": https://github.com/Daniel-Pailanir/TSCB-CCV} 
