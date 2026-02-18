{smcl}
{help undid_stage_three:undid_stage_three}
{hline}

{title:undid_stage_three}

{pstd}
Computes UN-DID results by taking in all filled diff df CSV files and using them to compute 
sub-aggregate and aggregate ATTs along with standard errors and p-values. Based on 
Karim, Webb, Austin & Strumpf (2025) {browse "https://arxiv.org/abs/2403.15910"}.
{p_end}

{title:Command Description}

{phang}
{cmd:undid_stage_three} is the final stage of the UN-DID estimation procedure. It reads the 
filled difference dataframes from stage two and computes treatment effects at various levels 
of aggregation, provides standard errors using heteroskedasticity-consistent covariance matrix 
estimators (HC0-HC4), implements jackknife standard errors for cluster-robust inference, and 
performs randomization inference to compute RI-pvals.
{p_end}

{title:Stored results}

{pstd}
{cmd:undid_stage_three} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(att)}}aggregate ATT estimate{p_end}
{synopt:{cmd:r(se)}}standard error of aggregate ATT{p_end}
{synopt:{cmd:r(p)}}p-value from two-sided t-test{p_end}
{synopt:{cmd:r(jkse)}}jackknife standard error{p_end}
{synopt:{cmd:r(jkp)}}p-value from two-sided t-test using jkse{p_end}
{synopt:{cmd:r(rip)}}p-value from randomization inference{p_end}
{synopt:{cmd:r(nperm)}}number of randomizations completed{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(undid)}}sub-aggregate ATT results table{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:undid_stage_three}
{cmd:,}
{cmd:dir_path(}{it:string}{cmd:)}
{p_end}

{p 8 17 2}
[{cmd:agg(}{it:string}{cmd:)}
{cmd:weights(}{it:string}{cmd:)}
{cmd:covariates(}{it:integer}{cmd:)}
{cmd:notyet(}{it:integer}{cmd:)}
{cmd:nperm(}{it:integer}{cmd:)}
{cmd:verbose(}{it:integer}{cmd:)}
{cmd:seed(}{it:integer}{cmd:)}
{cmd:max_attempts(}{it:integer}{cmd:)}
{cmd:check_anon_size(}{it:integer}{cmd:)}
{cmd:hc(}{it:integer}{cmd:)}
{cmd:omit(}{it:string}{cmd:)}
{cmd:only(}{it:string}{cmd:)}]
{p_end}

{title:Parameters}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt dir_path(string)}}filepath to folder containing filled diff CSV files from stage two{p_end}

{syntab:Aggregation and Weighting}
{synopt:{opt agg(string)}}aggregation method: "silo", "g", "gt", "sgt", "time", or "none" (default: "g"){p_end}
{synopt:{opt weights(string)}}weighting scheme: "none", "diff", "att", or "both" (default: matches stage one specification){p_end}

{syntab:Estimation Options}
{synopt:{opt covariates(integer)}}use covariate-adjusted estimates: 1 = use diff_estimate_covariates, 0 = use diff_estimate (default: 0){p_end}
{synopt:{opt notyet(integer)}}use not-yet-treated periods from treated silos as controls: 1 = yes, 0 = no (default: 0){p_end}
{synopt:{opt hc(integer)}}heteroskedasticity-consistent covariance matrix estimator: 0, 1, 2, 3, or 4 (default: 3){p_end}

{syntab:Silo Selection}
{synopt:{opt omit(string)}}space-separated list of silos to exclude from analysis{p_end}
{synopt:{opt only(string)}}space-separated list of silos to include in analysis (excludes all others){p_end}

{syntab:Randomization}
{synopt:{opt nperm(integer)}}number of permutations for randomization inference (default: 999){p_end}
{synopt:{opt verbose(integer)}}display progress every N permutations; 0 disables progress messages (default: 250){p_end}
{synopt:{opt seed(integer)}}random seed for replication (default: 0){p_end}
{synopt:{opt max_attempts(integer)}}maximum attempts to find unique permutations (default: 100){p_end}

{syntab:Diagnostics}
{synopt:{opt check_anon_size(integer)}}display anonymization settings from stage two: 1 = yes, 0 = no (default: 0){p_end}
{synoptline}
{p2colreset}{...}

{title:Examples}

{pstd}
For more examples and sample data, please visit the GitHub repository:{p_end}
{pstd}
{browse "https://github.com/ebjamieson97/undid"}{p_end}

{pstd}
{bf:Basic example with cohort aggregation:}{p_end}

{phang2}{cmd:. undid_stage_three, dir_path("stage_two/")}{p_end}

{title:Aggregation Methods}

{pstd}
The {cmd:agg()} option determines which sub-aggregate ATTs are calculated and consequently 
affects the calculation of the aggregate ATT. All options except {cmd:"none"} compute 
sub-aggregate ATTs, which are then combined into an aggregate ATT as a weighted mean.

