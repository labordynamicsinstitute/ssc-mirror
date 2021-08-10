{smcl}
{* *!version 1.1.0 17/11/2016}{...}
{cmd:help clean_name}
{hline}

{title:Title}



{title:Syntax}
{p 8 17 3}
{cmdab:clean_name}
 {depvar}  
{cmd:,} {it:options}


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth case(upper|proper)}} specify whether the variable should be returned with proper or upper case. By default,   lower case variable is returned. {p_end} 
{synoptline}


{phang}
{bf:clean_name} {hline 2} Cleans string variables by removing all uncommun characters. 
{p2colset 5 22 26 2}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:clean_fname} {varlist}

{marker description}{...}
{title:Description}

{pstd}
{opt clean_name} removes blanks, accents, full stops, hyphens, apostrophes and all uncommon characters (eszet, tilde, cedille, space and invisible characters...) from string variables. By default, it returns the lower version of the variables but upper and proper version can be specified in options. clean_name is particularly useful to clean non consistent identifiers (such as first and last name, school name, region name). The command proves itself very useful when merging using string variables (names, schools, villages) or to remove duplicates. 
Please do not hesitate to contact me to add other "uncommon" characters to the list. 

{marker examples}{...}
{title:Examples}

{phang} clean_name first_name first_name2, case(proper)




{title:Author}
{pstd}
Adrien Bouguen, Mannheim Universitat, bouguen@uni-mannheim.de
 {p_end}

