{smcl}
{* 9jan2015}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "Cfexp" "cfuncspec##cfexp"}{...}
INCLUDE help also_vlowy
{title:Title} 
 
{pstd}{bf:fromvars} {hline 1} select variables whose data satisfies some condition

{title:Syntax} 
 
{pmore}{cmdab:fromvars} {it:{help varelist}} {ifin} {cmd:,} {cmdab:th:oseforwhich(}{it:{help cfuncspec##cfexp:Cfexp}}{cmd:)}


{title:Description}

{pstd}{cmdab:fromvars} returns a list of variables for which some condition holds. For example,

{pmore}{cmd:fromvars *, th( Var()==0 )}

{pstd}will return those variables whose variance over the dataset (or subset selected with {ifin}) is zero.
You must specify a condition with a constant value for all relevant observations. IE, {cmd:Mean()>3} is ok, {cmd:Mean>x} is not.

{pstd}The variable list is also returned in {cmd:r(varlist)}.

