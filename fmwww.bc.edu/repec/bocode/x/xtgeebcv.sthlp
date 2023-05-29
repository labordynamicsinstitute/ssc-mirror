{smcl}
{* *! version 5.2.0 23May2023}
{cmd:help xtgeebcv}
{hline}

{title:Title}

{p2colset 5 17 17 5}{...}
{p2col :{hi:xtgeebcv} {hline 2}}Computes bias-corrected (small-sample) standard errors for generalized estimating equations

{marker syntax}{...}
{title:Syntax}


{p 8 17 5}
{cmd:xtgeebcv} {it:{help varlist}}{cmd:, } {cmd:cluster(}{it:varname}) [{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{cmd:cluster(}{it:varname})}Specify the name of the variable indicating the clusters{p_end}

{syntab:Optional}
{synopt :{cmd:family(}{it:string})}Specifies the distribution family; default is binomial{p_end}
{synopt :{cmd:link(}{it:string)}}Specifies the link function; the default depends on the specification of {cmd:family}.  The 
default for Gaussian, binomial, and Poisson are identity, logit, and log, respectively.  See table below for 
combinations of family and link allowed.{p_end}
{synopt :{cmd:stderr(}{it:string})}Standard error to compute; default is Kauermann-Carroll (kc).  See table below for full list of bias-corrected standard errors available.{p_end}
{synopt :{cmd:statistic(}{it:string)}}Specifies the test. Specifying "statistic(t)" requests the Wald t-test (the default).  Alternatively, the user may specify "statistic(z)" to report 
the Wald z-test instead of the Wald t-test.{p_end}
{synopt :{cmd:dfmethod(}{it:string)}}Specifies the computation of the degrees of freedom. More information provided in the explanations seciton below.{p_end}
{synopt :{cmd:dfspec(}{it:integer)}}Only specified for "dfmethod(specify)". More information provided in the explanations section below.{p_end}
{synopt :{cmd:corr(}{it:string)}}Specifies the type for the working correlation; default is exchangeable (exch). Independence (ind) may also be specified{p_end}

{phang}
{it:{help varlist}} contains the regression specification: the dependent variable (outcome) followed by independent variables (predictors).  The list of independent variables
can include factor variables (specified using "i.") and interactions.
{p_end}

{phang}
Any other options will be passed to {help xtgee}  within the program. For example, the option eform will 
provide exponentiated coefficients.  See the Stata helpfile for {help xtgee} for additional options available.  
Note that invoking {help xtset} is not necessary, as
{cmd:xtgeebcv} will automatically run {help xtset} based on the cluster variable supplied
by the user.
{p_end}

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{hi: Updates as of May 23, 2023}: {cmd:xtgeebcv} was now allows for additional degrees of freedom adjustments for the t-statistic, with the default being the number of clusters minus the number of cluster-level covariates (including the intercept). 

{pstd}
{hi: Updates as of December 03, 2021}: {cmd:xtgeebcv} was not allowing for intercept-only models.  The code has now been updated to permit the use of intercept-only models.

{pstd}
{hi: Updates as of April 05, 2021}: The MBN correction was missing a constant from the trace in the computation of phi that is listed in {help xtgeebcv##KC2001:Morel et al. (2003)}, but not listed
in {help xtgeebcv##LR2015:Li and Redden (2015)} (which is what we based our formulae on).  This constant has been added, but this should make very little difference to the output standard errors.

{pstd}
{hi: Updates as of August 25, 2020}: {cmd:xtgeebcv} was not taking into account offset terms in the computations.  This has been fixed, and version 4.0 of {cmd:xtgeebcv} will now
output the correct standard errors when an offset term is specified.

{pstd}
{hi: Updates as of August 17, 2020}: It has been noted that this command now throws an error when using with Stata version 15 because of some of the functionality
added.  Therefore, this version of the program will only allow use by researchers using Stata version 16.1 or later.  
{cmd:If you are using Stata version 15, please install the Stata Journal (package sj0599)}, which still works on version 15, but does not allow for factor variables and their interactions.  Note that
the Stata Journal package will likely be updated to match this version (published on SSC) after the release of Stata 17.

{pstd}
{hi:Updates as of March 4, 2020:} {cmd:xtgeebcv} now allows for the use of factor variables and interactions in {it:varlist}.  This will also allow for
the use of some postestimation commands (such as {help margins}) that were not possible before.  Additionally, the {cmd:outcome} option
has now been removed from the program.  Note that the use of orphan interactions of factor variable (i.e., an interaction between two factor variables but
one or both of the "main effects" is not included in the model) will cause the program to throw a "conformability error".  In this case, use dummy coding.

{pstd}
{cmd:xtgeebcv} computes bias-corrected standard errors for generalized estimating equations (GEEs), specifically 
for cluster-randomized trials (CRTs).  It is well-known
that below approximately 40 total clusters, GEE robust standard error estimates (as well as standard error
estimates from mixed models) will almost certainly be biased.  Given that CRTs are commonly performed in resource-limited
areas, it is common for only a small number of clusters to be randomized.

{pstd}
In this case, the type I error for time invariant covariates (such as treatment indicator) are inflated, 
leading to incorrect conclusions about "statistical significance".  Although several small sample bias-correction methods have
been around for 15 or more years, such methods have not yet been implemented in Stata until now.

{pstd}
This program allows the user to obtain bias-corrected standard errors when using GEE to estimate effects in the presence
of clustering.  Although this program was motivated by CRTs, this program can be used for GEE analyses of any type of
clustered data.  The types of corrections allowed (along with references) can be found in the tables below.  For more information, 
see {help xtgeebcv##LR2015:Li and Redden (2015)} or {help xtgeebcv##GLT2020:Gallis et al. (2020)}.

{marker options}{...}
{title:Options Explanations}

{phang}
The following options are available for {cmd:family} and {cmd:link}.

{center:Family     Link    }
{center:{hline 20}}
{center:binomial   logit   }
{center:binomial   log     }
{center:binomial   identity}
{center:poisson    log     }
{center:poisson    identity}
{center:gaussian   identity}
{center:{hline 20}}

{pstd}
For bias-corrected standard errors, the following options are available in {cmd:stderr}.  Note that the robust standard 
errors (SEs) provided by {cmd:xtgeebcv} will differ from Stata's default robust standard errors by a factor of 
sqrt((K-1)/K), where K is the number of clusters.  This is because Stata automatically applies a correction of sqrt(K/(K-1)) to 
the robust standard errors produced by {cmd:xtgee} when using the {cmd:vce(robust)} option.  
We do not follow this Stata-specific convention of applying
this correction in this program for the following reasons: (1) the robust sandwich variance of 
{help xtgeebcv##LZ1986:Liang and Zeger (1986)} does not involve this correction; (2) this robust variance of 
{help xtgeebcv##LZ1986:Liang and Zeger (1986)} is the one upon which the 
literature on bias-corrected sandwich variances is built; (3) other 
statistical software programs do not apply this sqrt(K/(K-1)) correction to their robust standard errors.  
Thus, all the bias-corrected standard errors we implement in this program are based on the robust standard error 
without the sqrt(K/(K-1)) correction.


{center:Options    Description                                          }
{center:{hline 65}}
{center:rb         Robust (sandwich) SEs                             }                
{center:df         Degrees-of-freedom correction                     }
{center:md         Bias-corrected SEs of {help xtgeebcv##MD2001:Mancl and DeRouen (2001)}    }
{center:fg         Bias-corrected SEs of {help xtgeebcv##FG2001:Fay and Graubard (2001)}     }
{center:kc         Bias-corrected SEs of {help xtgeebcv##KC2001:Kauermann and Carroll (2001)}}
{center:mbn        Bias-corrected SEs of {help xtgeebcv##KC2001:Morel et al. (2003)}         }
{center:{hline 65}}

{pstd}
The degrees-of-freedom correction is computed by multiplying the (uncorrected) robust standard
error by K/(K-p), where K is the number of clusters and p is the number of regression parameters.
More detailed information on the other corrections can be found in 
{help xtgeebcv##LR2015:Li and Redden (2015)} or {help xtgeebcv##GLT2020:Gallis et al. (2020)}.

{pstd}
The following options are available for the dfmethod option. The default option is "cluster". In all cases,
degrees of freedom for the t-test is defined by the number of clusters minus the option specified below:

{center:Options    Description                                                                            }
{center:{hline 100}}
{center:cluster    Subtract the number of cluster-level covariates plus the intercept                     }                
{center:all        Subtract the number of covariates plus the intercept                                   }
{center:specify    Subtract the number specified by the user through the dfspec() option. Default is 0    }
{center:{hline 100}}


{marker example}{...}
{title:Example}

{pstd}The example uses data referred to in {help xtgeebcv##H2009:Hayes & Moulton (2009)}.
The goal of the trial was to evaluate the impact of a sexual health intervention on various HIV-related
outcomes.  The data available for download include male participants at follow-up.  The main
outcome is "good knowledge of HIV aquisition", a binary variable.  In this dataset, 20 communities
were randomized to either receive intervention or "standard activities".  Below, we demonstrate
the application of the Kauermann-Carroll corrected standard errors in GEE modeling of the
binary outcome.

	Open data set
{phang2}{cmd:. ssc describe xtgeebcv}{p_end}
{phang2}{cmd:. net install xtgeebcv}{p_end}
{phang2}{cmd:. net get xtgeebcv}{p_end}
{phang2}{cmd:. use mkvtrial.dta}{p_end}
	
	Run xtgeebcv, obtaining odds ratio estimates and Kauermann-Carroll standard errors
{phang2}{cmd:. xtgeebcv know i.arm i.stratum i.ethnicgp, family(binomial) link(logit) cluster(community) stderr(kc) eform nolog}{p_end}

	For illustration, subset the dataset to stratum 2 and re-run
{phang2}{cmd:. keep if stratum == 2}{p_end}
{phang2}{cmd:. xtgeebcv know i.arm i.ethnicgp, family(binomial) link(logit) cluster(community) stderr(kc) eform nolog}{p_end}

	Also, run the model to obtain the robust standard errors for comparison
{phang2}{cmd:. xtgeebcv know i.arm i.ethnicgp, family(binomial) link(logit) cluster(community) stderr(rb) eform nolog}{p_end}


{marker reference}{...}
{title:References}

{marker MD2001}{...}
{phang}
Mancl, L. A., & DeRouen, T. A. (2001). A covariance estimator for GEE with improved 
small-sample properties. {it:Biometrics}, 57(1), 126-134
{p_end}

{marker FG2001}{...}
{phang}
Fay, M. P., & Graubard, B. I. (2001). Small-Sample Adjustments for Wald-Type Tests 
Using Sandwich Estimators. {it:Biometrics}, 57(4), 1198-1206. 
{p_end}

{marker kc2001}{...}
{phang}
Kauermann, G., & Carroll, R. J. (2001). A note on the efficiency of sandwich 
covariance matrix estimation. 
{it:Journal of the American Statistical Association}, 96(456), 1387-1396. 
{p_end}

{marker MBN2003}{...}
{phang}
Morel, J., Bokossa, M., & Neerchal, N. (2003). Small sample correction for the 
variance of GEE estimators. {it:Biometrical journal}, 45(4), 395-409. 
{p_end}

{marker LZ1986}{...}
{phang}
Liang, K. Y., & Zeger, S. L. (1986). Longitudinal data analysis using generalized 
linear models. {it:Biometrika}, 73(1), 13-22. 
{p_end}

{marker GLT2020}{...}
{phang}
Gallis, J. A., Li, F., & Turner, E. L. (2020). 
xtgeebcv: A command for bias-corrected
sandwich variance estimation for GEE analyses
of cluster randomized trials. {it:Stata Journal}, 20(2), 363-381.
{p_end}

{marker LR2015}{...}
{phang}
Li, P., & Redden, D. T. (2015). Small sample performance of bias-corrected sandwich 	
estimators for cluster-randomized trials with binary outcomes. 
{it:Statistics in Medicine}, 34(2), 281-296. 
{p_end}

{marker H2009}{...}
{phang}
Hayes, R. J., & Moulton, L. H. (2009). 
{it:Cluster randomised trials}. Boca Raton: CRC Press. 
{p_end}


{marker author}{...}
{title:Authors}
 John A. Gallis
 Duke University Department of Biostatistics and Bioinformatics
 Duke Global Health Institute
 Durham, NC
 john.gallis@duke.edu
  
 Fan Li
 Yale School of Public Health
 New Haven, CT
 fan.f.li@yale.edu
 
 Elizabeth L. Turner
 Duke University Department of Biostatistics and Bioinformatics
 Duke Global Health Institute
 Durham, NC
 liz.turner@duke.edu
 
{marker acknowledgements}{...}
{title:Acknowledgements}
The authors of this program would like to thank Dr. Andrew Forbes of Monash University for his help in discovering the issue with
the standard error calculation when specifying an offset term and help in suggesting corrections to the program to take into account the offset term.

