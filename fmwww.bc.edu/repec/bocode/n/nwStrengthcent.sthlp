{smcl}
{* *! version 1.0.0 22avr2016}{...}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwStrengthcent {hline 2} Calculates Freeman centralization index (1979) of the nodes strength }
{p2colreset}{...}


{title:Syntax}
{p 8 17 2}
{cmdab: nwStrengthcent}
[{cmd:,}
{opt DIRection()}
]



{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt DIRection()}}  Indicates the strength direction for directed networks (default: outward)


{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}

{cmd:nwStrengthcent()} returns the Freeman centralization index of the nodes strength.

In a famous article, Freeman defines a centralization index that could be adapted for all centrality measures {it:C}

Let {it:C_i*} be the maximum value of {it:C_i} of all nodes {it:i} in the network. 
The Freeman centralization index corresponds to: 
   F_C=  (sum_i [C_{i*}-C_i]) / ( max(sum_i [C_{i*}-C_i]))


More precisely, for the Strength centralization, we rewrote the denominator as the maximum difference possible
 in strength for a graph with the same dimensions (number of nodes and total weights {it:W}).
   
   F_s= (sum_i [s_{i*}-s_i]) / ((W-min(s_i)) (n-1))


See:
Freeman, L. C. (1978). Centrality in social networks conceptual clarification. Social networks, 1(3), 215-239.
 

{title:Saved results}

{pstd}{cmd: nwStrength} saves the following scalars in {cmd:r()}:

{pstd}

{synoptset 14 tabbed}{...}
{p2col 5 14 18 2: }{p_end}
{synopt:{cmd:r(s_central)}} Strength centralization index{p_end}


{p2colreset}{...}


{title:Examples}

	{cmd:. webnwuse klas12b, nwclear}
	{cmd:. nwkeep klas12b_wave2}
	{cmd:. nwStrengthcent,direction(outward)}
	
{title:Author}
Charlie Joyez, Paris-Dauphine University
charlie.joyez@dauphine.fr

{title:See also}
{pstd}
{cmd:nwStrengthcent}  requires the {bf : nwcommands} package developed by Thomas Grund.

{pstd}

For do-files and ancillary files, see:

	{cmd:. net describe nwcommands-ado, from(http://www.nwcommands.org)}
	
For help files, see :

	{cmd:. net describe nwcommands-hlp, from(http://www.nwcommands.org)}


