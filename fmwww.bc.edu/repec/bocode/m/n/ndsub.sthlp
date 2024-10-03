{smcl}
{* Copyright 2018 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 01April2018}{...}
{cmd:help ndsub}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:ndsub} {hline 2}}Count the number of distinct subsequences in a sequence {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:ndsub}, GEN(newvarname) STAtevars(string) NSPells(string) NSTates(real)

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Required}
{synopt :{opt gen(varname)}} names the variable in which to store the number of distinct subsequences{p_end}
{synopt :{opt sta:tevars(varlist)}} the variables holding the spell state information{p_end}
{synopt :{opt nsp:ells(varname)}} the variable holding the number of spells in each sequence{p_end}
{synopt :{opt nst:ates(real)}} the number of distinct states{p_end}

{title:Description}

{pstd}{cmd:ndsub} Calculates the number of distinct subsequences in a
sequence, where a subsequence is an ordered subset of the sequence, not
necessarily consecutive. The STATEVARS option identifies the variables
holding the sequence state information, and the NSPELLS option the
variable holding the length of the sequence.{p_end}

{pstd}{bf:Note}: Assumes sequences are represented by consecutive variables containing numeric values.{p_end}


{title:Author}

{phang}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{phang}{cmd:. ndsub, gen(phi) sta(spell*) nsp(nspells) nst(5)}{p_end}


{title:See Also}

{phang}{help combinadd}{p_end}
{phang}{help turbulence}{p_end}
{phang}{help }{p_end}
{phang}{help }{p_end}
{phang}{help }{p_end}
