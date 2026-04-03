{smcl}
{* *! version 3.0.0  30mar2026}{...}
{viewerjumpto "Syntax" "midas##syntax"}{...}
{viewerjumpto "Description" "midas##description"}{...}
{viewerjumpto "Subcommands" "midas##subcommands"}{...}
{viewerjumpto "Examples" "midas##examples"}{...}
{viewerjumpto "References" "midas##references"}{...}
{viewerjumpto "Author" "midas##author"}{...}

{title:Title}

{phang}
{bf:midas} {hline 2} Meta-analytical Integration of Diagnostic Accuracy Studies


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas} {it:subcommand} [{it:varlist}] [{cmd:,} {it:options}]

{pstd}
where {it:subcommand} is one of the commands listed below.


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas} is a comprehensive Stata suite for diagnostic test accuracy (DTA)
meta-analysis using the bivariate random-effects model.  It provides five
estimation engines, nine post-estimation graphics, seven exploratory tools,
and five data management utilities, all accessible through both command-line
syntax and GUI dialogs.

{pstd}
The bivariate model jointly estimates logit-transformed sensitivity and
specificity using a two-level hierarchical structure that separates
within-study sampling variability from between-study heterogeneity.

{pstd}
To open the main GUI launcher:

{phang2}{cmd:. db midas}{p_end}


{marker subcommands}{...}
{title:Subcommands}

{dlgtab:Data Preparation}

{synoptset 22}{...}
{synopt:{helpb midas_simdata:simdata}}simulate DTA datasets under the bivariate model{p_end}
{synopt:{helpb midas_ord2bin:ord2bin}}convert ordinal test ratings to binary at optimal Youden threshold{p_end}
{synopt:{helpb midas_con2bin:con2bin}}convert continuous biomarker results to binary 2x2 tables{p_end}
{synopt:{helpb midas_bclust2bin:clust2bin}}adjust clustered (lesion-level) data by design effect{p_end}
{synopt:{helpb midas_ipd2ad:ipd2ad}}aggregate individual participant data to study-level 2x2 tables{p_end}

{dlgtab:Exploratory Analysis}

{synopt:{helpb midas_quadas:quadas}}QUADAS-2 quality assessment plots{p_end}
{synopt:{helpb midas_quadas2:quadas2}}QUADAS-2 with improved legend handling{p_end}
{synopt:{helpb midas_bivbox:bivbox}}bivariate boxplot of logit Se vs logit Sp{p_end}
{synopt:{helpb midas_chiplot:chiplot}}Fisher-Switzer chi-plot for bivariate dependence{p_end}
{synopt:{helpb midas_kendall:kendall}}Kendall plot for rank-based dependence{p_end}
{synopt:{helpb midas_binsse:binsse}}regression tests for small-study effects{p_end}
{synopt:{helpb midas_assess:assess}}pre-model diagnostic battery with traffic-light system{p_end}
{synopt:{helpb midas_eforest:eforest}}exploratory coupled forest plot (no summary diamond){p_end}

{dlgtab:Estimation}

{synopt:{helpb midas_mle:mle}}maximum likelihood via adaptive Gauss-Hermite quadrature{p_end}
{synopt:{helpb midas_qrsim:qrsim}}maximum simulated likelihood via quasi-random sequences{p_end}
{synopt:{helpb midas_mh:mh}}Bayesian Metropolis-Hastings via {cmd:bayesmh}{p_end}
{synopt:{helpb midas_hmc:hmc}}Bayesian HMC/NUTS via CmdStan{p_end}
{synopt:{helpb midas_inla:inla}}integrated nested Laplace approximation via R-INLA{p_end}

{dlgtab:Post-Estimation}

