{smcl}
{* *!version 1.1.0 20/03/2015}{...}
{cmd:help clean_lname}
{hline}

{title:Title}

{phang}
{bf:clean_lname} {hline 2} Cleans string variables (particularly "Last names")
{p2colset 5 22 26 2}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:clean_lname} [{varlist}]

{marker description}{...}
{title:Description}

{pstd}
{opt clean_lname} removes blanks, accents, full stops, hyphens and apostrophes 
within a string variable. It also returns the uppercased version of the 
variable. clean_lname (together with clean_fname) is particularly useful for name matching procedure. 


{marker examples}{...}
{title:Examples}

{phang}clean_sname last_name last_name2




{title:Author}
{pstd}
Adrien Bouguen, Paris School of Economics, J-PAL Europe 
abouguen@povertyactionlab.org
 {p_end}
