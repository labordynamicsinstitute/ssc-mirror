{smcl}
{* *! version 1 10may2025}{...}
{cmd:help koenker}
{hline}

{p2colset 5 14 16 2}{...}
{p2col :{hi:koenker} {hline 2}}Koenker/White detailed test for heteroskedasticity {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 13 2}
{cmd:koenker}

{pstd}
{cmd:koenker} implements the Koenker/White N*R2 test for heteroskedasticity 
after {cmd:regress}.  {cmd:estat hettest} with the {bf:mtest} option is
based on the Breusch-Pagan/Cook-Weisberg LM test, which has a null hypothesis
of normality of the error distribution. The Koenker/White test relaxes this
assumption, presuming that errors are i.i.d. under the null hypothesis.
The test is executed separately for each regressor, and then for the entire
regression. The simultaneous test is based on the full set of regressors.

{pstd} In the preceding regression, only individual variables, a 
hyphenated list of variables, or a list with wildcards are accepted.
Regressions containing factor variables or interactions cannot be used.


{title:Author} 

{p 4 4 2}Kit Baum, Boston College{break} 
         baum@bc.edu

