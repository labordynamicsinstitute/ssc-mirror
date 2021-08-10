{smcl}
{* version 1.0.0 06apr2011}
{cmd:help labellist}
{hline}

{title:Title}

{p 5}
{cmd:labellist} {hline 2} List value labels

{title:Syntax}

{p 8}
{cmd:labellist} [{varlist}] [{cmd:,} {opt l:istonly} {opt ret:urnall}]


{title:Description}

{pstd}
{cmd:labellist} lists contents of value labels attached to variables in 
{it:varlist}. Value label names, values and corresponding labels are 
displayed and returned in {cmd:r()}. If {it:varlist} is not specified, 
it defaults to {it:_all}. Any variable in {it:varlist} that does not 
have a value label attached is ignored.


{title:Options}

{dlgtab:Options}

{phang}
{opt l:istonly} does not return the contents of value labels. If 
{it:varname} has value label {it:lblname} assigned, specifying 
{opt listonly} executes: {help label:label list} {it:lblname}

{phang}
{opt ret:urnall} returns the value label names, values and labels for 
each variable in {it:varlist} in 
{cmd:r({it:varname_}}{it:labels}/{it:values}/{it:lblname{cmd:)}}.


{title:Example}

	. sysuse nlsw88 ,clear
	(NLSW, 1988 extract)

	. labellist occupation
	occlbl:
	           1 Professional/technical
	           2 Managers/admin
	           3 Sales
	           4 Clerical/unskilled
	           5 Craftsmen
	           6 Operatives
	           7 Transport
	           8 Laborers
	           9 Farmers
	          10 Farm laborers
	          11 Service
	          12 Household workers
	          13 Other


{title:Saved results}

{pstd}
{cmd:labellist} saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
        {cmd:r(}[{it:varname_}]{bf:labels}{cmd:)}	labels
        {cmd:r(}[{it:varname_}]{bf:values}{cmd:)}	values
        {cmd:r(}[{it:varname_}]{bf:lblname}{cmd:)}	value label name


{title:Acknowledgments}

{pstd}
The idea and concept is borrowed from Ben Jann's {helpb labelsof}. Both 
programs return the same information.

{pstd}
The approach taken is inspired by Austin Nichols, who also encouraged 
me to make myself familiar with Mata.

{pstd}
The name {cmd:labellist} is borrowed from Stata's official 
{help label list}, as is the output.
 

{title:Author}

{pstd}
Daniel Klein, University of Bamberg, klein.daniel.81@gmail.com

{title:Also see}

{psee}
Online: {help label}{p_end}

{psee}
if installed: {help labelsof}
{p_end}
