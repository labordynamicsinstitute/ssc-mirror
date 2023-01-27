{smcl}
{* *! version 1.0 19 Jan 2023}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help boxcoxsim" "help boxcoxsim"}{...}
{viewerjumpto "Syntax" "ros##syntax"}{...}
{viewerjumpto "Description" "ros##description"}{...}
{viewerjumpto "Examples" "ros##examples"}{...}
{viewerjumpto "Author and support" "ros##author"}{...}
{viewerjumpto "References" "ros##references"}{...}

{title:Title}
{phang}
{bf:ros} {hline 2} Regression order statistics - Estimating upper reference 
bounds for a dataset with possibly non-detectable/censored positive values and 
possibly contaminated in the upper end.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:ros}
varlist(max=1
numeric)
[{help if}]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional }

{synopt:{opt c:ensor}} A variable indicating whether a value is censored (1) or 
not (0)

{synopt:{opt noq:uietly}} Show regression output and save generated variables if 
set

{synopt:{opt p:ercentiles}} A numlist of values between 0 and 100. Specifies the 
percentiles to estimate. The values will be sorted. Default values are 50 75 90 95 99

{synopt:{opt sc:atter}} Generates a {help qnorm:qnorm} scatter plot as model control.
The observed values should either be on a straight line. 
Or at least the first part should be.

{synopt:{opt rs:qrtheta}} Generates a line plot of adjusted R squares by thetas
(Box-Cox transformation). The thetas with the highest R squares are the best 
Box-Cox transformations.

