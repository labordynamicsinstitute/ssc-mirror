{smcl}
{cmd:help elabel adjust}
{hline}

{title:Title}

{p 4 8 2}
{cmd:elabel adjust} {hline 2} Adjust value labels to changed values


{title:Syntax}

{p 8 12 2}
{cmd:elabel adjust}
{cmd::} {c -(}
{helpb mvencode}
{c |}
{helpb mvencode:mvdecode}
{c |} 
{helpb recode}
{c |}
{helpb replace}
{c )-}
{it:...}


{title:Description}

{pstd}
{cmd:elabel adjust} is a {help prefix} command 
that may be used with {cmd:mvencode}, {cmd:mvdecode}, 
{cmd:recode}, and {cmd:replace}. {cmd:elabel adjust} 
modifies value labels to match the changed values in 
variables. 

{pstd}
{cmd:elabel adjust} does not support {cmd:recode} 
options to create new variables. {cmd:elabel adjust} 
requires all variables that have the same value label 
attached to be changed simultaneously. Value labels 
are modified in all label languages.


{title:Examples}

{pstd}
Change numeric values to missing values

{phang2}{cmd:. elabel adjust : mvdecode _all , mv(-9 = .a)}{p_end}


{title:Author}

{pstd}
Daniel Klein{break}
klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {help label}, {help mvencode}, {help mvdecode}, 
{help recode}, {help replace}
{p_end}

{psee}
if installed: {help elabel recode}, {help elabel}
{p_end}
