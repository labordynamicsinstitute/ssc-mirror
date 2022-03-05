{smcl}
{* *!  version 1.0 2/21/2018}
{title:Title}

{p 4 15 2}
{cmd:intspec} {hline 2} Define interaction specification for ICALC add-on prior to using {help gfi}, {help sigreg}, {help effdisp} or {help outdisp} commands


{title:Description}

{p 4 4 2}
{cmd:intspec} Specifies interacting variables, their display ranges and names, which variable to treat as focal 
and which varible(s) to treat as moderating. Can set equation name of results to use if there are multiple. See Kaufman (2018)
for detailed explanation and step-by-step examples of using this and other ICALC add-on commands.


{title:Syntax}

{p 4 10 2}
{cmd:intspec} {opt focal(varname)} {opt main((varlist1, suboptions)(varlist2, suboptions) … )} 
{opt int2:vars(varlist)} [ {opt int3:vars(varlist)} {opt dvn:ame(string)} {opt eqn:ame(string)} {opt ndig:its(#)} 
{opt nran:ge(#)} {opt abbrevn(#)} {opt sumwgt(string)}  ]
{p_end}


{p2colset 4 23 23 2}
{p2col: {it:options}}Description {p_end}
   {hline}

{p2col:{cmd:focal}({varname})}specifies the name of the focal variable

{p2col:{cmd:main(({varlist}, suboptions) ... )}} sets info for each focal and moderator main effect variable
{p_end}
{p2colset 7 23 23 2}
{p2col:{varlist}}{varname} if interval variable {p_end}
{p 22}
{help fvvarlist:fvname} if factor variable  {p_end}
{p 22}
{varlist} if a set of dummy variables {p_end}

{p 22 22}
Relative order determines moderator numbering; moderator#1 is 1st moderator listed; moderator#2 is 2nd moderator listed;  focal set can be in any order
{p_end}

{p2colset 7 23 25 2}
{p2col:suboptions}name({it:string})  display name for the variable;  default is 1st varname in varlist , abbreviated to 12 characters 
{p_end}

{p 22 24} 
range({help numlist}){it:numlist} sets display values to label/define tables and graphs for interval variable. 
Max # of digits in numlist entry defines # digits for display values.   {it:OR} {p_end}
{p 22 24} 
range({it:keyword})  {it:keyword} can be {p_end} 
{p 24 24}
{it:minmax}  min to max in increments = (max-min)/nrange {p_end}
{p 24 24}
{it:meanpm1}  mean +/- 1 std. dev. {p_end}
{p 24 24}
{it:meanpm2}  mean +/- 1 std. dev., +/- 2 std. dev. {p_end}
{p 24 24}
{it:meanpm1mm}   min,  mean +/- 1 std. dev., max {p_end}
{p 24 24}
{it:meanpm2mm}   min,  mean +/- 1 std. dev. And +/- 2 std. dev., max {p_end}
{p 24 26}
{bf:Default is range(minmax) {sf:with} default nrange=5}. For a single dummy variable can specify range(0/1)
Not needed for i.varname; ignored if included
{p_end}

{p2colset 4 23 23 2}
{p2col:{cmd:int2vars({varlist})}}lists the 2-way interaction terms; must be ordered as  focal-by-moderator#1   focal-by-moderator#2  ; if a 3-way interaction also  moderator#1-by-moderator#2

{p2col:{cmd:int3vars({varlist})}}lists the 3-way interaction terms if any; must be ordered as  focal-by-moderator#1-by-moderator#2 

{p2col:{cmd:dvname({it:string})}}display name of dependent variable. {bf:Default is {it:varname} of dependent variable}.

{p2col:{cmd:eqname({it:string})}}use for multi-equation models; {it:string} specifies which equation’s coefficients are analyzed 

{p2col:{cmd:ndigits(#)}}integer # of digits used in default display value labels if range( ) not specified. {bf:Default ndig(2)}

{p2col:{cmd:nrange(#)}}nrange+1 =  # of increments in range(minmax); {bf:Default is 5 increments} 

{p2col:{cmd:abbrevn(#)}}specifies the character length used to abbreviate names; must be an integer; {bf:default is abbrevn(12)}

{p2col:{cmd:sumwgt({it:string})}}sumwgt(no) specifies that estimation command weights not used to calculate summary statistics


{title:Example 1: two-way interaction}

{p 0 0 2}
After a model predicting poor mental health days ({it:pmhdays}) which includes the interaction of work-family conflict ({it:wfconflict}) and job status ({it:sei}), {cmd:intspec} 
specfies {it:wfconflict}) as the focal and {it:sei} as the moderating variable and identifies {it:c.wfconflict#c.sei} as the term 
used to model the interaction of {it:wfconflict}) and {it:sei}.

{p 4 4 2} 
*** Interaction specified using factor variables, use default display names and ranges

{p 6 4 2}
nbreg pmhdays c.wfconflict##c.sei ... {p_end}
{p 6 4 2}
intspec focal(c.wfconlifct) main( (c.sei) (c.wfconflict)) int2vars(c.wfconflict#c.sei)

{p 4 4 2} 
*** Also specify display names and ranges 

{p 6 8 2}
intspec focal(c.wfconlifct) main( (c.sei, name(JobStatus) range(17(10)97)) (c.wfconflict, name(WorkFamConflict) range(1/4))) int2vars(c.wfconflict#c.sei)

{p 4 4 2}
*** Not using factor variables, use product term wfconbysei (=wfconflict*sei), use default display names and ranges

{p 6 4 2}
nbreg pmhdays wfconflict sei wfconfbysei ... {p_end}
{p 6 4 2}
intspec focal(wfconlifct) main( (sei) (wfconflict)) int2vars(wfconbysei)


{title:Example 2: three-way interaction}

{p 0 0 2}
After a model predicting voluntary association memberships ({it:memnum}) which includes the interaction of age, educ (education) and female, {cmd:intspec} 
specfies the focal and moderating variables, their names and ranges, and the model terms for the interactions

{p 4 4 2} 
*** Interaction specified using factor variables, specify display names and ranges, set numeric display labels' format to 2 digits

{p 6 8 2}
reg memnum i.female##c.age##c.educ ... {p_end}
{p 6 8 2}
intspec focal(i.female) main( (c.age, name(Age) range(18(10)88)) (c.educ, name(Education) range(0(4)20)) (i.female, name(Sex) range(0/1)) ) 
int2vars( c.age#i.female c.ed#i.female c.age#c.ed ) int3vars(i.female#c.age#c.ed)  dvname(Memberships) ndig(0)


{title:Author and Citation}

{p 4 4 2}
I would appreciate users of this and other ICALC commands citing

{p 6 6 2}
Robert L. Kaufman.  2018. {it: Interaction Effects in Linear and Generalized Linear Models}, Sage Publcations. 

