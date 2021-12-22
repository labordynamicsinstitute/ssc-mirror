{smcl}
{* *! version 1.0.0  25mar2021}{...}

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
{cmd:winratio} {it:idvar} {it:trtvar} {cmd:[if]} {cmd:,}
{cmdab:out:comes(}{it:list}{cmd:)} [ 
{opth str:ata(varname)} 
{cmdab:stw:eight(}{it:weighting method}{cmdab:)}
{opth pf:ormat(%fmt)} 
{opth wrf:ormat(%fmt)} ]

{pstd}
{it:idvar} may be a string or numeric unique identifier variable.

{pstd}
{it:trtvar} must be a binary 0 1 numeric variable, where 0 and 1 indicate the control and intervention groups respectively.

{p 4 4 2}
{cmd: outcomes(}{it:list}{cmd:)} is a required option; {it: list} consists of sets of 3 items to indicate the outcome, type of outcome and either time variable if time to event or repeat events
 or direction of comparison (< or >) if continuous, ordinal categorical or binary. See options and examples below for more details. 

{pstd}
{cmd:by} is not allowed.

{marker description}{...}
{title:Description}

{pstd}
{cmd:winratio} The win ratio was introduced in 2012 by Pocock {it:et al} {cmd:[1]} as a novel approach to the analysis of composite endpoints in randomised clinical trials.
The approach motivated by the Finkelstein–Schoenfeld test {cmd:[2]} takes into account the order of importance of the component events and also allows the components to be different types of outcomes
e.g. time to event (failure or success), quantitative outcomes such as quality of life scores and vital signs, repeat events, and more.


{marker options}{...}
{title:Options}

{pstd}
{cmd: outcomes(}{it:list}{cmd:)} is a required option; {it: list} consists of sets of 3 items each of which refers to an outcome in the composite.
The first set of 3 items refers to the first (i.e. most important) outcome in the composite, the second set of 3 items to the second outcome, and so on. 

{pstd}
The {cmd:first item} in each set will be the name of the outcome variable. In the case of time-to-event this will be a binary (0/1) variable indicating the event.
For binary, ordinal categorical and continous outcomes this will be the variable name. 
In the case of repeat events this will be the stub of the names of a set of  binary (0/1) variables indicating the repeat events 
e.g. hosp if hosp1, hosp2, hosp3 are three binary variables indicating repeat hospitalisations. For repeat events the winner or loser in each patient pair is decided based upon the number of events during shared follow-up (timing of events during shared follow-up is not considered).  

{pstd}
The {cmd: second item} in each set will indicate the {it:type of outcome}. 
 This will be {cmd: tf} for time-to-event failure outcomes, {cmd: ts} for time-to-event success outcomes,{cmd: c} for continuous, ordinal categorical or binary outcomes and {cmd: r} for repeat events.

{pstd}
The {cmd:third item} in each set depends on the type of outcome.
For time-to-event outcomes this will be the name of the variable containing the follow-up (censoring or event) time.
For continuous, ordinal categorical or binary outcomes this will be {cmd: >} or {cmd:<} to indicate the direction of the comparison i.e. whether higher or lower values are better.
For repeat events this will be the stub of the names of a set of variables containing follow-up times.

{pstd}
{opth str:ata(varname)} allows computation of the stratified Win Ratio. varname must be a numeric categorical variable.  

{pstd}
{cmdab:stw:eight(}{it:method}{cmdab:)} allows specification of the weighting method to be used for the stratified win ratio. 
{it:method} can be {bf:unweighted} (the default if no weighting option is specified along with strata: test statistics and variance estimators are simply summed across strata) {bf:IV} for inverse-variance weights and {bf:MH} for Mantel-Haenszel (MH) weights (each strata weighted according to the number of patients in the strata).

{pstd}
{opth pf:ormat(%fmt)} controls the numeric display format for p-values; for example, for a p-value with a leading
0 and 4 decimal places %05.4f. 

{pstd}
{opth wrf:ormat(%fmt)} controls the numeric display format for the estimated Win Ratio and confidence intervals.
 
{marker examples}{...}
{title:Examples}

{p 4 4 2}
{bf:Example 1:}
Consider a trial with two prioritised outcomes, death and heart failure hospitalisation.
Death is a time-to-event (failure) outcome with a binary (0/1) variable {cmd:dth} indicating whether the patient died or not and the variable {cmd: fudth} containing the event time or censoring time.
Heart failure hospitalisation is a repeated event with a maximum of 4 repeat events observed.  
{cmd: hf1}, {cmd: hf2}, {cmd: hf3}, {cmd: hf4} are four binary (0/1) variables indicating the event. {cmd: fuhf1}, {cmd: fuhf2}, {cmd: fuhf3}, {cmd: fuhf4} are four variables containing the event or censoring time.
For example, if a patient did not experience any hospitalisations for heart failure and was censored at 300 days then {cmd: hf1-hf4} would all be 0 and {cmd: fuhf1-fuhf4} would all contain 300.
If a patient experienced 1 hospitalisation at day 90 and was then censored at day 250 then {cmd: hf1} would be 1 and {cmd: fuhf1} would be 90, {cmd: hf2-hf4} would all contain 0 and {cmd: fuhf2-fuhf4} would all be 250.
The variable {cmd: patid} is a unique patient identifier and {cmd: trt} is a binary variable indicating the active treatment group. An example dataset with this structure is provided here: 

{pstd}
use win_ratio_example.dta

{pstd}
The command syntax for this analysis would then be: 

{pstd}
winratio patid trt , outcomes(dth tf fudth hf r fuhf) 

{pstd}
{bf:Example 2:}
Suppose the trial in example 1 now adds a third prioritised outcome, quality of life ({cmd:qol}). Quality of life is to be considered as the third outcome in the hierarchy and higher values are better. The command syntax would then be: 

{pstd}
winratio patid trt , outcomes(dth tf fudth hf r fuhf qol c >) 


{marker savedresults}{...}
{title:Saved results}

{pstd}
{cmd:winratio} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{synopt:{cmd:r(se_logwr)}}standard error of log win ratio. The standard error of the win ratio is calculated using the method described at the end of the Supplement of Pocock 2012 {p_end}
{synopt:{cmd:r(wr)}}win ratio{p_end}

{synopt:{cmd:r(se{it:i})}}standard error of log win ratio in strata {it:i} for i=1 to m strata{p_end}
{synopt:{cmd:r(wr{it:i})}}win ratio in strata {it:i}{p_end}


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

{phang}Tim Collier, Medical Statistics Department, London School of Hygiene and Tropical Medicine
{phang}John Gregson, Medical Statistics Department, London School of Hygiene and Tropical Medicine, john.gregson@lshtm.ac.uk
