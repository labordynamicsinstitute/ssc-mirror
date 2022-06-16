{smcl}
{* *! version 1.0.2  Nicolai T. Borgen 15june2022}{...}
{cmd:help rqrplot}
{hline}

{title:Title}

{p2colset 5 16 19 20}{...}
{p2col :{hi:rqrplot} {hline 2}}Graphing quantile regression coefficients after RQR{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 13 2}
{cmd:rqrplot} [{cmd:, } {opth bopts(string)} {opth ciopts(string)} {opth twopts(string)} 
		{opt level(#)} {opth bootstrap(string)} {opt nodraw} {opt notabout}
		{opt noci}]

{marker options}{...}
{synoptset 27 tabbed}{...}
{synopthdr :options}
{synoptline}
{p2coldent : {opth bopts(string)}}allows for the customizing the display of the 
	coefficients. The default is solid line graph. See {it:twoway {help twoway##options:options}} 
	for other line options.{p_end}
{p2coldent : {opth ciopts(string)}}allows for customizing the confidence intervals.
	The default is area plot with opacity set at 40%. See {it:twoway {help twoway_options##options:options}} 
	for other options.{p_end}
{p2coldent : {opth twopts(string)}}allows for customizing the overall graph, including 
	title and labels. See {it:twoway_options {help twoway##options:options}} 
	for various options.{p_end}
{p2coldent : {opt level(#)}}decides the confidence level for the confidence intervals, 
	where # is any number between 10.00 and 99.99. The default is 95% confidence interval.{p_end}
{p2coldent : {opth bootstrap(string)}}requests normal-approximation bootstrap CIs 
	({cmd:bootstrap(normal)}), percentile bootstrap CI ({cmd:bootstrap(percentile)}), 
	or bias-corrected bootstrap CI ({cmd:bootstrap(bc)}). The default is 
	normal-approximation when {helpb rqr} is estimated with the {helpb bootstrap} 
	prefix.{p_end}
{p2coldent : {opt nodraw}}suppresses the display of the {cmd:twoway} plot.{p_end}
{p2coldent : {opt notabout}}suppresses the display of the result matrix.{p_end}
{p2coldent : {opt noci}}plots the coefficients without confidence intervals.{p_end}
{synoptline}
{p2colreset}{...}
{marker weights}{...}
{pstd}


{title:Description}

{pstd}
{cmd:rqrplot} is a {helpb rqr} postestimation command that effortless plots 
quantile regression coefficients and their confidence intervals. It visualizes 
the coefficients and the confidence intervals based on the current estimation 
results from the {helpb rqr} model. 

{pstd} 
The {helpb rqrplot} postestimation command only works after the {helpb rqr} 
command.

{pstd}
See {browse "https://osf.io/preprints/socarxiv/4vquh": Borgen, Haput, and Wiborg (2021b)}
for descriptions and examples of the {cmd:rqr} and {helpb rqrplot} commands. 


{title:Examples: Basic usage}

{pstd}
Setup{p_end}
{phang2}{cmd:. webuse nlswork}

{pstd}
Estimate treatment effects for quantiles 0.03 to 0.097 at steps of .02 using {helpb rqr}.{p_end}
{phang2}{cmd:. rqr ln_wage union, quantile(.03(.02).97) controls(year c.grade##c.grade south i.ind_code)}

{pstd}
Plot treatment coefficients using defaults. {p_end}
{phang2}{cmd:. rqrplot}


{title:Examples: Customize graph layout}

{pstd}
Change line pattern from solid to dash. {p_end}
{phang2}{cmd:. rqrplot, bopts(lpattern(dash))}

{pstd}
Change colors of line and CIs. {p_end}
{phang2}{cmd:. rqrplot, bopts(color(red)) ciopts(color(red%40))}

{pstd}
Change line plot to connected plot. {p_end}
{phang2}{cmd:. rqrplot, bopts(recast(connected))}

{pstd}
Change markers of connected plot. {p_end}
{phang2}{cmd:. rqrplot, bopts(recast(connected) msymbol(square) msize(vsmall))}

{pstd}
Change area CIs to line CIs. {p_end}
{phang2}{cmd:. rqrplot, ciopts(recast(rline))}

{pstd}
Change confidence level, here with 70% CIs. {p_end}
{phang2}{cmd:. rqrplot, level(70)}

{pstd}
Add overall title and change the default y-titles. {p_end}
{phang2}{cmd:. rqrplot, twopts(title(Union wage effects) ytitle(QTE))}

{pstd}
Remove grid lines. {p_end}
{phang2}{cmd:. rqrplot, twopts(ylabel(,nogrid) xlabel(,nogrid))}

{pstd}
Suppress the confidence intervals. {p_end}
{phang2}{cmd:. rqrplot, noci}

{pstd}
Names for graph are specified in {opt twopts(string)}. {p_end}
{phang2}{cmd:. rqrplot, twopts(name(union_effects, replace))}

{pstd}
Combine some of the different options mentioned above. {p_end}
{phang2}{cmd:. rqrplot, bopts(recast(connected) color(red) msymbol(oh)) ciopts(color(red%40)) twopts(title(Union wage effects) ytitle(QTE))}


{title:Examples: Bootstrapped confidence intervals}

{pstd}
To get bootstrapped CIs, we first need to run {cmd:rqr} with the {cmd:bootstrap} 
prefix. To save time, we will restrict the anlysis to 33-36-year-olds and only 
run 20 reps. {p_end}
{phang2}{cmd:. bootstrap, reps(20): rqr ln_wage union if inrange(age,33,35),, quantile(.03(.02).97) controls(year c.grade##c.grade south i.ind_code)}

{pstd}
When {cmd:rqr} is estimated using the {cmd:bootstrap} prefix, the default 
in {cmd:rqrplot} is to plot the normal-approximation CIs. {p_end}
{phang2}{cmd:. rqrplot}

{pstd}
To get percentile-based CIs:{p_end}
{phang2}{cmd:. rqrplot, bootstrap(percentile)}


{title:Stored results}

{cmd:rqr} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(plotmat)}}matrix containing quantile, coefficient, standard 
errors, and upper and lower confidence intervals{p_end}
{p2colreset}{...}


{title:Version requirements}

The {cmd:rqrplot} command requires Stata 12.0 or later. 


{title:Reference}

{p 4 8 2}
{browse "https://osf.io/preprints/socarxiv/42gcb/": Borgen, Haupt, and Wiborg (2021a)}
A New Framework for Estimation of Unconditional Quantile Treatment Effects: 
The Residualized Quantile Regression (RQR) Model. {it:SocArXiv}. 
doi:10.31235/osf.io/42gcb{p_end}

{p 4 8 2}
{browse "https://osf.io/preprints/socarxiv/4vquh": Borgen, Haupt, and Wiborg (2021b)}
Flexible and fast estimation of quantile treatment effects: The rqr and rqrplot
commands {it:SocArXiv}. doi:10.31235/osf.io/4vquh{p_end}


{title:Authors}

{p 4 4 2} Nicolai T. Borgen, University of Oslo{break}
n.t.borgen@isp.uio.no{p_end}

{p 4 4 2} Andreas Haupt, Karlsruhe Institute of Technology{break}
andreas.haupt@kit.edu{p_end}

{p 4 4 2} Øyvind Wiborg, University of Oslo{break}
o.n.wiborg@sosge.uio.no{p_end}

{p 4 4 2} 
Thanks for citing this software in one of the following ways:
{p_end}

{p 8 8 2}
{browse "https://osf.io/preprints/socarxiv/42gcb/": Borgen, NT., A. Haupt, and ØN. Wiborg (2021).}
A New Framework for Estimation of Unconditional Quantile Treatment Effects: 
The Residualized Quantile Regression (RQR) Model. {it:SocArXiv}. 
doi:10.31235/osf.io/42gcb{p_end}

{p 8 8 2}
{browse "https://osf.io/preprints/socarxiv/4vquh": Borgen, Haput, and Wiborg (2021b)}
Flexible and fast estimation of quantile treatment effects: The rqr and rqrplot
commands {it:SocArXiv}. doi:10.31235/osf.io/4vquh{p_end}


