
{smcl}

{* *! version 1.0.1 10Nov2023}
{cmd:help pmvalsampsize}
{hline}

{title:Title}

{phang}
{bf:pmvalsampsize} {hline 2} Calculates the minimum sample size required for external validation of a multivariable prediction model

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:pmvalsampsize} , {opt type(string)} 
	[{opt rsq:uared(real 0)} {opt rsqci:width(real 0.1)}  
		{opt cs:lope(real 1)} {opt csci:width(real 0.2)}  
		{opt citl(real 0)} {opt citlci:width(real 0)} {opt varobs(real 0)}  
		{opt prev:alence(real 0)} {opt simobs(int 1000000)}  
		{opt cstat:istic(real 0)} {opt cstatci:width(real 0.1)} 
	{opt oe(real 1)} {opt oeci:width(real 0.2)} {opt oeseinc:rement(real 0.0001)}
		{opt lpnorm:al(numlist max=2)} {opt lpskew:ednormal(numlist max=4)} 
		{opt lpbeta(numlist max=2)} {opt lpcstat(numlist max=1)}  
		{opt tol:erance(real 0.0005)} {opt inc:rement(real 0.1)} 
		{opt sens:itivity(real 0)} {opt spec:ificity(real 0)} {opt thresh:old(real 0)}
		{opt nbci:width(real 0.2)} {opt nbseinc:rement(real 0.0001)}
		{opt seed(int 123456)} {opt mmoe(real 1.1)} {opt trace} {opt graph} {opt noprint}]	


{synoptset 30}{...}
{synopthdr:pmvalsampsize_general_options}
{synoptline}
{synopt :{opt type(string)}}specifies the type of analysis for which sample size is being calculated{p_end}
{synopt :{opt cs:lope(real 1)}}anticipated C-slope performance in validation sample{p_end}
{synopt :{opt csci:width(real 0.2)}}target CI width for calibration slope performance{p_end}
{synopt :{opt noprint}}suppress criteria descriptions in output{p_end}
{synoptline}

{phang}
{bf:Binary outcome models}

{synoptset 30}{...}
{synopthdr:binary_outcome_options}
{synoptline}
{synopt :{opt prev:alence(real 0)}}anticipated prevalence of outcome in validation sample{p_end}
{synopt :{opt simobs(int 1000000)}}sets the number of observations to use for simulated LP calculations{p_end}
{synopt :{opt cstat:istic(real 0)}}anticipated c-statistic at validation{p_end}
{synopt :{opt cstatci:width(real 0.1)}}target CI width for c-statistic performance{p_end}
{synopt :{opt oe(real 1)}}anticipated observed/expected ratio at validation{p_end}
{synopt :{opt oeci:width(real 0.2)}}target CI width for OE performance{p_end}
{synopt :{opt lpnorm:al(numlist max=2)}}defines parameters to simulate LP from normal distribution{p_end}
{synopt :{opt lpskew:ednormal(numlist max=4)}}defines parameters to simulate LP from a skewed normal distribution{p_end}
{synopt :{opt lpbeta(numlist max=2)}}defines parameters to simulate P from beta distribution{p_end}
{synopt :{opt lpcstat(numlist max=1)}}defines starting value for non-events mean{p_end}
{synopt :{opt tol:erance(real 0.0005)}}sets tolerance for observed event prop. during iterative procedure for non-events mean{p_end} 
{synopt :{opt inc:rement(real 0.1)}}sets increment by which to iterate when identifying mean for non-events for lpcstat(){p_end}
{synopt :{opt trace}}output a trace of the iteration process when using {opt lpcstat()}{p_end}
{synopt :{opt oeseinc:rement(real 0.0001)}}sets increment by which to iterate when identifying the SE(ln(OE)) to meet the target CI width for OE{p_end}
{synopt :{opt seed(int 123456)}}set seed for simulation based calclulations{p_end}
{synopt :{opt graph}}produces histogram of the LP distribution for checking{p_end}
{synopt :{opt sens:itivity(real 0)}}anticipated sensitivity at validation{p_end}
{synopt :{opt spec:ificity(real 0)}}anticipated specificity at validation{p_end}
{synopt :{opt thresh:old(real 0)}}specifies risk threshold used for net benefit calculation{p_end}
{synopt :{opt nbci:width(real 0.2)}}target CI width for standardised net benefit performance{p_end}
{synopt :{opt nbseinc:rement(real 0.0001)}}sets increment by which to iterate when identifying the SE(standardised net benefit) to meet the target CI width for standardised net benefit{p_end}
{synoptline}

