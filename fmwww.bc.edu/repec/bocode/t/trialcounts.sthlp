{smcl}
{* *! version 1.0)}
{hline}
{cmd:help trialcounts}
{hline}
{vieweralsosee "mixedpower" "help mixedpower"}{...}
{vieweralsosee "mvmixedpower" "help mvmixedpower"}{...}
{vieweralsosee "dmmixedpower" "help dmmixedpower"}{...}
{viewerjumpto "Syntax" "trialcounts##syntax"}{...}
{viewerjumpto "Menu" "trialcounts##menu"}{...}
{viewerjumpto "Description" "trialcounts##description"}{...}
{viewerjumpto "Options" "trialcounts##options"}{...}
{viewerjumpto "Examples" "trialcounts##examples"}{...}
{viewerjumpto "Stored results" "trialcounts##results"}{...}
{viewerjumpto "Author" "trialcounts##author"}{...}

{title:Title}
{p2colset 5 20 20 2}{...}
{p2col :{hi:trialcounts} {hline 2}}{cmd:trialcounts} is a program for calculating the number of subjects recruited to, 
and the number having reached subsequent scheduled visits, in a clinical trial based on supplied linear piecewise
 recruitment functions, whilst additionally accounting for potential dropout.
 From these are derived the 'cohort weights' 
 which can be used in the {helpb mixedpower} program in order to calculate power or sample size for linear mixed models,
 accounting for the recruitment and dropout functions established in {cmd:trialcounts} at a given point in trial time.


