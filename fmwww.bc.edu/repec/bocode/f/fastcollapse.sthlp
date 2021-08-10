{smcl}
{* *! version 1.2  25nov2014}{...}
{title:Title}
{vieweralsosee "collapse" "help collapse"}{...}
{vieweralsosee "hash" "help hash"}{...}
{vieweralsosee "fastsample" "help fastsample"}{...}

{p2colset 5 21 23 2}{...}
{p2col :{manlink P fastcollapse} {hline 2}}Collapse variables using fast hash-based-algorithm{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fastcollapse}
[{opt (stat)}] {cmd:{varlist}} [{help weight:{it:aweight}}] {ifin}, by({help varlist:integer varlist}) [cw]

{p 4 17 2}
where {opt (stat)} is either {opt sum} or {opt mean}.
If {it:stat} is not specified, {opt sum} is assumed (for backwards compatibility).

{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt:{opt by(varlist)}}Groups over which sum is to be calculated.{p_end}
{synopt:{opt cw}}Casewise deletion. Missing values of {varlist} are dropped.{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:fastcollapse} is a much faster version of calculating sums over groups
than {help collapse} that scales in O(n) time rather than O(nlogn). It achieves this
by generating a hash map from the {it:by()} varlist rather than sorting over it 
({help collapse} internally sorts by the {it:by()} varlist).
{cmd:fastcollapse} is restricted to collapsing by {it:by()} varlists
whose cumulative product of ranges is less than or equal to 2,147,483,647. Cumalative
product of ranges is defined as: (max(byvar_1)-min(byvar_1)+1)*...*(max(byvar_k)-min(byvar_k)+1).

{pstd}
For a population size of 10^9; with 3 grouping variables of ranges 5, 5, and 100, 
the computation times were benchmarked as:

{pin}
{opt collapse}: 2245 seconds (37.4 minutes)

{pin}
{opt fastcollapse}: 539 seconds (9.0 minutes)


{marker limitations}{...}
{title:Limitations}

{pstd}
{cmd:fastcollapse} weights are only supports with (mean) for the time being.
Error will be displayed if user specifies weights with (sum).

{pstd}
{cmd:fastcollapse} may only be used to fastcollapse {it:by()} varlists of 
type byte, int, or long. (Negative values are okay)

{pstd}
WARNING: {cmd:fastcollapse} may require significant instantaneous memory usage.
Peak memory useage is on the order of (Cumulative product of ranges)*8 bytes
(eg, for 4 {it:by()} variables, each with a range of 100, peak memory usage will be
on the order of (100*100*100*100)*8 = 0.8GB.

{marker remarks}{...}
{title:Remarks}

{pstd}
See {help hash} for a description of the hashing algorithm used.

{marker author}{...}
{title:Author:}

{pstd}
Andrew Maurer, November 25, 2014

{marker examples}{...}
{title:Examples:}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}

{pstd}Create a dataset of total prices and weights of cars by distinct groups of foreign and rep78{p_end}
{phang2}{cmd:. fastcollapse (sum) price weight, by(foreign rep78)}

    {hline}