{phang}
{bf:Continuous outcomes models}

{synoptset 30}{...}
{synopthdr:continuous_outcome_options}
{synoptline}
{synopt :{opt rsq:uared(real 0)}}anticipated value of the R-squared in the validation sample{p_end}
{synopt :{opt rsqci:width(real 0.1)}}target precision in terms of CI width for R-sq{p_end}
{synopt :{opt citl(real 0)}}assumed CITL performance in validation sample{p_end}
{synopt :{opt citlci:width(real 0)}}target precision in terms of CI width for CITL{p_end}
{synopt :{opt varobs(real 0)}}anticipated variance of observed values in the validation sample{p_end}
{synopt :{opt mmoe(real 1.1)}}set MMOE threshold for acceptable precision of residual variance of CITL & C-slope{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd: pmvalsampsize} computes the minimum sample size required for the external validation of an existing multivariable prediction model using the criteria proposed by Archer et al. and Riley et al.
{cmd: pmvalsampsize} can currently be used to calculate the minimum sample size for the external validation of models with continuous or binary outcomes.
Survival (time-to-event) outcome model calculations are a work in progress.

{pstd}A series of criteria define the sample size needed to ensure precise estimation of key measures of prediction model performance,
allowing conclusions to be drawn about whether the model is potentially accurate and useful in a given population of interest.  

{phang}For {bf:continuous outcome models}, Archer et al. specify four criteria to calculate the sample size (N) needed for:{p_end} 
{pmore}i) precise estimation of the R-squared performance,{p_end}
{pmore}ii) precise estimation of the calibration-in-the-large (CITL),{p_end}
{pmore}iii) precise estimation of the calibration slope (c-slope), and{p_end} 
{pmore}iv) precise estimation of the residual variance for CITL & c-slope.{p_end} 

{phang}The sample size calculation requires the user to pre-specify
(e.g. based on previous evidence from the development study or information known from the validation sample if available) the following;{p_end} 
{pmore}- the anticipated R-squared performance{p_end} 
{pmore}- the target precision (CI width) for the R-squared{p_end}   
{pmore}- the anticipated CITL performance{p_end}
{pmore}- the target precision (CI width) for the CITL{p_end}  
{pmore}- the anticipated c-slope{p_end}
{pmore}- the target precision (CI width) for the c-slope{p_end}
{pmore}- the anticipated variance of observed values in the validation sample{p_end} 

{phang}For {bf:binary outcomes}, there are three criteria to calculate the sample size (N) needed for:{p_end} 
{pmore}i) precise estimation of the Observed/Expected (O/E) statistic,{p_end}
{pmore}ii) precise estimation of the calibration slope (c-slope), and{p_end}
{pmore}iii) precise estimation of the c-statistic.{p_end}
{phang}And a fourth optional criteria to calculate the sample size (N) needed for:{p_end}
{pmore}iv) precise estimation of the standardised net-benefit (sNB).{p_end}

{phang}The sample size calculation requires the user to pre-specify the following;{p_end} 
{pmore}- the outcome event proportion{p_end}
{pmore}- the anticipated O/E performance{p_end}
{pmore}- the target precision (CI width) for the O/E{p_end}
{pmore}- the anticipated c-slope{p_end}
{pmore}- the target precision (CI width) for the c-slope{p_end}
{pmore}- the anticipated c-statisitic performance{p_end}
{pmore}- the target precision (CI width) for the c-statisitic{p_end}
{pmore}- the distribution of estimated probabilities from the model, ideally specified on the log-odds scale - AKA the Linear Predictor (LP){p_end}
{pmore}- the anticipated sensitivity, specificity and relevant risk threshold for sNB calculation{p_end}
{pmore}- the target precision (CI width) for the standardised net benefit{p_end}


{marker options}{...}
{title:General Options}

