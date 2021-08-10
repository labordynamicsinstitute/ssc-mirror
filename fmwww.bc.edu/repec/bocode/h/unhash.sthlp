{smcl}
{* *! version 1.0  17oct2014}{...}
{title:Title}
{vieweralsosee "collapse" "help collapse"}{...}
{vieweralsosee "fastcollapse" "help fastcollapse"}{...}

{p2colset 5 21 23 2}{...}
{p2col :{manlink P hash} {hline 2}}Perform non-minimal perfect hashing on variables{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:hash}
{cmd:{varlist}} [, gen({help newvar:newhashvarname}) replace force nodrop]

{p 8 17 2}
{cmd:unhash}
{cmd:{help varname:hashvarname}} [, nodrop]

{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt:{opt gen(name)}}Name of the hashed variable to be generated.{p_end}
{synopt:{opt replace}}Causes generated variable to be replaced if it already exists.{p_end}
{synopt:{opt force}}Force hashing to occur even if {varlist} has missing values or contains invalid variable types (not recommended).{p_end}
{synopt:{opt nodrop}}Stop {varlist} from being dropped after hashing (default is to drop {varlist} after hashing).{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:hash} combines multiple variables of type byte, int, or long into a single 
hashed variable that may later be used to recover the original variables. It is
a programmer's command that executes very quickly and requires no internal
sorting. Hash retains the original variable characteristics; namely, variable
{help data_types:types}, {help format:display formats}, {help label:labels}, and
{help char:characteristics}. {cmd:hash} is limited to hashing variables whose
cumulative product of ranges is less than or equal to 2,147,483,647. Cumalative
product of ranges is defined as: (max(var_1)-min(var_1)+1)*...*(max(var_k)-min(var_k)+1).

{pstd}
{cmd:unhash} takes a hashed variable, previously created with {cmd:hash} and restores
the constituent variables. 

{marker limitations}{...}
{title:Limitations}

{pstd}
{cmd:hash} May not be used to hash variables with missing values. I can add
this feature in the future if there is interest.

{pstd}
{cmd:hash} May only be used to hash variables of type byte, int, or long. (Negative
values are okay)

{marker remarks}{...}
{title:Remarks}

{pstd}
The algorithm used may be thought of as a tree. I'll try to better describe
this later on. For now, think of 2 variables: make (takes value 1 or 2) and
color (takes value 1, 2, or 3). There are 6 total combinations of make and color.
{cmd:hash} combines the variables into a new variable that takes values 1 to 6.
hashid=1 corresponds to (make=1,color=1), hashid=2 corresponds to (make=1,color=2),
..., and hashid=6 corresponds to (make=2,color=3).

{pstd}
Hash may be used recursively. Ie: you may use {cmd:hash} to hash a variable
that has already been hashed.

{marker author}{...}
{title:Author:}

{pstd}
Andrew Maurer, October 17, 2014

{marker examples}{...}
{title:Examples:}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}

{pstd}Drop missing values of mpg, length, turn, foreign, and rep78 so they can be hashed{p_end}
{phang2}{cmd:. drop if mi(mpg,length,turn,foreign,rep78)}

{pstd}Hash the variables into new variable hashid.{p_end}
{phang2}{cmd:. hash mpg length turn foreign rep78, gen(hashid)}

{pstd}Recover the original variables from hashid{p_end}
{phang2}{cmd:. unhash hashid}

    {hline}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:hash} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(TableSize)}}Total length of of Table required for hash (ie: cumulative product of ranges).{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(hasheqn)}}Hash equation used to generate hashid from {varlist}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(info)}}matrix of mins, maxs, ranges, and cumulative products of each variable{p_end}
{p2colreset}{...}