{synoptset 15 tabbed}{...}
{synopthdr:Aggregation Option}
{synoptline}
{synopt:{bf:g}}Aggregates ATTs by treatment time (cohort), computing sub-aggregate ATTs 
for each group based on when treatment begins (default).{p_end}

{synopt:{bf:silo}}Aggregates ATTs by treated silo, computing sub-aggregate ATTs for each silo.{p_end}

{synopt:{bf:gt}}Aggregates ATTs by (g,t) group, where g is the first treatment time and t 
is any period from g to the end of the data.{p_end}

{synopt:{bf:sgt}}Aggregates ATTs by (silo,g,t) combinations, where gt aggregation is further 
divided by silo.{p_end}

{synopt:{bf:time}}Aggregates ATTs by periods since treatment (event time), computing 
sub-aggregate ATTs based on time elapsed since treatment began.{p_end}

{synopt:{bf:none}}No aggregation. Computes a single aggregate ATT without sub-aggregates.{p_end}
{synoptline}
{p2colreset}{...}

{title:Weighting Options}

{pstd}
The {cmd:weights()} option controls how observations are weighted when computing sub-aggregate 
and aggregate ATTs.

{synoptset 15 tabbed}{...}
{synopthdr:Weighting Option}
{synoptline}

{synopt:{bf:none}}No weighting. All differences receive equal weight when computing 
sub-aggregate ATTs, and all sub-aggregate ATTs receive equal weight when computing the 
aggregate ATT.{p_end}

{synopt:{bf:diff}}Difference weighting. Applies weights when computing sub-aggregate ATTs. 
Each difference is weighted by the total number of observations used to compute that difference. 
Differences based on more observations receive greater weight.{p_end}

{synopt:{bf:att}}ATT weighting. Applies weights when computing the aggregate ATT from 
sub-aggregate ATTs. Each sub-aggregate ATT is weighted by the total number of treated 
observations included in its calculation. Sub-aggregates with more treated observations 
receive greater weight.{p_end}

{synopt:{bf:both}}Combined weighting. Applies both {cmd:diff} weighting (when computing 
sub-aggregate ATTs) and {cmd:att} weighting (when computing the aggregate ATT).{p_end}

{synoptline}
{p2colreset}{...}

{title:Jackknife Standard Errors}

{pstd}
{cmd:undid_stage_three} automatically computes jackknife standard errors for cluster-robust 
inference. Jackknife standard errors and pvalues are only calculated if there are at least 2 
control and 2 treated silos for that particular subaggregate ATT (or aggregate ATT).
The jackknife procedure leaves out one silo at a time and recomputes all sub-aggregate and aggregate ATTs,
then uses the variance across these leave-one-out estimates to compute jackknife standard errors.

{pstd}
Results are stored in 
{cmd:r(jkse)} and {cmd:r(jkp)}.

{title:Randomization Inference}

{pstd}
{cmd:undid_stage_three} implements randomization inference following MacKinnon and Webb (2020) 
to compute p-values. See the paper here: {browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407620301445"}

{pstd}
The procedure works as follows:

{phang}
1. Treatment times are randomly reassigned among silos {cmd:nperm} times, while ensuring each 
randomization produces a unique assignment

{phang}
2. For each randomization, sub-aggregate and aggregate ATTs are recalculated according 
to the randomized treatment assignment

{phang}
3. The distribution of ATTs from these randomizations is compared against the actual 
ATT estimates to compute p-values

{pstd}
Randomization inference p-values are returned in {cmd:r(rip)} for the aggregate ATT and 
can be seen at the sub-aggregate level with {cmd:matrix list r(undid)}. Set {cmd:seed()} 
for reproducible results across runs.

{title:Package Author}

{pstd}
Eric Jamieson. Report bugs at: ericbrucejamieson@gmail.com or {browse "https://github.com/ebjamieson97/undid"}.
{p_end}

{title:Citations}

{pstd}
If you use {cmd:undid} in your research, please cite:{p_end}

{pstd}
Sunny Karim, Matthew D. Webb, Nichole Austin, and Erin Strumpf. "Difference-in-Differences 
with Unpoolable Data." {browse "https://arxiv.org/abs/2403.15910"}{p_end}

{pstd}
If you reference the randomization inference p-values in your work, please also cite:{p_end}

{pstd}
MacKinnon, James G., and Matthew D. Webb. "Randomization Inference for Difference-in-Differences 
with Few Treated Clusters." {browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407620301445"}{p_end}

{pstd}
To cite the {cmd:undid} Stata package:{p_end}

{pstd}
Eric Jamieson (2026). undid: Difference-in-Differences with Unpoolable Data. 
Stata package version 2.0.0. {browse "https://github.com/ebjamieson97/undid"}{p_end}

{* undid_stage_three                                  }
{* written by Eric Jamieson                           }
{* version 2.0.0 2026-02-16                           }

{smcl}