{phang}{opt type(string)} specifies the type of analysis for which sample size is being calculated:{p_end}
{pmore}{opt c} specifies sample size calculation for a prediction model with a continuous outcome{p_end}
{pmore}{opt b} specifies sample size calculation for a prediction model with a binary outcome{p_end}

{phang}{opt cslope(real 1)} specifies the anticipated c-slope performance in the validation sample.
Default conservatively assumes perfect c-slope=1. 
The value could alternatively be based on a previous validation study for example.
For {bf:binary outcomes} the c-slope calculation requires the user to specify a distribution for the assumed LP in the validation sample 
(or alternatively the distibution of predicted probabilities in the validation sample). See {opt lp*()} options below.

{phang}{opt csciwidth(real 0.2)} specifies the target CI width (acceptable precision) for the c-slope performance. 
Default assumes CI width=0.2. 

{phang}{opt noprint} suppresses output showing the detailed descriptions of each of the criteria shown in the results table.

{marker options}{...}
{title:Binary outcome options}

{phang}{opt prevalence(real)} specifies the overall outcome proportion (for a prognostic model) or overall prevalence (for a diagnostic model) expected within the model validation sample.
This is a {bf:required input}.
This should be derived based on previous studies in the same population or 
directly from the validation sample if to hand.

{phang}{opt simobs(int)} specifies the number of observations to use when simulating the LP distribution for c-slope calculation in criteria 2.
Default observations=1,000,000. 
Higher {opt simobs()} values will reduce random variation further.

{phang}{opt cstatistic(real)} specifies the anticipated c-statistic performance in the validation sample. 
This is a {bf:required input}.
May be based on the optimism-adjusted c-statistic reported in the development study for the existing prediction model.
Ideally, this should be an {it: optimism-adjusted} c-statistic.  
NB: This input is also used when using the {opt lpcstat()} option.

{phang}{opt cstatciwidth(real 0.1)} specifies the target CI width (acceptable precision) for the c-statistic performance. 
Default assumes CI width=0.1.

{phang}{opt oe(real 1)} specifies the anticipated O/E performance in the validation sample.
Default conservatively assumes perfect O/E=1. 

{phang}{opt oeciwidth(real 0.2)} specifies the target CI width (acceptable precision) for the E/O performance. 
Default assumes CI width=0.2. 
The choice of CI width is context specific, and depends on the event probability in the population. 
See Riley et al. for further details. 

{phang}{opt oeseincrement(real 0.0001)} sets the increment by which to iterate when identifying the SE(ln(OE)) to meet the target CI width specified for OE.
The default iteration increment=0.0001.
In the majority of cases this will be suitably small to ensure a precise SE is identified.
The user should check the output table to ensure that the target CI width has been attained and adjust the increment if necessary. 

{phang}{opt lpnormal(numlist)} defines parameters to simulate the LP distribution for criteria 2 from a normal distribution.
The user must specify the mean and standard deviation (in this order) of the LP distribution.

{phang}{opt lpskewednormal(numlist)} defines parameters to simulate the LP distribution for criteria 2 from a skewed normal distribution.
The user must specify the mean, variance, skew and kurtosis parameters (in this order) of the LP distribution.
NB: {opt lpskewednormal()} option uses {cmd: sknor} and can take a little longer than other distributional assumptions.

{phang}{opt lpbeta(numlist)} defines parameters to simulate the distribution of predicted probabilities for criteria 2 from a beta distribution.
The user must specify the alpha and beta parameters (in this order) of the probability distribution. 
The LP distribution is then generated internally using this probability distribution.

{phang}{opt lpcstat(numlist)} defines parameters to simulate the LP distribution for criteria 2 assuming that the distribution of events and non-events are normal with a common variance.
The user specifies a single input value - the expected mean for the non-events distribution. This could be informed by clinical guidance.
However, this input is taken as a starting value and an iterative process is used to identify the most appropriate values for the event and non-event distributions
so as to closely match the anticipated prevalence in the validation sample.
NB: this approach makes strong assumptions of normality and equal variances in each outcome group, which may be unrealistic in most situations.

{phang}{opt tolerance(real 0.0005)} for use with {opt lpcstat()} option.
Sets the tolerance for agreement between the simulated and expected event
 proportion during the iterative procedure for calculating the mean for the non-events distribution.

