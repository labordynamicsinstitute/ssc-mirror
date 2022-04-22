{smcl}
{* *! version 3.1  13jul2015}{...}
{vieweralsosee "mvmeta" "mvmeta"}{...}
{vieweralsosee "Getting the data in" "mvmetademo_setup"}{...}
{viewerjumpto "Berkey data" "mvmetademo_run##Berkey"}{...}
{viewerjumpto "p53 data" "mvmetademo_run##p53"}{...}
{viewerjumpto "fsc data 1" "mvmetademo_run##fscfpama"}{...}
{viewerjumpto "fsc data 2" "mvmetademo_run##fscshape"}{...}
{viewerjumpto "References" "mvmetademo_run##refs"}{...}
{hline}
{cmd:Demonstration for the mvmeta package in Stata: running mvmeta}
{cmd:Ian White}
{hline}

{title:How to run this tutorial}

{p}You will need to install the mvmeta package and get the associated data and graph files.


{title:Installing mvmeta}

{p} Click the following command

{pstd}{stata "net from http://www.homepages.ucl.ac.uk/~rmjwiww/stata/"}

{p}then click on {cmd:meta}, then on {cmd:mvmeta}, then on {cmd:(click here to install)}. This installs the package.

{p}Now click on {cmd:(click here to return to the previous screen)} and {cmd:(click here to get)}. 
This installs the associated data and graph files.


{title:Getting the data in}{marker data}

{p}A separate {help mvmetademo_setup:demonstration} is available.


{title:Berkey data}{marker Berkey}

