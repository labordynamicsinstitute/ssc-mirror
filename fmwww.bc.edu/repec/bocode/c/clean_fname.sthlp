{smcl}
{* *!version 1.1.0 20/03/2015}{...}
{cmd:help clean_fname}
{hline}

{title:Title}

{phang}
{bf:clean_fname} {hline 2} Cleans firstname variables.
{p2colset 5 22 26 2}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:clean_fname} {varlist}

{marker description}{...}
{title:Description}

{pstd}
{opt clean_fname} removes blanks, accents, full stops, hyphens and apostrophes 
from a string variable. It returns the proper version of the 
variable. clean_fname (together with clean_lname) is particularly useful for name matching procedure.


{marker examples}{...}
{title:Examples}

{phang}clean_fname first_name first_name2




{title:Author}
{pstd}
Adrien Bouguen, Paris School of Economics, J-PAL Europe 
abouguen@povertyactionlab.org
 {p_end}

