{smcl}
{* February 25th 2022}{...}
{hline}
 {cmd:srtfreq} {hline 2} Effect Size calculation for Simple Randomised Trials
{hline}

{marker syntax}{...}
{title:Syntax}

	{cmd:srtfreq} {varlist} {ifin}{cmd:,} {opt int:ervention(interv_var)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr: main}
{synoptline}
{synopt :{opt int:ervention()}}requires a factor variable identifying the intervention (arms) of the trial.{p_end}
{synoptline}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt seed(#)}}seed number; default is 1020252.{p_end}
{synopt :{opt np:erm(#)}}number of permutations; default is NULL. {p_end}
{synopt :{opt nb:oot(#)}}number of bootstraps; default is NULL. {p_end}
{synopt :{opt perc:entile}}percentile confidence interval for bootstrap. {p_end}
{synopt :{opt basic}}basic confidence interval for bootstrap; default is percentile. {p_end}

{syntab:Reporting}
{synopt :{opt noi:sily}}displays the calculation of conditional models.{p_end}
{synopt :{opt nodot}}suppresses display of dots; default is one dot character every 10 replications.{p_end}
{synopt :{opt paste}}attaches bootstrapped/permutated effect sizes on the existing dataset.{p_end}
{synoptline}
{phang}
{it:varlist} and {cmd:intervention()} may contain factor-variable operators; see {help fvvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:srtfreq} Performs analysis of educational trials under the assumption of independent errors among pupils; this can also be used with schools as fixed effects.
The analysis produces {cmd:Effect Size} (ES) estimates for both conditional and unconditional model specifications in Simple Randomised Trials. It also allows for sensitivity analysis options such as permutations
and bootstraps.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt seed(#)} Sets seed number for permutations/bootstraps.

{phang}
{opt nperm(#)} Specifies number of permutations required to generate permutated p-values; see Stored results.  
If specified with {cmd:paste}, a list of generated variables attaches to the user's dataset containing the permutated effect sizes. 

{phang}
{opt nboot(#)} Specifies number of bootstraps required to generate the bootstrap confidence intervals. 
If specified with {cmd:paste}, a list of generated variables attaches to the user's dataset containing the bootstrapped effect sizes.

{phang}
{opt perc:entile} Specifies use of the percentile bootstrap confidence interval. {p_end}

{phang}
{opt basic} Specifies use of the basic (Hall's) bootstrap confidence interval; default is percentile. {p_end}


{dlgtab:Reporting}

{phang}
{opt noisily} Displays the permutated/bootstrapped conditional models' regression results as they occur.
 
{phang}
{opt nodot} Suppresses display of dots indicating progress of permutations/bootstraps. Default is one dot character displayed for every block of 10 replications. {p_end}

{phang}
{opt paste} Attaches bootstrapped or permutated effect sizes to existing dataset if nperm (PermC/Unc_I#) or nboot (BootC/Unc_I#) has been specified, 
where I# denotes number of interventions and C/Unc denotes Conditional/Unconditional estimates. Existing variables generated from previous use are replaced. {p_end}



{marker Examples}{...}
{title:Examples}

 {hline}
{pstd}Setup:{p_end}
{phang2}{cmd:. use mstData.dta}{p_end}

{pstd}Simple model:{p_end}
{phang2}{cmd:. srtfreq Posttest Prettest, int(Intervention)}{p_end}

{pstd}Model using permutations including Schools as fixed effects with base level change:{p_end}
{phang2}{cmd:. srtfreq Posttest Prettest i.School, int(ib(#2).Intervention) nperm(3000)}{p_end}

{pstd}Model using permutations and bootstraps with three-arm intervention variable:{p_end}
{phang2}{cmd:. srtfreq Posttest Prettest, int(Intervention2) nperm(3000) nboot(2000) noisily}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:srtfreq} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(CondES)}}conditional Hedges’ g effect size and its 95% confidence intervals for the trial arm(s) in {it:interv_var}. If nboot is specified, CIs are replaced with bootstrapped CIs.{p_end}
{synopt:{cmd:r(UncondES)}}unconditional effect size for the trial arm(s) in {it:interv_var}, obtained based on variance from the unconditional model (model with only the intercept as a fixed effect).{p_end}
{synopt:{cmd:r(Beta)}}estimates and confidence intervals for variables specified in the model.{p_end}
{synopt:{cmd:r(Sigma2)}}residual variance for conditional and unconditional models.{p_end}
{synopt:{cmd:r(Pv)}}conditional and unconditional two-sided within and total effect size permutation p-values (available if nperm(#) has been selected).{p_end}