{synopt:{helpb midas_sforest:sforest}}summary forest plot with pooled diamond and prediction intervals{p_end}
{synopt:{helpb midas_bayesplot:bayesplot}}MCMC diagnostic plots (trace, density, ACF, Gelman-Rubin){p_end}
{synopt:{helpb midas_rgsroc:rgsroc}}Rutter-Gatsonis hierarchical summary ROC curve{p_end}
{synopt:{helpb midas_bvsroc:bvsroc}}bivariate summary ROC with confidence/prediction ellipses{p_end}
{synopt:{helpb midas_fagan:fagan}}Fagan nomogram for post-test probability{p_end}
{synopt:{helpb midas_lrmat:lrmat}}likelihood ratio scattergram and matrix{p_end}
{synopt:{helpb midas_condiplot:condiplot}}conditional sensitivity-specificity plot{p_end}
{synopt:{helpb midas_pubbias:pubbias}}publication bias assessment (Deeks funnel plot){p_end}
{synopt:{helpb midas_hsruc:hsruc}}hierarchical summary relative utility curve (decision analysis){p_end}
{synopt:{helpb midas_subgroup:subgroup}}stratified subgroup analysis with comparison table and SROC overlay{p_end}
{synopt:{helpb midas_metareg:metareg}}bivariate meta-regression with study-level covariates{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Complete workflow{p_end}

{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/m/midas_example_data.dta, clear}{p_end}
{phang2}{cmd:. gen study = _n}{p_end}

{pstd}Exploratory analysis{p_end}
{phang2}{cmd:. midas bivbox tp fp fn tn, id(study)}{p_end}
{phang2}{cmd:. midas assess tp fp fn tn}{p_end}
{phang2}{cmd:. midas eforest, plottype(generic)}{p_end}

{pstd}Estimation{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(study) hetstats hsroc}{p_end}

{pstd}Post-estimation{p_end}
{phang2}{cmd:. midas sforest, plottype(generic) predinterval}{p_end}
{phang2}{cmd:. midas rgsroc, data cregion pregion weighted}{p_end}
{phang2}{cmd:. midas bvsroc, cellipse pellipse data mean}{p_end}
{phang2}{cmd:. midas fagan, pretestprob(0.10 0.30 0.50)}{p_end}
{phang2}{cmd:. midas lrmat}{p_end}
{phang2}{cmd:. midas condiplot}{p_end}
{phang2}{cmd:. midas pubbias, wgt regline}{p_end}

{pstd}Clinical utility{p_end}
{phang2}{cmd:. midas hsruc, prevalence(0.20) allmetrics prediction}{p_end}

{pstd}Bayesian estimation{p_end}
{phang2}{cmd:. midas mh tp fp fn tn, id(study) covariance(cholesky) chains(4) mcsize(20000)}{p_end}
{phang2}{cmd:. midas bayesplot}{p_end}
{phang2}{cmd:. midas sforest, plottype(rain)}{p_end}

{pstd}GUI launcher{p_end}
{phang2}{cmd:. db midas}{p_end}


{marker references}{...}
{title:References}

{phang}
Dwamena BA. 2007. MIDAS: a program for meta-analytical integration of
diagnostic accuracy studies in Stata. {it:Statistical Software Components},
Boston College Department of Economics.

{phang}
Dwamena BA. 2026. {it:MIDAS: Meta-analytical Integration of Diagnostic
Accuracy Studies -- Theory, Methods, and Software}. BennyBeauBooks.

{phang}
Reitsma JB, Glas AS, Rutjes AWS, Scholten RJPM, Bossuyt PM, Zwinderman AH.
2005. Bivariate analysis of sensitivity and specificity produces informative
summary measures in diagnostic reviews.
{it:Journal of Clinical Epidemiology} 58: 982-990.

{phang}
Rutter CM, Gatsonis CA. 2001. A hierarchical regression approach to
meta-analysis of diagnostic test accuracy evaluations.
{it:Statistics in Medicine} 20: 2865-2884.

{phang}
Harbord RM, Deeks JJ, Egger M, Whiting P, Sterne JAC. 2007. A unification
of models for meta-analysis of diagnostic test accuracy studies.
{it:Biostatistics} 8: 239-251.

{phang}
Vickers AJ, Elkin EB. 2006. Decision curve analysis: a novel method for
evaluating prediction models. {it:Medical Decision Making} 26: 565-574.


{marker author}{...}
{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
Clinical Associate Professor Emeritus of Radiology{break}
Division of Nuclear Medicine and Molecular Imaging{break}
University of Michigan{break}

{pstd}
{browse "mailto:ben@bennybeaubooks.com":ben@bennybeaubooks.com}{break}
{browse "https://www.bennybeaubooks.com":www.bennybeaubooks.com}

{pstd}
Requires: Stata 16+{break}
Optional: CmdStan (for {cmd:midas hmc}), R + R-INLA (for {cmd:midas inla}),
{cmd:bayesparallel} from SSC (for parallel MH chains)
{p_end}
