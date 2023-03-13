{smcl}
{* Copyright 2012 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 28June2012}{...}
{cmd:help sdentropy}
{hline}

{title:Title}

{p2colset 5 17 23 2}{...}
{p2col:{hi:sdentropy} {hline 2}}Calculate the Shannon entropy of a sequence{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:sdentropy} {it: varlist} , {opt gen:erate(string)} {opt cd:stub(string)}  {opt nst:ates(int)}

{title:Description}

{pstd}{cmd:sdentropy} creates a new variable holding the Shannon entropy
of the sequence, given by the {opt gen:erate()} option. As a side
effect, it creates variables containing the relative cumulated duration
(named by the {opt cd:stub()} option, as in {help cumuldur}).
{opt nstates} tells Stata how many states there are. States must be
numbered from 1 up.  {p_end}

{pstd}Shannon entropy takes no account of sequence order, and is just
based on the relative cumulated duration in the different states, with the formula:{p_end}

{phang}- Sum [ p_i * log_2(p_i) ] {p_end}


{title:Author}

{phang}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{phang}{cmd:. sdentropy m1-m40, gen(ent) cd(dur) nstates(3)}{p_end}
