{smcl}
{* 14jul2005}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:encodel} {c -} Streamlined encode

{title:Syntax}

{pmore}
{cmd:encodel} {it:{help varelist}} , [ {cmdab:l:abel(}{it:label-name}{cmd:)} {cmdab:m:ultilabel} {cmd:yn}] 

{title:Description}

{pstd}{cmd:encodel} is a streamlined version of encode, for bulk changing of string variables to numeric. In the default case, one set of value labels is created and assigned to all variables in {it:{help varelist}},
with the values and corresponding labels determined by the first variable. If {cmdab:m:ultilabel} is specified, each variable gets it's own set of labels.

{pstd}Also, each variable in {it:{help varelist}} is {it:replaced} with a numeric version; no new variables are generated (and no warnings are issued).

{title:Options} 
 
{phang}{cmdab:l:abel()} specifies a label name. If it is not specified, the label name will be the the name of the first variable in {it:{help varelist}}, with the suffix {bf:_enc}. 
 
{phang}{cmdab:m:ultilabel} overrides {cmdab:l:abel()}, and results in each variable in {it:{help varelist}} being labeled independently, with it's own values, and with each label name matching its variable name, with the suffix {bf:_enc}. 
 
{phang}{cmd:yn} overrides both {cmdab:l:abel()} and {cmdab:m:ultilabel}. It treats all variables in {it:{help varelist}} as yes/no variables, converts them to 0/1, and applies the value labels "No" and "Yes", with the label name "yn". 
 
{pmore}In this case, the command will convert all varieties of {bf:n}, {bf:no}, {bf:f}, and {bf:false} to 0, and all varieties of {bf:y}, {bf:yes}, {bf:t}, and {bf:true} to 1. 