{phang}{opt increment(real 0.1)} for use with {opt lpcstat()} option. 
Sets increment by which to iterate the value of the mean for the non-events distribution.
Trial and error may be necessary as it is dependent on how close the inital input for the non-event mean in {opt lpcstat()} is to the required value. 
If the process takes a particularly long time then the user could try an alternative increment value, or an alternative non-event mean value in {opt lpcstat()}.
The {opt trace} option may be useful in such circumstances.

{phang}{opt trace} for use with {opt lpcstat()} option. 
Specifies that a trace of the values obtained in each iteration when identifying the non-event mean is output. 
Useful when finding the approriate values for {opt lpcstat()} & {opt increment()} is proving difficult!

{phang}{opt seed(int 123456)} specifies the initial value of the random-number seed used by the random-number functions when simulating data 
to approximate the LP distribution for criteria 2. 

{phang}{opt graph} specifies that a histogram of the simulated LP distribution for criteria 2 is produced.
The graph also details summary statistics for the simulated distribution.
Useful option for checking the simulated LP distribution against the source of input parameters. 
Also useful for reporting at publication. 

{phang}{opt sensitivity(real 0)} specifies the anticipated sensitivity performance in the validation sample at the chosen risk threshold (specified using {opt threshold()}). 
If sensitivity and specificity are not provided then {opt pmvalsampsize} uses the simulated LP distribution from criteria 2 
and the user-specified risk threshold to estimate the anticipated sensitivity and specificity 
to be used in calculation of net benefit. 
NB: net benefit criteria is only calculated if either i) {opt sensitivity()}, {opt specificity()} and {opt threshold()} or ii) {opt threshold()} option are provided.

{phang}{opt specificity(real 0)} specifies the anticipated specificity performance in the validation sample at the chosen risk threshold (specified using {opt threshold()}). 
If sensitivity and specificity are not provided then {opt pmvalsampsize} uses the simulated LP distribution from criteria 2 
and the user-specified risk threshold to estimate the anticipated sensitivity and specificity 
to be used in calculation of net benefit. 
NB: net benefit criteria is only calculated if either i) {opt sensitivity()}, {opt specificity()} and {opt threshold()} or ii) {opt threshold()} option are provided.

{phang}{opt threshold(real 0)} specifies the risk threshold to be used for calculation of net benefit performance of the model in the validation sample. 
If sensitivity and specificity are not provided then {opt threshold()} must be given in order for {opt pmvalsampsize} to assess sample size requirements for net benefit.
NB: net benefit criteria is only calculated if either i) {opt sensitivity()}, {opt specificity()} and {opt threshold()} or ii) {opt threshold()} option are provided.

{phang}{opt nbciwidth(real 0.2)} specifies the target CI width (acceptable precision) for the standardised net benefit performance. 
Default assumes CI width=0.2. 
The choice of CI width is context specific. 
See Riley et al. for further details. 

{phang}{opt nbseincrement(real 0.0001)} sets the increment by which to iterate when identifying the SE(standardised net benefit) to meet the target CI width specified for standardised net benefit.
The default iteration increment=0.0001.
In the majority of cases this will be suitably small to ensure a precise SE is identified.
The user should check the output table to ensure that the target CI width has been attained and adjust the increment if necessary. 

{marker options}{...}
{title:Continuous outcome options}

{phang}{opt rsquared(real)} specifies the anticipated value of R-squared in the validation sample. 
This is a {bf:required input}.
May be based on the optimism-adjusted R-squared reported in the development study for the existing prediction model.
Ideally, this should be an {it: optimism-adjusted} R-squared value, not the apparent R-squared value, as the latter is optimistic (biased).

{phang}{opt rsqciwidth(real 0.1)} specifies the target CI width (acceptable precision) for the R-squared performance. 
Default assumes CI width=0.1. 

{phang}{opt citl(real 0)} specifies the anticipated value of CITL in the validation sample. 
Default conservatively assumes perfect CITL=0.

{phang}{opt citlciwidth(real 0)} specifies the target CI width (acceptable precision) for the CITL performance. 
The choice of CI width is context specific, and depends on the scale of the outcome. 
See Archer et al. for further details. 

{phang}{opt varobs(real 0)} the anticipated variance of observed values in the validation sample. 
This is a {bf:required input}.
This could again be based on the previous development study, or on clinical knowledge.

