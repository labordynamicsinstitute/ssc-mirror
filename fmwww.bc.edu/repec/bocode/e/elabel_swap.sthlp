{smcl}
{cmd:help elabel swap}
{hline}

{title:Title}

{p 4 8 2}
{cmd:elabel swap} {hline 2} Swap value labels


{title:Syntax}

{p 4 10 2}
Basic syntax

{p 8 12 2}
{cmd:elabel swap} 
{it:oldlbl} 
[ {{it:newlbl}|{cmd:.}}
[ {it:oldlbl} 
[ {{it:newlbl}|{cmd:.}}
[ {it:...} ] ] ] ]


{p 4 10 2}
Extended syntax

{p 8 12 2}
{cmd:elabel swap}
{cmd:(}{it:oldlbl1} {it:oldlbl2} [ {it:...} ]{cmd:)}
{cmd:(}{{it:newlbl1}|{cmd:.}} [ {{it:newlbl2}|{cmd:.}} {it:...} ]{cmd:)}


{p 4 10 2}
where {it:oldlbl} and {it:oldlbl1}, {it:oldlbl2}, {it:...} may 
contain the wildcard characters {cmd:*}, {cmd:~}, and {cmd:?} 

{p 10 10 2}
{it:newlbl} and {it:newlbl1}, {it:newlbl2}, {it:...} may be  
{help elabel##elblnamelist:{it:elblname}} or {it:newlblname}


{title:Description}

{pstd}
{cmd:elabel swap} interchanges value labels, i.e., detaches value 
labels from variables and, optionally, attaches new value labels 
to variables.

{pstd}
The command complements {helpb elabel_values:elabel values}, 
which attaches and detaches value labels from a {varlist}. 

{pstd}
In the basic syntax, omit the rightmost {it:newlbl} (or specify {cmd:.}) 
to detach {it:oldlbl} from all variables to which it is attached. If 
{it:newlbl} is specified, it is attached to all variables that previously 
had the respective {it:oldlbl} attached.

{pstd}
In the extended syntax, the mapping of {it:oldlbl} to {it:newlbl} is 
one-to-one. If only one {it:newlbl} is specified, this value label is 
attached to all variables that previously had one of {it:oldlbl1}, 
{it:oldlbl2}, {it:...} attached.

{pstd}
Value labels are swapped in all {help label_language:label languages}.
	

{title:Examples}

{pstd}
Load example dataset

{phang2}{stata sysuse nlsw88:. sysuse nlsw88}{p_end}

{pstd}
Detach value label {cmd:occlbl} form {cmd:occupation} 
(and any other variable that has {cmd:occlbl} attached)

{phang2}{stata elabel swap occlbl:. elabel swap occlbl}{p_end}

{pstd}
Detach {cmd:marlbl} form {cmd:married} and attach new (not yet defined) 
value label {cmd:yesno} to {cmd:married}

{phang2}{stata elabel swap marlbl yesno:. elabel swap marlbl yesno}{p_end}


{title:Author}

{pstd}
Daniel Klein{break}
University of Kassel{break}
klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {helpb label}
{p_end}

{psee}
if installed: {help elabel}
{p_end}
