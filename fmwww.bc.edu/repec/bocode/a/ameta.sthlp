{smcl}
{**!version 10.0 | 10 march 2021}
{viewerjumpto "Options" "ameta##method_options"}{...}
{viewerjumpto "References" "ameta##refs"}{...}

{hline}
help for {bf}ameta
{hline}

{title:Title}

{phang}
{hi:ameta} {hline 2} Alternative and Bayesian meta-analysis
	
	
{marker syntax}{...}
{title:Syntax}

{pstd}
{cmd:ameta} has the following syntax:

{p 8 18 2}
{cmd:ameta} varname1 varname2 [varname3] {ifin}, {it:{help ameta##method_options:method}}{hi:(}{it:string}{hi:)} [{opt study(string)}] [{opt , a(real 0)} {opt b(real 2)} {opt l(real 95)}] [{opt by(string)}] [{cmd:graph}] [{cmd:eform}]


	where:
		varname1 is the study effect size
		varname2 is the study standard error
		varname3 is the number of participants 
			 
		     
		
{marker options}{...}
{synoptset 24 tabbed}{...}
{synopthdr :options}
{synoptline}
{synopt :{it:{help ameta##method_options:method}}{cmd:(}{it:string}{cmd:)}} Specify the method to conduct the meta-analysis. Choose one of the dl,dl2,hm,he,sj,sj2,ca2,pm,abi,gllamm,metareg {p_end}
{synopt :{cmd:study(}{it:string}{cmd:)}} Defines labels for the studies. If this option is omitted, ameta uses numbers as studies' names {p_end}
{synopt :{cmd:a(}{it:real 0}{cmd:)}} Shape parameter of inverse gamma distribution. The default value is zero {p_end}
{synopt :{cmd:b(}{it:real 2}{cmd:)}} Scale parameter of inverse gamma distribution. The default value is two {p_end}
{synopt :{cmd:l(}{it:real 95}{cmd:)}} Confidence level. The default level is 95%. The available confidence levels are 80%, 85%, 90%, 95%, 98%, 99%, 99.5%, 99.9% {p_end}
{synopt :{cmd:by(}{it:string}{cmd:)}} Subgroup meta-analysis {p_end}
{synopt :{cmd:graph}} Forest plot. Only one graph output is allowed in each execution. Graph output is not allowed in the subgroup meta-analysis {p_end}
{synopt :{cmd:eform}} Requests the results of the meta-analysis to be displayed in exponential form {p_end}
	

{marker description}{...}
{title:Description}

{pstd}
{cmd:ameta} offers a choice of two meta-analysis approaches, an alternative and a bayesian. On the one hand, the alternative method consists of eight different heterogeneity estimators
for the calculation of the pooled intervention effect, its std. error and CI, the between-studies variance tau-squared, as well as other heterogeneity measures under a 
random-effects model and with the assumption that the pooled intervention effect is following a normal distribution. On the other hand, the bayesian method offers three
Bayesian meta-analysis models for calculating parameters such as the posterior variance and expected value of mu and posterior variance and expected value of tau-squared
of the unknown population parameter theta along with its credible interval. All three models are of the random-effects family so they take into account both the within 
and between study variation and estimate it. Moreover, since a Bayesian inference is used, we also assign prior probability distribution to the parameter theta and 
specifically an inverse gamma prior distribution with parameters a and b which are also known as shape and scale parameters of the distribution.



{marker options}{...}
{title:Options}

{marker method_options}{...}
{dlgtab:method_options}

{synoptset 24 tabbed}{...}
{synopt :{cmd:dl}} DerSimonian-Laird estimator {help ameta##refs:(DerSimonian & Laird 1986)} {p_end}
{synopt :{cmd:dl2}} Two-step DerSimonian-Laird estimator {help ameta##refs:(DerSimonian & Kacker 2007)} {p_end}
{synopt :{cmd:hm}} Hartung and Makambi estimator {help ameta##refs:(Hartung & Makambi 2003)} {p_end}
{synopt :{cmd:he}} Hedges aka Cochran ANOVA aka variance component estimator {help ameta##refs:(Cochran 1954; Hedges 1986; Hedges & Olkin 1985)} {p_end}
{synopt :{cmd:sj}} Sidik and Jonkman estimator {help ameta##refs:(Sidik & Jonkman 2005, 2007)} {p_end}
{synopt :{cmd:sj2}} Sidik and Jonkman 2 estimator {help ameta##refs:(Sidik & Jonkman 2005, 2007)} {p_end}
{synopt :{cmd:ca2}} Two-step Cochran ANOVA estimator {help ameta##refs:(DerSimonian & Kacker 2007)} {p_end}
{synopt :{cmd:pm}} Paule and Mandel aka empirical Bayes estimator {help ameta##refs:(Paule &  Mandel 1989)} {p_end}
{synopt :{cmd:abi}} Approximation method  {help ameta##refs:(Abrams & Sans{c o'} 1998)} {p_end}
{synopt :{cmd:gllamm}} GLLAMMs method {help ameta##refs:(Chung, Rabe-Hesketh & Choi 2013)} {p_end}
{synopt :{cmd:metareg}} Meta - regression method {help ameta##refs:(Rhodes et al 2016)} {p_end}



{marker remarks}{...}
{title:Remarks}

{pstd}
For a more detailed description of the methods see also {help ameta##refs:Langan et al (2019)} and {help ameta##refs:Thorlund et al (2011)} for the alternative meta-analysis.{p_end}
{pstd}Special attention should be paid in the approximation method when the number of studies is equal or less than five. In this case the shape parameter(a) must be bigger than two.{p_end}
{pstd}No empty cells should be present in the dataset. {p_end}
{pstd}Regarding the bayesian approach,the syntax that uses three variables (the effect size,the standard error and the number of participants) calls for the approximation method, while the 
syntax with the two variables(the effect size and the standard error) calls for either the GLLAMM or the meta-regression method, depending which one is 
specified in the method() option. {p_end}
{pstd}Attention should also be paid when using the gllamm method because the value of the shape parameter is set to 2 and the value of the scale parameter is close to 0. This model has 
been proved to be the optimal {help ameta##refs:(Chung, Rabe-Hesketh, Dorie, et al 2013)}.{p_end}
{pstd}In order to run the gllamm and the metareg method someone should install the following:{p_end}
{pstd}. For the gllamm method{p_end}
{pstd}	ssc install gllamm{p_end}
{pstd}	download init_prior.ado and calc_prior.ado{p_end}
{pstd}	copy these files into your working directory (or anywhere in adopath){p_end}
{pstd}. For the metareg method{p_end}
{pstd}	ssc install metareg{p_end}
{pstd}Moreover, for the graph option the metagraph command needs to be installed as follows:{p_end}
{pstd}ssc install metagraph{p_end}



{marker saved_results}{...}
{title:Saved results}

{pstd}{cmd:ameta} saves the following in {cmd:r()}:{p_end}
{pstd}(with some variation, according to which method is being used){p_end}

{synoptset 25 tabbed}{...}
{p2col 5 20 24 2: Scalars} {p_end}
{synopt:{cmd:r(numberofstudies)}} Number of studies included in the meta-analysis {p_end}
{synopt:{cmd:r(Qtest)}} Cochran's Q  test of homogeneity {p_end}
{synopt:{cmd:r(Tausquared)}} Between-studies variance tau-squared {p_end}
{synopt:{cmd:r(m)}} Pooled intervention effect mu {p_end}
{synopt:{cmd:r(se)}} Standard error of pooled intervention effect mu {p_end}
{synopt:{cmd:r(Isquare)}} Heterogeneity measure I-square {p_end}
{synopt:{cmd:r(Dsquare)}} Heterogeneity measure D-square {p_end}
{synopt:{cmd:r(em)}} Posterior expectation of the population parameter mu {p_end}
{synopt:{cmd:r(vm)}} Posterior variance of the population parameter mu {p_end}
{synopt:{cmd:r(et2)}} Posterior expectation of the between study variability tau-squared {p_end}
{synopt:{cmd:r(vt2)}} Posterior variance of the between study variability tau-squared {p_end}
{synopt:{cmd:r(ConfIntervalLow)}} Lower Confidence Interval for mu. In the alternative meta-analysis the confidence level is 95% {p_end}
{synopt:{cmd:r(ConfIntervalUp)}} Upper Confidence Interval for mu. In the alternative meta-analysis the confidence level is 95%{p_end}
{synopt:{cmd:r(z)}} Z-score {p_end}
{synopt:{cmd:r(pvalue)}} P-value for pooled intervention effect {p_end}

{pstd}The posterior variance of the between study variability tau-squared is not returned in the GLLAMM and meta-regression methods{p_end}



{marker examples}{...}
{title:Examples}

{pstd}
All examples use a simulated example dataset (Ross Harris 2006) originally prepared for metan9. {p_end} 
{pmore}
{stata "use http://fmwww.bc.edu/repec/bocode/m/metan_example_data, clear":. use http://fmwww.bc.edu/repec/bocode/m/metan_example_data, clear}

{pstd} The Risk Ratio is also used as effect size, given by the user as logrr and its standard error as se. n is the number of patients in each study, where pop1
and pop0 are the number of patients in the treatment and control groups, respectively. {p_end}

{cmd}{...}
{pmore}
. generate pop0 = cdeath+cnodeath {* ///} {p_end}
{p 10 20 2}
generate pop1 = tdeath+tnodeath {p_end}
{p 10 20 2}
generate logrr = ln((tdeath/pop1)/(cdeath/pop0)) {* ///} {p_end}
{p 10 20 2}
generate se = sqrt((1/tdeath)+(1/cdeath)-(1/pop1)-(1/pop0)) {p_end}
{p 10 20 2}
generate n = (pop0*pop1)/(pop0+pop1)
{txt}{...}



{pstd}
Risk ratio as effect size, DerSimonian-Laird estimation method, labeled studies, graph and results of the meta-analysis in exponential form to be displayed

{cmd}{...}
{pmore}
. ameta logrr se, method(dl) study(id) graph eform
{txt}{...}


{pstd}
Risk ratio as effect size, Paule and Mandel estimation method, unlabeled studies and graph to be displayed

{cmd}{...}
{pmore}
. ameta logrr se, method(pm) graph 
{txt}{...}


{pstd}
Risk ratio as effect size, Hartung and Makambi estimation method, labeled studies, subgroup analysis by year and results of the meta-analysis in exponential form to be displayed

{cmd}{...}
{pmore}
. ameta logrr se, method(hm) study(id) by(year) eform
{txt}{...}


{pstd}
Risk ratio as effect size, Approximation method, confidence level 90%, labeled studies, graph and results of the meta-analysis in exponential form to be displayed

{cmd}{...}
{pmore}
. ameta logrr se n, method(abi) study(id) graph eform l(90)
{txt}{...}


{pstd}
Risk ratio as effect size, GLLAMM method, unlabeled studies and graph to be displayed

{cmd}{...}
{pmore}
. ameta logrr se, method(gllamm) graph 
{txt}{...}


{pstd}
Risk ratio as effect size, meta-regression method, labeled studies,shape parameter is equal to three, scale parameter is equal to one, subgroup analysis by year and results of the meta-analysis in exponential form to be displayed

{cmd}{...}
{pmore}
. ameta logrr se, method(metareg) study(id) by(year) eform a(3) b(1)
{txt}{...}



{title:Authors}

{pstd} Kalliopi K. Exarchou-Kouveli, Eleni Nikolaidou, Panagiota I. Kontou and Pantelis G. Bagos. {p_end}
{pstd} Department of Computer Science and Biomedical Informatics, {p_end}
{pstd} University of Thessaly, Lamia, Greece {p_end}

{pstd}
Email {browse "mailto:kexarch@uth.gr":kexarch@uth.gr} {p_end}
{p 10 20 2}  
{browse "mailto:elnikolaidou98@gmail.com":elnikolaidou98@gmail.com} {p_end}
{p 10 20 2}	 
{browse "mailto:pbagos@compgen.org":pbagos@compgen.org}


{marker refs}{...}
{title:References}

{phang}
Abrams K, Sans{c o'} B. 1998. Approximate Bayesian Inference for Random Effects Meta-Analysis.
Statistics in Medicine, 17(2), 201-218. https://doi.org/10.1002/(SICI)1097-0258(19980130)17:2<201::AID-SIM736>3.0.CO;2-9

{phang}
Chung Y, Rabe-Hesketh S, Choi I. 2013. Avoiding Zero Between-Study Variance Estimates in Random-Effects Meta-Analysis. 
Statistics in Medicine, 32(23), 4071-4089.  https://doi.org/10.1002/sim.5821

{phang}
Chung Y, Rabe-Hesketh S, Dorie V, Gelman A, Liu J. 2013. A Nondegenerate Penalized Likelihood Estimator for Variance Parameters in Multilevel Models.
Psychometrika, 78, 685-709. https://doi.org/10.1007/s11336-013-9328-2
	
{phang}
Cochran, WG. 1954. The Combination of Estimates from Different Experiments.
Biometrics, 10(1), 101-129. https://doi.org/10.2307/3001666

{phang}
DerSimonian R, Kacker R. 2007. Random-effects model for meta-analysis of clinical trials: An update.
Contemporary Clinical Trials, 28(2), 105-114. https://doi.org/10.1016/j.cct.2006.04.004

{phang}
DerSimonian R, Laird N. 1986. Meta-analysis in clinical trials.
Controlled clinical trials, 7(3), 177-188.

{phang}
Exarchou-Kouveli KK, Nikolaidou E, Bagos PG. 2022. ameta: a command for alternative and bayesian meta-analysis.
Submitted.

{phang}
Hartung J, Makambi KH. 2003. Reducing the Number of Unjustified Significant Results in Meta-analysis.
Communications in Statistics Part B: Simulation and Computation, 32(4), 1179-1190. https://doi.org/10.1081/SAC-120023884

{phang}
Hedges LV. 1986. Chapter 11: Issues in Meta-Analysis.
Review of Research in Education, 13(1), 353-398. https://doi.org/10.3102/0091732X013001353

{phang}
Hedges LV, Olkin I. 1985. Statistical methods for meta-analysis. 
Academic Press.

{phang}
Langan D, Higgins JPT, Jackson D, Bowden J, Veroniki AA, Kontopantelis E, Viechtbauer W, Simmonds M. 2019.
A comparison of heterogeneity variance estimators in simulated random-effects meta-analyses.
Research Synthesis Methods, 10(1), 83-98. https://doi.org/10.1002/jrsm.1316

{phang}
Paule RC, Mandel J. 1989. Consensus Values and Weighting Factors.
Journal of Research of the National Bureau of Standards, 87(5).

{phang}
Rhodes KM, Turner RM, White IR, Jackson D, Spiegelhalter DJ, Higgins JPT. 2016. Implementing Informative Priors for Heterogeneity in Meta-analysis Using Meta - regression and Pseudo Data. 
Statistics in Medicine, 35(29), 5495-5511.  https://doi.org/10.1002/sim.7090

{phang}
Sidik K, Jonkman JN. 2005. Simple heterogeneity variance estimation for meta-analysis.
Applied Statistics, 54(2), 367-384.

{phang}
Sidik K, Jonkman JN. 2007. A comparison of heterogeneity variance estimators in combining results of studies.
Statistics in Medicine, 26(9), 1964-1981. https://doi.org/10.1002/sim.2688

{phang}
Thorlund K, Wetterslev J, Awad T, Thabane L, Gluud C. 2011.
Comparison of statistical inferences from the DerSimonian-Laird and alternative random-effects model meta-analyses - an empirical
assessment of 920 Cochrane primary outcome meta-analyses. Research Synthesis Methods, 2(4), 238-253. https://doi.org/10.1002/jrsm.53




		
		
