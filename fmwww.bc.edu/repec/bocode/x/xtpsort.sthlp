{smcl}
{* 26aug2024}{...}
{cmd:help xtpsort}{right:version:   1.5}
{right:also see:  {helpb xtscc}}
{hline}

{title:Title}

{p 4 8}{cmd:xtpsort}  -  Portfolio Sorts Approach (or Jensen alpha approach){p_end}


{title:Syntax}

{p 8 14 2}
{cmd:xtpsort}
{depvar}
[{indepvars}]
{ifin}
[, {it:options}]


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt group:var(varname)}}Dummy variable which defines TWO subject groups (e.g. firms, funds, or investors).
If this option is not set, then it is assumed that all observations belong to the same subject group.{p_end}
{synopt:{opt lag(#)}}Compute Newey-West standard errors with a lag length of {opt lag(#)} periods.{p_end}
{synopt:{opt vce:type(vcetype)}}Define the covariance matrix estimator that has to be applied in the estimation. See below.{p_end}
{synopt:{opt rob:ust}}Compute heteroscedasticity consistent (or White) standard errors.{p_end}
{synopt:{opt ase}}Compute asymptotic rather than small sample adjusted standard errors.{p_end}
{synopt:{opt ipw(varname)}}Variable containing the intra-period weights of the observations;
by default all observations within a period are equally weighted.{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}
{p 4 6 2}
You must {helpb tsset} your data before using {opt xtpsort}.{p_end}
{p 4 6 2}
{opt by} may be used with {opt xtpsort}; see {help by}.{p_end}
{p 4 6 2}


{title:Description}

{p 4 4 2}
{opt xtpsort} performs the portfolio sorts approach (or Jensen alpha approach).
The procedure includes two steps. In the first step, all observations in a given period are aggregated
by computing the (weighted) average value for the {opt depvar}. Then, in the second step, a time-series
regression is estimated with the averaged {opt depvar} as the dependent variable and the {opt indepvars}
as the explanatory variables.{p_end}

{p 4 4 2}
 The {opt xtpsort} program assumes that the {opt indepvars} are identical for all subjects. Put 
 differently, the {opt indepvars} are expected to be factor variables which vary over time but 
 not across the subjects.{p_end}
 
{p 4 4 2}
The {opt xtpsort} program works for both balanced and unbalanced panels, respectively. 
Moreover, it is capable to handle missing values and gaps.{p_end}


{title:Options}

{dlgtab:Model}

{phang}
{opt group:var(varname)} is a dummy variable which defines TWO groups of subjects. In corporate 
finance applications, the subject groups are typically event firms and non-event firms. In studies
on the performance of private investors, the subject groups could be men and women. If this option
is set, then {opt xtpsort} computes for each period the difference between the portfolio excess
return (or whatever the {opt depvar} is) of group 1 and that of group 0.

{p 8 8 2}
An example might help here. Let the dependent variable ({opt depvar}) be the monthly portfolio excess 
return (X) and option {opt group:var(varname)} be set as {it: group(Woman)} where {it:Woman} is a 
dummy variable which is one for women and zero for men. Then, the {opt xtpsort} program computes
for each month the return differential between the aggregated portfolio excess return of the women
and that of the men: {it: Delta(X,t) = X(Women,t) - X(Men,t)}. In the second step of the procedure,
the {opt xtpsort} program then estimates the regression model:{p_end}

{p 8 8 2}
{it: Delta(X,t) = c0 + c1 * Indepvar_1(t) + ... + ck * Indepvar_k(t) + e(t)}.{p_end}

{phang}
{opt lag(#)} estimates the time-series regression of the second step with Newey-West standard errors
which are autocorrelation consistent up to {opt lag(#)} lags.

{phang}
{opt rob:ust} estimates the time-series regression of the second step with heteroscedasticity consistent
(or White) standard errors. Option {opt rob:ust} produces identical results as {opt lag(0)}.

{phang}
{opt vce:type(vcetype)} specifies how to compute the standard errors for the 
coefficient estimates. The following {opt vcetypes} are allowed: {opt rob:ust} estimates 
the time-series regression of the second step with heteroscedasticity consistent (or White)
standard errors. This option yiels similar results as if option {opt rob:ust} (see above)
is chosen. {opt boot:strap} provides bootstrapped standard errors for the time-series 
regression of the second step. Finally, {opt jack:nife} derives jacknifed standard errors 
for the time-series regression of the second step.

{phang}
{opt ase} estimates asymptotic rather than small sample adjusted standard errors.

{phang}
{opt ipw(varname)} defines the intra-period weights of the observations; by default all 
observations within a period are equally weighted. This option may be used to compute value or
firm size weighted portfolio returns rather than equally weighted portfolio returns.

{dlgtab:Reporting}

{phang}
{opt level(#)}; see {help estimation options##level():estimation options}.



{title:Examples}

{phang}{stata "webuse grunfeld, clear" : . webuse grunfeld, clear}{p_end}
{phang}{stata "gen FDummy = (company>6)" : . gen FDummy = (company>6)}{p_end}
{phang}{stata "by year, sort: egen tvar = mean(invest - kstock + mvalue/10)" : . by year, sort: egen tvar = mean(invest - kstock + mvalue/10)}{p_end}
{phang}{stata "xtpsort invest tvar, group(FDummy) lag(2) ase" : . xtpsort invest tvar, group(FDummy) lag(2) ase}{p_end}
{phang}{stata "xtpsort invest tvar if FDummy==1, robust" : . xtpsort invest tvar if FDummy==1, robust}{p_end}


{title:Author}

{p 4 4}Daniel Hoechle, FHNW Business School, daniel.hoechle@fhnw.ch{p_end}



{title:Also see}

{psee}
Manual:  {bf:[R] regress}, {bf:[XT] xtreg}

{psee}
Online:  {help xtscc}, {help xtscc postestimation};{break}
{helpb tsset}, {helpb regress}, {helpb xtreg}, {helpb _robust}
{p_end}

