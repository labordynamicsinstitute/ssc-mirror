{smcl}
{* *! version 1.0.0 7July2025}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Required Input" "examplehelpfile##required"}{...}
{viewerjumpto "Options" "examplehelpfile##options"}{...}
{viewerjumpto "Remarks" "examplehelpfile##remarks"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{title:Title}

{phang}
{bf:attcic} {hline 2} implements the CiC attrition corrections for continuous and binary outcomes proposed in {help attcic##JoE2024:Ghanem et al. (2024b)} along with comparator approaches. 
The CiC corrections exploit baseline outcome data and can be applied to randomized experiments as well as quasi-experimental difference-in-difference designs. 

{pstd}
This command computes the attrition corrections in settings with a single treatment intervention and for one follow-up at a time. Before using it, the panel dataset should be set in a long format and the packages {helpb esttab:[R] {it:esttab}}
and {helpb leebounds:[R] {it:leebounds}} should be installed.{p_end}



{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:attcic}
{it: outcome treat_group id post}
{ifin}
{cmd:,}
rct(string)
ytype(string)
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt breps(integer)}} number of bootstrap replications.{p_end}
{synopt:{opt clustervar(varname)}} numerical variable identifying the cluster structure of the data.{p_end}
{synopt:{opt stratavar(varname)}} numerical variable identifying the strata groups used in the random assignment of treatment status.{p_end}
{synopt:{opt ipwcov(varlist)}} list of baseline covariates to be used in the IPW corrections besides the baseline outcome.{p_end}
{synopt:{opt yname(string)}} outcome's name. The default name is {it:outcome}.{p_end}
{synopt:{opt qreport(string)}} use {it:yes} to also obtain a report of the quantile treatment effects.{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:attcic} implements the CiC attrition corrections proposed in {help attcic##JoE2024:Ghanem et al. (2024b)}. 
These corrections exploit baseline outcome data to recover the ATT-R, ATE-R, and ATE under the assumptions that the outcome equation is monotonic on an scalar unobservable, and that the distribution of this unobservable is time-invariant for 
each treatment-response group. 
See Section 2 in the paper for a discussion of these assumptions and details on the identification of treatment effects using this approach.{p_end}

{pstd} In addition to these corrections, {cmd:attcic} also reports the results of the IPW corrections, Manski bounds, and Lee bounds.{p_end}


{pstd}
{ul: Attrition Corrections for Continuous Outcomes:}{p_end}

{pstd}
{it:CiC corrections:} {cmd:attcic} computes the ATT-R and ATE-R for continuous outcomes using Proposition 2 and Proposition 3 in {help attcic##JoE2024:Ghanem et al. (2024b)}, respectively. 
Meanwhile, the computation of the ATE depends on the study design. 
If the study is a completely or cluster-randomized experiment, the ATE is computed exploiting initial random assignment via Proposition 5. For stratified experiments or difference-in-difference designs, the ATE is computed using Proposition 4. 
By default, the standard errors are obtained using 200 bootstrap replications.{p_end}

{pstd}
Along with these corrected estimates, the program reports the percentage of quantiles with missing support for each counterfactual measure computed.  
For completely or cluster-randomized experiments, the program also reports the results of the testable implication formulated in Remark 2 of the paper, which constitutes a test of the corrections' assumptions. 
{p_end}

{pstd}
{it:IPW corrections:} these corrections point-identify the ATE-R by re-weighting the observed outcome at follow-up with a treatment propensity score. 
Similarly, the ATE is identified by re-weigting the follow-up oucome with treatment and response propensity scores.
The propensity scores are estimated conditional on the baseline outcome and strata fixed effects when relevant. 
To include additional covariates in these propensity scores, use the option {opt ipwcov(varlist)}.
By default, the standard errors are obtained using 200 bootstrap replications.{p_end}  

{pstd}
{it:Manski Bounds:} following {help attcic##Manski1989:Manski (1989)}, {cmd:attcic} computes bounds for the ATE-R and ATE by imputing the minimum and maximum values of the follow-up outcome under  best-case and worst-case scenarios. 
These bounds do not consider baseline outcome or covariates.{p_end}  

{pstd}
{it:Lee Bounds:} this program computes bounds for the average treatment effect of always-responders using the Stata command {helpb leebounds:[R] {it:leebounds}}. 
This estimation does not consider baseline outcome or covariates. See {help attcic##Lee2009:Lee (2009)} for more details about this approach.{p_end}  

{pstd}
{it:Naive Estimator:} this estimator is computed as the unconditional difference in mean outcomes among respondents at follow-up. If the option {opt stratavar(varname)} is specified, this estimation includes strata fixed effects.  
{p_end}  

{pstd}
{it:Output:} The main output of this analysis is a table with the attrition corrections. 
For randomized experiments, the table reports the CiC and IPW corrections,
the Manski bounds, and the Lee bounds. 
For quasi-experimental difference-in-difference designs, the table only reports the CiC corrections. 
This output table is saved in the text file {it:correction_output} and stored in a new folder entitled {it:corrections_outcome}, 
where {it:outcome} refers to the name of the outcome variable in the dataset.{p_end}

{pstd}
In addition to this file, {cmd:attcic} also saves two datasets that can be used for further analyses:{p_end}
{pstd} a) A dataset with the corrected average treatment effects for each bootstrap sample.{p_end}
{pstd} b) A dataset with the diagnostic of missing quantiles for the counterfactual outcomes in each boostrap sample.{p_end} 
{pstd}If the option {opt qreport(string)} is specified, the program also saves the analysis of quantile treatment effects.{p_end}


{pstd}
{ul: Attirtion Corrections for Binary Outcomes:}{p_end}

{pstd}
{it:CiC Bounds:} for binary outcomes, {cmd:attcic} computes the CiC-corrected lower and upper bounds for the ATT-R, ATE-R, and ATE using the results of Proposition 6 in {help attcic##JoE2024:Ghanem et al. (2024b)}.{p_end} 

{pstd}
{it:IPW:} these corrections point-identify the ATE-R and ATE by re-weighting the follow-up outcome with treatment and response 
propensity scores. 
The propensity scores are estimated conditional on the baseline outcome and strata fixed effects when relevant. To include additional covariates in these propensity scores, 
use the option {opt ipwcov(varlist)}.
Standard errors are approximated asymptotically.{p_end} 

{pstd}
{it:Manski Bounds:} this program computes bounds for the ATE-R and ATE by imputing the minimum and maximum values of the support of the binary outcome under best-case and worst-case scenarios ({help attcic##Manski1989:Manski, 1989}). 
These bounds do not consider baseline outcome or covariates.{p_end}  

{pstd}
{it:Lee Bounds:} this program uses the results in {help attcic##Lee2002:Lee (2002)} to compute bounds for the average treatment effect of always-responders. 
This estimation does not consider baseline outcome or covariates,
and unlike the code in the Stata command {helpb leebounds:[R] {it:leebounds}},
 is specifically tailored for binary outcomes.{p_end}  

{pstd}
{it:Naive Estimator:} this estimator is computed as the unconditional difference in mean outcomes among respondents at follow-up. If the option {opt stratavar(varname)} is specified, this estimation includes strata fixed effects.{p_end}  

{pstd}
{it:Output:} The main output of this analysis is a table with the attrition corrections. 
For randomized experiments, the table reports the CiC bounds, the IPW corrections, 
the Manski bounds, and the Lee bounds. 
For quasi-experimental difference-in-difference designs, the table only reports the CiC bounds. 
This output table is saved in the text file {it:correction_output} and stored in a new folder entitled {it:corrections_outcome}, 
where {it:outcome} refers to the name of the outcome variable in the dataset.{p_end}


{marker required}{...}
{title:Required Inputs}

{dlgtab:Main}

{phang}
{bf:outcome} specifies the variable with the outcome of interest. This variable should be either continuous or binary.{p_end}

{phang}
{bf:treat_group} specifies the variable that identifies the treatment group. 
This variable should take the value of one for the treatment group and zero for the control group. 
This program does not accomodate settings with multiple treatment interventions.{p_end}

{phang}
{bf:id} specifies the variable identifying each unit in the long dataset (e.g., household id). This variable should be numerical.{p_end}

{phang}
{bf:post} specifies the variable identifying the survey period. 
It should take the value of one if the data refers to the follow-up survey and zero if the data refers to the pre-treatment.
This program is set up to conduct the analysis for one follow-up at a time. {p_end}

{phang}
{bf:rct(string)} specifies whether the study is a randomized experiment. 
The two available options are {it:yes} and {it:no}. 
If the option {it:no} is specifed, the program computes the CiC-corrections without assuming random treatment assignment.{p_end}

{phang}
{bf:ytype(string)} specifies the type of outcome variable. 
The two available types are {it:continuous} and {it:binary}. If the {it:continuous} type is specifed, the program computes the CiC-corrected point estimates. 
If the {it:binary} type is specifed, the program computes the CiC-corrected bounds.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt breps(integer)} specifies the number of bootstrap repetitions for the estimation of the standard errors.
The default number is 200 repetitions. 
This option should only be specified for the corrections of treatment effects for continuous outcomes.{p_end}

{phang}
{opt clustervar(varname)} specifies the variable identifying the cluster structure of the data. Variable must be numerical. 
If this option is specified, the standard errors are estimated taking into account the cluster nature of the data.{p_end}
				 
{phang}
{opt stratavar(varname)} specifies the numerical variable identifying the strata groups used in stratified field experiments. 
If this option is specified, the program will draw bootstrap samples for each subsample identified by
 the strata and report the CiC corrections that are appropriate for this design.{p_end}

{phang}
{opt ipwcov(varlist)} by default, the propensity scores of the ipw corrections are estimated conditional on 
the baseline outcome.
If {opt stratavar(varname)} is specified, this estimation also includes strata fixed effects. 
This option specifies additional baseline covariates to be included in these propensity scores.
The variables must be numerical and be already defined as baseline measures for {bf: post}=1.{p_end}

{phang}
{bf:yname(string)} specifies the name of the outcome of interest. 
For instance, {it:value of production animals} or {it:monthly profits}. 
The default name is {it:Outcome}.
If the option {opt qreport(string)} is specified, this name is used in the figures displaying the quantile treatment effects.{p_end}

{phang}
{opt qreport(string)} this option specifies whether to report the quantile analysis of the CiC attrition corrections. 
This additional analysis, available  only for continuous outcomes, provides a dataset with the quantile treatment effects for each bootstrap sample and the visualizations of the QTEs with their respective confidence intervals. 
If {it: yes} is specified, the program will save the results of this analysis in the subfolder {it:quantile_analysis}.{p_end}


{marker examples}{...}
{title:Examples}

{phang}
This section provides two examples of the implementation of the attrition corrections proposed in {help attcic##JoE2024:Ghanem et al. (2024b)} using the {cmd:attcic} program. 
These examples use data from the evaluation of the Progresa program in Mexico to examine impacts on the value and ownership of production animals.{p_end}

{phang}
Download the dataset to run these examples from {view  "https://www.dropbox.com/scl/fo/7o0trm90272weinaowj8i/AKAJNNk66b4QlsacLKNLCa4?rlkey=ca430gc7vjdalz0vvf9wfejy8&st=lrlmdfg2&dl=0":this link}.{p_end} 

{phang}Make sure to set the directory where you want the results to be saved.{p_end}   

{phang} 
{bf: Example 1. Computing attrition corrections for a continuous outcome of a cluster randomized experiment:} {p_end}
{phang}
{it: attcic val_prod_animals treat hhid post, rct(yes) ytype(continuous) clustervar(comuid2) yname(Value of production animals)}{p_end}
				

{phang}
If you want to save the report for the quantile treatment effects, you should specify it in the option {opt qreport(string)}: {p_end}
{phang}
{it: attcic  val_prod_animals treat hhid post,  rct(yes) ytype(continuous) clustervar(comuid2) yname(Value of production animals) qreport(yes)}{p_end}
				
{phang} 
In the examples above, {cmd:attcic} uses the default of 200 bootstrap replications to calculate standard errors. If you want to use more bootstrap replications, you should edit the option {opt breps(integer)} accordingly. {p_end}


{phang} 
{bf: Example 2. Computing attrition corrections for a binary outcome of a cluster randomized experiment:} {p_end}
{phang} 
{it: attcic own_prod_animals treat hhid post,  rct(yes) ytype(binary) clustervar(comuid2) yname(Ownership of production animals)} {p_end}


{marker acknowledgements}{...}
{title:Acknowledgements}

{phang}
The code of the CiC attrition corrections for continuous outcomes builds on the do-file written by Robert Garlick to estimate the nonlinear difference-in-differences model in his paper 
{help attcic##Garlick2018:Academic Peer Effects with Different Group Assignment Policies: Residential Tracking versus Random Assignment (AEJ: Applied Economics, 2018)}.{p_end}


{marker references}{...}
{title:References}

{marker Garlick2018}{...}
{phang}
Garlick, R. (2018). Academic Peer Effects with Different Group Assignment Policies: Residential Tracking versus Random Assignment. {it: American Economic Journal: Applied Economics}.{p_end}

{marker JoE2024}{...}
{phang}
Ghanem, D., Hirshleifer, S., Kédagni, D., Ortiz-Becerra, K. (2024b). Correcting Attrition Bias using Changes-in-Changes. {it:Journal of Econometrics}.{p_end}

{marker Lee2009}{...}
{phang}
Lee, D. (2009). Training, Wages, and Sample Selection: Estimating Sharp Bounds on Treatment Effects. {it:Review of Economic Studies}.{p_end}

{marker Lee2002}{...}
{phang}
Lee, D. (2002). Trimming for Bounds on Treatment Effects with Missing Outcomes. {it:NBER Technical Working Papers}.{p_end}

{marker Manski1989}{...}
{phang}
Manski, C. (1989). Anatomy of the Selection Problem. {it:The Journal of Human Resources}.{p_end}


{marker authors}{...}
{title:Authors}

{phang}Karen Ortiz-Becerra{p_end}
{phang}University of San Diego{p_end}
{phang}kortizbecerra@sandiego.edu{p_end}

{phang}Dalia Ghanem{p_end}
{phang}University of California, Davis{p_end}
{phang}dghanem@ucdavis.edu{p_end}

{phang}Sarojini Hirshleifer{p_end}
{phang}University of California, Riverside{p_end}
{phang}sarojini.hirshleifer@ucr.edu{p_end}

{phang}Désiré Kédagni{p_end}
{phang}University of North Carolina, Chapel Hill{p_end}
{phang}dkedagni@unc.edu{p_end}


