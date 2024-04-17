{smcl}
{* *! version 1.0.0  15apr2024}{...}

{title:Title}

{p2colset 5 13 14 2}{...}
{p2col:{hi:usos} {hline 2}} Unweighted sum of squares test for global goodness of fit after logistic model {p_end}
{p2colreset}{...}



{marker syntax}{...}
{title:Syntax}

{p 8 19 2}
		{cmd:usos}

{phang}
{opt weights} are not allowed.



{title:Description}

{pstd}
{cmd:usos} implements the unweighted sum of squares (USOS) test for global goodness of fit (GOF) following the estimation of a logistic/logit 
model. This method has been attributed to Copas (1989) and le Cessie and van Houwelingen (1995). Hosmer et al. (1997) report that this 
method (in addition to the Pearson chi-square method which is available in official Stata ({help logistic estat gof}) offers superior power 
based on simulations. As such, they recommend the use of these two GOF approaches for confirmation of model fit or lack-of-fit.

{pstd}
{cmd:usos} is based on Frank Harrell's residuals.lrm {rms} package in R ({browse "https://cran.r-project.org/web/packages/rms/rms.pdf"}).



{title:Examples}

{pstd}Set up{p_end}
{p 4 8 2}{stata "webuse lbw, clear":. webuse lbw, clear}{p_end}

{pstd}Fit logistic regression to predict low birth weight{p_end}
{p 4 8 2}{stata "logistic low age lwt i.race smoke ptl ht ui":. logistic low age lwt i.race smoke ptl ht ui}{p_end}

{pstd}Perform USOS goodness-of-fit test{p_end}
{p 4 8 2}{stata "usos":. usos}{p_end}



{title:Saved results}

{pstd}{cmd:usos} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(sse)}}unweighted sum of squared errors {p_end}
{synopt:{cmd:r(ev)}}expected value (H0) {p_end}
{synopt:{cmd:r(estimate)}}sse - ev {p_end}
{synopt:{cmd:r(sd)}}std. dev. of the estimate {p_end}
{synopt:{cmd:r(z)}}{it:z} value{p_end}
{synopt:{cmd:r(p)}}{it:p} value{p_end}



{p2colreset}{...}

{title:References}

{phang}
Copas, J. B. 1989. Unweighted sum of squares test for proportions. {it:Journal of the Royal Statistical Society: Series C (Applied Statistics)} 38: 71-80.

{phang}
Hosmer, D. W., Hosmer, T., Le Cessie, S. and S. Lemeshow. 1997. A comparison of goodness‐of‐fit tests for the logistic regression model. 
{it:Statistics in Medicine} 16: 965-980.
 
{phang}
Le Cessie, S. and H. C. Van Houwelingen. 1995. Testing the fit of a regression model via score tests in random effects models. {it:Biometrics} 51: 600-614.



{title:Citation of {cmd:usos}}

{p 4 8 2}{cmd:usos} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2024. usos: Stata module for computing the unweighted sum of squares test for global goodness of fit after logistic model.
{p_end}



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Acknowledgments}

{p 4 4 2}
I wish to thank John Moran for advocating that I write this package.


        
{title:Also see}

{p 4 8 2}Online: {helpb logistic estat gof}{p_end}