{p}Data from {help mvmetademo_run##Berkey98:Berkey et al (1998)}: treatment effects on 
two outcomes (probing depth, y1; attachment level, y2)
in periodontal disease. 
The within-trial variances and covariances were reported by the authors.

{pstd}{stata use berkey, clear}

{pstd}{stata l, noo sep(0)}

{p}Now we'll draw a bubble plot of the data. This is an option of {cmd:mvmeta}. 
We will use the {cmd:noestimate} option to avoid fitting the model yet:

{pstd}{stata mvmeta y V, noestimate bubble}

{p}We fit a bivariate meta-analysis:

{pstd}{stata mvmeta y V}

{p}The y1 results are very similar to those from univariate meta-analysis:

{pstd}{stata mvmeta y V, var(y1)}

{p}We compare the univariate {cmd:mvmeta} results with those from {cmd:metan}.

{pstd}{stata gen s1 = sqrt(V11)}

{pstd}{stata metan y1 s1}

{p}These differ because by default (1) {cmd:mvmeta} fits the random-effects model,
whereas {cmd:metan} fits the fixed-effect model;
(2) {cmd:mvmeta} uses REML, 
whereas {cmd:metan} uses the method of moments;
(3) {cmd:mvmeta}'s standard error allows for uncertainty in estimating tau.
To get exact agreement:

{pstd}{stata metan y1 s1, random}

{pstd}{stata mvmeta y V, var(y1) mm nouncertainv print(bscov)}

{p}Let's return to the bivariate setting and 
explore a meta-regression on year of publication.

{pstd}{stata mvmeta y V pubyear}

{p}There's no evidence that either outcome is associated with year of publication.



{title:p53 data}{marker p53}

{p}These data come from 6 observational studies in patients with squamous cell carcinoma of the oropharynx.
The presence of mutant p53 tumor suppressor gene is considered as a possible prognostic factor {help mvmetademo_run##Jackson++11:(Jackson et al, 2011)}.

{p}
The data are the estimated log hazard ratios (lnHR) 
for mutant vs. normal p53 gene for two outcomes,
overall survival (OS) and disease-free survival (DFS), 
together with their variances.

{pstd}{stata use p53, clear}

{pstd}{stata l, noo sep(0) abb(12)}

{p}Now we'll draw a bubble plot of the data. 
The data don't include the within-study correlations: 
we assume they are all 0.7.

{pstd}{stata mvmeta lnHR VlnHR, bubble noestimate wscorr(0.7)}

{p}Note that the OS results in studies without
DFS results are much larger than those in studies with DFS results. 
This suggests that the multivariate result for DFS may be substantially larger
than the univariate result - but also that we should be cautious of both results.

{p}Let's fit the univariate meta-analysis for DFS:

{pstd}{stata mvmeta lnHR VlnHR, var(lnHRdfs)}

{p}Let's compare with the multivariate meta-analysis. 

{pstd}{stata mvmeta lnHR VlnHR, wscorr(0.7)}

{p}Yes, the multivariate result for DFS is larger (lnHRdfs is less negative)
than the univariate result. It also has a larger between-studies variance,
and hence a larger standard error.

{p}Various post-estimation options can be called after a {cmd:mvmeta}
fit without re-fitting the model.
The {cmd:i2} option estimates a multivariate I-squared,
together with its confidence interval. 
It also gives a confidence interval for the between-studies correlation:

{pstd}{stata mvmeta, i2}

{p}The {cmd:eform} option shows the exponentiated coefficients - here hazard ratios:

{pstd}{stata mvmeta, eform}

{p}We can also see the full parameterisation of the model,
including the Cholesky decomposition of the variance terms 
which are usually hidden:

{pstd}{stata mvmeta, showall}

{p}Other post-estimation options include {cmd:t(#)} to specify
a t-distribution for inference.

{p}Above we assumed the unknown within-study correlations were all 0.7.
We can avoid this assumption by using Riley's alternative model {help mvmetademo_run##Riley++08:(Riley et al, 2008)}. 
Usually this converges quickly, 
but for these data on this occasion it can need more than 2000 iterations:

{pstd}{stata mvmeta lnHR VlnHR, wscorr(riley)}

{p}Adding the {cmd:difficult} option leads to convergence in a small number of iterations, 
but a warning is printed because the overall correlation is close to 1. 
It is better for these data not to rely on the alternative model.

{pstd}{stata mvmeta lnHR VlnHR, wscorr(riley) difficult}


{title:Fibrinogen Studies Collaboration 1}{marker fscfpama}
{title:Fully and partly adjusted associations}

{p}The original data are from 31 studies relating plasma levels of fibrinogen,
a blood clotting factor, to time to a coronary heart disease (CHD) event {help mvmetademo_run##FSC05:(Fibrinogen Studies Collaboration, 2005)}.
In this example, we assume a linear association between fibrinogen and CHD, 
and we wish to adjust for confounding. Some confounders are recorded in all studies, while 
others are recorded in only 14 studies.
We therefore estimate a partly adjusted coefficient (log hazard ratio) in all 31 studies, 
and a fully adjusted coefficient in the 14 studies.
We also estimate their (within-studies) correlation: in the paper we considered three methods,
but here we'll use the bootstrap method {help mvmetademo_run##FSC09:(Fibrinogen Studies Collaboration, 2009)}.

{pstd}{stata use fscfpama, clear}

{pstd}{stata l, noo}

{p}In the variable names, "fa" refers to fully adjusted estimates, and "pa" refers to partly adjusted estimates.
"corrb" is the correlation between fully and partly adjusted estimates, estimated by the bootstrap method.

{p}In order to do {cmd:mvmeta} we need to construct the variance-covariance matrices:

{pstd}{stata gen varfafa = sefa^2}

{pstd}{stata gen varpapa = sepa^2}

{pstd}{stata gen varfapa = corrb*sefa*sepa}

{p}The "standard" approach would be to analyse only the fully adjusted estimates:

{pstd}{stata mvmeta beta var, var(betafa)}

{p}Our new approach analyses the fully-adjusted estimates jointly with the partly-adjusted estimates
in order to gain precision:

{pstd}{stata mvmeta beta var}

{p}The standard error for betafa has decreased from 0.0389 to 0.0266 or 32%.
This represents a 53% decrease in variance.
Note the between-studies correlation is estimated as 1, so that the model is able to infer 
fully-adjusted estimates quite precisely from partly-adjusted estimates.

{p}The {cmd:wt} option estimates the borrowing of strength 
- the degree to which results for one outcome gain precision
by the inclusion of the other outcome(s) in the analysis.

{pstd}{stata mvmeta, wt}

{p}The output shows a 53.3% borrowing of strength for the fully adjusted result (using the column headed "Overall: betafa"). 

{p}The output also shows the relative contributions of the studies to the fully-adjusted result:
for example, study 12 makes the largest contribution (9.8% of the total weight).
A large study which is only partly adjusted may contribute more weight 
than a small study which is fully adjusted.
For example, study 28 which is only partly adjusted contributes more weight (5.7% of the total weight) 
than study 1 which is fully adjusted (0.5% of the total weight).
This is because study 28 is much more precise:

{pstd}{stata l cohort sepa if inlist(cohort,1,28)}



{title:Fibrinogen Studies Collaboration 2}{marker fscshape}
{title:Shape of exposure-outcome relationship}

{p}We now use the same original data to explore the shape of association
between fibrinogen and CHD, adjusting for complete confounders.
Each study has been analysed using a Cox model including fibrinogen
categorised into 5 groups and adjusting for confounders.
The "outcomes" of interest are therefore the 4 contrasts (log hazard ratios) of groups 
2-5 with group 1.
Some studies (e.g. study 15) 
have no participants or no events in group 1:
these have been handled by introducing ("augmenting") a very small amount of 
data in group 1.
{cmd:mvmeta_make} has been used to automate the augmentation, fitting of the Cox models 
and extraction of the point estimates, variances and covariances {help mvmetademo_run##White09:(White, 2009)}.

{pstd}{stata use fscstage1, clear}

{pstd}{stata browse}

{pstd}{stata mvmeta b V}

{pstd}{stata estimates store fsc2full}

{p}That was a little slow. 
We'll demonstrate some faster alternatives.
First and probably best, the method of moments. The original version is by {help mvmetademo_run##Jackson++10:Jackson et al (2010)}:

{pstd}{stata mvmeta b V, mm}

{p}and a matrix-based method of moments is by {help mvmetademo_run##Jackson++13:Jackson et al (2013)}:

{pstd}{stata mvmeta b V, mm2}

{p}The fixed-effect method (not recommended, because it ignores heterogeneity):

{pstd}{stata mvmeta b V, fixed}

{p}We could also assume that the between-studies variation 
is captured by a random slope:

{pstd}{stata matrix B = (1,2,3,4)'*(1,2,3,4)}

{pstd}{stata mvmeta b V, bscov(prop B)}

{pstd}{stata lrtest fsc2full}

{p}Not significantly worse, 
but I'd prefer to use the full model:

{pstd}{stata estimates replay fsc2full}

{p}Finally, here's a graph I made earlier:

{pstd}{stata graph use fsc2cigraph}



{title:References}{marker refs}

{phang}{marker Berkey98}Berkey CS, Hoaglin DC, Antczak-Bouckoms A, Mosteller F, Colditz GA (1998). 
Meta-analysis of multiple outcomes by regression with random effects. 
Statistics in Medicine 17: 2537-2550.
{browse  "https://onlinelibrary.wiley.com/doi/10.1002/(SICI)1097-0258(19981130)17:22%3C2537::AID-SIM953%3E3.0.CO;2-C":Link.}

{phang}{marker Jackson++10}Jackson D, White IR, Thompson SG (2010). 
Extending DerSimonian and Laird's methodology to perform multivariate random effects meta-analyses. 
Statistics in Medicine 29: 1282-1297.
{browse "http://onlinelibrary.wiley.com/doi/10.1002/sim.3602/abstract":Link.}

{phang}{marker Jackson++11}Jackson D, Riley R, White IR (2011). 
Multivariate meta-analysis: potential and promise. 
Statistics in Medicine 30: 2481-2498.
{browse "http://onlinelibrary.wiley.com/doi/10.1002/sim.4172/abstract":Link.}

{phang}{marker Jackson++13}Jackson D, White IR, Riley R (2013). 
A matrix based method of moments for fitting the random effects model 
    for meta-analysis and meta-regression. 
Biometrical Journal 55: 231-245.
{browse "http://onlinelibrary.wiley.com/doi/10.1002/bimj.201200152/abstract":Link.}

{phang}{marker FSC05}Fibrinogen Studies Collaboration (2005). 
Plasma fibrinogen and the risk of major cardiovascular diseases and non-vascular mortality: meta-analysis of individual data for 154 211 adults in 31 prospective studies. 
Journal of the American Medical Association 294: 1799-1809.
{browse "http://jama.jamanetwork.com/article.aspx?doi=10.1001/jama.294.14.1799":Link.}

{phang}{marker FSC09}Fibrinogen Studies Collaboration (2009). 
Systematically missing confounders in individual participant data meta-analysis of observational cohort studies. 
Statistics in Medicine 28: 1218-1237. 
Writing committee: Jackson D, White IR.
{browse "https://onlinelibrary.wiley.com/doi/10.1002/sim.3540":Link.}

{phang}{marker Riley++08}Riley RD, Thompson JR, Abrams KR (2008). 
An alternative model for bivariate random-effects meta-analysis when the within-study correlations are unknown. 
Biostatistics 9: 172-186.
{browse "http://biostatistics.oxfordjournals.org/content/9/1/172.short":Link.}

{phang}{marker White09}White IR (2009). 
Multivariate random-effects meta-analysis. 
Stata Journal 9: 40-56.
{browse "http://www.stata-journal.com/article.html?article=st0156":Link.}


