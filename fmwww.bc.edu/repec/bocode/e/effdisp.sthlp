{smcl}
{* *!  version 1.0 2/27/2018}
{title:Title}

{p 4 15 2}
{cmd:effdisp} {hline 2} creates plots of an interaction effect showing how the effect of a designated focal variable changes with its moderator(s). 

{title:Description}

{p 4 4 2}
{cmd:effdisp} produces line plots, drop line plots, error bar plots or contour plots displaying the focal variable's effect on the observed or
 "modeled" outcome as it varies with the values of its moderator(s). Line plots and contour plots can optionally show where the moderated effect 
 of the focal variable is and is not significant. Must run {help intspec} before running {cmd:effdisp}. See Kaufman (2018) for detailed 
 explanation and step-by-step examples of using this and other ICALC add-on commands. 

{title:Syntax}

{p 4 10 2}
{cmd:effdisp} {cmd:,} [ {opt plot}({opt type}({it:plottype}) {opt name}({it:graphname}) {opt keep} {opt save}({it:filepath}) 
{opt freq}({it:base})) {opt effect}({it:type}({it:suboptions})) {opt cilev}({it:#}, {it:adjtype}) {opt ndig:its}({it:#}) 
{opt pltopts}({it:string}) {opt sigmark} {opt ccuts}({it:numlist}) {opt heatmap} ]

{p2colset 4 24 24 2}
{p2col: {it:options}}Description {p_end}
   {hline}
{p2colset 4 24 26 2}
{p2col:{cmd:plot(type}({it:plottype}) {opt suboptions})}specifies how to plot focal variable’s effect varying with moderator(s) {p_end}
{p2colset 7 24 26 2}
{p2col:{cmd:type}({it:plottype})}{ul:{it:plottype} is keyword for type of plot}  {p_end}
{p2colset 7 25 25 2}
{p2col: {cmd: }}{cmd:cbound} for a confidence bounds plot, default if interval 1st moderator{p_end}
{p2col: {cmd: }}{cmd:errbar} for an error bar plot, default if categorical 1st moderator{p_end}
{p2col: {cmd: }}{cmd:line} for a connected line plot, interval 1st moderator {p_end}
{p2col: {cmd: }}{cmd:drop} for a drop line plot, usually categorical 1st moderator{p_end}
{p2col: {cmd: }}{cmd:contour}  for contour plot, only if interval 1st & 2nd moderators{p_end}
{p2col:{opt suboptions}}{p_end}
{p2colset 8 24 26 2}
{p2col: {cmd:name}({it:graphname})}save plot as memory graph with name {it:graphname}{p_end}
{p2col: {cmd:keep}}save any intermediate graphs used to create final graph{p_end}
{p2col: {cmd:save}({it:filepath})}save the plotting data & frequency distribution to Excel file with name & location given by {it:filepath}{p_end}
{p2col: {cmd:freq}({it:base})}add relative frequency distribution of 1st moderating variable or 1st by 2nd moderator to the plot{p_end}
{p2col: {cmd: }}{ul:{it:base} can be            }{p_end}
{p2col: {cmd: }}  {it:tot} for distribution of 1st moderator {p_end}
{p2col: {cmd: }}  {it:sub} for distribution of the 1st moderator within levels of the 2nd{p_end}
{p2col: {cmd: }}  {it:subtot} for joint distribution of the 1st & 2nd moderators relative to total sample size {p_end}
{p2colset 4 24 26 2}
{p2col:{cmd:effect(type}({it:suboptions}))}Type of coefficient value reported in significance region table for delta unit change in focal variable {p_end}
{p2colset 7 24 26 2}
{p2col:{cmd:type}}{ul:Keyword for coefficient type}   {p_end}
{p2colset 7 25 25 2}
{p2col: {cmd: }}{cmd:b} for estimated coefficient {p_end}
{p2col: {cmd: }}{cmd:factor} for factor change coefficient {p_end}
{p2col: {cmd: }}{cmd:spost} for marginal/discrete change calculated by the SPOST13 {help mchange} command{p_end}
{p2col: {cmd: }}{bf:Default is effect(b)}. {p_end}
{p2colset 7 24 26 2}
{p2col:suboptions}{ul:b({it:delta}) or factor({it:delta}) where {it:delta} is} {p_end}
{p2colset 7 25 27 2}
{p2col: {cmd: }}{cmd:1} for 1 unit change. {bf:Default} {p_end}
{p2col: {cmd: }}{cmd:sd} for 1 standard deviation change {p_end}
{p2col: {cmd: }}{cmd:#} any non-zero real number change{p_end}
{p2col: {cmd: }}{cmd:sdy} for estimated effect scaled in standard deviation units of "modeled" outcome {p_end}
{p2col: {cmd: }}{cmd:sdyx} for sdy effect calculated for a 1 standard deviation change in focal variable{p_end}
{p2col: {cmd: }}{bf:Default is delta of 1}. {p_end}
{p2colset 7 24 26 2}
{p2col:suboptions}{ul:spost({it:amtopt( )} {it:atopt( ))} where}{p_end}
{p2colset 7 25 27 2}
{p2col: {cmd: }}{cmd:amtopt( )} specifies amount-of-change options for SPOST13 {help mchange} command ((see Long and Freese 2014).
 Must include amount( ) with a single entry. {bf:Default amtopt(amount(one)).} {p_end}
{p2col: {cmd: }}{cmd:atopt( )}specifies content for the at( ) option of the {help margins} command for predictors other than focal or moderators. 
{bf:Default is atopt((asobs) _all)} {p_end}
{p2colset 4 24 26 2}
{p2col:{cmd:cilev}({opt #}, {it:adjtype})}# is confidence interval level (.95 for a 95% CI){p_end} 
{p2col:{cmd: }}{it:adjtype} is bonferroni, sidak or potthoff adjustment for multiple tests, can specify potthoff in combination with 
either bonferroni or sidak. Can abbreivate to 1st three letters. {bf:Default ci(.95)}{p_end}

{p2col:{cmd:ndigits(#)}}number of digits for {it:y}-axis labels {bf:Default = 4}. {p_end}

{p2col:{cmd:sigmark}}if {cmd:sigmark} keyword present, add visual displays to denote significant and non-significant effects on line, 
drop line or contour plots{p_end} 
{p2col:{cmd:pltopts}({it:string})}{it:string} contains {help twoway_options:two-way graph options} to customize appearance (e.g. line colors). These do not always work as expected. 
Use the graph editor if not.{p_end}

{p2col:  {ul:{it:Contour plot only options}}}{p_end}
{p2colset 6 24 26 2}
{p2col: {cmd:ccuts}({it:numlist})}{it:numlist} defines contour cutpoints. {bf:Default is 6 equal steps from min to max of moderated effect.}{p_end}
{p2col: {cmd:heatmap}} Stata twoway contour option for how similar height areas are portrayed{p_end}

{p 2 11 2}
{bf:Note:} Moderator {cmd:range( )} specifications define display values/labels on axis plotting 1st moderator 
(contour plots: also 2nd moderator). For additional moderators defines calculation points at which the plot is repeated.


{title:Example: two-way interaction}

{p 0 0 2}
For a model predicting poor mental health days ({it:pmhdays}) by the interaction of work-family conflict ({it:wfconflict}) 
and job status ({it:sei}), {cmd:intspec} specfies {it:wfconflict} as the focal variable and {it:sei} as its moderator.  {cmd:effdisp} 
produces a confidence bounds plot of {it:wfconflict}'s effect on {it:pmhdays} as it changes with {it:sei}, the default plot type.

{p 6 10 2}
nbreg pmhdays c.wfconflict##c.sei ... {p_end}
{p 6 10 2}
intspec, focal(c.wfconlifct) main( (c.sei name(JobStatus) range(17(10)97)) (c.wfconflict name(WorkFamConflict) range(1/4))) int2vars(c.wfconflict#c.sei) {p_end}
{p 6 10 2}
effdisp , plot(type(cbound)) ndigits(2)

{p 2 4 2} 
*** Add frequency distribution of sei to plot

{p 6 4 2}
effdisp ,  plot(type(cbound) freq(tot)) ndigits(2)

{p 2 4 2}
*** Change plot type to error bar

{p 6 4 2}
effdisp , ndigits(2) plot(type(errbar) freq(tot))

{title:Example 2: three-way interaction}

{p 0 0 2}
After a model predicting voluntary association memberships ({it:memnum}) which includes the interaction of age, educ (education) and female, 
{cmd:intspec} specfies {it:female} as the focal, {it:age} as the 1st moderator and {it:educ} as the 2nd moderator. {cmd:effdisp} 
produces a confidence bounds plot of {it:female}'s effect on {it:memnum} as it changes with {it:age}, with a separate plot for each 
of the five display values for education (0,5,10,15,20).

{p 6 8 2}
reg memnum i.female##c.age##c.educ ... {p_end}
{p 6 8 2}
intspec, focal(i.female) main( (c.age, name(Age) range(18(10)88)) (c.educ, name(Education) range(0(5)20)) (i.female, name(Sex) range(0/1)) ) 
int2vars( c.age#i.female c.ed#i.female c.age#c.ed ) int3vars(i.female#c.age#c.ed)  dvname(Memberships) ndig(0) {p_end}
{p 6 8 2}
effdisp , ndig(2) plot(type(cbound))

{p 2 4 2}
*** Change plot type to contour 

{p 6 8 2}
effdisp , ndig(2) plot(type(contour))

{title:Author and Citation}

{p 4 4 2}
I would appreciate users of this and other ICALC commands citing

{p 6 6 2}
Robert L. Kaufman.  2018. {it: Interaction Effects in Linear and Generalized Linear Models}, Sage Publcations. 

