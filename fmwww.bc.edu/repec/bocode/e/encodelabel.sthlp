{smcl}
{cmd:help encodelabel}
{hline}

{title:Title}

{p 4 8 2}
{cmd:encodelabel} {hline 2} Encode string variable into categorical variable


{title:Syntax}

{p 8 40 2}
{cmd:encodelabel} 
{varname} 
{ifin}
{cmd:,}
{c -(}{opt g:enerate}{cmd:(}{newvar}{cmd:)}{c |}{opt replace}{c )-}
{opt l:abel(name)}
[
{opt min(#)} 
{opt nosort} 
{opt de:fine}
]


{...}
{title:Description}

{pstd}
{cmd:encodelabel} 
is an alternative to {helpb encode} with the {opt label()} option. 
{cmd:encodelabel} adds to the value label starting with the value 1 
and skipping all values that are already present.

{pstd}
Do not use {cmd:encodelabel} 
if {it:varname} contains numbers that merely happen to be stored as strings; 
instead, use {cmd:generate} {it:newvar} {cmd:=} {opt real(varname)} or {cmd:destring}; 
see {helpb real()} or {helpb destring:[D] destring}.


{...}
{title:Options}

{phang}
{opt generate}{cmd:(}{it:newvar}{cmd:)}
specifies the name of the variable to be created. 
Either option {opt generate()} or {opt replace} is required. 

{phang}
{opt replace} 
specifies that the encoded (numeric categorical) variable replaces {it:varname}; 
any {help notes} and {help char:characteristics} are stripped. 
Either option {opt replace} or {opt generate()} is required.

{phang}
{opt label(name)} 
is required and specifies the name of the value label to be used or added to; 
the named value label must already exist unless {opt define} is also specified.

{phang}
{opt min(#)} 
specifies the first (not yet existing) value to be added to the value label. 
The default is {it:#}=1. 

{phang}
{opt nosort} 
prevents alphanumeric sorting of (the levels of) {it:varname} 
when adding to the value label; 
new labels are added according to the current {help sort} order.

{phang}
{opt define}
specifies that the value is defined if it does not already exist. 


{...}
{title:Examples}

{pstd}
None; see the examples in {helpb encode}.


{...}
{title:Acknowledgments}

{pstd}
{cmd:encodelabel} first appeared on 
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1576828-encode-or-sencode-with-specific-reserved-value-labels":Statalist}
as an answer to a question from Bruce McDougall.


{...}
{title:Support}

{pstd}
Daniel Klein{break}
klein.daniel.81@gmail.com


{...}
{title:Also see}

{psee}
Online: {helpb encode}{p_end}

{psee}
if installed: {helpb sencode}, {helpb multencode}{p_end}
