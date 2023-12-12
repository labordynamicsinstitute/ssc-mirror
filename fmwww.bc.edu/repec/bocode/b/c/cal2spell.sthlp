{smcl}
{* Copyright 2018 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 05Apr2018}{...}
{cmd:help cal2spell}
{hline}

{title:Title}

{p2colset 5 17 23 2}{...}
{p2col:{hi:cal2spell} {hline 2}}Create spell-format variables from wide calendar format variables{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:cal2spell}, options


{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Options}
{synopt :{opt st:ate(string)}} Stub of state variable name, in {help reshape} fashion{p_end}
{synopt :{opt spell:var(string)}} Stub of spell state-variable name (will be created){p_end}
{synopt :{opt length(string)}} Stub of spell length-variable name (will be created){p_end}
{synopt :{opt nsp:ells(varname)}} number-of-spells variable (will be created){p_end}

{title:Description}

{pstd}{cmd:cal2spell} takes variables representing sequence data in wide calendar format
(i.e., a consecutive string of numbered state variables representing
state in each time unit, with one case per sequence) and creates
wide spell format variables (consecutive pairs of numbered state and duration
variables) with a separate variable indicating the number of spells.
{p_end}

{pstd} It returns the maximum number of spells observed in r(maxspells)
and the range of the state variable in r(nels).{p_end}

{pstd} This can be used to prepare the data for {help:combinadd} and
other techniques that focus on spell history rather than state history.{p_end}

{pstd} Spells are defined as consecutive runs of the same state in the
calendar variables.{p_end}

{pstd} Note: this replaces {cmd:combinprep}, and differs from it in that
it retains both the calendar and spell format representations, rather
than replacing the calendar with the spell variables.{p_end}

{title:Author}

{phang}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{pstd} Given sequences represented as consecutive variables s1-s40:{p_end}

{phang}{cmd:. cal2spell, state(s) spell(sp) length(dur) nspells(nsp)}{p_end}

{pstd} will generate a new structures with variable pairs sp1,
dur1 to spX, durX where X is the maximum number of
spells observed. The spells are defined as consecutive runs in the same
state, and their duration is recorded in the dur variable. The
observed number of spells in each case is recorded in nsp.{p_end}
