{smcl}
{* *! version 12.1  2020-08-23}{...}
{viewerdialog outlabs "dialog ssci"}{...}
{viewerjumpto "Syntax" "ssci##syntax"}{...}
{viewerjumpto "Description" "ssci##description"}{...}
{viewerjumpto "Options" "ssci##options"}{...}
{viewerjumpto "Examples" "ssci##examples"}{...}
{viewerjumpto "Stored Results" "ssci##stored_results"}{...}
{viewerjumpto "References" "ssci##references"}{...}
{title:Title}

{p 4 8}{cmd:ssci} {hline 2} Short and Simple Confidence Interval {p_end}


{marker syntax}{...}
{title:Syntax}

{p 4 8}
{cmd:ssci} {varname}
[{cmd:,} 
{opt below(varlist)}
{opt above(varlist)}
{opt alpha(real)}
{opt type(string)}
{opt bounds(var1=real var2=real ...)}
]{p_end}


{marker description}{...}
{title:Description}

{p 4 8}{cmd:ssci} constructs adaptive confidence intervals on a parameter of 
interest in the presence of nuisance parameters when some of the nuisance 
parameters are bounded from below or above, following 
{browse "https://img1.wsimg.com/blobby/go/891816c3-956f-422c-a26e-edb7c0874bad/SSCIs-0001.pdf":Ketz and McCloskey (2021)}. 
The program uses the last estimation output and user-specified lists of nuisance parameters that are either bounded from below or from above.{p_end}


{marker options}{...}
{title:Options}

{synoptset 34 tabbed}{...}
{synopt :{opt below(varlist)}}list of variables whose coefficients are bounded from below{p_end}

{synopt :{opt above(varlist)}}list of variables whose coefficients are bounded from above{p_end}

{synopt :{opt alpha(real)}}level of significance; can only take 
values {cmd:.1}, {cmd:.05}, or {cmd:.01}; default is {cmd:.05}{p_end}

{synopt :{opt type(string)}}type of confidence interval; can take values 
{cmd:upper}, {cmd:lower}, or {cmd:two-sided}; default is {cmd:two-sided}{p_end}

{synopt :{opt bounds(var1=real var2=real ...)}}optional user-specified bounds for 
variables listed in {cmd:below()} or {cmd:above()}; for example, {cmd:bounds(X1=10 X2=-5)} specifies the bounds on the coefficients of X1 and X2 to be 10 and -5, respectively; default is 0 for all variables{p_end}

{hline}

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. reg price mpg rep78 headroom trunk weight length turn foreign}{p_end}

{pstd}Two-sided 95% confidence interval for {cmd:mpg} when {cmd:trunk} is 
bounded below by 0{p_end}
{phang2}{cmd:. ssci mpg, below(trunk)}{p_end}

{pstd}Lower one-sided 90% confidence interval for {cmd:mpg} when 
{cmd:trunk} and {cmd: rep78} are bounded below by 0, {cmd:weight} is bounded 
below by 4.01, and {cmd:turn} is bounded above by -10{p_end}
{phang2}{cmd:. ssci mpg, below(rep78 trunk weight) above(turn) bounds(turn=-10 weight=4.01) alpha(0.1) type(lower)} {p_end}


{marker stored_results}{...}
{title:Stored results}

{phang2}{cmd:ssci} stores the Short and Simple Confidence Interval (SSCI) in the matrix {cmd:e(SSCI)}{p_end}

{hline}

{marker references}{...}
{title:References}

{p 4 8}Ketz, P. and A. McCloskey (2021).
{browse "https://img1.wsimg.com/blobby/go/891816c3-956f-422c-a26e-edb7c0874bad/SSCIs-0001.pdf":Short and Simple Confidence Intervals when the Directions of Some Effects are Known}. 
{it:Working paper}.
{p_end}


{title:Authors}

{p 4 8}Chad Brown, Department of Economics, University of Colorado.
{browse "mailto:chad.brown@colorado.edu":chad.brown@colorado.edu}.{p_end}
{p 4 8}Philipp Ketz, Paris School of Economics, CNRS.
{browse "mailto:philipp.ketz@psemail.eu":philipp.ketz@psemail.eu}.{p_end}
{p 4 8}Adam McCloskey, Department of Economics, University of Colorado.
{browse "mailto:adam.mccloskey@colorado.edu":adam.mccloskey@colorado.edu}.{p_end}