{phang}{opt mmoe(real 1.1)} multiplicative margin of error (MMOE) acceptable for calculation of the variance for c-slope and CITL in the calibration model. 
The default is a MMOE of 10%.  
See Archer et al. reference below for further information.

{marker examples}{...}
{title:Examples}

{pstd}Examples based on those included in the papers referenced below by Riley et al. & Archer et al. published in Statistics in Medicine.{p_end}

{phang}
{bf:Binary outcome models}

{pstd}Use {cmd: pmvalsampsize} to calculate the minimum sample size required to externally validate an existing multivariable prediction model for a binary outcome (e.g. mechanical heart valve failure). 
Based on previous evidence, the outcome prevalence is anticipated to be 0.018 (1.8%) and the reported c-statistic was 0.8.
The LP distribution was published and appeared normally distributed with mean(SD) of -5(2.5).
We target default CI widths for all but O/E CI width=1 (see Riley et al. for details).
We can use the {opt graph} option to check the simulated distribution is appropriate{p_end}
{phang2}{cmd:. }{stata pmvalsampsize, type(b) prev(.018) cstat(.8) lpnorm(-5 2.5) oeciwidth(1) graph}{p_end}

{pstd}On further inspection a skewed normal distribtion may be more appropriate as below:{p_end}
{phang2}{cmd:. }{stata pmvalsampsize, type(b) prev(.018) cstat(.8) lpskew(-5.8 5 -0.5 4) oeciwidth(1) graph}{p_end}

{pstd}Alternatively, lets assume that the authors provided a distribution of predicted probabilities (e.g. as part of a calibration plot).
We can use this to specify parameters for a beta distribution to simulate the LP distribution as below:{p_end}
{phang2}{cmd:. }{stata pmvalsampsize, type(b) prev(.018) cstat(.8) lpbeta(.5 .5) oeciwidth(1) graph}{p_end}

{pstd}Finally, we can use the anticipated c-statistic to simulate the event and non-event distributions assuming normality and common variances.
We input a starting value for the mean of the non-events distribution as below:{p_end}
{phang2}{cmd:. }{stata pmvalsampsize, type(b) prev(.018) cstat(.8) lpcstat(-4) oeciwidth(1) seed(1234) graph}
{p_end}

{phang}
{bf:Continuous outcome models}

