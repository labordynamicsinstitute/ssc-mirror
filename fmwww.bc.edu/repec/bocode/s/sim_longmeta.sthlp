{smcl}
{* *! sim_longmeta.sthlp  metaLong for Stata 14.1}{...}
{vieweralsosee "metalong" "help metalong"}{...}
{vieweralsosee "ml_meta"  "help ml_meta"}{...}
{hline}
{title:sim_longmeta — Simulate a Longitudinal Meta-Analytic Dataset}

{title:Syntax}

{p 8 17 2}
{cmd:sim_longmeta} [{cmd:,}
{cmd:k(}{integer}{cmd:)}
{cmd:times(}{numlist}{cmd:)}
{cmd:mu(}{real}{cmd:)}
{cmd:tau(}{real}{cmd:)}
{cmd:vlow(}{real}{cmd:)}
{cmd:vhigh(}{real}{cmd:)}
{cmd:missing(}{real}{cmd:)}
{cmd:nocovariates}
{cmd:seed(}{integer}{cmd:)}
{cmd:saving(}{filename}{cmd:)}
{cmd:replace}
{cmd:clear}]

{title:Description}

{pstd}
{cmd:sim_longmeta} generates a synthetic long-format dataset of effect sizes
across multiple follow-up time points and studies. It is designed to test and
illustrate all {cmd:metaLong} commands without requiring real data.

{pstd}
The data-generating model is:

{pstd}
{it:theta_it} = {it:mu} + {it:u_i} + {it:epsilon_it}

{pstd}
where {it:mu} is the true (common) mean effect, {it:u_i} ~ N(0, tau²) is a
study-level random effect that induces within-study correlation across time
points, and {it:epsilon_it} ~ N(0, {it:vi}) is independent sampling error.
Sampling variances {it:vi} are drawn uniformly from [{cmd:vlow()}, {cmd:vhigh()}].

{title:Options}

{phang}
{cmd:k(}{integer}{cmd:)} specifies the number of studies. Default is 20.

{phang}
{cmd:times(}{numlist}{cmd:)} specifies the follow-up time points as an ascending
numeric list. Default is {cmd:0 6 12 24}.

{phang}
{cmd:mu(}{real}{cmd:)} specifies the true mean effect, shared across all time
points. Default is 0.4. To simulate a time-varying true effect, generate the
data from {cmd:sim_longmeta} and then manually replace {it:yi} values.

{phang}
{cmd:tau(}{real}{cmd:)} specifies the between-study standard deviation.
Default is 0.2.

{phang}
{cmd:vlow(}{real}{cmd:)} and {cmd:vhigh(}{real}{cmd:)} specify the lower and
upper bounds for the uniform distribution of sampling variances. Defaults are
0.02 and 0.12.

{phang}
{cmd:missing(}{real}{cmd:)} specifies the proportion of study × time cells to
drop (simulating incomplete follow-up). Must be in [0, 1). Default is 0 (none).

{phang}
{cmd:nocovariates} suppresses generation of the study-level covariates
{it:pub_year}, {it:quality}, and {it:n}. By default these are generated and
are used by {helpb ml_benchmark}.

{phang}
{cmd:seed(}{integer}{cmd:)} sets the random number seed for reproducibility.
Default is −1 (no seed set). Pass any non-negative integer for a fixed seed.

{phang}
{cmd:saving(}{filename}{cmd:)} saves the dataset to {it:filename}.dta.

{phang}
{cmd:replace} allows overwriting an existing {cmd:saving()} file.

{phang}
{cmd:clear} clears any data currently in memory before generating the new
dataset. If omitted and there is data in memory, the command preserves the
original data (using preserve/restore), which means the generated dataset
is in memory only if {cmd:saving()} is also specified.

{title:Generated variables}

{synoptset 14 tabbed}{...}
{synopt:{opt study}}Study identifier string, e.g. "s01", "s02", …{p_end}
{synopt:{opt time}}Follow-up time (numeric){p_end}
{synopt:{opt yi}}Observed effect size{p_end}
{synopt:{opt vi}}Sampling variance{p_end}
{synopt:{opt pub_year}}Publication year (2000-2022); dropped with nocovariates{p_end}
{synopt:{opt quality}}Study quality score (standard normal); omitted with {cmd:nocovariates}{p_end}
{synopt:{opt n}}Study sample size (uniform 30-500);{break}omitted with {cmd:nocovariates}{p_end}

{title:Examples}

{pstd}Basic usage — generate and keep in memory:{p_end}
{phang2}{cmd:. sim_longmeta, k(20) times(0 6 12 24) seed(42) clear}

{phang2}{cmd:. list in 1/8}

{pstd}Save to file:{p_end}
{phang2}{cmd:. sim_longmeta, k(15) times(0 3 6 12) mu(0.3) tau(0.3) ///}
{phang3}{cmd:    seed(99) saving(simdata) replace clear}

{pstd}With missing data (20% missing study × time cells):{p_end}
{phang2}{cmd:. sim_longmeta, k(30) times(0 6 12 24) missing(0.20) seed(7) clear}

{phang2}{cmd:. tabulate time, missing}

{pstd}Without covariates:{p_end}
{phang2}{cmd:. sim_longmeta, k(10) nocovariates seed(1) clear}

{title:See also}

{helpb ml_meta}, {helpb ml_sens}, {helpb ml_benchmark}, {helpb metalong}

{hline}
