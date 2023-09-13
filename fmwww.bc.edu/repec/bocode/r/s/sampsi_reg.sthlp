{smcl}
{* *! version 1.0 14 Mar 2019}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "sampsi_reg##syntax"}{...}
{viewerjumpto "Description" "sampsi_reg##description"}{...}
{viewerjumpto "Options" "sampsi_reg##options"}{...}
{viewerjumpto "Remarks" "sampsi_reg##remarks"}{...}
{viewerjumpto "Examples" "sampsi_reg##examples"}{...}
{title:Title}
{phang}
{bf:sampsi_reg} {hline 2} Calculates Sample Size or Power for Simple Linear Regression

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:sampsi_reg}
[{help varlist}]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt null(#)}}  specifies the "null slope".

{pstd}
{p_end}
{synopt:{opt alt(#)}}  specifies the "alternative slope".

{pstd}
{p_end}
{synopt:{opt n:1(#)}}  size of sample.

{pstd}
{p_end}
{synopt:{opt sd:1(#)}}  standard deviation of the residuals.

{pstd}
{p_end}
{synopt:{opt a:lpha(#)}}  significance level of test.

{pstd}
{p_end}
{synopt:{opt p:ower(#)}}  power of test.

{pstd}
{p_end}
{synopt:{opt s:olve(string)}}  specifies whether to solve for the sample size or power; default is s(n) solves for n
and the only other choice is s(power) solves for power.
{p_end}
{synopt:{opt onesided}}  one-sided test; default is two-sided.

{pstd}
{p_end}
{synopt:{opt sx(#)}}  the standard deviation of the X's.

{pstd}
{p_end}
{synopt:{opt sy(#)}}  the standard deviation of the Y's.

{pstd}
{p_end}
{synopt:{opt var:method(string)}}  specifies the method for calculating the residual standard deviation.  varmethod(r)
uses the Y-X correlation and varmethod(sdy) uses the standard deviation of the Y's, the default uses
a direct estimate of the residual sd sd1(#).
{p_end}
{synopt:{opt yxcorr(#)}}  the correlation between Y's and X's.

{pstd}
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
{cmd:sampsi_reg} calculates the power and sample size for a simple linear regression. The theory behind
this command is described in Dupont and Plummer (1998) Power and Sample Size Calculations for Studies
involving Linear Regression, Controlled Clinical Trials 19:589-601.

{pstd}
The calculations require an estimate of the residual standard error. There are three methods for
doing this: enter the estimate directly; enter the standard deviation of the Y's; or enter the
correlation between Y and X values.

{pstd}
This command can be combined with samplesize in order to look at multiple calculations and to plot
the results.

{pstd}

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt null(#)}     specifies the "null slope".

{pstd}
{p_end}
{phang}
{opt alt(#)}     specifies the "alternative slope".

{pstd}
{p_end}
{phang}
{opt n:1(#)}     size of sample.

{pstd}
{p_end}
{phang}
{opt sd:1(#)}     standard deviation of the residuals.

{pstd}
{p_end}
{phang}
{opt a:lpha(#)}     significance level of test.

{pstd}
{p_end}
{phang}
{opt p:ower(#)}     power of test.

{pstd}
{p_end}
{phang}
{opt s:olve(string)}     specifies whether to solve for the sample size or power; default is s(n) solves for n
and the only other choice is s(power) solves for power.
{p_end}
{phang}
{opt onesided}     one-sided test; default is two-sided.

{pstd}
{p_end}
{phang}
{opt sx(#)}     the standard deviation of the X's.

{pstd}
{p_end}
{phang}
{opt sy(#)}     the standard deviation of the Y's.

{pstd}
{p_end}
{phang}
{opt var:method(string)}     specifies the method for calculating the residual standard deviation.  varmethod(r)
uses the Y-X correlation and varmethod(sdy) uses the standard deviation of the Y's, the default uses
a direct estimate of the residual sd sd1(#).
{p_end}
{phang}
{opt yxcorr(#)}     the correlation between Y's and X's.

{pstd}
{p_end}


{marker examples}{...}
{title:Examples}
{pstd}

{pstd}

{pstd}
Calculate power for a two-sided test:

{pstd}
  {stata sampsi_reg, null(0) alt(0.25) n(100) sx(0.25) yxcorr(0.2) varmethod(r) s(power)}

{pstd}
Compute sample size:

{pstd}
{stata  sampsi_reg, null(0) alt(0.25) sx(0.25) sy(1) varmethod(r) s(n)}

{pstd}
When specifying the variance of the y's you must have a varmethod option
  WRONG: {stata sampsi_reg, null(0) alt(5) sx(0.5) sy(12.3)}
  CORRECT: {stata sampsi_reg, null(0) alt(5) sx(0.5) sy(12.3) var(sdy)}

{pstd}

{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Locals}{p_end}
{synopt:{cmd:r(power)}}  the power {p_end}
{synopt:{cmd:r(N_1)}}  the first arm sample size {p_end}
{synopt:{cmd:r(N_2)}}  the second arm sample size {p_end}


{title:Author}
{p}

Dr Adrian Mander, MRC Biostatistics Unit, University of Cambridge.

Email {browse "mailto:adrian.mander@mrc-bsu.cam.ac.uk":adrian.mander@mrc-bsu.cam.ac.uk}



{title:See Also}
Related commands:


{help samplesize} (if installed){stata ssc install samplesize} (to install this command)
{help sampsi_fleming} (if installed)  {stata ssc install sampsi_fleming} (to install this command)
{help simon2stage} (if installed)   {stata ssc install simon2stage} (to install this command)

