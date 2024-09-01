{smcl}
{* 1sept2003/17oct2007/19sept2008/28aug2024}{...}
{hline}
help for {hi:vreverse9}
{hline}

{title:Reverse existing categorical variable}

{p 8 15 2}
{cmd:vreverse9}
{it:varname} 
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
, {cmdab:gen:erate(}{it:newvar}{cmd:)}
[{cmdab:val:uelabelname(}{it:lblname}{cmd:)} 
{cmdab:remove:numlabel} 
{cmdab:m:ask(}{it:str}{cmd:)}]   


{title:Description}

{p 4 4 2}
{cmd:vreverse9} generates {it:newvar} as a reversed copy of an existing
categorical variable {it:varname} which has integer values and (usually) 
value labels assigned.  Suppose that in the observations specified 
{it:varname} varies between minimum {it:min} and maximum {it:max}. Then 

{p 8 8 2}{it:newvar} = {it:min} + {it:max} - {it:varname} 

{p 4 4 2}
and any value labels are mapped accordingly. If no value labels have been 
assigned, then the values of {it:varname} will become the value labels of 
{it:newvar}. {it:newvar} will have the same storage
type and the same display format as {it:varname}.  

{p 4 4 2}If {it:varname} possesses a
variable label or characteristics, these will also be copied. It is the user's
responsibility to consider whether the copied variable label and
characteristics also apply to {it:newvar}. 

{p 4 4 2}
Any missing values in {it:varname}, whether system missing {cmd:.} 
or any extended missing values from {cmd:.a} to {cmd:.z} are copied 
unchanged to {it:newvar}. No attempt is 
made to reverse such categories, but any value labels are copied. 

{p 4 4 2}
This command ignores any value labels associated with {it:varname} for 
values not present in the data specified.  

{p 4 4 2}
The name {cmd:vreverse9} signals not only that this version is slightly 
different from the original {cmd:vreverse} but also that version 9 is 
required (as this command uses {help levelsof}). 


{title:Options}

{p 4 8 2}
{cmd:generate()} is a required option specifying a new variable name.

{p 4 8 2}
{cmd:valuelabelname()} specifies a name for the new value labels. By 
default {it:newvar} is used as the name for the new value labels; any existing 
value labels under that name for the values of {it:newvar} will be overwritten. 
 
{p 4 8 2}
{cmd:removenumlabel} specifies that a numeric prefix previously assigned 
using {help numlabel} to the value labels attached to {it:varname} should be 
removed from the value labels attached to {it:newvar}. The value labels 
attached to {it:varname} will not be modified, unless they are the value 
labels named by {cmd:valuelabelname()}. 

{p 8 8 2}Concretely, suppose you defined value labels for the values 1 to 5 of
{cmd:rep78} and then used {cmd:numlabel} to add numeric prefixes to those
labels. By default, without the {cmd:removenumlabel} option, {cmd:vreverse9}
produces value labels attached to {it:newvar} that will start with "5. " "4. "
"3. " "2. " and "1. ". Specifying the {cmd:removenumlabel} option will strip
those prefixes. Note that a subsequent {cmd:numlabel} would add prefixes "1. "
"2. " "3. " "4. " and "5. ". See also {cmd:mask()} below. 
 
{p 4 8 2}{cmd:mask()} is for use with {cmd:removelabel}. If, and only if, 
some {cmd:mask()} was specified when previously using {cmd:numlabel}, 
then specify the same {cmd:mask()} now. 


{title:Examples} 

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. vreverse9 foreign, gen(Foreign)}

{p 4 8 2}{cmd:. clear}

{p 4 8 2}{cmd:. input testvar}{p_end}
{p 4 8 2}{cmd:1}{p_end}
{p 4 8 2}{cmd:2}{p_end}
{p 4 8 2}{cmd:3}{p_end}
{p 4 8 2}{cmd:4}{p_end}
{p 4 8 2}{cmd:5}{p_end}
{p 4 8 2}{cmd:.}{p_end}
{p 4 8 2}{cmd:.a}{p_end}
{p 4 8 2}{cmd:.z}{p_end}
{p 4 8 2}{cmd:end}

{p 4 8 2}{cmd:. label def testvar 1 Admirable 2 Approved 3 Adequate 4 Alarming 5 Abysmal .a Unrecorded .z Irrelevant}{p_end}
{p 4 8 2}{cmd:. label val testvar testvar}{p_end}
{p 4 8 2}{cmd:. vreverse9 testvar, gen(wanted)}{p_end}
{p 4 8 2}{cmd:. version 17: table testvar wanted, missing}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University, U.K.{break} 
n.j.cox@durham.ac.uk


{title:Acknowledgments}

{p 4 4 2}Original {cmd:vreverse}: Renzo Comolli pointed out an issue that can arise if {cmd:numlabel} 
had previously been used. 
Daniel Stegmueller alerted me to a problem with extended missing values.

{p 4 4 2}This {cmd:vreverse9}: Felix Wilke also flagged problems with extended missing values. 

 
{title:Also see}

{p 4 13 2}
Online: help for {help label}, {help numlabel} 
{p_end}

