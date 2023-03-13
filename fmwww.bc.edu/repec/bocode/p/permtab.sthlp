{smcl}
{* Copyright 2007-2017 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 28May2017}{...}
{cmd:help permtab}
{hline}

{title:Title}

{p2colset 5 17 23 2}{...}
{p2col:{hi:permtab} {hline 2}}Rearrange columns of a table to maximise kappa{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:permtab} {it: rowvar colvar} [if] [in] [, gen(newvarname) algorithm(string) random tables maxiter(real)]

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt :{opt algo:rithm(string)}} (Optional) select algorithm (exhaustive, hill-climb or genetic algorithm){p_end}
{synopt :{opt ran:dom}} (Optional) If hillclimb algorithm is selected, start from a random permutation{p_end}
{synopt :{opt tab:les}} (Optional) Show tabulations{p_end}
{synopt :{opt maxit:er}} (Optional) Maximum GA iterations (default 250){p_end}
{synoptline} {p2colreset}{...}



{title:Description}

{pstd}{cmd:permtab} permutes the columns of the crosstabulation of
rowvar by colvar to maximise kappa. If the table is not square, it is
padded with rows or columns of zeros. {cmd:permtab} is intended for use
for problems such as comparing cluster solutions where the identity of
categories from one solution to the other is only defined in terms of
membership. Kappa measures the excess of observed over expected on the
diagonal. Kappa_max is the Kappa of the best solution, and is
reported.{p_end}

{pstd}A permuted version of {it:colvar} is created by the {opt gen} option.{p_end}


{pstd}Three algorithms are used. By default all permutations are
examined. This is slow for more than 8 categories, and become impossible
above about 11. Second, a hill-climb algorithm takes either the current
ordering or a random permutation of it and looks for all pairwise swaps
that improve fit. Third, a genetic algorithm efficiently searches for an
approximate maximum in the permutation space. Both the hill-climb and
genetic algorithm approaches do very well at finding a good solution.{p_end}


{pstd}The {opt algorithm()} option controls which is used. The default
(or {opt algorithm(full)}) yields all permutations. Hill-climb is
selected by {opt algorithm(hc)}, and {opt algorithm(hc)} {opt random}
randomises the starting permutation. The genetic algorithm is selected
by {opt algorithm(ga)}.{p_end}


{pstd}Returns kappa_max as r(kappa).{p_end}
{pstd}Returns the best permutation as r(perm).{p_end}



{title:References}

{p 4 4 2}
C. Reilly, C. Wang and M. Rutherford, 2005: 
A Rapid Method for the Comparison of Cluster Analyses,
{it:Statistica Sinica},
15(1), pp 19-33.


{title:Author}

{phang}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{phang}{cmd:. permtab a8 b8, tables}{p_end}
{phang}{cmd:. permtab a8 b8, gen(b8x)}{p_end}
{phang}{cmd:. permtab a9 b9, algo(hc)}{p_end}
{phang}{cmd:. permtab a9 b9, algo(hc) random}{p_end}
{phang}{cmd:. permtab a32 b32, algo(ga)}{p_end}