{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:trialcounts}
        {cmd:,}
        {opth sched:ule(numlist)}
		{opth ends(numlist)}
		{opth rates(numlist)}
        [{it:{help trialcounts##options_table:options}}]


{synoptset 32 tabbed}{...}
{marker options}
{marker options_table}{...}
{synopthdr}
{synoptline}

{p2coldent :* {opth sched:ule(numlist)}}list of visit times for the proposed study{p_end}
{p2coldent :* {opt ends(varname|numlist)}}list of timepoints ends of each piecewise (linear) recruitment function{p_end}
{p2coldent :* {opt rates(varname numlist|numlist)}}list of recruitment rates for each piecewise (linear) function{p_end}
{synopt :{opth time:list(numlist)}}single time value to evaluate recruitment function; or timelist to search over when using {opt search}{p_end}
{synopt :{opt quad:ratic}}set the first piecewise recruitment function to be quadratic{p_end}
{synopt :{opt maxn(#)}}maximum number to be recruited to the trial, overrriding recruitment function{p_end}
{synopt :{opt search(# #)}}search for the timepoint that reaches target #_1 at visit #_2{p_end}
{synopt :{opth drop:outs(numlist)}}list of proportions of those who only reached visit k, and no further, due to dropout{p_end}
{synopt :{cmdab: drf:unction(}{it:{help trialcounts##drf_type:drf_type}}{cmd:, p(#) [l(#) k(#) s(#)])}}define dropout function using a parametric survival model{p_end}
{synopt :{opt rgr:aph}}request a plot of the recruitment function{p_end}
{synopt :{opt dgr:aph}}request a plot each of the parametric survival and hazard dropout functions{p_end}
{synopt :{opt noli:nes}}suppress red count lines in recruitment function{p_end}
{synopt :{opth rgopts(twoway_options)}}recruitment function plot options, except graph name{p_end}
{synopt :{opth dhgopts(twoway_options)}}dropout hazard function plot options, except graph name{p_end}
{synopt :{opth dsgopts(twoway_options)}}dropout survival function plot options, except graph name{p_end}
{synopt :{opth ren:ame(name_option)}}recruitment function plot name option{p_end}
{synopt :{opth dhn:ame(name_option)}}dropout hazard function plot name option{p_end}
{synopt :{opth dsn:ame(name_option)}}dropout survival function plot name option{p_end}
{synopt :{opt comp:act}}display table of results in compact form{p_end}
{synopt :{opt disp2}}include the rescaled probability weights in the displayed table of results{p_end}



{synoptline}
{pstd}*this option is required.
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{marker drf_type}{...}
{synopthdr :drf_type }
{synoptline}
{synopt :{opt w:eibull}}weibull dropout model{p_end}
{synopt :{opt logn:ormal}}log normal dropout model{p_end}
{synopt :{opt gom:pertz}}gompertz dropout model{p_end}
{synopt :{opt logl:ogistic}}log logistic dropout model{p_end}
{synopt :{opt ggam:ma}}generalized gamma dropout model{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:trialcounts} calculates the number of subjects recruited to a trial, as well as the number having reached subsequent 
scheduled visits, based on a user-supplied recruitment function. The reported numbers are given as both the total number
having reached each visit, and the unique number who have only reached each visit but no further. 

{pstd}
 The user defines the recruitment function in 
a list of piecewise linear functions in two required options; {opt ends} which defines that endpoint {it:t} for 
each consecutive piecewise function and {opt rates} which defines the recruitment rates for each of those 
functions i.e number recruited per unit time, regardless of length of the function (difference between {opt ends}).
The recruitment function can therefore be arbitrarily complex. The {opt ends} and {opt rates} options
can be supplied either directly as number lists or as variable names containing the successive values.

{pstd}
The other required option is {opt sched:ule} which informs {cmd:trialcounts} the visit timepoints where the 
counts need to be evaluated at. Another crucial option, though not required, {opt time:list} indicates at what point in 
'trial time' the counts are to be calculated for. Other useful options are {opt maxn} which will override the 
defined recruitment function in the sense that you can set a limit to the number of total recruited to the trial.
You can also use the {opt search} option to establish at what point in time do a target number of subjects reach 
a specific visit, which is when {opt time:list} needs to be an actual list to search over. The {opt quad:ratic} option
can be used to easily replicate an increasing recruitment rate in its early phase.

{pstd}
Based on the list of counts, {cmd:trialcounts} also produces 'probability weights' representing the 
proportion who have reached the various visit schedule points, 
either out of all those who will be recruited according to the {cmd:trialcounts} recruitment function 
('final weights' in the output) or out of all those currently recruited according to the time value used 
to evaluate the recruitment function ('final weights rescaled' in the output). Either of the weight lists
may be used, according to required needs, in the {cmd:mixedpower,} {opt strec:ruitment} option to calculate power 
or sample size accounting for partial subject follow-up at interim study timepoints.

{pstd}
{cmd:trialcounts} also incorporates dropout rates and integrates the dropout and recruitment functions to produce
the necessary counts and probability weights, accounting for both factors. Dropout probabilities can be supplied
as a list within the {opt drop:outs} option or using the {opt drf:unction} which calculates dropout probabilities
for the user based on common parametric survival models, selected according to preferential hazard shapes. Plots
can also be produced by {cmd:trialcounts} to visualise both dropout and recruitment function selections.
 

{marker options}{...}
{title:Options}

{dlgtab:Required option}

{phang}
{opth sched:ule(numlist)} specifies the visit times for the proposed trial. The supplied number list must always be increasing and
 not negative. The length of the list is limited to 101 visits including baseline, though the table of counts output will not
 be printed with visit length>20. Even so, the output will not be presented prettily before that number is reached. All important
  information will in supplied in the returned list regardless of visit length.
 
{phang}
{opt ends(varname|numlist)} list of timepoints that relate to the 'end' of each piecewise (linear) recruitment function. The list can be directly supplied as a number list,
 allowing the usual shorthand conventions, or as a (numeric) variable name that contain the numbers therein, with relevant rows
 as indexed by the {opt rates} option. However supplied, the  number list can be just one value and a maximum of 120 values
 but must always be increasing 
and not negative. The number of values must match the number supplied in {opt rates} (guaranteed if using the {helpb varname}
method for both {opt ends} and {opt rates})
, but not necessarily that in {opt sched:ule}.
The first piecewise function then, spans time zero (baseline) to the first value in {opt ends},
and the second piecewise from first value in {opt ends} to the second, and so on. 

{phang} 
{opt rates(varname numlist|numlist)} list of recruitment rates that relate to each piecewise (linear) recruitment function. 
The list can be directly supplied as a number list,
 allowing the usual shorthand conventions, or as a (numeric) variable name that contain the numbers therein, with relevant rows
 to include additionally indexed by a number list. The number list used for either method can be just one value and a maximum of
 120 values
 and must not be negative. However, only for the variable name method (where its role is as a row index) must the number list
 be always increasing. 
The number of values must match the number supplied in {opt ends} (guaranteed if using the {helpb varname}
method for both {opt ends} and {opt rates}), but not necessarily that in {opt sched:ule}. The rate values 
 themselves should represent the number recruited per unit time (hence {it:rate}) in that piecewise function span, 
 regardless of the length of the span. One could even supply a long list of values if one was attempting to 
 replicate the actual recruitment rates of a trial through time (e.g. one rate per month so far, and perhaps supplemented with predicted
 rates into the future), and this can be easily performed with the variable name method if such rates exist in a data file. 
 
{pmore}
If using the variable name input method for {opt ends} then one must do so also for {opt rates}; if using the variable name
input method for {opt rates} then one may use either the variable name or number list input method for {opt ends}, assuming the length matches for both.
 With the variable name method one may select non-consecutive rows to input (e.g. {opt rates(1/5 8/10 14 20)}), if
 consecutive rows have the same rate. This may speed-up computation if there are many rows (say, recruitment rates for every
 month of a trial) and the search option is being utilised. Also be aware that including an empty row will cause the
 program to exit.
 
{dlgtab:Other options} 

{phang}
{opt time:list(# [# ...])} despite the option name one will typically supply just one value that indicates the point in trial 
time where the recruitment function will be evaluated and counts of subjects at each visit made.
However, you need not request any time value, or alternatively you may specify a needlessly large value far beyond
 the length of the trial. In which case the functions 
are evaluated at 'the end of the trial' which is defined as the time of the last value in {opt ends} plus the last value 
in {opt sched:ule} i.e. time at the last visit for the last subject recruited. In which case, a warning message is given telling
the user no time value has been supplied.{p_end} 
{p 8 8 2} When using the {opt search} option then the {opt time:list} option must be now be a list of at least 2 increasing 
numbers for the program to search over. You will probably want to use a shorthand convention such as {opt time:list(4(0.01)5)}.

{phang}
{opt quad:ratic} this is to specify that the first (and only first) piecewise recruitment function is to be a quadratic, rather
than linear, function. This is to enable a convenient shortcut to approximating a smooth and increasing recruitment rate in the
early phase of the trial, rather than trying to replicate through a series of linear piecewise functions, each increasing in rates
slightly. The first value in the {opt rates} list will be be interpreted as if the coefficient of a quadratic function, and so 
will typically require a smaller value than for the linear rates. 

{phang}
{opt maxn(#)} to specify a maximum size of the trial. This will override the recruitment function as supplied in {opt ends} 
and {opt rates}. One may be able to estimate a recruitment rate stretching into the future but be unsure for how long one needs
to indicate this function i.e. what should the last value from {opt ends} be? If you just know that the trial only needs to 
recruit a certain number of subjects then use {opt maxn(#)}. Once the supplied recruitment function hits the {opt maxn(#)} limit,
 that point becomes the time value of the last recruited subjects (and hence the last value of {opt ends} 
in this restricted recruitment function). Counts and recruitment plots (including the limit of the trial) will reflect this.
 
{phang} 
{opt search(# #)} allows one to search for the point in trial time where a target number (the first #) of subjects reaches a
particular visit number (the second #). Hence the second # must not be greater than the length of {opt sched:ule}. If the {opt search}
option is requested then a list of increasing time values must be supplied to {opt time:list} for the program to search over. 
If the time list is first specified in large intervals you could rerun the command with a more focused, granular time list to obtain an
accurate estimate of the objective time value. That being said, the {cmd:trialcounts,} {opt search}
option is typically fast even when searching over many values, although there is a limit of 2500 for the number of elements Stata allows in a
number list. If the supplied list is entirely below the objective time value then
{cmd:trialcounts} will produce a warning message to that effect and report the counts and weights at the last supplied time value.
If the supplied list is entirely above the objective time value then {cmd:trialcounts} will produce a warning message 
to that effect and report the counts and weights at the first supplied time value.

{phang} 
{opth drop:outs(numlist)} specifies the estimated proportion of dropouts you 
expect at each study visit. It must correspond exactly to the length of the schedule list. 
Each number in the list should be between 0 and 1 and is the proportion who only reached visit {it:k}, and no further, 
due to dropout. Therefore, the sum of all proportions should not exceed one. There is a built in tolerance of 0.000001 
to deal with numerical inaccuracies within Stata. 

{phang}
{cmdab: drf:unction(}{it:{help trialcounts##drf_type:drf_type}}{cmd:, p(#) [l(#) k(#) s(#)])} allows the user to define in a more convenient,
and perhaps plausible, manner the dropout function compared to the direct entry of {opt drop:outs}. Instead a parametric survival model 
is chosen with a hazard function that reflects anticipated dropout rates over the trial history (for example increasing, decreasing,
 non-monotonic). The function choices are weibull, log normal, gompertz, log logistic and generalized gamma. 
 
{pmore}
 All models except the generalized gamma are specified using 2 of 3 
 possible parameters {opt p(#)}, {opt l(#)} and {opt s(#)}. The letters {opt p} and {opt l} are taken from the Weibull model relating
 to the shape parameter p and the rate parameter lambda. The other three models have a 'shape' or 'scale' parameter,
 and a 'rate' parameter
 of a sort where the linear predictor would enter in a survival regression model (although typically known with differing Greek letters 
 but have been given the same indications here for convenience). 
 The third parameter {opt s} is an additional parameter where the user can alternatively specify the 
 survival function probability at the last vist in the {opt sched:ule} list, instead of {opt l(#)} which is rarely intuitive. The 
 value of {opt l} is then back-calculated in order to generate the dropout probabilities. Hence {opt s(#)} must be between 0 and 1.
 For the generalized gamma model, there is no {opt s(#)} as it is not possible to back-calculate the other parameters from a survival
 probability. Instead the generalized gamma has an additional parameter kappa {opt k(#)}{p_end}
 
{phang2}{opt weibull} where {opt p} is the shape parameter p (>0) and {opt l} the rate parameter lambda (>0). {opt p}<1 
results in an decreasing monotonic hazard function; {opt p}=1 results in a constant hazard function 
i.e. exponential survival model at value of {opt l(#)}; {opt p}=2 results in an positive linear hazard function; 
{opt p}>1 results in an increasing monotonic hazard function{p_end}
{phang2}{opt lognormal} where {opt p} is the scale parameter sigma (>0) and {opt l} the 'rate' parameter mu. {opt p}>0 
 results in an non-monotonic hazard function that increases and then decreases; {opt p} dictates the magnitude of the 
 rise and fall; depending on the parameter values the decrease in hazard might not be observed for the range of the trial schedule{p_end}
{phang2}{opt gompertz} where {opt p} is the shape parameter gamma and {opt l} the rate parameter lambda (>0). {opt p}<0 
results in an decreasing monotonic hazard function starting from value of {opt l(#)}; {opt p}=0 results in a constant 
hazard function i.e. exponential survival model at value of {opt l(#)}; {opt p}>0 results in an increasing monotonic 
hazard function starting from value of {opt l(#)}{p_end}
{phang2}{opt loglogistic} where {opt p} is the scale parameter gamma (>0) and {opt l} the rate parameter lambda (>0). 
{opt p}>0 & <1 results in an non-monotonic hazard function that increases and then decreases; depending on the parameter 
values the decrease in hazard might not be oberved for the range of the trial schedule; {opt p}>=1 results in a monotonic
 decreasing hazard function{p_end}
{phang2}{opt ggmamma} where {opt p} is the shape parameter sigma (>0), {opt k} is another ancillary parameter
 and {opt l} the 'rate' parameter mu (>0). {opt ggmama} is a flexible model, with the Weibull ({opt k}=1), exponential 
 ({opt k}=1 and {opt p}=1) and log-normal {opt k}=0 as special cases.{p_end} 

{phang}
{opt rgr:aph} produces a graph of the recruitment function up to the final timepoint of the trial, defined
as time of last entry in {opt ends} list plus time of last entry in {opt sched:ule} list. The furthest right vertical
 red line is for the first time value in {opt sched:ule}
 plotted at the specified time value, and meets the line for number recruited. 
 Each horizontal line to the left, in turn, is distanced equal 
 to the time interval between visits and so corresponds to the horizontal for the counts at each visit, 
 evaluated at the supplied time. Red horizontal 
lines hence reflect, in order from highest line to lowest, the number of subjects who have reached each visit in the
{opt sched:ule} list, in ascending time order, at the time value supplied in {opt time:list}.
Think of the red vertical lines moving from left to right as trial time progresses 
 with distances between them kept fixed, and where they meet the recruitment function reflecting the {cmd: trialcounts}
 sums at a given {opt time:list(#)}. 
 These red lines can be excluded with option {opt nolines}. If no one has reached a given visit that 
 line will not be present. If the search function is called the lines
 are drawn for the time value in {opt time:list} that meets the target of the search. Additional 
 information regarding the recruitment function is also presented. Note, that if dropout is indicated then this will
 not impact this graph which exclusively concerns recruitment, unlike the table result of counts which integrates
 in the dropout function or list.
 
{phang}
{opt dgr:aph} produces two graphs of the dropout survival and hazard functions specified in {opt drf:unction} with
additional information concerning parameter values. 

{phang}
{opt noli:nes} suppresses the red vertical and horizontal lines depicting the visit counts, as described above in {opt rgr:aph}
 
{phang}
{opth rgopts(twoway_options)} supply (and possibly override) any options allowed for twoway plots for the recruitment graph,
 except for {help name_option} in which case use {opt ren:ame}.

{phang}
{opth dhgopts(twoway_options)} supply (and possibly override) any options allowed for twoway plots for the dropout hazard graph,
 except for {help name_option} in which case use {opt dhn:ame}.

{phang}
{opth dsgopts(twoway_options)} supply (and possibly override) any options allowed for twoway plots for the dropout survival graph,
 except for {help name_option} in which case use {opt dsn:ame}.
 
{phang}
{opth ren:ame(name_option)} override the default name given to the recruitment function graph.

{phang}
{opth dhn:ame(name_option)} override the default name given to the dropout hazard function graph.

{phang}
{opth dsn:ame(name_option)} override the default name given to the dropout survival function graph. 

{phang}
{opt comp:act} display the table of results in compact form. If the table is not displaying nicely into your output window 
because it is too wide, this option may allow the table to fit. Vist index and time value labelling is abbreviated and the results 
are presented to fewer decimal places.

{phang}
{opt disp2} additionally print in the output the list of final cohort probability weights that have been rescaled so as to sum to one. 
Note, the unscaled 'final weights' may sum<1 if not every subject has been recruited at {opt time(#)}.

{title:Output}
    {hline}
{pstd}
The output first provides a summary with the total number who are planned to be recruited to the trial based purely on the recruitment
function, and limited by the {opt maxn} option if necessary. Also given is the number who have have been recruited given the recruitment 
 function (i.e. have had at least a 
baseline visit, so that dropout is not a factor) at the timepoint given by the option {opt time} or evaluated by {opt search}.  

{pstd}
Following this is a table of the cohort probability weights and counts for each visit. The first line gives the final cohort weights, integrated
over dropout and recruitment, which may be used for power and sample size calculation in {cmd:mixedpower}. They reflect the probabilities
of having reached visit {it:k}, and no further, when considering an overall final sample size i.e. the first number in the summary output. The second line
(if requested with {opt disp2}) are the final cohort weights rescaled so they sum to one, and are appropriate for use in {cmd:mixedpower} if considering
an intermediate sample size i.e. the second number in the summary output at {opt time(#)}.

{pstd}
Following the probability weights are the counts per visit. 'Unique counts' indicates the {it:number} having reached visit {it:k}, and no further, at 
{opt time(#)}, whilst 'sum counts' are the total number who have reached at least visit {it:k} at {opt time(#)}, both taking dropout into account.

{marker examples}{...}
{title:Examples}
    {hline}

{pstd}
Specify a recruitment function with 5 piecewise linear functions and request recruitment graph. No time value specified{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0 0.5 1 1.5 2 2.5 3) ends(0.5 1 1.5 3 5) rates(5 7 12 16 25)  rgr"'}}{p_end}

{pstd} 
Same recruitment function but supply a time to evaluate function. Also use {opt disp2}to the rescaled weights in table{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0 0.5 1 1.5 2 2.5 3) ends(0.5 1 1.5 3 5) rates(5 7 12 16 25) time(3.5) rgr disp2  "'}}{p_end}

{pstd} 
Use {opt maxn} to place a limit to recruitment of n=60 and integrate in a weibull dropout function with high early hazard (p=0.7)
and a 'survival' probability of 0.75 at the end of the trial. Also request dropout graphs{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0 0.5 1 1.5 2 2.5 3) ends(0.5 1 1.5 3 5) rates(5 7 12 16 25) time(5) rgr disp2 drfunction(weibull, p(0.7) s(0.75)) maxn(60) dgr"'}} {p_end}

{pstd}
A small trial with slow exponential growth in recruitment{p_end}
{pmore}{bf:{stata `". trialcounts,sched(0(1)10) rates(5(0.5)15) ends(0.5(0.5)10.5) rgr time(9)"'}}{p_end}
{pmore}{bf:{stata `". trialcounts,sched(0(1)10) rates(5(0.5)15) ends(0.5(0.5)10.5) rgr time(9) maxn(80)"'}} 
{p_end}

{pstd} 
Use {opt quad} to indicate first recruitment piece is interpreted as a quadratic function and recreate increasing early recruitment, 
followed by a static recruitment rate and giving the plot a title. Note, only 2 piecewise functions required{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0 0.5 1 1.5 2 2.5 3) ends(3 5) rates(40 250) time(3.5) rgr quad rgopts(title(recruitment function for new trial))"'}} {p_end}

{pstd} 
Use {opt search} function to find when the 5th visit is reached by 80 subjects. We try searching over years 3 to 4 in 0.01 unit 
increments. At least 2 values are required to search over. Also include a lognormal dropout function{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0 0.5 1 1.5 2 2.5 3) ends(3 5) rates(40 250) time(3(0.01)4)  quad drfunction(lognormal, p(1.3) s(0.6)) search(80 5) dgr"'}} {p_end}

{pstd} 
The same set-up (plus a gompertz dropout function) but we search over a range too low to reach the target.
 Note the warning message{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0 0.5 1 1.5 2 2.5 3) ends(3 5) rates(40 250) time(3(0.01)3.5)  quad drfunction(gompertz, p(-0.3) l(0.2)) search(80 5) dgr"'}} {p_end}

{pstd} 
The same set-up (plus a log-logistic dropout function) but we search over a range too high and surpass the target with the first time value. Note the warning message{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0 0.5 1 1.5 2 2.5 3) ends(3 5) rates(40 250) time(4(0.01)5)  quad drfunction(loglogistic, p(0.5) s(0.75)) search(80 5) dgr"'}} {p_end}


{pstd}
{ul:COMBINING MIXEDPOWER WITH TRIALCOUNTS}{p_end}

{pstd}  
An advanced example looking at combining {cmd:trialcounts} with {helpb mixedpower}, or rather in this example, 
{helpb mvmixedpower} and using the variable name entry method.
 We first load a dataset containing recruitment rates for a real MS trial. 
 The variable {bf:recr2} contains the recruitment rate per month for consecutive 2 month intervals
 in the control arm. The first 10 entries are actual monthly rates, 
 with the subsequent 17 entries being 
best estimates into the future. The interim analysis is to be held at 38 months so we really only need to consider the 
first 19 entries. However, for exposition we will include all rows in the file, but use the {opt time} option to limit the calculations 
at month 38. Doing this also allows us to show how one could reduce the number of defined {opt ends} and {opt rates} by using entering the 
number list {opt rates(recr2 1(1)21 27)}, so excluding rows 22-26 as the rates here are identical to 27. In a different example, this may
 reduce the computational burden, especially if combining with {opt search}. We also enter the name of the variable containing the {opt ends}.{p_end}
{pmore}{bf:{stata `". use ms_recruitment, clear"'}}{p_end}

{pstd}
We will run {cmd:trialcounts} with months as the unit of time and the command 
will evalute the supplied recruitment function at 38 months. In addition, we integrate in a Weibull 
dropout function that implies 90% will still be in the trial by the last visit (at 36 months). The variance parameters
for a power calculation are loaded from a
saved multivariate mixed model, which we will auto-input into {cmd:mvmixedpower}. We use the rescaled weights 
from the {cmd:trialcounts} output as the entries in the {opt strec:ruitment} list because we defined a recruitment function that resulted in 
planned sample size greater than the sample size at the time of the interim analysis. By evaluating the local 
rescaled weights macro ({bf:r(fw_rescale)}) returned by {cmd:trialcounts} one can 
enable seamless .do file use.{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0(6)36) ends(month) rates(recr2 1(1)20) time(38) drfunction(weibull, p(0.75) s(0.9)) disp2 rgr dgr"'}}{p_end}
{pmore}{bf:{stata `". est use mvmixed_ms.ster"'}} {p_end}
{pmore}{bf:{stata `". mvmixedpower, trtspec(slope) sched(0 0.5 1 1.5 2 2.5 3) diff(0.05)  auto multi(3) weighting(1 1 1) n(686) alpha(0.3) dropout(`= r(fw_rescale)')"'}}{p_end}

{pstd}
Note, even though use of {cmd:mvmixedpower} will overwrite the r-class returned list from
 {cmd:trialcounts}, {cmd:mixedpower} 
also returns the (integrated) weightings with the same macro names (either {bf:r(final_wgts)} or {bf:r(fw_rescale)}) so one may
continue entering the same {cmd: mixedpower} command when altering some other parameter of the mixed model. Because the mixed model was fitted in years we will return to years as the time unit for the {opt sched:ule} list and 
{opt diff:erence} effect sizes, which will be linearly combined with equal weighting. Note, we indicate the sample size is 343*2=686 to reflect both groups now.


 {hline}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:trialcounts} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 20 4: Scalars}{p_end}
{synopt:{cmd:r(max_time)}}maximum time length of the trial{p_end}
{synopt:{cmd:r(N_limit)}}maximum sample size{p_end}
{synopt:{cmd:r(N_current)}}number recruited evaluated at the supplied time value {p_end}
{synopt:{cmd:r(time_value)}}supplied (or evaluated if using search) time value{p_end}
{synopt:{cmd:r(fwgtsum)}}sum of the recruitment weights based on r(N_limit){p_end}
{synopt:{cmd:r(drate)}}dropout function rate parameter value{p_end}
{synopt:{cmd:r(dshape)}}dropout function shape parameter value{p_end}
{synopt:{cmd:r(dSurv_max)}}dropout function survival probability at last visit{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(schedlist)}}supplied schedule list{p_end}
{synopt:{cmd:r(origends)}}supplied ends list{p_end}
{synopt:{cmd:r(origrates)}}supplied rates list{p_end}
{synopt:{cmd:r(ends)}}effective ends list, different if maxn used{p_end}
{synopt:{cmd:r(rates)}}effective rates list, different if maxn used{p_end}
{synopt:{cmd:r(dropwgts)}}supplied dropout weights{p_end}
{synopt:{cmd:r(recweights)}}recruitment weights based on recruitment function{p_end}
{synopt:{cmd:r(rescalefwgts)}}rescaled final weights so sum to 1{p_end}
{synopt:{cmd:r(uniqcts)}}the unique count making each visit{p_end}
{synopt:{cmd:r(cumcts)}}the cumulative count making each visit{p_end}

{cmd:trialcounts} also returns all the above as macros, as well as the command line, 
the full timelist if using search and the dropout function name in {cmd:r()}:

{p2colreset}{...}

{marker Author}{...}
{title:Author}
Matthew Burnell
MRC Centre of Research Excellence in Clinical Trial Innovation
University College London  
London, UK
m.burnell@ucl.ac.uk


