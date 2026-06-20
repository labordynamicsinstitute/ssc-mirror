{smcl}
{* Nov11,2024}{...}
{cmd:help stackscpvals} 
{hline}

{title:Title} {p 19 20 0} {cmd:Version 1.2} - Release date: November 11, 2024. Tested on Stata 15.1 and above. 

{p2colset 5 20 20 2}{...}
{p2col :{hi:stackscpvals} {hline 2}}Post-estimation command for use in conjunction with {cmd:allsynth}. {cmd:stackscpvals} automates the stacking and averaging of 
(generally, modified) synthetic control estimated gaps for multiple treated units and the donor pool units, the creation of the sample empirical ditribution of placebo 
average treatment effects, and the calculation of specified p-values. 
As {cmd:allsynth} automates these procedures with ''classic'' and ''bias-corrected'' synthetic control estimates, {cmd:stackscpvals} should be used when making additional 
corrections to the outcome variables after estimating the synthetic control donor weights (e.g. correcting for the impact of local pandemic response shocks as in 
{browse "https://www.journals.uchicago.edu/doi/10.1086/735551":Wiltshire et al. Forthcoming}).{p_end}
{p2colreset}{...}


{title:Syntax}

{p 6 8 2}
{opt stackscpvals} {opt gap}({it:gapvar})  {opt time}({it:timevar}) {opt unit}({it:unitvar}) {opt pvalues}({it:string}) {opt filepath}({it:string}) 
[ {opt filepath_2}({it:string})... {opt filepath_9}({it:string}) {opt savepath}({it:string}) {opt savename}({it:string}) {opt keeptrunits}({it:numlist})
{opt numavg}({it:#}) {opt emin}({it:#}) {opt emax}({it:#}) {opt avgwts}({it:string}) {opt balance} ]

{p 4 4 2}
Variables specified in {it:gapvar}, {it:timevar}, and {it:unitvar} must be numeric variables; abbreviations are not allowed. 

{title:Description}

{p 4 4 2}
{cmd:stackscpvals} is a post-estimation command for use in conjunction with the {cmd:allsynth} command ({browse "https://justinwiltshire.com/s/allsynth_Wiltshire.pdf":Wiltshire Forthcoming}), 
which should be understood prior to implementation of {cmd:stackscpvals} and which automates the implementation of several synthetic control estimation features. 
{cmd:stackscpvals} permits simple post-estimation stacking and averaging of synthetic control estimated gaps (and placebo gaps) and especially post-estimation adjusted versions thereof 
for users who have already estimated those gaps using {cmd:allsynth}.

{title:Required Settings}

{p 4 4 2}
{marker predoptions}

{p 4 4 2}
{cmd:gapvar} the variable observing the synthetic control estimated gaps. {cmd:allsynth} produces {it:gap} and/or {it:gap_bc}, but users may choose to make adjustments
(e.g. adjusting outcome variables for the impact of local pandemic responses as in {browse "https://www.journals.uchicago.edu/doi/10.1086/735551":Wiltshire et al. Forthcoming}) 
and may thus rename {cmd:gapvar}, which must be observed for all units in each data set in the directory specified by {cmd:filepath}({it:filepath}) unless particular
units are excluded using the {cmd:keeptrunits}({it:numlist})

{p 4 4 2}
{cmd:timevar} the time variable.

{p 4 4 2}
{cmd:unitvar} the unit variable.

{p 4 8 2}
{cmd:pvalues}({cmd:rmspe|variance)} automates estimation of in-space placebo gaps across the donor pool units, for the purpose of calculating {it:p}-values. This means that
the {cmd:allsynth} option {cmd:pvalues}({it:string}) must have been specified and the placebo gap estimated for the donor pool units affiliated with each treated unit.

{p 8 8 2}{it:At least one} of {cmd:rmspe} or {cmd:variance} is required, and both are permitted.
{cmd:rmspe} will calculate RMSPE-ranked {it:p}-values for each post-treatment period. {cmd:variance} will calculate {it:p}-values and 95% confidence intervals for each post 
treatment period based on the variance of the sample distribution of placebo average gaps (see {browse "https://justinwiltshire.com/s/allsynth_Wiltshire.pdf":Wiltshire Forthcoming} 
for further discussion). The variables {it:RMSPE}, {it:RMSPE_rank}, and {it:p} (based on
the form of the variables in the specified data sets) will be estimated if {cmd:rmspe} is specified. The variables {it:_Se}, {it:_Tstat}, {it:_Pval}, {it:LB_95}, and 
{it:UB_95} (based on the form of the variables in the specified data sets) will be estimated if {cmd:variance} is specified.{p_end}

{p 4 8 2}
{cmd:filepath}({it:filepath}) specifies the directory where the (possibly adjusted) files containing the estimates to be stacked can be found. 

{title:stackscpvals Options}

{p 4 8 2}
{opt filepath_2}({it:filepath})... {opt filepath_9}({it:filepath}) specifies the directories of additional files to be stacked beyond those in {cmd:filepath}({it:filepath}).

{p 4 8 2}
{opt savepath}({it:directory}) specifies the directory where the results should be saved as {cmd:savename}({it:file}).

{p 4 8 2}
{opt savename}({it:file}) specifies the filename to be used to save the results

{p 4 8 2}
{opt keeptrunits}({it:numlist}) specifies a list of {it:at least two} treated units--and the associated donor pool units--to be stacked (and averaged). Any estimates found 
in {opt filepath}({it:string}) [ {opt filepath_2}({it:string})... {opt filepath_9}({it:string}) ] associated with treated units not specified in {cmd:keeptrunits}({it:numlist}) 
will be excluded from the stack.

{p 4 8 2}
{opt numavg}({it:#}) specifies the number of placebo average gaps that should be sampled from the population of possibilities. If {cmd:pvalues}(rmspe) is specified, the default 
setting for {cmd:numavg}({it:#}) is 100 and the minimum is 30 ({cmd:stackscpvals} will automatically set {cmd:numavg}({it:#}) to 30 if a lower number is specified. If 
{cmd:pvalues}(variance) is specified, cmd:numavg}({it:#}) will be ignored and {cmd:stackscpvals} will automatically sample 1000 placebo average gaps.

{p 4 8 2}
{opt emin}({it:#}) specifies the earliest period in event time to be considered, where {it:e=0} is the period of treatment. {cmd:emin}({it:#}) must be < 0, and the default
setting is -5. The earliest event period actually observed can (obviously) not be earlier than what exists in the data.

{p 4 8 2}
{opt emax}({it:#}) specifies the latest period in event time to be considered, where {it:e=0} is the period of treatment. {cmd:emax}({it:#}) must be > 0, and the default
setting is 5. The latest event period actually observed can (obviously) not be later than what exists in the data.

{p 4 8 2}
{opt avgwts}({it:varname}) specifies a numeric variable that identifies the treated-unit weights to be used to calculated the (weighted) average treatment effects. 
For each treated unit {it:i} the weights must be non-missing and constant across all {it:timevar} periods. {cmd:avgwts}({it:varname}) is likely to be the same 
variable as specified in the {cmd:avgweights}() option of the {cmd:stacked}() option of {cmd:allsynth}.

{p 4 8 2}
{opt balance} specifies that the estimated average treatment effects (gaps) should be displayed and saved only for those event periods 
in which {it:every} treated unit is observed. This ensures common interpretability of the estimated average gap across retained event periods (this 
is true even if the results are displayed and saved in calendar time).


{p 0 4 2} Users are pointed to "2_qcew_stack.do" and "4_qwi_stack.do" of the replication package for {browse "https://www.journals.uchicago.edu/doi/10.1086/735551":Wiltshire et al. Forthcoming}
to see examples of how stackscpvals can be used.

{title:References}

{p 4 8 2}
Wiltshire, J.C., McPherson, C., Reich, M. and D. Sosinskiy, Forthcoming. Minimum Wage Effects and Monopsony Explanations. {it:Journal of Labor Economics}.

{p 4 8 2}
Wiltshire, J.C., Forthcoming. allsynth: (Stacked) Synthetic Control Bias-Correction Utilities for Stata. {it:Working paper}.


{title:Author}

	Justin C. Wiltshire
	University of Victoria, Department of Economics

