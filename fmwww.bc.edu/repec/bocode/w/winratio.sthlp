{smcl}
{* *! Version 1.0.3 Sept 26 2022 }{...}

{viewerjumpto "Syntax" "winratio##syntax"}{...}
{viewerjumpto "Description" "winratio##description"}{...}
{viewerjumpto "Options" "winratio##options"}{...}
{viewerjumpto "Examples" "winratio##examples"}{...}
{viewerjumpto "Saved results" "winratio##savedresults"}{...}
{viewerjumpto "References" "winratio##references"}{...}
{viewerjumpto "Authors" "winratio##authors"}{...}


{cmd: help winratio}
{hline}

{title:Title}

{phang}
{bf:winratio} {hline 2} calculates the unmatched Win Ratio for prioritised outcomes.

{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:winratio} {it:idvar} {it:trtvar} {cmd:,}
{cmdab:out:comes(}{it:list}{cmd:)} [ 
{opth str:ata(varname)} 
{cmdab:stw:eight(}{it:weighting method}{cmdab:)}
{opth pf:ormat(%fmt)} 
{opth wrf:ormat(%fmt)} 
{cmdab:saving(filename [, replace])}
]

{pstd}
{it:idvar} is a unique identifier variable and may be string or numeric.

{pstd}
{it:trtvar} must be a binary 0 1 numeric variable, where 0 and 1 indicate the control and intervention groups respectively.

