{smcl}
{* *! version 1.0  5march2011}{...}
{cmd:help semipar}{right: ({browse "http://www.stata-journal.com/article.html?article=st0278":SJ12-4: st0278})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:semipar} {hline 2}}Robinson's semiparametric regression
estimator{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:semipar} {varlist} {ifin} {weight}{cmd:,} {opth nonpar(varname)}
[{it:options}]

{synoptset 23 tabbed}
{synopthdr}
{synoptline}
{p2coldent :* {opth nonpar(varname)}}specify variable that enters the model nonlinearly{p_end}
{synopt:{opth g:enerate(varname)}}generate nonparametric fit of the dependent variable{p_end}
{synopt:{opt nos:hift}}parametric residuals are not shifted. See the Remarks section at the end of the help file {p_end}
{synopt:{opth par:tial(varname)}}generate dependent variable partialled out from parametric fit (eventually rescaled) {p_end}
{synopt:{opt degree(#)}}specify degree of local weighted polynomial fit used in the kernel; default is {cmd:degree(1)} (see {helpb lpoly}){p_end}
{synopt:{opt trim(#)}}specify level of trimming for the probability distribution function of the variable entering the model nonlinearly; default is {cmd:trim(0)} (no trimming){p_end}
{synopt:{opt kernel(kernel)}}kernel function, where {it:kernel} can be {cmd:gaussian} (the default), {cmd:epanechnikov}, {cmd:epan2}, {cmd:biweight}, {cmd:cosine}, {cmd:parzen}, {cmd:rectangle}, or {cmd:triangle}{p_end}
{synopt:{opt nog:raph}}suppress graph of the nonparametric fit{p_end}
{synopt:{opt ci}}show confidence interval around the nonparametric fit{p_end}
{synopt:{opt level(#)}}specify level of confidence for inference; default is {cmd:level(95)}{p_end}
{synopt:{opt t:itle(string)}}specify title of graph for the nonparametric fit{p_end}
{synopt:{opt ytitle(string)}}specify label of y axis in graph of the nonparametric fit{p_end}
{synopt:{opt xtitle(string)}}specify label of x axis in graph of the nonparametric fit{p_end}
{synopt:{opt robust}}use sandwich variance formula to compute standard errors of the estimated parameters{p_end}
{synopt:{opth cluster(varname)}}compute clustered-corrected standard errors of the estimated parameters{p_end}
{synopt:{opt test(#)}}compute H{c a:}rdle and Mammen's (1993) specification
test{p_end}
{synopt:{opt nsim(#)}}specify number of bootstrap replicates to be done; default is {cmd:nsim(100)}{p_end}
{synopt:{opth weight_test(varname)}}allow user to weight the distance between nonparametric and parametric fits for the test; default is {cmd:weight_test(1/n)}{p_end}
{synoptline}
{p 4 6 2}* {opt nonpar(varname)} is required.{p_end}
{p 4 6 2}{cmd:aweight}s and {cmd:fweight}s are allowed; see {help weight}.
{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:semipar} estimates Robinson's (1988) double residual estimator and
estimates the nonlinear relation between the variable set in {cmd:nonpar()}
and the dependent variable.  The nonparametric estimator used is a Gaussian
kernel-weighted local polynomial fit.

{pstd}
In addition, the {cmd:test()} option allows the user to assess whether a
polynomial adjustment could be used to approximate the nonparametric fit.


{title:Options}

{phang}
{opth nonpar(varname)} specifies the variable that enters the model
nonlinearly.  {cmd:nonpar()} is required.

{phang}
{opth generate(varname)} generates the nonparametric fit of the dependent
variable.

{phang}
{opth partial(varname)} generates the dependent variable partialled out from
the parametric fit.

{phang}
{opt degree(#)} specifies the degree of the local weighted polynomial fit used
in the kernel.  The default is {cmd:degree(1)} (see {helpb lpoly}).

{phang}
{opt trim(#)} specifies the level of trimming for the probability distribution
function of the variable entering the model nonlinearly.  The default is
{cmd:trim(0)} (no trimming).

{phang}
{opt kernel(kernel)} specifies the kernel function.  The default is
{cmd:kernel(gaussian)}.  {it:kernel} can be one of the following:

{pmore}
{cmd:gaussian} specifies the Gaussian kernel function, the default.

{pmore}
{cmd:epanechnikov} specifies the Epanechnikov kernel function.

{pmore}
{cmd:epan2} specifies the alternative Epanechnikov kernel function.

{pmore}
{cmd:biweight} specifies the biweight kernel function.

{pmore}
{cmd:cosine} specifies the cosine trace kernel function.

{pmore}
{cmd:parzen} specifies the Parzen kernel function.

{pmore}
{cmd:rectangle} specifies the rectangle kernel function.

{pmore}
{cmd:triangle} specifies the triangle kernel function.

{phang}
{opt nograph} suppresses the graph of the nonparametric fit.

{phang}
{opt ci} shows the confidence interval around the nonparametric fit. See end note.

{phang}
{opt level(#)} specifies the level of confidence for inference.  The default
is {cmd:level(95)}.

{phang}
{opt title(string)} specifies the title of the graph for the nonparametric
fit.

{phang}
{opt ytitle(string)} specifies the title of the y axis in the graph of the
nonparametric fit.

{phang}
{opt xtitle(string)} specifies the title of the x axis in the graph of the
nonparametric fit.

{phang}
{opt robust} uses the sandwich variance formula to compute standard errors of
the estimated parameters.

{phang}
{opth cluster(varname)} computes cluster-corrected standard errors of the
estimated parameters.

{phang}
{opt test(#)} computes H{c a:}rdle and Mammen's (1993) specification test to
assess whether the nonparametric fit can be approximated by a parametric
adjustment of order {it:#}.  With the {cmd:cluster()} option specified,
bootstrap sample of clusters are drawn. The p-value is returned in e(p_HM).

{phang}
{opt nsim(#)} specifies the number of bootstrap replicates to be done to
perform inference on the test.  The default is {cmd:nsim(100)}.

{phang}
{opth weight_test(varname)} allows the user to weight the distance between the
nonparametric and parametric fits for the test.  The default is
{cmd:weight_test(1/n)}.


{title:Examples}
{phang2}{cmd:.} {bf:{stata "clear"}} // warning, this command removes data from memory {p_end}
{phang2}{cmd:.} {bf:{stata "use http://fmwww.bc.edu/ec-p/data/wooldridge/hprice3"}}{p_end}
{phang2}{cmd:.} {bf:{stata "semipar lprice ldist larea lland rooms bath age, nonpar(linst) xtitle(linst) ci"}}{p_end}

{pstd}Same as above but testing for the appropriateness of a polynomial
adjustment of order 2 for {cmd:linst}{p_end}
{phang2}{cmd:.} {bf:{stata "semipar lprice ldist larea lland rooms bath age, nonpar(linst) xtitle(linst) ci test(2)"}}{p_end}

{title:Remarks}

Note that once the parametric part has been estimated, the “parametric” residuals are recovered. 
They are then shifted by adding the average value of the predicted value of the parametric fit.
This transformation does not affect the shape  of the function but allows to have an idea of 
how the average value of the dependent variable (rather than the parametric residuals) changes
after a change in the variable entering the model non-parametrically. We believe this should lead 
results conceptually comparable to {helpb plreg} by Michael Lokshin and {helpb margins} and {helpb marginsplot}
after {helpb npregress series} (see the example below).

We would like to thank Anna Houstecka and Bernd Fitzenberger that signaled that when the “partial” option 
is used, these rescaled residuals are returned rather than the raw ones. To get the raw ones, 
one could either generate the prediction of the parametric part.  Then, removing  this prediction from the 
dependent variable, would lead to the raw "parametric" residuals. Alternatively, we added a “noshift” 
option to simplify this procedure. When the "noshift" option is used, the shift is not implemented 
anywhere, not even for the default graph. We believe this should lead results conceptually comparable 
to {helpb pspline} by Ben Jann and Roberto G. Gutierrez.

Example (please install plreg and pspline; npregress series is only available for Stata 16 and higher):

{phang2}{cmd:.} {bf:{stata "clear"}} // warning, this command removes data from memory {p_end}
{phang2}{cmd:.} {bf:{stata "set seed 1234"}}{p_end}
{phang2}{cmd:.} {bf:{stata "set obs 1000"}}{p_end}
{phang2}{cmd:.} {bf:{stata "drawnorm x1-x3 e"}}{p_end}
{phang2}{cmd:.} {bf:{stata "replace x2=x2+50"}}{p_end}
{phang2}{cmd:.} {bf:{stata "replace x1=x1+10"}}{p_end}
{phang2}{cmd:.} {bf:{stata "gen y=40+5*x1+x2+x3+x3^2+e"}}{p_end}

Without "noshift" option

{phang2}{cmd:.} {bf:{stata "semipar y x1 x2, nonpar(x3) gen(semiparfit) degree(4)"}}{p_end}
{phang2}{cmd:.} {bf:{stata "plreg y x1 x2, nlf(x3) gen(plregfit)"}}{p_end}
{phang2}{cmd:.} {bf:{stata "npregress series y x3, asis(x1 x2)"}} // For Stata 16 and above {p_end}
{phang2}{cmd:.} {bf:{stata "margins, at(x3=(-2.5(0.1)3.5)) nose post"}} // For Stata 16 and above {p_end}
{phang2}{cmd:.} {bf:{stata `"marginsplot, plotopts(msymbol(none)) addplot(line semiparfit plregfit x3, sort legend(rows(1) order(2 "npregress" 3 "semipar" 4 "plreg" ))) title(Predictive margins)"'}} // For Stata 16 and above {p_end}

With "noshift" option

{phang2}{cmd:.} {bf:{stata "semipar y x1 x2, nonpar(x3) noshift gen(semiparfit2) degree(4)"}}{p_end}
{phang2}{cmd:.} {bf:{stata "pspline y x3 x1 x2, noi gen(psplinefit) at(x3)"}}{p_end}
{phang2}{cmd:.} {bf:{stata `"line semiparfit2 psplinefit x3, sort legend(rows(1) order(1 "semipar" 2 "pspline" ))"'}}{p_end}



{title:References}

{phang}H{c a:}rdle, W., and E. Mammen.  1993.  Comparing nonparametric versus
parametric regression fits. {it:Annals of Statistics} 21: 1926-1947.

{phang} Jann, B., and R. Gutierrez. 2008. pspline: Stata module providing a penalized 
spline scatterplot smoother based on linear mixed model technology. Available from 
http://ideas.repec.org/c/boc/bocode/s456972.html.

{phang}Lokshin, M. 2006.  Difference-based semiparametric estimation of
partial linear regression models.
{it:The Stata Journal} 6(3): 377-383.

{phang}Robinson, P. M.  1988.  Root-n-consistent semiparametric regression.
{it:Econometrica} 56: 931-954.


{title:Authors}

{pstd}Nicolas Debarsy{p_end}
{pstd}CNRS, LEM UMR 9221, Université de Lilles{p_end}
{pstd}Building SH2, Office 104{p_end}
{pstd}F-59655 Villeneuve-d’Ascq, France{p_end}
{pstd}nicolas.debarsy@cnrs.fr{p_end}


{pstd}Vincenzo Verardi{p_end}
{pstd}University of Namur, FNRS{p_end}
{pstd}(Centre for Research in the Economics of Development){p_end}
{pstd}Namur, Belgium{p_end}
{pstd}vverardi@unamur.be{p_end}




{title:Note}
No correction for the degrees of freedom is implemented for the confidence intervals associated to the non-paramatric fit.

{title:Also see}

{manhelp npregress R} from Stata 16, {help plreg}  if installed, {help pspline} if installed

Article:  {it:Stata Journal}, volume 12, number 4: {browse "http://www.stata-journal.com/article.html?article=st0278":st0278}
