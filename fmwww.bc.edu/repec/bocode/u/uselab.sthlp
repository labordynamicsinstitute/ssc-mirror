{smcl}
{* version 1.0.2 25jun2011}
{cmd:help uselab}
{hline}

{title:Title}

{p 5}
{cmd:uselab} {hline 2} list value labels and variables using them

{title:Syntax}

{p 8}
{cmd:uselab} [{it:namelist}] [{cmd:,} {opt var:iables}]


{p 5 5}
where {it:namelist} is either a list of value label names, or, if 
{opt var:iables} is specified, a {varlist}

{title:Description}

{pstd}
{cmd:uselab} lists value label names and all variables they are attached to. 
It provides similar information to {helpb uselabel}, but without creating a 
dataset. If {it:namelist} is not specified, all value labels in memory are 
listed together with all variables that use them.

{title:Options}

{phang}
{opt var:iables} lists value labels attached to variables in {it:namelist} 
together with all other variables in the current dataset, that use the 
respective value labels.

{title:Example}

	. sysuse nlsw88 ,clear
	(NLSW, 1988 extract)

	{cmd:. uselab}

	racelbl: race
	marlbl: married
	gradlbl: collgrad
	smsalbl: smsa
	indlbl: industry
	occlbl: occupation
	unionlbl: union

	{cmd:. uselab mar coll ,variables}

	marlbl: married
	gradlbl: collgrad

{title:Saved results}

{pstd}
{cmd:uselab} saves the following in {cmd:r()}:

{pstd}
Macros{p_end}
	{cmd:r({it:lblname})} 	varlist using value label {it:lblname}


{title:Acknowledgements}

{pstd}
The major part of the code used is from offical Stata's {help uselabel}.


{title:Author}

{pstd}Daniel Klein, University of Bamberg, klein.daniel.81@gmail.com

{title:Also see}

{psee}
Online: {helpb uselabel}, {help label}
{p_end}
