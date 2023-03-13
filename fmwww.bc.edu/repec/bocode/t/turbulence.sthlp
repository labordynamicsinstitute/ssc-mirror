{smcl}
{* Copyright 2018 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 01April2018}{...}
{cmd:help turbulence}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:turbulence} {hline 2}}Calculate sequence turbulence {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:turbulence}, GEN(newvarname) STAtevars(string)  LENgthvars(string) NSPells(string) NSTates(real)

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Required}
{synopt :{opt gen(varname)}} names the variable in which to store the number of distinct subsequences{p_end}
{synopt :{opt sta:tevars(varlist)}} the variables holding the spell state information{p_end}
{synopt :{opt len:gthvars(varlist)}} the variables holding the spell duration information{p_end}
{synopt :{opt nsp:ells(varname)}} the variable holding the number of spells in each sequence{p_end}
{synopt :{opt nst:ates(real)}} the number of distinct states{p_end}

{title:Description}

{pstd}{cmd:turbulence} Calculates Elzinga's {it:turbulence} measure of
sequence complexity. It takes spell information, where each spell has a
state variable and a length variable, and calculates an index based on
the number of distinct subsequences (see {cmd:ndsub}) and the variance of the durations.
{p_end}

{pstd}{bf:Note}: Assumes sequences are represented by consecutive variables containing numeric values.{p_end}


{title:Author}

{phang}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{phang}{cmd:. turbulence, gen(turb) sta(spell*) len(len*) nsp(nspells) nst(5)}{p_end}