{p 4 4 2}
{cmd: outcomes(}{it:list}{cmd:)} is a required option which will be repeated for each outcome in the hierarchy (starting with highest through to lowest priority); 
{it: list} consists of a set of 3 items which provide information about
 (i) the outcome variable(s), (ii) the type of outcome and (iii) either the follow-up time variable(s) if the outcome is a time-to-event or a repeated event, 
 or the direction of comparison (<[#] or >[#]) if the outcome is continuous, ordinal or binary. See options and examples below for more details. 

{pstd}
{cmd:if} and {cmd:by} are not allowed.

{marker description}{...}
{title:Description}

{pstd}
{cmd:winratio} The win ratio was introduced in 2012 by Pocock {it:et al} {cmd:[1]} as a novel approach to the analysis of composite endpoints in randomised clinical trials.
The approach motivated by the Finkelstein–Schoenfeld test {cmd:[2]} takes into account the order of importance of the component events and also allows the components to be different types of outcomes
e.g. time-to-event (failure or success), quantitative outcomes such as quality of life scores and vital signs, repeated events, and more.


{marker options}{...}
{title:Options}

{pstd}
{cmd: outcomes(}{it:list}{cmd:)} is a required option which will be repeated for each outcome in the hierarchy, starting with the first outcome through to the last outcome;
 {it: list} consists of {cmd: 3 items} which provide information about each outcome as follows: 

{pstd}
The {cmd:first item} in each specifies the outcome variable(s). For binary, ordinal, and continous outcomes this will be the variable name. 
In the case of a time-to-event outcome this will be a binary (0/1) variable indicating whether or not the event occurred.
In the case of a repeated event outcome this will be the stub of the names of a set of  binary (0/1) variables indicating the repeat events 
e.g. hosp if hosp1, hosp2, hosp3 are three binary variables indicating repeat hospitalisations.

{pstd}
The {cmd: second item} in each set will indicate the {it:type of outcome}. 
 This will be {cmd: c} for continuous, ordinal categorical or binary outcomes, {cmd: tf} for time-to-event failure outcomes, {cmd: ts} for
 time-to-event success outcomes, and {cmd: r#} for repeat events where # is the maximum number of variables to consider in the analysis of the repeat events.
 

{pstd}
The {cmd:third item} in each set depends on the type of outcome.
For continuous, ordinal or binary outcomes this will be {cmd: >}[#] or {cmd:<}[#] to indicate the direction of the comparison i.e. whether higher or lower values are better, and where # is the margin of success required for a win;
when # is not specified the default margin is 0. 
For time-to-event outcomes this will be the name of the variable containing the follow-up (censoring or event) time.
For repeat events this will be the stub of the names of a set of variables containing follow-up times.

{pstd}
{opth strata(varname)} allows computation of the stratified win ratio. {cmd:varname} must be a numeric categorical variable.  

{pstd}
{cmdab:stweight(}{it:method}{cmdab:)} allows specification of the weighting method to be used for the stratified win ratio. 
{it:method} can be {bf:unweighted} (the default if no weighting option is specified along with strata: test statistics and
 variance estimators are simply summed across strata) {bf:iv} for inverse-variance weights and {bf:mh} for Mantel-Haenszel (MH) weights (each strata weighted according to the number of patients in the strata).

{pstd}
{cmdab:saving(filename [, replace])} saves a dataset containing the number of wins, losses and ties at each level of the hierarchy and for each strata. 

{pstd}
{opth pf:ormat(%fmt)} controls the numeric display format for p-values; for example, for a p-value with a leading
0 and 4 decimal places %05.4f. 

{pstd}
{opth wrf:ormat(%fmt)} controls the numeric display format for the estimated win ratio and confidence intervals.

 
{marker examples}{...}
{title:Examples}

{pstd}
The following examples use the dataset {cmd: win_ratio_example.dta} which is provided along with the program files. 

{p 4 4 2}
{bf:Example 1:}
Consider a trial with two prioritised outcomes, (i) death and (ii) heart failure hospitalisation, where death is considered to be more important that heart failure hospitalisation. 
Death is a time-to-event (failure) outcome with a binary (0/1) variable {cmd:dth} indicating whether the patient died or not and the variable {cmd: fudth} containing the event time or censoring time.
Heart failure hospitalisation is a repeated event with a maximum of 4 repeat events observed.  
{cmd: hf1}, {cmd: hf2}, {cmd: hf3}, {cmd: hf4} are four binary (0/1) variables indicating the event. {cmd: fuhf1}, {cmd: fuhf2}, {cmd: fuhf3}, {cmd: fuhf4} are four variables containing the event time or censoring time.
For example, if a patient did not experience any hospitalisations for heart failure and was censored at 300 days then {cmd: hf1-hf4} would each be 0 and {cmd: fuhf1-fuhf4} would each be 300.
If a patient experienced a heart failure hospitalisation at day 90 and was then censored at day 250 without any further heart failure hospitalisations, 
 then {cmd: hf1} would be 1 and {cmd: fuhf1} would be 90, {cmd: hf2-hf4} would each contain 0 and {cmd: fuhf2-fuhf4} would each be 250.
The variable {cmd: patid} is a unique patient identifier and {cmd: trt} is a binary variable indicating the active treatment group.

{pstd}
The command syntax for this analysis would then be: 

{pstd}
{cmd: use win_ratio_example.dta}

{pstd}
{cmd: winratio patid trt , outcomes(dth tf fudth) outcomes(hf r4 fuhf)}

{pstd}
{bf:Example 2:}
Suppose we now add another outcome, quality of life ({cmd:qol}), as the third prioritised outcome in the hierarchy. {cmd:qol} is a continuous variable and higher values are better. The command syntax would then be: 

{pstd}
{cmd: winratio patid trt , outcomes(dth tf fudth) outcomes(hf r4 fuhf) outcomes(qol c >) }

{pstd}
{bf:Example 3:}
Suppose we now require the quality of life score to be more than 0.1 points higher to declare a winner. The command syntax would then be: 

{pstd}
{cmd: winratio patid trt , outcomes(dth tf fudth) outcomes(hf r4 fuhf) outcomes(qol c >0.1)}

{pstd}
Notice that there is no gap between > and 0.1. We could also specify >=0.1 for at least 0.1 points higher. 

{pstd}
{bf:Example 4:}
Suppose we now want to repeat the analysis in Example 1 but we also want to stratify by the variable {cmd: blvar} using Mantel-Haenszel weights. The command syntax would then be: 

{pstd}
{cmd: winratio patid trt , outcomes(dth tf fudth) outcomes(hf r4 fuhf) strata(blvar) stweight(mh) }

{pstd}
{bf:Example 5:} Note that binary variables and ordered categorical/discrete variables are dealt with in the same way as continuous variables. For example, suppose we use the (0/1) binary variable {cmd: qol_bin} where 1 indicates a better quality of life the
 command syntax would then be:

{pstd}
{cmd: winratio patid trt , outcomes(dth tf fudth) outcomes(hf r4 fuhf) outcomes(qol_bin c >)}

{marker savedresults}{...}
{title:Saved results}

{pstd}
{cmd:winratio} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{synopt:{cmd:r(se_logwr)}}standard error of log win ratio. The standard error of the win ratio is calculated using the method described at the end of the Supplement of Pocock 2012 {p_end}
{synopt:{cmd:r(wr)}}win ratio{p_end}
{synopt:{cmd:r(logwr)}}log win ratio{p_end}

{pstd}
If the strata option is used then the following results are also stored: 

{synopt:{cmd:r(p#)}}p-value in strata #{p_end}
{synopt:{cmd:r(se#)}}standard error of log win ratio in strata #{p_end}
{synopt:{cmd:r(wr#)}}win ratio in strata #{p_end}
{synopt:{cmd:r(logwr#)}}log win ratio in strata #{p_end}

{marker references}{...}
{title:References}

{phang}
1. Pocock SJ, Ariti CA, Collier TJ, Wang D. The win ratio: a new approach to the analysis of composite endpoints in clinical trials based on clinical priorities. {it:Eur Heart J} 2012;33:176–182.

{marker C1985}{...}
{phang}
2. Finkelstein DM, Schoenfeld DA. Combining mortality and longitudinal measures in clinical trials. {it:Stat Med} 1999;18:1341–1354.
{p_end}


{marker authors}{...}
{title:Authors}

{phang}Tim Collier, Medical Statistics Department, London School of Hygiene and Tropical Medicine, tim.collier@lshtm.ac.uk
{phang}John Gregson, Medical Statistics Department, London School of Hygiene and Tropical Medicine, john.gregson@lshtm.ac.uk

