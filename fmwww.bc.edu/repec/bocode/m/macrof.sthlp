{smcl}
{* *! version 0.1.0  11Aug2021}{...}
{viewerjumpto "Syntax" "macroF##syntax"}{...}
{viewerjumpto "Description" "macroF##description"}{...}
{viewerjumpto "Options" "macroF##options"}{...}
{viewerjumpto "Examples" "macroF##examples"}{...}
{viewerjumpto "Authors" "macroF##authors"}{...}

{...}{* NB: these hide the newlines }
{...}
{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:macroF} {hline 2}} Compute macroF {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:macroF} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth pred:(macroF##pred:str)}} Variable name containing predicted classification coded as 0/1.{p_end}
{synopt :{opth true:(macroF##true:str)}} Variable name containing true classification coded as 0/1.{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:macroF} Computes the macroF evaluation criterion for multi-class outcomes.


{marker options}{...}
{title:Options}

{phang}
{marker pred}{...} 
{opt  pred:(str)}  Variable name containing predicted classification coded as 0/1.{p_end}

{phang}
{marker true}{...} 
{opt  true:(str)}  Variable name containing predicted classification coded as 0/1.{p_end}



{marker examples}{...}
{title:Examples}

{pstd}Example:  Predict 3 types of insurance. Convert probabilities for each to a single variable with the predicted category. Compute macroF. 

{phang}{cmd:. use https://www.stata-press.com/data/r17/sysdsn1 }

{phang}{cmd:. mlogit insure nonwhite age male }

{phang}{cmd:. predict p1 p2 p3 }

{phang}{cmd:. gen maxp=max(p1,p2,p3) }

{phang}{cmd:. gen pred=. }

{phang}{cmd:. replace pred=1 if p1==maxp }

{phang}{cmd:. replace pred=2 if p2==maxp }

{phang}{cmd:. replace pred=3 if p3==maxp }

{phang}{cmd:. tab pred,m }

{phang}{cmd:. macroF, pred(pred) true(insure) }

{marker authors}{...}
{title:Authors}

{pmore} Matthias Schonlau <schonlau@uwaterloo.ca>{p_end}




