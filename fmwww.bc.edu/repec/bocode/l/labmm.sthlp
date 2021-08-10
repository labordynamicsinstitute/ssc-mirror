{smcl}
{* version 1.0.1 22jun2011}
{cmd:help labmm}
{hline}

{title:Title}

{p 5}
{cmd:labmm} {hline 2} Modify multiple value labels

{title:Syntax}

{p 8}
{cmd:labmm} [{it:namelist}] {bf:\} {it:#} {bf:"}{it:label}{bf:"} 
[{it:#} {bf:"}{it:label}{bf:"} {it:...}] [{cmd:,} {opt var:iables}]


{p 5 8}
where {it:namelist} is a list of value label names or, if 
{opt var:iables} is specified, a {varlist}


{title:Description}

{pstd}
{cmd:labmm} modifies (multiple) value labels. All value labels 
specified in {it:namelist} are modified according to definitions. 
The syntax is very similar to {help label:label define} with one 
exception. Associations of intergers and text must be separated 
from {it:namelist} using {bf:\}. If no {it:namelist} is specified, 
it defaults to {it:_all}, meaning all value labels in memory, or 
if {opt var:iables} is specified, all value labels attached to 
variables in the dataset.

{title:Options}

{phang}
{opt variables} causes {it:namelist} to be interpreted as a 
{varlist}.


{title:Examples}

	. sysuse nlsw88 ,clear
	(NLSW, 1988 extract)

	{cmd:. labmm _all \ .a "don't know" .b "refused"}
	
	
{title:Acknowledgments}

{pstd}
Modifying multiple value labels was suggested by Anna Reimondos on 
{browse "http://www.stata.com/statalist/archive/2010-04/msg00554.html":statalist}.
Michael Norman Mitchell's solution led to this ado.

{title:Author}

{pstd}Daniel Klein, University of Bamberg, klein.daniel.81@gmail.com

{title:Also see}

{psee}
Online: {helpb label}{p_end}

{psee}
if installed: {help strrec}
{p_end}
