{smcl}
{* *! version 1.0 22 Feb 2023}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help stset" "help stset"}{...}
{vieweralsosee "Help stsplit" "help stsplit"}{...}
{vieweralsosee "Help collapse" "help collapse"}{...}
{vieweralsosee "Help stpiece (if installed)" "help stpiece"}{...}
{viewerjumpto "Syntax" "tteir##syntax"}{...}
{viewerjumpto "Description" "tteir##description"}{...}
{viewerjumpto "Examples" "tteir##examples"}{...}
{viewerjumpto "Generated variables" "tteir##variables"}{...}
{viewerjumpto "Author and support" "tteir##author"}{...}
{title:Title}
{phang}
{bf:tteir} {hline 2} Prepare time-to-event data for incidence rates

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:tteir}
varname
[{cmd:,}
{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Mandatory, see {help stset:stset}}
{synopt :{cmdab:f:ailure:(}{it:failvar}[{cmd:==}{it:{help numlist}}]{cmd:)}}failure event{p_end}

{syntab :Options, see {help stset:stset}}
{synopt :{cmdab:o:rigin(}{cmdab:t:ime} {it:{help exp}}{cmd:)}}define when a subject becomes at risk{p_end}
{synopt :{opt sc:ale(#)}}rescale time value{p_end}
{synopt :{cmdab:en:ter(}{cmdab:t:ime} {it:{help exp}}{cmd:)}}specify when subject first enters study{p_end}
{synopt :{cmdab:ex:it(}{cmdab:t:ime} {it:{help exp}}{cmd:)}}specify when subject exits study{p_end}

{syntab :Options, see {help stsplit:stsplit}}
{p2coldent :* {opth at(numlist)}}split records at specified analysis times{p_end}
{p2coldent :* {opt ev:ery(#)}}split records when analysis time is a multiple of {it:#}.
When {it:#} is set to missing the {opt at(failures):} option of the {cmd:stplit} 
is used{p_end}
{synopt :{opt af:ter(spec)}}use time since {it:spec} for {opt at()} or {opt every()} rather than time since onset of risk{p_end}
{synopt :{opt trim}}exclude observations outside of range{p_end}

{syntab :Options, see {help collapse:collapse}}
{synopt :{opth by(varlist)}}groups over which the generated {it:variables} are 
to be calculated. 
The generated time points from {help stsplit:stsplit} are added the varlist{p_end}

{syntab :Options}
{synopt :{opt ni:ntervals(#)}}Split event evenly into # intervals{p_end}
{synopt :{opt mini:nterval(#)}}Suggested number of events in each interval.{p_end}
{synopt:{opt noq:uietly}}Show output from the used commands in the log{p_end}

{synoptline}
{p2colreset}{...}
{pstd}
* Either {opt at(numlist)} or {opt every(#)} is required with {cmd:stsplit} at designated times.

{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}The command {cmd:tteir} is a wrapper for the use of {help stset:stset},  
{help stsplit:stsplit}, and {help collapse:collapse} as described in 
sections 4.3 to 4.5 in Royston and Lambert (2011) to prepare time-to-event 
datasets for poisson regressions with piecewise constant incidence rates.
A piecewise constant incidence rate for an interval can be interpreted as the 
average hazard rate for that same interval.
The main idea is to get a minimal but sufficient dataset for analysis.

{pstd}Note that using {help mepoisson:mixed-effects poisson regressions} 
for the reduced datasets leads to similar point estimates but different 
variance estimates compared to 
{help mestreg:mixed-effects parametric survival models}.


{marker examples}{...}
{title:Examples}

{phang}The command {cmd:tteir} generates{p_end}
{phang}{stata `"webuse diet, clear"'}{p_end}
{phang}{stata `"tteir dox, failure(fail) origin(time doe) scale(365.25) at(0(2)18)"'}{p_end}
{phang}five variables summarizing the original dataset:{p_end}
{phang}{stata `"list, sep(0) noobs"'}{p_end}
{phang}The list is a summary of number of events and total follow-up time for 
each group.{p_end}

{phang}Instead of the Kaplan-Meyer failure curve,{p_end}
{phang}{stata `"webuse diet, clear"'}{p_end}
{phang}{stata `"stset dox, failure(fail) origin(time doe) scale(365.25) id(id)"'}{p_end}
{phang}{stata `"sts graph, by(hienergy) failure name(km, replace)"'}{p_end}

{phang}one can use the {cmd:tteir} command and the predicted incidence rates 
from the post estimation of the poisson regression{p_end}
{phang}{stata `"tteir dox, failure(fail) origin(time doe) scale(365.25) at(0(2)18) by(hienergy)"'}{p_end}
{phang}{stata `"qui poisson _x bn._start#i.hienergy, irr exposure(_futm) nocons vce(robust)"'}{p_end}
{phang}{stata `"predict ir, ir"'}{p_end}
{phang}{stata `"format ir %6.4f"'}{p_end}
{phang}to get a piece-wice constant Nelson-Aalen failure curve, i.e., the cummulative incidence 
rates{p_end}
{phang}{stata `"generate dt = _stop - _start"'}{p_end}
{phang}{stata `"bysort hienergy (_stop): generate cir = 1 - exp(-sum(ir*dt))"'}{p_end}
{phang}{stata `"format cir %6.4f"'}{p_end}
{phang}The simplest way to compare is to use {help addplot: (if installed) addplot}{p_end}
{phang}{stata `"addplot km: (line cir _stop if !hienergy,sort) (line cir _stop if hienergy,sort)"'}{p_end}


{phang}To reproduce a cox regression like{p_end}
{phang}{stata `"webuse diet, clear"'}{p_end}
{phang}{stata `"stset dox, failure(fail) origin(time doe) scale(365.25) id(id)"'}{p_end}
{phang}{stata `"stcox i.hienergy"'}{p_end}
{phang}can be done simple by{p_end}
{phang}{stata `"tteir dox, failure(fail) origin(time doe) scale(365.25) every(.) by(hienergy)"'}{p_end}
{phang}{stata `"qui poisson _x bn._start i.hienergy, irr exposure(_futm) nocons vce(robust)"'}{p_end}
{phang}{stata `"lincom _b[1.hienergy], eform"'}{p_end}


{phang}To handle non-proportional hazards or time-dependent effects is simple{p_end}
{phang}{stata `"webuse diet, clear"'}{p_end}
{phang}{stata `"generate bmi = weight / height / height * 10000"'}{p_end}
{phang}{stata `"egen bmi_grp = cut(bmi), at(15 18.5 25 30 200) label"'}{p_end}
{phang}{stata `"tteir dox, failure(fail) origin(time dob) enter(time doe) scale(365.25) id(id) at(30(10)70) by(bmi_grp)"'}{p_end}
{phang}{stata `"list, sep(0) noobs"'}{p_end}
{phang}{stata `"poisson _x i.bmi_grp#bn._start, irr exposure(_futm) nocons vce(robust)"'}{p_end}

{phang}Visualizing the time-dependent effects by BMI groups on CHD{p_end}
{phang}{stata `"quietly margins _start#bmi_grp, predict(ir)"'}{p_end}
{phang}{stata `"marginsplot, xtitle(Age (years)) title("") ytitle("Incidence rates and 95% CI")"'}{p_end}


{phang}To secure better estimates, it would often be better to chose that 
events are evenly distributed into the time intervals. 
Here 5 intervals are chosen.{p_end}
{phang}{stata `"webuse diet, clear"'}{p_end}
{phang}{stata `"tteir dox, failure(fail) origin(time doe) scale(365.25) nintervals(5)"'}{p_end}
{phang}{stata `"list, sep(0) noobs"'}{p_end}
{phang}Or one can chose intervals with a minimum number of 20 events in each 
interval.{p_end}
{phang}{stata `"webuse diet, clear"'}{p_end}
{phang}{stata `"tteir dox, failure(fail) origin(time doe) scale(365.25) mininterval(20)"'}{p_end}
{phang}{stata `"list, sep(0) noobs"'}{p_end}


{marker variables}{...}
{title:Generated variables}

{pstd}
{cmd:tteir} generates the following variables:
{synoptset 15 tabbed}{...}

{p2col 5 15 19 2: Name and description}{p_end}
{synopt:{cmd:_start}}Selected start time values.{p_end}
{synopt:{cmd:_stop}}Selected stop time values.{p_end}
{synopt:{cmd:_futm}}Total follow-up time for in the original dataset in the 
interval starting at _start and ending at the following _start, _stop.{p_end}
{synopt:{cmd:_total}}Population size at the start time point _start. 
Note that the {cmd:collapse} is made after the {cmd:stsplit}{p_end}
{synopt:{cmd:_x}}Total number of events in the original dataset in the interval 
starting at _start and ending at _stop.{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}

{title:References}
{phang}Clayton, D. G., and M. Hills. (1993). 
Statistical Models in Epidemiology.
Oxford University Press.

{phang}Royston, Patrick & Lambert, Paul. (2011). 
Flexible Parametric Survival Analysis Using Stata: Beyond the Cox Model.
Stata Press.
{p_end}
