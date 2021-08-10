{smcl}
{* version 1.1.2 21jul2011}{...}
{cmd:help revv}
{hline}

{title:Title}

{p 5}
{cmd:revv} {hline 2} Reverse value order of variables

{title:Syntax}

{p 8}
{cmd:revv} {varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt pre:fix(str)}}use {it:str} as prefix for new variables
{p_end}
{synopt:{opt g:enerate(namelist)}}create new variables 
{it:name1, ..., namek}
{p_end}
{synopt:{opt replace}}replace variables with reversed version
{p_end}
{synopt:{opt v:alid(numlist)}}reverse all values specified in 
{help numlist}
{p_end}
{synopt:{opt def:ine(namelist)}}define value labels and use 
{it:name1, ..., namek} as value label names
{p_end}
{synopt:{opt nol:abel}}do not define a value label for new variables
{p_end}
{synopt:{opt num:label}}handle numeric prefix in value labels
{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:revv} reverses the value order of each variable specified in 
{it:varlist}. New variables are created containing the reversed value 
order of the original variables. Value labels are reversed accordingly.

{pstd}
{bf:Remarks:} Variables are assumed to be Likert-type items with 
integer values incremented by one. If this is not the case specify 
{opt valid()}. {cmd:revv} is also able to handle variables that 
contain non-integer values.

{title:Options}

{dlgtab:Options}

{phang}
{opt prefix(str)} uses {it:str} as prefix for the new variables' names. 
Default prefix is {it:rv_}, meaning that reversed variables names are 
{hi:{it:rv_}}{it:varname}.

{phang}
{opt generate(namelist)} creates new variables {it:name1, ..., namek}. 
May be combined with {opt prefix()}.

{phang}
{opt replace} replaces variables in {it:varlist} with their reversed 
version. May not be combined with {opt generate()} or {opt prefix()}.

{phang}
{opt valid(numlist)} reverses values specified in {it:numlist}. In 
numlist (1 2 3 4) values 1 and 4 and values 2 and 3 are swapped. 
See example.

{phang}
{opt define(namelist)} uses names as value label names for the created 
variables. Default is to use new variables' names as value label names.

{phang}
{opt nolabel} specifies that no value labels will be defined for the 
new variables.

{phang}
{opt numlabel} indicates that there is a numeric prefix assigned to the 
value labels by {help numlabel}. If a {cmd:numlabel} command has been 
used previously value labels defined by {cmd:revv} will not be 
appropriate, unless {opt numlabel} is specified. 


{title:Examples}

{pstd}
Suppose three variables containing information on respondents attitudes 
towards some issue. Variable {it:var1} has values 1 'strongly agree' to 
5 'strongly disagree', {it:var2} has values 1 'very important' to 7 
'not important at all' and {it:var3} has values 1 'always' to 4 
'never'. For some reason we want to reverse the value order of all 
three variables, so {it:var1} has values 1 'strongly disagree' to 5 
'strongly agree' and so on. We can do so typing something like:

{phang2}
{cmd:. recode var1 (5 = 1)(4 = 2)(2 = 4)(1 = 5) ,prefix(rec_)}
{p_end}
{phang2}
{cmd:. recode var2 (7 = 1)(6 = 2)(5 = 3)(3 = 5)(2 = 6)(1 = 7) ,prefix(rec_)}
{p_end}
{phang2}
{cmd:. recode var3 (4 = 1)(3 = 2)(2 = 3)(1 = 4) ,prefix(rec_)}
{p_end}

{pstd}
We get the same result (and appropriate value labels) typing:

{phang2}
{cmd:. revv var1 var2 var3 ,prefix(rec_)}
{p_end}


{pstd}
{ul:How to use the {opt valid()} option}

{phang2}
. tabulate var1
{p_end}

	             var1 |      Freq.     Percent        Cum.
	------------------+-----------------------------------
	            agree |          2       14.29       14.29
	        undecided |          3       21.43       35.71
	         disagree |          4       28.57       64.29
	strongly disagree |          5       35.71      100.00
	------------------+-----------------------------------
	            Total |         14      100.00

{phang2}
. label list var1
{p_end}
	var1:
	           1 strongly agree
	           2 agree
	           3 undecided
	           4 disagree
	           5 strongly disagree
	           9 missing

{pstd}
Note that the minimum valid value in the data (which is 2) is not the 
theoretical minimum value in the underlying Likert-item (which is 1). 
Without specifying {opt valid()} you will get:

{phang2}
{cmd:. revv var1}
{p_end}

{phang2}
. tabulate rv_var1
{p_end}

	          rv_var1 |      Freq.     Percent        Cum.
	------------------+-----------------------------------
	strongly disagree |          5       35.71       35.71
	         disagree |          4       28.57       64.29
	        undecided |          3       21.43       85.71
	            agree |          2       14.29      100.00
	------------------+-----------------------------------
	            Total |         14      100.00
{phang2}
. label list rv_var1
{p_end}	
	rv_var1:
        	  1 strongly agree
	          2 strongly disagree
	          3 disagree
	          4 undecided
	          5 agree
	          9 missing

{pstd}
Note that 'strongly agree' is coded '2', whereas you want it to be 
coded '1'. Specifying the {opt valid()} option gives the 
appropriate result

{phang2}
{cmd:. revv var1 ,valid(1/5)}
{p_end}

{phang2}
. tabulate rv_var1
{p_end}

	         rv_var1  |      Freq.     Percent        Cum.
	------------------+-----------------------------------
	strongly disagree |          5       35.71       35.71
	         disagree |          4       28.57       64.29
	        undecided |          3       21.43       85.71
	            agree |          2       14.29      100.00
	------------------+-----------------------------------
	            Total |         14      100.00

{phang2}
. label list rv_var1
{p_end}
	rv_var1:
	          1 strongly disagree
	          2 disagree
	          3 undecided
	          4 agree
	          5 strongly agree
	          9 missing

			  
{title:Acknowledgments}

{pstd}
There are several programs that serve the same purpose as {cmd:revv}. 
The {cmd:omscore} command written by Marc Jacobs in 1992, {cmd:revrs} 
by Kyle C. Longest, {cmd:reverse} by Johan Martinsson (which is not 
available form SSC yet) and the {cmd:vreverse} command by Nicholas 
J. Cox, to name a view. Implemented in official Stata there is the 
{cmd:gsort} command which can (in some cases) be used to reverse the 
value order of variables. Looking at these programs was very helpful 
writing {cmd:revv}. I have tried to combine their strengths and 
overcome their shortcomings.

{pstd}
{cmd:revv} enables the user to specify a list of variables (as revrs 
and gsort) rather than only one variable and allows a user defined name 
for the created new variables (as reverse, vreverse and gsort). 
Extended missing values are left unchanged and copied to the new 
variable (as revrs does). {cmd:revv} handles non-integer values and the 
user may specify valid values that are not in the data. The command 
applies to value labels, too (as revrs and vreverse). Value labels are 
reversed for all valid values (either in the data or given by the user) 
and left unchanged if there are no corresponding valid values. 
{cmd:revv} can also handle a previously used {help numlabel} command 
(probably not as well as vreverse does though).

{title:Author}

{pstd}Daniel Klein, University of Bamberg, klein.daniel.81@gmail.com

{title:Also see}

{psee}
Online: {help gsort}, {help recode}, {help label}{p_end}

{psee}
if installed: {help omscore}, {help revrs}, {help vreverse}
{p_end}
