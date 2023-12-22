{smcl}
{* *! version 1.0  12jul2023}{...}
{viewerdialog canon "dialog canon"}{...}
{vieweralsosee "[MV] canon" "mansection MV canon"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[MV] canon postestimation" "help canon postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[MV factor" "help factor"}{...}
{vieweralsosee "[MV] mvreg" "help mvreg"}{...}
{vieweralsosee "[MV] pca" "help pca"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] correlate" "help correlate"}{...}
{vieweralsosee "[R] pcorr" "help pcorr"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{viewerjumpto "Syntax" "svycanon##syntax"}{...}
{viewerjumpto "Menu" "svycanon##menu"}{...}
{viewerjumpto "Description" "svycanon##description"}{...}
{viewerjumpto "Options" "svycanon##options"}{...}
{viewerjumpto "Examples" "svycanon##examples"}{...}
{viewerjumpto "Stored results" "svycanon##results"}{...}
{p2colset 1 15 16 2}{...}
{p2col:{bf: svycanon}{hline 2}}Canonical correlation analysis for complex survey data{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}{cmd:svycanon}
[{cmd:,} {it:options}]

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Model}
{synopt :{opt svysetcom(str)}} specifies the {cmd:svy} options required for the accurate analysis of the data set. {p_end}

{syntab :Reporting}
{synopt :{opt howmany(#)}} allows the user to choose for number of canonical correlations for which the statistical significance statistics are displayed.{p_end}
{synopt :{opt firstdim(#)}} determines which canonical variate serves as the horizontal axis in the variables graph.{p_end}
{synopt :{opt secdim(#)}} determines which canonical variate serves as the horizontal axis in the variables graph. {p_end}
{synopt :{opt freq(str)}} allows the user to choose whether the type of sample size is equal to the number of rows in the data set or the sum of the survey weights. {p_end}

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
 The post estimation command {cmd:svycanon} extends the functionality of {cmd:canon} by calculating the test statistics, degrees of freedom and p-values necessary to assess the statistical significance of the secondary canonical correlations (CC).
{p_end}

{pstd} This is done according to the methods Wilks' lambda, Pillai's trace, and Hotelling-Lawley trace (Caliński et al., 2006) and Roy's largest root (Johnstone, 2009).
{p_end}
 
{pstd}
{cmd:svycanon} also implements an algorithm (Cruz-Cano et al., 2024) that allows the inclusion of complex survey design factors (CSD), e.g., strata, cluster and replicate weights, in the estimation of the statistical significance of the CC. 
{p_end}

{pstd}
The algorithm's core idea is to calculate the correlations among the canonical variates and their corresponding statistical significance via an equivalent sequence of univariate linear regression models.
{p_end}

{pstd}
 This transformation allows the user to utilize the existing resources that can integrate CSD factors into these regression models (Valliant and Dever, 2018). Hence, this algorithm can incorporate the same CSD factors as {cmd:svy:}{cmd:reg}.
{p_end}

{pstd} 
The units and variables graphs (Gittins, 1986) can also be drawn by {cmd:svycanon} further complementing the information listed by the existing {cmd:canon} post estimation commands.
{p_end}

{pstd}
Examples from the Wave 1 of the Population Assessment of Tobacco and Health (PATH) study (Hyland et al., 2017) and the 2021 National Youth Tobacco Survey (Gentzke et al., 2022) are included as examples.
{p_end}

{pstd}
{cmd:svycanon} typed without arguments displays the values needed to assess the statistical significance of the canonical correlations obtained using a classic canonical correlation analysis.
{p_end}

{pstd}
The canonical structure variables must be set beforehand by {cmd:canon}, see help {help canon}.
{p_end}

{pstd}
Warning:  Use of {cmd:if}, {cmd:by}, or {cmd:in} restrictions has not been incorporated yet in {cmd:svycanon}.
{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}{opt svysetcom(str)} specifies the {cmd:svy} options required for the accurate analysis of the data set. If this option is set to {cmd:"classic"} or missing, then it is assumed the data comes from a simple random sample of the population and hence no complex survey design elements need to be specified.  

{dlgtab:Reporting}

{phang}{opt howmany(#)}} allows the user to choose for number of canonical correlations for which the statistical significance statistics are displayed. Notice that regardless of the value or this option, all canonical correlations are evaluated, i.e. this option just determines how many results are shown. If this option is not used, then all possible canonical correlations are presented.

{phang}{opt firstdim(#)} determines the which canonical variate serves as the horizontal axis in the variables graph. If this option is not used, then then no plots are displyed.{p_end}

{phang}{opt secdim(#)} determines the which canonical variate serves as the horizontal axis in the variables graph.{p_end}

{phang}{opt freq(str)} allows the user to choose whether the sample size should be considered equal to the number of rows in the data set or the sum of the survey weights.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup Simple Automobile Example {p_end}
{phang2}{cmd:.  use https://www.stata-press.com/data/r17/auto, clear}{p_end}
{phang2}{cmd:.  canon (displacement mpg gear_ratio turn) (length weight headroom trunk)}{p_end}

{pstd}Estimate canonical correlations p-values for Simple example {p_end}
{phang2}{cmd:. svycanon, svysetcom("classic") howmany(3)}{p_end}

{pstd} Setup PATH Example{p_end}
{phang2}{cmd:. use svycanonPATHStudyWave1example, clear}{p_end}
{phang2}{cmd:. canon (R01_AC1022 R01_AE1022 R01_AG1022CG) (R01_AX0075 R01_AX0076) [weight=R01_A_PWGT] }{p_end}

{pstd}Estimate canonical correlations p-values for PATH Example {p_end}
{phang2}{cmd:. svycanon , svysetcom("svyset [pweight= R01_A_PWGT], brr(R01_A_PWGT1 - R01_A_PWGT100) vce(brr) mse fay(.3)") howmany(2) firstdim(1) secdim(2)}{p_end}

{pstd} Setup NYTS Example{p_end}
{phang2}{cmd:. use svycanonNYTS2021example, clear}{p_end}
{phang2}{cmd:. canon (qn9 qn38 qn40 qn53 qn54 qn64 qn69 qn74 qn76 qn78 qn80 qn82 qn85 qn88 qn89) (qn128 qn129 qn130 qn131 qn132 qn134) [weight=finwgt] }{p_end}

{pstd}Estimate canonical correlations p-values for NYTS Example {p_end}
{phang2}{cmd:. svycanon , svysetcom("svyset [pweight=finwgt], psu(psu2) strata( v_stratum2)") howmany(3)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:svycanon} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(WilksStat)}}test statistic for Wilk's lambda{p_end}
{synopt:{cmd:r(WilksDf1)}}degrees of freedom for Wilk's lambda Chi-square distribution{p_end}
{synopt:{cmd:r(WilksChiSq)}}value for Wilk's lambda Chi-square test statistic{p_end}
{synopt:{cmd:r(WilksPval)}}p-value for Wilk's lambda Chi-square test{p_end}
{synopt:{cmd:r(PillaisStat)}}test statistic for  Pillai's trace{p_end}
{synopt:{cmd:r(PillaisDf1)}}degrees of freedom for Pillai's trace Chi-square distribution{p_end}
{synopt:{cmd:r(PillaisChiSq)}}value for Pillai's trace Chi-square test statistic{p_end}
{synopt:{cmd:r(PillaisPval)}}p-value for Pillai's trace Chi-square test{p_end}
{synopt:{cmd:r(HotellingStat)}}test statistic for  Hotelling-Lawley trace{p_end}
{synopt:{cmd:r(HotellingDf1)}}degrees of freedom for Hotelling-Lawley trace Chi-square distribution{p_end}
{synopt:{cmd:r(HotellingChiSq)}}value for Hotelling-Lawley trace Chi-square test statistic{p_end}
{synopt:{cmd:r(HotellingPval)}}p-value for Hotelling-Lawley trace Chi-square test{p_end}
{synopt:{cmd:r(RoysStat)}}test statistic for Roy's greatest root{p_end}
{synopt:{cmd:r(RoysDf1)}}degrees of freedom for Roy's greatest root Chi-square distribution{p_end}
{synopt:{cmd:r(RoysChiSq)}}value for Roy's greatest root Chi-square test statistic{p_end}
{synopt:{cmd:r(RoysPval)}}p-value for Roy's greatest root Chi-square test{p_end}
{synopt:{cmd:r(WtSCCStat)}}test statistic for the Survey CC algorithm using only the survey weights{p_end}
{synopt:{cmd:r(WtSCCDf1)}}numerator degrees of freedom for the Survey CC algorithm using only the survey weights{p_end}
{synopt:{cmd:r(WtSCCDf2)}}denominator degrees of freedom for the Survey CC algorithm using only the survey weights{p_end}
{synopt:{cmd:r(WtSCCF)}}value for the Survey CC algorithm F distribution using only the survey weights{p_end}
{synopt:{cmd:r(WtSCCPval)}}p-value for the Survey CC algorithm F distribution using only the survey weights{p_end}
{synopt:{cmd:r(CSCCStat)}}test statistic for the Survey CC algorithm using all complex survey design elements{p_end}
{synopt:{cmd:r(CSCCDf1)}}numerator degrees of freedom for the Survey CC algorithm using only the survey weights{p_end}
{synopt:{cmd:r(CSCCDf2)}}denominator degrees of freedom for the Survey CC algorithm using only the survey weights{p_end}
{synopt:{cmd:r(CSCCF)}}value for the Survey CC algorithm F distribution using all complex survey design elements{p_end}
{synopt:{cmd:r(CSCCPval)}}p-value for the Survey CC algorithm F distribution using all complex survey design elements{p_end}

{title:Authors}

{p 4 4}Raul Cruz-Cano, Indiana University, Bloomington{break}
<raulcruz@iu.edu>

{title:Acknowledgement}

{p 4 4} Thanks to Erin Mead-Morse, Aaron Cohen, and Nicolas Escobar Velasquez for their contributions to this work. 

{title:References}

{p 4 4} Cruz-Cano R, Cohen A, and Mead-Morse E. Canonical Correlation Analysis of Survey Data: the SurveyCC R package,{it: The R Journal} under review. 2024.

{p 4 4} Caliński T., Krzyśko M. and WOłyński W. (2006) A Comparison of Some Tests for Determining the Number of Nonzero Canonical Correlations, {it: Communications in Statistics - Simulation and Computation}, 35:3, 727-749, DOI: 10.1080/03610910600716290.

{p 4 4} Gentzke AS, Wang TW, Cornelius M, Park-Lee E, Ren C, Sawdey MD, Cullen KA, Loretan C, Jamal A, Homa DM. Tobacco Product Use and Associated Factors among Middle and High School Students - National Youth Tobacco Survey, United States, 2021. MMWR Surveill Summ. 2022;71(5):1-29. doi: 10.15585/mmwr.ss7105a1. PubMed PMID: 35271557.

{p 4 4}	Gittins R. {it: Canonical Analysis: A Review with Applications in Ecology}: Springer Berlin Heidelberg; 1986.

{p 4 4} Hyland A, Ambrose BK, Conway KP, et al. Design and methods of the Population Assessment of Tobacco and Health (PATH) StudyTobacco Control. 2017;26:371-378.

{p 4 4} Johnstone IM. Approximate Null Distribution of the largest root in a Multivariate Analysis.{it:  Ann Appl Stat.} 2009;3(4):1616-1633. doi: 10.1214/08-AOAS220. PMID: 20526465; PMCID: PMC2880335.

{p 4 4} Valliant R. and Dever JA. {it: Survey Weights: A Step-by-Step Guide to Calculation}: Stata Press; 2018. ISBN-13: 978-1-59718-260-7.

{title:Also see}

{p 1 14}Manual:  {hi:[U] 30 Overview of survey estimation}, {hi:[SVY]}{p_end}

{p 0 19}On-line:  help for {help svy} and {help canon}.{p_end}