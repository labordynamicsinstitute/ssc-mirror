{smcl}
{* February 25th 2022}{...}
{hline}
 {cmd:mstfreq} {hline 2} Effect Size calculation for Multisite Randomised Trials
{hline}

{marker syntax}{...}
{title:Syntax}

	{cmd:mstfreq} {varlist} {ifin}{cmd:,} {opt int:ervention(interv_var)} {opt ran:dom(clust_var)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr: main}
{synoptline}
{synopt :{opt int:ervention()}}requires a factor variable identifying the intervention (arms) of the trial.{p_end}
{synopt :{opt ran:dom()}}requires a factor variable identifying the clusters (Schools) of the trial.{p_end}
{synoptline}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt ml}}fits model via maximum likelihood; default is RMLE.{p_end}
{synopt :{opt seed(#)}}seed number; default is 1020252.{p_end}
{synopt :{opt np:erm(#)}}number of permutations; default is NULL. {p_end}
{synopt :{opt nb:oot(#)}}number of bootstraps; default is NULL. {p_end}
{synopt :{opt case(# [#])}}level of case bootstrap resampling with option to use both levels; default is 1. {p_end}
{synopt :{opt res:idual}}residual bootstrap; default is case bootstrap. {p_end}
{synopt :{opt perc:entile}}percentile confidence interval for bootstrap. {p_end}
{synopt :{opt basic}}basic confidence interval for bootstrap; default is percentile. {p_end}
{synopt :{opt *}}additional maximization options such as {cmd:technique()}, {cmd:difficult}, {cmd:iterate()}. {p_end}

{syntab:Reporting}
{synopt :{opt noi:sily}}displays the calculation of conditional models.{p_end}
{synopt :{opt nodot}}suppresses display of dots; default is one dot character every 10 replications.{p_end}
{synopt :{opt paste}}attaches bootstrapped/permutated effect sizes on the existing dataset.{p_end}
{synoptline}
{phang}
{it:varlist} and {it:interv_var} may contain factor-variable operators; see {help fvvarlist}.{p_end}
{phang}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mstfreq} Performs analysis of multisite randomised trials using a multilevel model under a frequentist setting.
This analysis produces {cmd:Effect Size} (ES) estimates for both conditional and unconditional model specifications. It also allows for sensitivity analysis options such as permutations
and bootstraps.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt ml} Calculates model using maximum likelihood estimation; default is Restricted Maximum Likelihood.

{phang}
{opt seed(#)} Sets seed number for permutations/bootstraps.

{phang}
{opt nperm(#)} Specifies number of permutations required to generate permutated p-values; see Stored results. 
If specified with {cmd:paste}, a list of generated variables attaches to the user's dataset containing the permutated effect sizes. 

{phang}
{opt nboot(#)} Specifies number of bootstraps required to generate the bootstrap confidence intervals.
If specified with {cmd:paste}, a list of generated variables attaches to the user's dataset containing the bootstrapped effect sizes.

{phang2}
{cmd:Note:} When running bootstraps or permutations, use {cmd:iterate()} to reduce the maximum number of log-likelihood iterations in order to induce quicker failure in the event of non-convergence; Stata default is {cmd:iterate(16000)}.
To identify non-convergence you can also specify the option {cmd:noisily}. Supplementary permutations/bootstraps are automatically deployed when # number of permutated/bootstrapped models have failed to converge. 

{phang}
{opt case(# [#])} Specifies case bootstrap with a specific resampling structure. The numlist may take the value(s) of integers 1 and/or 2 indicating which level should be resampled with replacement from.
If {cmd:case(1,2)} is selected, then resampling will first take place at school level (2) followed by resampling at the pupil level (1); default is {cmd:case(1)}. {p_end}

{phang}
{opt res:idual} Specifies type of bootstrap as the non-parametric residual bootstrap; default is case bootstrap. {p_end}

{phang}
{opt perc:entile} Specifies use of the percentile bootstrap confidence interval. {p_end}

{phang}
{opt basic} Specifies use of the basic (Hall's) bootstrap confidence interval; default is percentile. {p_end}

{phang}
{cmd:*} Additional maximization options are allowed including {cmd:technique()}, {cmd:difficult} see {helpb maximize:[R] Maximize}. {p_end}

{dlgtab:Reporting}

{phang}
{opt noisily} Displays the permutated/bootstrapped conditional models' regression results as they occur.
 
{phang}
{opt nodot} Suppresses display of dots indicating progress of permutations/bootstraps. Default is one dot character displayed for every block of 10 replications. {p_end}

{phang}
{opt paste} Attaches bootstrapped or permutated effect sizes to existing dataset if nperm (PermC/Unc_I#_W/T) or nboot (BootC/Unc_I#_W/T) has been specified, 
where I# denotes number of interventions, C/Unc denotes Conditional and Unconditional estimates and W/T within and total effect sizes. Existing variables generated from previous use are replaced. {p_end}


{marker Examples}{...}
{title:Examples}

 {hline}
{pstd}Setup:{p_end}
{phang2}{cmd:. use mstData.dta, clear}{p_end}

{pstd}Simple model:{p_end}
{phang2}{cmd:. mstfreq Posttest Prettest, int(Intervention) ran(School)}{p_end}

{pstd}Model using residual bootstraps including factor parameters and additional maximization options with base level change:{p_end}
{phang2}{cmd:. mstfreq Posttest Prettest i.School, int(ib2.Intervention) ran(School) nboot(3000) res iterate(100)}{p_end}

{pstd}Model using permutations with three-arm intervention variable, additional maximization options and attaching permutated effect sizes to existing dataset:{p_end}
{phang2}{cmd:. mstfreq Posttest Prettest, int(Intervention2) ran(School) nperm(3000) iterate(100) paste}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mstfreq} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(CondES#)}}conditional Hedges’ g effect size and its 95% confidence intervals for # number of arms in {it:interv_var}. If nboot is specified, CIs are replaced with bootstrapped CIs.{p_end}
{synopt:{cmd:r(UncondES#)}}unconditional effect size for # number of arms in {it:interv_var}, obtained based on variances from the unconditional model (model with only the intercept as a fixed effect).{p_end}
{synopt:{cmd:r(Beta)}}estimates and confidence intervals for variables specified in the model.{p_end}
{synopt:{cmd:r(Cov)}}variance decomposition into within cluster variance (Pupils) and Total variance. It also contains intra-cluster correlation (ICC).{p_end}
{synopt:{cmd:r(schCov)}}variance decomposition into between cluster variance-covariance matrix (School by Intervention).{p_end}
{synopt:{cmd:r(UschCov)}}variance decomposition for the Unconditional model into between cluster variance (School).{p_end}
{synopt:{cmd:r(SchEffects)}}estimated deviation of each school from the intercept and intervention slope.{p_end}
{synopt:{cmd:r(CondPv)}}conditional two-sided within and total effect size permutation p-values (available if nperm(#) has been selected).{p_end}
{synopt:{cmd:r(UncondPv)}}unconditional two-sided within and total effect size permutation p-values (available if nperm(#) has been selected).{p_end}
