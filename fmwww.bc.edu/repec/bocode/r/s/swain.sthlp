{smcl}
{* 27 August 2020}{...}
{* 15 March 2013}{...}
{hline}
help for {cmd:swain}, {cmd:swaini}
{hline}

{title:Correct the SEM chi-square overidentification test in small sample sizes or complex models}

{title:Description}

{p}{cmd:swain} and {cmd:swaini} provide a suite of corrections to the chi-square overidentification 
test (i.e., likelihood ratio test of fit) for structural equation models whether with or without 
latent variables. The chi-square statistic is asymptotically correct; however, it does not behave as 
expected in small samples and/or when the model is complex (cf. Herzog, Boomsma, & Reinecke, 2007). 
In situations where the ratio of the sample size to the number of parameters estimated is relatively 
small, the chi-square test will tend to overreject correctly specified models. Applied researchers 
should thus use a statistic having a more appropriate Type 1 reject error rate to judge model fit 
in finite samples (Bastardoz & Antonakis, 2014, 2016). {p_end} 
{p} The module provides three corrections: (a) the Swain (1975) scaling factor (see Herzog & Boomsma, 
2009; Herzog, et al., 2007); (b) an empirical correction T(MLEC1) by Yuan, Tian, and Yanagihara (2015), 
and (c) the F-test, which can be thought of as the small sample correction to the chi-square test (McNeish, 
2020).{p_end}

Swain can be executed: 

1. after -sem- as a postestimation command by simply typing {cmd:swain}

2. or immediately (see {help immed}) as follows: {cmd:swaini #vars #df #N #chi} 

{title:Examples}

{p}Note, the examples below are from correctly specified models. They {it:should not} be rejected 
by the chi-square overidentification statistic (yet they are). As shown in the examples, -swain- 
and -swaini- appropriately correct the statistic, which, on the basis of all the corrections, 
becomes nonsignificant. In practice the true model is unknown; however, there is sufficient 
simulation evidence to show that on repeated sampling, Type 1 error will be held to approximately 
5% for true models. {p_end}

To run the commands, simply click on the relevant links.

{ul:1. Immediate version: -swaini-}
{p}Enter data in the following order: #vars #df #N #chi. Note, the example data for the
immediate version are based on the full structural equation model in the 3rd example below.
We will use the chi-square value to two decimal places only, as reported in the output of
the model; thus the minor difference in the -swaini- as compared to the -swain-
chi-square value is because of rounding error.{p_end}

{phang}{stata "swaini 22 208 50 265.71" : . swaini 22 208 50 265.71}

{ul:2. Postestimation for confirmatory factor analysis: -swain-}

{phang}{stata "use http://www.hec.unil.ch/jantonakis/swaindata.dta" : . use http://www.hec.unil.ch/jantonakis/swaindata.dta}

{phang}{stata "sem (X->x*)" : . sem (X->x*)}

{phang}{stata "swain" : . swain}

{ul:3. Postestimation for full structural equation model: -swain-}

{phang}{stata "use http://www.hec.unil.ch/jantonakis/swaindata.dta" : . use http://www.hec.unil.ch/jantonakis/swaindata.dta}

{phang}{stata "sem (X->x*) (X->m) (m->y), cov(e.m*e.y)" : . sem (X->x*) (X->m) (m->y), cov(e.m*e.y)}

{phang}{stata "swain" : . swain}


{dlgtab:Citation}

{cmd:swain} is not an official Stata command. Please cite it as: 

{phang}Antonakis, J., & Bastardoz, N. (2020) Swain: Stata module to correct the SEM
chi-square overidentification test in small sample sizes or complex models. 
http://econpapers.repec.org/software/bocbocode/s457617.htm

{title:Authors}

	John Antonakis, University of Lausanne, Switzerland
	john.antonakis@unil.ch
	
	Nicolas Bastardoz, University of Zurich, Switzerland
	nicolas.bastardoz@business.uzh.ch
	
{title:References and readings}

{p 0 4} Bastardoz, N., & Antonakis, J. (2014). Sample size requirement for unbiased 
estimation of structural equation models. A Monte Carlo study. Academy of Management 
Proceedings, 13405.{p_end}

{p 0 4} Bastardoz, N., & Antonakis, J. (2016). How should the fit of structural 
equation models be judged? Insights from Monte Carlo simulations. Academy of 
Management Proceedings, 12634.{p_end}

{p 0 4} Curran, P. J., Bollen, K. A., Paxton, P., Kirby, J., & Chen, F. N. (2002). 
The noncentral chi-square distribution in misspecified structural equation models: 
Finite sample results from a Monte Carlo simulation. Multivariate Behavioral Research, 
37(1), 1-36.{p_end}

{p 0 4} Herzog, W., & Boomsma, W. (2009). Small-sample robust estimators of 
noncentrality-based and incremental model fit. Structural Equation Modeling, 16(1), 1–27.{p_end}

{p 0 4} Herzog, W., Boomsma, W., & Reinecke, S. (2007). The model-size effect on traditional 
and modified tests of covariance structures. Structural Equation Modeling, 14(3), 361–90.{p_end}

{p 0 4} Jackson, D. L., Voth, J., & Frey, M. P. (2013). A Note on Sample Size and Solution 
Propriety for Confirmatory Factor Analytic Models. Structural Equation Modeling, 20(1), 86-97.
{p_end}

{p 0 4} McNeish, D. (2020). Should We Use F-Tests for Model Fit Instead of Chi-Square in 
Overidentified Structural Equation Models? Organizational Research Methods, 23(3), 487-510.{p_end}

{p 0 4} Swain, A. J. (1975). Analysis of parametric structures for variance matrices 
(doctoral thesis). University of Adelaide, Adelaide.{p_end}

{p 0 4} Yuan, K.-H., Tian, Y., & Yanagihara, H. (2015). Empirical correction to the likelihood ratio 
statistic for structural equation modeling with many variables. Psychometrika, 80(2), 379-405.{p_end}

{title:Saved results}	

{p}{cmd:swain} and {cmd:swaini} save the following results in {cmd:r()}:

{col 4}{cmd:r(swain_corr)}{col 18}Swain correction factor
{col 4}{cmd:r(swain_chi)}{col 18}Swain-corrected chi-square
{col 4}{cmd:r(swain_p)}{col 18}p-value of the Swain chi-square
{col 4}{cmd:r(f_test)}{col 18}F-test value
{col 4}{cmd:r(f_test_p)}{col 18}p-value of the F-test
{col 4}{cmd:r(yuan_chi)}{col 18}Yuan-Tian-Yanagihara corrected chi-square value
{col 4}{cmd:r(yuan_p)}{col 18}p-value of Yuan-Tian-Yanagihara empirically corrected chi-square

	
{title:Also see}

{p 0 19}Manual:  {hi:[R] sem}{p_end}
{p 0 19}On-line:  help for {help sem}{p_end}