{synopt:{opt t:heta(#)}} for the choice of Box-Cox transformation, default = 1.

{synopt:{opt s:tart(#)}} Start value for the theta's in the {opt rs:qrtheta} graph.
The default value is 0.

{synopt:{opt st:ep(#)}} Step value for the theta's in the {opt rs:qrtheta} graph.
The default value is 0.25.

{synopt:{opt e:nd(#)}} end value for the theta's in the {opt rs:qrtheta} graph.
The default value is 2.

{synopt:{opt twoway options}} Add twoway graph options to the {help qnorm:qnorm} 
scatter plot

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}The command {cmd:ros} is for estimating upper reference bounds for a 
dataset with possibly non-detectable/censored values and possibly 
contaminated in the upper end.

{pstd}The upper reference bounds are from the mean and standard deviation from 
regressing the observed values on the empirical (normal) z-values.
The mean and the standard deviation estimated from {cmd:ros} are the intercept 
and slope of the regression.
Box-Cox optimization is done by choosing a transformation with a high R square 
from the regressions.

{pstd}A dataset can have non-detectable/censored values to the left and can also be 
contaminated to right by non-healthy participants, so it might be only a 
small linear part of the {help qnorm:qnorm} scatter plot that is acceptable for 
estimation.
This means that some of the estimated upper bounds are extrapolations from the 
acceptable part.
The estimated, not extrapolated, upper bounds, are similar to the empirical 
percentiles.

{pstd}The Ideas behind the command {cmd:ros} were demonstrated at the
{browse "https://www.stata.com/meeting/northern-european22/slides/Northern_Europe22_Bruun.pdf" :2022 Northern European Stata Conference on 12 October in Oslo}.
The {cmd:ros} is inspired by the work in the references.
However, more tools for model control, the rsquare for goodness of fit, 
the rsquare theta plot, and the {help qnorm:qnorm} scatter plot are available.

{pstd}The only modification from the presentation is that the Box-Cox 
transformation here is defined as: bct(x; theta) = x^theta / abs(theta) 
if theta != 0 and bct(x; 0) = log(x).
This modification means that negative thetas can be included in the Box-Cox 
transformations.


{marker examples}{...}
{title:Examples}

{phang}Below are some examples of how to assess a dataset using {cmd:ros}.
It is worth noting that when using {cmd:ros} there is no correct model, 
but sometimes there is a useful model.


{dlgtab:Real data example}

{phang}The first dataset is from Huston (2009). It is used to show that using 
the log as a default transformation is a mistake.{break}
Using log as a default transformation is what has been recommended in, e.g., 
Helsel (2010) and Hewett and Ganser (2009){p_end}
{phang}Get the data (Can retrieved together with this package).{p_end}
{phang}{stata `". use "savona (NADA).dta", clear"'}{p_end}
{phang}Get a description of the dataset.{p_end}
{phang}{stata `". notes"'}{p_end}
{phang}Rescale the measured concentrations with a factor 1000.{p_end}
{phang}{stata `". replace concentration = 1000 * concentration"'}{p_end}
{phang}Use the log transformation as done in Huston (2009), Helsel (2010), 
and Hewett and Ganser (2009).{p_end}
{phang}{stata `". ros concentration, censor(censored) theta(0) rsqrtheta scatter"'}{p_end}

    Adjusted Rsquared is 0.8653
    
    ------------------------------------------------
                              Estimate     Empirical
    ------------------------------------------------
    theta(0.000)                                    
                    P50%          2.85          2.00
                    P75%          4.77          6.00
                    P90%          7.59          7.00
                    P95%         10.01          8.35
                  P97.5%         12.74          9.00
                    P99%         16.85          9.00
    ------------------------------------------------
    
    --------------------------------------
          R2 adj         theta     optimal
    --------------------------------------
           0.865         0.000           .
           0.881         0.250           .
           0.894         0.500           .
           0.906         0.750           .
           0.915         1.000           .
           0.921         1.250           .
           0.923         1.500           1
           0.921         1.750           .
           0.916         2.000           .
    --------------------------------------

{phang}There is a relatively poor fit (rsquare = 0.8653). 
This is also seen in the differences between the estimated (from {cmd:ros}) 
and the empirical (from {help centile:centile}).
Note that the best is with a rsquare at 0.923 at theta equal to 1.5.{break}
Looking at the {help qnorm:qnorm} scatter plot, there is no indication of a 
mixture of distributions.{break}
The Box-Cox transformation 1.5 is tried.
{p_end}
{phang}{stata `". ros concentration, censor(censored) theta(1.5) rsqrtheta scatter"'}

    Adjusted Rsquared is 0.9228
    
    ------------------------------------------------
                              Estimate     Empirical
    ------------------------------------------------
    theta(1.500)                                    
                    P50%          3.42          2.00
                    P75%          5.61          6.00
                    P90%          7.26          7.00
                    P95%          8.16          8.35
                  P97.5%          8.90          9.00
                    P99%          9.73          9.00
    ------------------------------------------------

{phang}The estimated and empirical percentiles are similar, although the 
empirical median and the empirical 99% percentile are underestimated.{break}
The estimated percentiles using the log transformation appear to be too high.
{p_end}


{dlgtab:Simulated data example 1}

{phang}A log-normal data set of size 200 is created with a mean of 2 and a 
standard deviation of 1 for the log-transformed data, 
see {help boxcoxsim:boxcoxsim}.{p_end}
{phang}{stata `". boxcoxsim, n(200) nd(0) theta(0) mean(4) sd(1) outlierpct(0) clear"'}{p_end}
{phang}To visualize the data set.{p_end}
{phang}{stata `". hist yc, norm ylabel(none) xtitle(normal values)"'}{p_end}
{phang}Run the {cmd:ros} command to assess the data{p_end}
{phang}{stata `". ros yc, censor(censored) rsqrtheta scatter start(-1)"'}{p_end}
{phang}The adjusted rsquare is low.{p_end}
{phang}From the log window and the rsqrtheta graph, one can see that the log 
transformation (theta = 0) is best.{p_end}
{phang}The curve in the {help qnorm:qnorm} scatter plot is a typical log curve 
indicating the need for the log transformation.{p_end}
{phang}The log transformation is used in the {cmd:ros} command.{p_end}
{phang}{stata `". ros yc, censor(censored) rsqrtheta scatter start(-1) theta(0)"'}{p_end}
{phang}The rsqrtheta graph indicates that the log transformation (theta = 0) 
is best.{p_end}
{phang}The curve in the {help qnorm:qnorm} scatter plot is linear.{p_end}
{phang}In the log window, there is quite a difference between the estimated and 
the empirical percentiles. In this case, the estimated percentiles should be 
used for upper bounds.


{dlgtab:Simulated data example 2}

{phang}A log-normal data set of size 200 is created with a mean of 1.5 and a 
standard deviation of 0.3 for the power 4 transformation data, 
see {help boxcoxsim:boxcoxsim}.{p_end}
{phang}{stata `". boxcoxsim, n(200) nd(0) theta(4) mean(1.5) sd(0.3) outlierpct(0) clear"'}{p_end}
{phang}To visualize the data set.{p_end}
{phang}{stata `". hist yc, norm ylabel(none) xtitle(normal values)"'}{p_end}
{phang}Run the {cmd:ros} command to assess the data{p_end}
{phang}{stata `". ros yc, censor(censored) rsqrtheta scatter start(-1)"'}{p_end}
{phang}The curve in the {help qnorm:qnorm} scatter plot is not linear.{p_end}
{phang}The rsqrtheta graph identifies the correct inverse transformation 
(theta = 0.25) as optimal.{p_end}
{phang}Run the {cmd:ros} command with the optimal theta (0.25).{p_end}
{phang}{stata `". ros yc, censor(censored) rsqrtheta scatter start(-1) theta(0.25)"'}{p_end}
{phang}The curve in the {help qnorm:qnorm} scatter plot is now linear.{p_end}
{phang}The rsqrtheta graph identifies the correct inverse transformation 
(theta = 0.25) as optimal.{p_end}


{dlgtab:Simulated data example 3}

{phang}A log-normal data set of size 200 is created with a mean of 5 and a 
standard deviation of 1 for the log-transformed data, 
see {help boxcoxsim:boxcoxsim}.{break}
There are 55% of the observations below the lower detection line.{p_end}
{phang}{stata `". boxcoxsim, n(200) nd(55) theta(0) mean(4) sd(1) outlierpct(0) clear"'}{p_end}
{phang}To visualize the data set.{p_end}
{phang}{stata `". hist yc, norm ylabel(none) xtitle(normal values)"'}{p_end}
{phang}Run the {cmd:ros} command to assess the data{p_end}
{phang}{stata `"ros yc, censor(censored) rsqrtheta scatter start(-1)"'}{p_end}
{phang}The curve in the {help qnorm:qnorm} scatter plot is curved like a log function.{p_end}
{phang}The rsqrtheta graph identifies the correct inverse transformation 
(theta = 0, ie the log) as optimal.{p_end}
{phang}Run the {cmd:ros} command with the optimal theta (0).{p_end}
{phang}{stata `"ros yc, censor(censored) rsqrtheta scatter theta(0) start(-1)"'}{p_end}
{phang}This verifies our assessments.{p_end}


{dlgtab:Simulated data example 4}

{phang}A normal data set of size 200 is created with a mean of 5 and a standard 
deviation of 1, see {help boxcoxsim:boxcoxsim}.{break}
There are 40% of the observations below the lower detection line.{break}
The upper 30% are outliers and the outlier distribution is normal with a mean of 11
and a standard deviation of 2.{p_end}
{phang}{stata `". boxcoxsim, n(200) nd(40) mean(5) sd(1) outlierpct(30) omean(11) osd(2) clear"'}{p_end}
{phang}Run the {cmd:ros} command to assess the data{p_end}
{phang}{stata `". ros yc, censor(censored) rsqrtheta scatter"'}{p_end}
{phang}The curve in the {help qnorm:qnorm} scatter plot is quite linear with some 
curvature around the line.{break}
The curvatures around the line could indicate a mixture of models.{break} 
Comparing the estimated and the empirical percentiles in the log window suggests
that a good cut-off would be between 5.5 and 6.5. The value 6 is tried.
{p_end}
{phang}In the rsqrtheta graph, there is little difference between the lowest and 
highest rsquare, so most transformations would do. We choose the value 1.{p_end}
{phang}Run the {cmd:ros} command to assess data with some contamination by outliers.{p_end}
{phang}{stata `". ros yc if yc < 6, censor(censored) scatter"'}{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(r2_a)}} The adjusted R square from the ROS estimation. {p_end}
{synopt:{cmd:r(rosmean)}} The estimated mean from ROS.{p_end}
{synopt:{cmd:r(rossd)}} The estimated standard deviation from ROS. {p_end}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(ros)}} Returned cut-off values as specified in option {opt p:ercentiles}. {p_end}
{synopt:{cmd:r(rsqrtheta)}} Returned point values for the {opt rs:qrtheta} graph. {p_end}


{marker author}{...}
{title:Author and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}

{phang}{bf:Development in collaboration with:}{break}
 	Stine Linding Andersen, {break}
  Department of Clinical Biochemistry, {break}
  Aalborg University Hospital
  
{phang}{break}Nanna Maria Uldall Torp, {break}
  Department of Clinical Biochemistry, {break}
  Aalborg University Hospital
  
{phang}{break}Peter Astrup Christensen, {break}
  Department of Clinical Biochemistry, {break}
  Aalborg University Hospital {break}
{p_end}


{marker references}{...}
{title:References}

{phang}Helsel, Dennis. 2010. "Much Ado About Next to Nothing: Incorporating Nondetects in Science."{break}
The Annals of Occupational Hygiene 54 (April): 257–62. {browse "https://doi.org/10.1093/annhyg/mep092" :"https://doi.org/10.1093/annhyg/mep092"}.

{phang}Hewett, Paul, and Gary Ganser. 2007. "A Comparison of Several Methods for Analyzing Censored Data."{break}
The Annals of Occupational Hygiene 51 (November): 611–32. {browse "https://doi.org/10.1093/annhyg/mem045" :"https://doi.org/10.1093/annhyg/mem045"}.

{phang}Hoffmann, Robert G. 1963. "Statistics in the Practice of Medicine." JAMA 185 (11): 864–73.
{browse "https://doi.org/10.1001/jama.1963.03060110068020" :"https://doi.org/10.1001/jama.1963.03060110068020"}.

{phang}Huston, C., and E. Juarez-Colunga. 2009. "Guidelines for Computing Summary Statistics for Data-Sets Containing Non-Detects."
{browse "https://bvcentre.ca/files/research_reports/08-03GuidanceDocument.pdf" :"https://bvcentre.ca/files/research_reports/08-03GuidanceDocument.pdf"}.

{phang}Jensen, Esther A., Per Hyltoft Petersen, Ole Blaabjerg, Pia Skov Hansen, Thomas H. Brix, and Laszlo Hegedüs. 2006. "Establishment of
Reference Distributions and Decision Values for Thyroid Antibodies Against Thyroid Peroxidase (Tpoab), Thyroglobulin (Tgab) and
the Thyrotropin Receptor (Trab)." Clinical Chemistry and Laboratory Medicine (CCLM) 44 (8): 991–98.
{browse "https://doi.org/doi:10.1515/CCLM.2006.166" :"https://doi.org/doi:10.1515/CCLM.2006.166"}.
