{smcl}
{* *!  version 1.0 2/21/2018}
{title:Title}

{p 4 15 2}
{cmd:gfi} {hline 2} defines and works with the formula for the structure of a designated focal variable’s interactive effect on the “modeled” outcome.

{title:Description}

{p 4 4 2}
{cmd:gfi} produces algebraic expression for the effect of a focal variable as it changes with the moderators, a sign change analysis of the effect
and an optional visualization in a path-style diagram. Must run {help intspec} before running {cmd:gfi}.  See Kaufman (2018) 
for detailed explanation and step-by-step examples of using this and other ICALC add-on commands. 


{title:Syntax}

{p 4 10 2}
{cmd:gfi} {cmd:,}  [ {opt fact:orchg}  {opt ndig:its}(#)  {opt path}({opt type} , {opt ti:tle}({it:string})  {opt name}({it:string})  
{opt boxw:idth}(#)  {opt ygap}(#)  {opt xgap}(#)  {opt ndig:its}(#) ) ] 

{p2colset 4 23 23 2}
{p2col: {it:options}}Description {p_end}
   {hline}
 
{p2col:{cmd:factorchg}}algebraic expression for moderated effect of focal variable also shown as a factor change if this keyword is specified

{p2col:{cmd:ndigits(#)}}number of digits after decimal for effects and coefficients in algebraic expression and sign change table. {bf:Default = 4}.

{p2col:{cmd:path(type, suboptions)}}Create path diagram of structure of interaction effect 
{p_end}
{p2colset 7 23 23 2}
{p2col:{it:type}}{it:focal} or {it:all}. {it:focal} shows only coefficient values for variables involving focal variable. 
{it:all} shows all coefficient values. {bf:Default is focal}. 
{p_end}

{p2colset 7 24 24 2}
{p2col:{it:suboptions}}{cmd:title({it:string})}  {it:string} is title for path diagram {p_end}
{p 23 23 2}
{cmd:name({it:string}})  save as memory graph with name given by {it:string} {p_end}
{p 23 23 2}
{cmd:ndigits(#)} # of digits used to report coefficient values in diagram {p_end}
{p 23 25 2}
{cmd:boxwidth(#)}, {cmd:ygap(#)}, {cmd:xgap(#)}  use to fine-tune graph. boxwidth sets width of boxes; 
ygap sets vertical distance between boxes; xgap sets horizontal distance between boxes. {bf:Defaults are  boxwidth(1.25), ygap(.625), xgap(1.25)}. 

{p 7 13 2 } 
{bf:Note:} Moderator {cmd:range( )} specifications define points at which moderated effect is calculated in sign change analysis. 
For categorical variables all categories define calculation points.

{title:Example: two-way interaction}

{p 0 0 2}
For a model predicting poor mental health days ({it:pmhdays}) by the interaction of work-family conflict ({it:wfconflict}) and job status ({it:sei}), {cmd:intspec} 
specfies  {it:wfconflict} as the focal variable and {it:sei} as its moderator.  {cmd:gfi}  produces the formula for how Job STatus ({it:sei}) moderates the effect of 
Work Famly Conlict ({it:wfconflict}) on {it:pmhdays} and a table portraying when, if at all, the moderated effect of {it:wfconflict} changes sign.


{p 6 10 2}
nbreg pmhdays c.wfconflict##c.sei ... {p_end}
{p 6 10 2}
intspec, focal(c.wfconlifct) main( (c.sei name(JobStatus) range(17(10)97)) (c.wfconflict name(WorkFamConflict) range(1/4))) int2vars(c.wfconflict#c.sei) {p_end}
{p 6 10 2}
gfi , ndigits(5) 

{p 4 4 2} 
*** Also show formula for moderated effect of wfconflict as a factor change

{p 6 4 2}
gfi , ndigits(5) factorchg

{p 4 4 2}
*** Also draw path-style diagram of the effect of wfconflict moderated by sei

{p 6 4 2}
gfi , ndigits(5) factorchg path(all) 



{title:Author and Citation}

{p 4 4 2}
I would appreciate users of this and other ICALC commands citing

{p 6 6 2}
Robert L. Kaufman.  2018. {it: Interaction Effects in Linear and Generalized Linear Models}, Sage Publcations. 