{pstd}Use {cmd: pmvalsampsize} to calculate the minimum sample size required for validation of a multivariable prediction model for a continuous outcome (here, fat-free mass in children). 
We know the existing prediction model has been previously validated in a small sample with an R-squared of 0.9.
Riley et al. compute the anticipated variance of outcome values in the validation sample based on reported upper and lower quartile values deriving var(Y)=0.089 (see Riley et al. for details).
We conservatively assume perfect calibration performance at validation.
If we target a R-sq CI width=0.1, CITL CI width=0.08 and c-slope CI width=0.2, then we can run the following command:
{p_end}
{phang2}{cmd:. }{stata  pmvalsampsize, type(c) rsq(0.9) varobs(0.089) citlciwidth(0.08)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:pmvalsampsize} stores the following in {cmd:r()} as relevant for the specific outcome type chosen:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(sample_size)}}Minimum sample size required for model validation{p_end}
{synopt:{cmd:r(events)}}Minimum number of events required assuming input outcome proportion or outcome prevalence (binary models){p_end}
{synopt:{cmd:r(prevalence)}}Overall prevalence (binary models){p_end}
{synopt:{cmd:r(cstatistic)}} User-specified c-statistic (binary models){p_end}   
{synopt:{cmd:r(se_cstat)}} Standard error (SE) of c-stat based on target CI width (binary models){p_end}   
{synopt:{cmd:r(cstatciwidth)}} User-specified target CI width for c-statistic (binary models){p_end} 
{synopt:{cmd:r(oe)}} User-specified O/E (binary models){p_end}  
{synopt:{cmd:r(se_oe)}} SE of O/E based on target CI width (binary models){p_end} 
{synopt:{cmd:r(lb_oe)}} Lower CI of O/E based on target CI width (binary models){p_end} 
{synopt:{cmd:r(ub_oe)}} Upper CI of O/E based on target CI width (binary models){p_end}  
{synopt:{cmd:r(width_oe)}} User-specified target CI width for O/E (binary models){p_end}
{synopt:{cmd:r(citl)}} User-specified CITL (linear models){p_end}   
{synopt:{cmd:r(se_citl)}} SE of CITL based on target CI width (linear models){p_end}   
{synopt:{cmd:r(lb_citl)}} Lower CI of CITL based on target CI width (linear models){p_end}   
{synopt:{cmd:r(ub_citl)}} Upper CI of CITL based on target CI width (linear models){p_end}   
{synopt:{cmd:r(citlciwidth)}} User-specified target CI width for CITL (linear models){p_end}   
{synopt:{cmd:r(cslope)}} User-specified c-slope{p_end}   
{synopt:{cmd:r(se_cslope)}} SE of c-slope based on target CI width{p_end}   
{synopt:{cmd:r(lb_cslope)}} Lower CI of c-slope based on target CI width {p_end}   
{synopt:{cmd:r(ub_cslope)}} Upper CI of c-slope based on target CI width {p_end}   
{synopt:{cmd:r(csciwidth)}} User-specified target CI width for c-slope{p_end}   
{synopt:{cmd:r(rsquared)}} User-specified R-squared adjusted (linear models){p_end}   
{synopt:{cmd:r(se_rsq)}} SE of R-sq based on target CI width (linear models){p_end}   
{synopt:{cmd:r(lb_rsq)}} Lower CI of R-sq based on target CI width (linear models){p_end}   
{synopt:{cmd:r(ub_rsq)}} Upper CI of R-sq based on target CI width (linear models){p_end}   
{synopt:{cmd:r(rsqciwidth)}} User-specified target CI width for R-sq (linear models){p_end}  
{synopt:{cmd:r(non_event_mean)}}Derived mean for non-events distribution when using {opt lpcstat()} (binary models){p_end}
{synopt:{cmd:r(event_mean)}}Mean for events distribution when using {opt lpcstat()} (binary models){p_end}
{synopt:{cmd:r(common_variance)}}Common variance parameter when using {opt lpcstat()} (binary models){p_end}
{synopt:{cmd:r(tolerance)}}Tolerance for agreement between anticipated event prop. and simulated event prop. when using {opt lpcstat()} (binary models){p_end}
{synopt:{cmd:r(increment)}}Increment by which to iterate non-event mean when identifying suitable mean to meet {opt tolerance()} when using {opt lpcstat()} (binary models){p_end}
{synopt:{cmd:r(simulated_data_cstat)}}C-statistic calculated through simulation based process. Can be used to check against target c-statistic (binary models){p_end}
{synopt:{cmd:r(sensitivity)}}Sensitivity either user specified or calculated through simulation based process (binary models){p_end}
{synopt:{cmd:r(specificity)}}Specificity either user specified or calculated through simulation based process (binary models){p_end}
{synopt:{cmd:r(nb)}}Net benefit calculated using sens, spec and risk threshold (binary models){p_end}
{synopt:{cmd:r(standardised_nb)}}Standardised net benefit calculated using prevalence, sens, spec and risk threshold (binary models){p_end}
{synopt:{cmd:r(threshold)}}User specified risk threshold for net benefit (binary models){p_end}

{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}A matrix of all tabular output{p_end}
{p2colreset}{...}

{title:Authors}

{phang}Joie Ensor, University of Birmingham {break}
j.ensor@bham.ac.uk{p_end}


{title:Acknowledgements}

{phang}With thanks to Richard Riley for helpful feedback{p_end}

{marker reference}{...}
{title:References}

{p 5 12 2}
Archer L, Snell K, Ensor J, Hudda MT, Collins GS, Riley RD. 
Minimum sample size for external validation of a clinical prediction model with a continuous outcome. {it:Statistics in Medicine}. 2020.{p_end}

{p 5 12 2}
Riley RD, Debray TPA, Collins G, Archer L, Ensor J, van Smeden M, Snell KIE. 
Minimum sample size for external validation of a clinical prediction model with a binary outcome. {it:Statistics in Medicine}. 2021. {p_end}


{title:Also see}

{psee}
Online: {helpb pmsampsize}, {helpb pmcalplot}, {helpb matlist}, {helpb sknor}
{p_end}
