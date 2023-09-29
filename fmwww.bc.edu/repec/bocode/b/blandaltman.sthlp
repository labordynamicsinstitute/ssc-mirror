{smcl}
{* *! version 1.1  2023-09-27 Mark Chatfield}{...}
{viewerjumpto "Syntax" "blandaltman##syntax"}{...}
{viewerjumpto "Description" "blandaltman##description"}{...}
{viewerjumpto "Remarks" "blandaltman##remarks"}{...}
{viewerjumpto "Examples" "blandaltman##examples"}{...}
{viewerjumpto "Stored results" "blandaltman##stored_results"}{...}
{viewerjumpto "References" "blandaltman##references"}{...}
{viewerjumpto "Author" "blandaltman##author"}{...}
{viewerjumpto "Acknowledgements" "blandaltman##acknowledgements"}{...}
{viewerjumpto "Also see" "blandaltman##alsosee"}{...}
{title:Title}

{phang}
{bf:blandaltman} {hline 2} Bland-Altman plots featuring differences or %differences or ratios, with options to add a variety of lines and intervals


{marker syntax}{...}
{title:Syntax}

{phang}
{opt blandaltman} {it:varA varB} {ifin}{cmd:,} 
{cmdab:plot(}{it:plot_type_list}{cmd:)} 
[{cmdab:h:orizontal}
{opt noregloa} 
{opt noreg:bias} 
{opt hloa} 
{opt hbias} 
{cmdab:l:evel(}{it:#}{cmd:)} 
{opt predint:erval} 
{cmdab:ticonf:idence(}{it:#}{cmd:)}  
{cmdab:ticonfidence2(}{it:#}{cmd:)} 
{cmdab:ticonfidence3(}{it:#}{cmd:)} 
{opt ciloa} 
{opt cibias} 
{cmdab:cilevel(}{it:#}{cmd:)} 
{it: minor_options}]

{phang}
where {it:plot_type_list} is any combination of {it:plot_types}:{p_end}

{synoptset 18}{...}
{marker column}{...}
{synopthdr :plot_type }
{synoptline}
{synopt :{opt difference}}A-B is plotted on the y-axis,  Mean(A,B) on the x-axis{p_end}
{synopt :{opt percentmean}}100(A-B)/Mean(A,B) is plotted on the y-axis,  Mean(A,B) on the x-axis{p_end}
{synopt :{opt percentlmean}}100(A-B)/LMean(A,B) = 100(lnA-lnB) is plotted on the y-axis,  GMean(A,B) on the x-axis*{p_end}
{synopt :{opt ratio}}A/B is plotted on the y-axis,  GMean(A,B) on the x-axis*{p_end}
{synoptline}
{p 4 4}
*When A>0 and B>0, GMean(A,B) = sqrt(A*B) is the Geometric Mean, 
and LMean(A,B) = (A-B)/(lnA-lnB) is the Logarithmic Mean (LMean(A,B) = A if A=B){p_end}


{synoptset 18 tabbed}{...}
{marker synoptions}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt: {opt h:orizontal}}display horizontal rather than regression-based limits of agreement and bias. 
Equivalent to specifying: {cmd:noregloa noregbias hloa hbias}{p_end}   
{synopt: {opt noregloa}}prevent display of regression-based limits of agreement{p_end}	 
{synopt: {opt noreg:bias}}prevent display of regression-based bias and limits of agreement{p_end}  
{synopt: {opt hloa}}display horizontal limits of agreement{p_end} 
{synopt: {opt hbias}}display horizontal bias (i.e. average difference or %difference or ratio). 
This option is assumed whenever horizontal limits of agreements or a prediction interval or a tolerance interval is requested.{p_end} 
{synopt: {opt l:evel(#)}}specifies the level, in percent, for #% limits of agreement,
#% prediction interval, #% tolerance interval with ticonf% confidence. The default is {cmd:level(95)}.{p_end}
{synopt: {opt predint:erval}}display (horizontal) lines for a level% prediction interval{p_end}  
{synopt: {opt ticonf:idence(#)}}display (horizontal) lines for a level% tolerance interval with #% confidence{p_end}
{synopt: {opt ticonfidence2(#)}}display (horizontal) lines for a second level% tolerance interval with #% confidence{p_end}
{synopt: {opt ticonfidence3(#)}}display (horizontal) lines for a third level% tolerance interval with #% confidence{p_end}
{synopt: {opt ciloa}}display (exact) cilevel% confidence intervals for the (horizontal) limits of agreement. 
Requires {cmd:horizontal} or {cmd:hloa} to also be specified.{p_end}
{synopt: {opt cibias}}display a cilevel% confidence interval for the (horizontal) bias.
Requires {cmd:horizontal} or {cmd:hbias} to also be specified.{p_end} 
{synopt: {opt cilevel(#)}}specifies the level, in percent, for confidence intervals for the bias and limits of agreement. 
The default is {cmd:cilevel(95)}.{p_end}

{syntab:Minor}
{synoptset 38 tabbed}{...}
{synopt: {cmd: scopts(}{it:{help scatter:scatter_options}{cmd:)}}}alter the display of the scatterplot{p_end}	
{synopt: {cmd: regloaopts(}{it:{help twoway function:tw_function_options}{cmd:)}}}alter the display of the regression-based limits of agreement{p_end}
{synopt: {cmd: regbiasopts(}{it:{help twoway function:tw_function_options}{cmd:)}}}alter the display of the regression line{p_end} 
{synopt: {cmd: loaopts(}{it:{help twoway function:tw_function_options}{cmd:)}}}alter the display of the horizontal limits of agreement{p_end}
{synopt: {cmd: biasopts(}{it:{help twoway function:tw_function_options}{cmd:)}}}alter the display of the horizontal bias line{p_end} 
{synopt: {cmd: piopts(}{it:{help twoway function:tw_function_options}{cmd:)}}}alter the display of the prediction interval {p_end} 
{synopt: {cmd: tiopts(}{it:{help twoway function:tw_function_options}{cmd:)}}}alter the display of the first tolerance interval {p_end}
{synopt: {cmd: tiopts2(}{it:{help twoway function:tw_function_options}{cmd:)}}}alter the display of the second tolerance interval {p_end}
{synopt: {cmd: tiopts3(}{it:{help twoway function:tw_function_options}{cmd:)}}}alter the display of the third tolerance interval {p_end}
{synopt: {cmd: ciloaopts(}{it:{help twoway pcarrowi:tw_pcarrowi_options}{cmd:)}}}alter the display of the confidence interval for the limits of agreement{p_end} 
{synopt: {cmd: cibiasopts(}{it:{help twoway pcarrowi:tw_pcarrowi_options}{cmd:)}}}alter the display of the confidence interval for the bias{p_end} 
{synopt: {cmd: addplot(}{it:plot} ... [|| {it:plot} ... [...]]{cmd:)}}plot may be any subcommand of {help graph twoway:graph twoway}, such as {help twoway function:function}{p_end} 
{synopt: {it:{help twoway_options}}}titles, legends, axes, added lines and text, regions, name, aspect ratio, etc.
by() warning: any lines, intervals and stats are NOT calculated separately for each subset{p_end} 
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
As described in {browse "https://doi.org/10.1177/1536867X231196488":Chatfield et al. (2023)}, {cmd:blandaltman} produces Bland-Altman plots featuring 
(a) difference, (b) percentage difference or (c) ratio on the y-axis, 
and (arithmetic or geometric) mean on the x-axis. 
By default, regression-based bias and limits of agreement are produced in order to help everyone 
see how the distribution of (a), (b) or (c) varies with the average of the paired measurements 
(this is a key purpose of a Bland-Altman plot). 
Horizontal lines for bias and limits of agreement can be produced instead. 

{pstd} 
This is the first community-contributed Bland-Altman plot command in Stata allowing display of 
confidence intervals for the bias and limits of agreement,
as well as a prediction interval and (up to 3) tolerance intervals, 
assuming the distribution of (a), (b) or log (c) is normal and has no relationship with the magnitude of the measurements. 

{pstd}
Logarithmically-scaled axes are used (i) for both axes when ratios are plotted against the geometric mean, 
(ii) for the x-axis when percentage differences are plotted against the (arithmetic or geometric) mean.


{marker remarks}{...}
{title:Remarks}

{pstd}The following 3 plots are equivalent (they differ only in their axis labelling):{p_end}

{pstd}{cmd:   . blandaltman lnvarA lnvarB, plot(difference)}{p_end} 
{pstd}{cmd:   . blandaltman varA varB, plot(ratio)}{p_end} 
{pstd}{cmd:   . blandaltman varA varB, plot(percentlmean)}{p_end} 
{pstd}For more on {cmd:percentlmean} see {browse "https://doi.org/10.1177/1536867X231196488":Chatfield et al. (2023)}, 
and references therein.

{pstd}The following plot will often be very similar (this plot is commonly used with lab measures){p_end} 
{pstd}{cmd:   . blandaltman varA varB, plot(percentmean)}{p_end} 

{pstd}
Bland and Altman (1999) described a {cmd:regression-based approach to describe the bias and 95% limits of agreement} 
on a plot of difference (A-B) against the mean of the paired measurements.
Their method has been adapted for plots featuring percentage differences or ratios:{p_end} 
{phang2}{opt percentmean} ... the first regression is %difference on ln(Mean(A,B)){p_end}
{phang2}{opt percentlmean} ... the first regression is %difference on ln(GMean(A,B)){p_end}
{phang2}{opt ratio} ... the first regression is ln(A/B) on ln(GMean(A,B)){p_end}
{pstd}The first regression equation can be interpreted as an equation for the Bias 
of difference or %difference or ln(A/B). 
After the first regression, residuals are calculated, their absolute values taken, 
then adjusted by multiplying by sqrt(_pi/2). A second regression then takes place using
these adjusted absolute residuals. This allows the resulting regression equation
to be interpreted as an equation for the SD of difference or %difference or ln(A/B).
Equations for 95% LoA are then: Bias_equation ± 1.96 SD_equation.
Note an equation lnR = b0 + b1 × ln(GMean(A,B)) can be re-written as R = exp(b0) × GMean(A,B)^b1.
{p_end}

{pstd}
As well as reporting limits of agreement, Bland and Altman (1999) proposed 
calculating a {cmd:95% CI around each of the 95% limits of agreement}
and this advice features in reporting standards for Bland-Altman agreement analysis (Gerke 2020). 
While Bland and Altman described how to calculate approximate 95% CIs, 
there exists an exact method based on the noncentral t distribution 
(Carkeet 2015, Meeker et al. 2017, Shieh 2018) which is implemented here.
It is an oversight of {help centile:[R] centile} that this exact method is not available.
The 2021 revision of the {cmd: tolerance} command ({stata "ssc install tolerance"}) 
calculates CIs for the limits of agreement (i.e. 2.5th and 97.5th normal percentiles), 
as well as prediction and tolerance intervals.

{pstd}
Some authors have disagreed with some of Bland and Altman's recommendations, and 
have recommended that prediction intervals and tolerance intervals be used 
(Ludbrook 2010, Vock 2016, Carkeet and Goh 2018, Francq, Berger and Boachie 2020), 
though their recommendations vary quite a bit.
Royston and Matthews (1991) considered all these for how to best estimate a 95% reference range from a normal sample -
they favoured mean ± 1.96 sd, the same as Bland and Altman. 

{pstd}
A {hi:95% prediction interval} is an interval where a future measurement is expected to lie, with a given confidence {cmd:level} 
(Meeker et al. 2017, Vardeman 1992). It is equivalent to a {hi:95%-expectation tolerance interval}, 
which is an interval that contains 95% of the population, on average.

{pstd}
A {hi:95% tolerance interval with #% confidence} is an interval that contains at least 95% of a population, with #% confidence (Vangel 2005, Vardeman 1992). 
Howe (1969)'s λ_3 formula is used.

{pstd}
Ratios can be lognormally distributed, in which case the geometric (or multiplicative) 
mean and standard deviation can be reported as: GMean ×/ GSD (Limpert and Stahel 2011).

{pstd}
Cox (2018) discusses labelling logarithmically scaled axes in detail. 
The command {cmd:niceloglabels} can be helpful here (Cox 2018, 2020). 
I have made use of some of it inside {cmd:blandaltman} in an attempt to provide publication ready graphs.
Labelling that I consider "nice" may not be labelling that you consider "nice".
You might prefer to specify different value labels and ticks, by specifying e.g. xlabel() and xtick().



{marker examples}{...}
{title:Examples}

{pstd}To run these examples you will have to change directory to where you installed the datasets associated with the command {cmd:blandaltman} 
(assuming you installed the datasets as well as the command).{p_end}

    {title:The 4 types of Bland-Altman plots that are readily created with blandaltman}

{pstd}This example also helps the user to decide whether heteroscedasticity is evident in a plot featuring differences or %differences (or ratios) {p_end}	
{phang2}{sf:. }{stata `"use http://fmwww.bc.edu/repec/bocode/l/labmeasures.dta, clear"'}{p_end}

{phang2}{sf:. }{stata "blandaltman plexrbp4µmoll nimanurbp4µmoll, plot(difference percentmean percentlmean ratio)"}{p_end}

{pstd}After seeing the output from the above command, it could be assumed that 
the distribution of percentage differences or ratios does not 
vary with the magnitude of the measurements. If the user is happy to also assume normality
of percentage differences or log ratios, one of these plots might be preferred:{p_end}	
{phang2}{sf:. }{stata "blandaltman plexrbp4µmoll nimanurbp4µmoll, plot(percentmean percentlmean ratio) horizontal ciloa cibias"}{p_end}

{pstd}Numbers or equations can be added using {cmd:text()}. Note, the range of the x-axis has also been increased:{p_end}
{phang2}{sf:. }{stata `"blandaltman plexrbp4 nimanurbp4, plot(percentmean) h ciloa cibias xscale(range(6)) text(23 4.5 "23%" "(20% to 28)") text(-44 4.5 "-44%" "(-48% to -40%)") text(-10 4.5 "-10%" "(-12% to -8)")"'}{p_end}

    {title:Other intervals that can be displayed with blandaltman}

{pstd}
This example gives a flavour of what other intervals are possible to display,  
assuming the distribution of differences (or percentage differences or log ratios) is normal and does not vary with the magnitude of the measurements.
You won't want them all! See Remarks. 
Bland and Altman's (1986) PEFR dataset is used. {p_end}

{phang2}{sf:. }{stata `"use http://fmwww.bc.edu/repec/bocode/p/PEFR.dta, clear"'}{p_end}

{phang2}{sf:. }{stata `"blandaltman Wright Mini, plot(difference) h ciloa cibias predint ticonf(95) loaopts(lc(red)) ciloaopts(mc(red) lc(red)) legend(on order(2 "Bias (& 95% CI)" 4 "95% LoA (& 95% CI)" 6 "95% PI" 8 "95% TI with 95% conf."))"'}
{p_end}

{pstd}Note. legend(on) needed to be used as an option prior to knowing how to write the more complicated {cmd:legend()} specification above.{p_end}


{marker stored_results}{...}
{title:Stored results}

{pstd}
With the exception of some of the regression output, {cmd:blandaltman} stores every element of its output in {cmd:r()}:

{phang2}{sf:. }{stata `"return list"'}{p_end}


{marker references}{...}
{title:References}

{phang}Bland, J. M. and D. G. Altman. 1986. Statistical methods for assessing agreement between two methods of clinical measurement. Lancet 327: 307–10. {p_end} 
{phang}Bland, J. M. and D. G. Altman. 1999. Measuring agreement in method comparison studies. Statistical Methods in Medical Research 8: 135-160.{p_end} 
{phang}Carkeet, A. 2015. Exact parametric confidence intervals for Bland–Altman limits of agreement. Optometry and Vision Science 92: e71–e80.{p_end} 
{phang}Carkeet, A. and Y. T. Goh. 2018. Confidence and coverage for Bland–Altman limits of agreement and their approximate confidence intervals. Statistical Methods in Medical Research 27: 1559-1574.{p_end} 
{phang}Chatfield, M. 2021. Tolerance: Stata module to calculate tolerance intervals (normal distribution). Statistical Software Components S459009, Boston College Department of Economics.{p_end} 
{phang}{browse "https://doi.org/10.1177/1536867X231196488":Chatfield M. D., Cole T. J., de Vet H. C. W., Marquart-Wilson L. and D. M. Farewell. 2023. blandaltman: A command to create variants of Bland-Altman plots. Stata Journal 23: 851-874.}

{phang}Cox, N. J. 2018. Speaking Stata: Logarithmic binning and labelling. Stata Journal 18: 262–286.{p_end} 
{phang}Cox, N. J. 2020. Software update for niceloglabels. Stata Journal 20: 1028-1030.{p_end} 
{phang}Francq, B. G., M. Berger and C. Boachie. 2020. To tolerate or to agree: A tutorial on tolerance intervals in method comparison studies with BivRegBLS R Package. Statistics in Medicine 39: 4334-4349.{p_end} 
{phang}Gerke, O. 2020. Reporting standards for a Bland-Altman agreement analysis: a review of methodological reviews. Diagnostics 10: 334.{p_end} 
{phang}Howe, W. G. 1969. Two-sided tolerance limits for normal populations - some improvements. Journal of the American Statistical Association 64: 610–620.{p_end} 
{phang}Limpert, E. and W. A. Stahel. 2011. Problems with using the normal distribution – and ways to improve quality and efficiency of data analysis. PLoS ONE 6: e21403.{p_end} 
{phang}Ludbrook, J. 2010. Confidence in Altman–Bland plots: a critical review of the method of differences. Clinical and Experimental Pharmacology and Physiology 37: 143–149.{p_end} 
{phang}Meeker, W. Q., G. J. Hahn and L. A. Escobar. 2017. Statistical Intervals: A guide for practitioners and researchers. Second edition. John Wiley & Sons, Inc.{p_end} 
{phang}Royston, P. and J. N. S Matthews. 1991. Estimation of reference ranges from normal samples. Statistics in Medicine 10: 691-695.{p_end} 
{phang}Shieh, G. 2018. The appropriateness of Bland-Altman's approximate confidence intervals for limits
of agreement. BMC Medical Research Methodology 18:45.{p_end} 
{phang}Vangel, M. G. 2005. Tolerance Interval. In The Encyclopedia of Biostatistics, 2nd Edition, edited by P. Armitage and T. Colton. John Wiley & Sons, Ltd.{p_end} 
{phang}Vardeman, S. B. 1992. What about the Other Intervals? The American Statistician 46: 193-197.{p_end}

{phang}Vock, M. 2016. Intervals for the assessment of measurement agreement: Similarities, differences, and consequences of incorrect interpretations. Biometrical Journal 58, 489–501.{p_end}


{marker author}{...}
{title:Author}

{p 4 4 2}
Mark Chatfield, The University of Queensland, Australia.{break}
m.chatfield@uq.edu.au{break}


{marker acknowledgements}{...}
{title:Acknowledgements}

{p 4 4 2}
I have incorporated some of the syntax from the {cmd:niceloglabels} command (Cox 2018, 2020), 
and the expanded and corrected version of the {cmd:tolerance} command (Chatfield 2021). 

{p 4 4 2}
Over the years, I have used Adrian Mander's {cmd:batplot} command to visually assess heteroscedasticity in a plot of differences against means.
{cmd:blandaltman} extends this for plots featuring %differences or ratios. 


{marker alsosee}{...}
{title:Also see}

{p 7 14 2}
Help: {helpb niceloglabels} (if installed), 
{helpb tolerance} (if 2021 not 2006 version installed), 
{helpb concord} (if installed), {helpb kappaetc} (if installed), 
{helpb rmloa} (if installed), {helpb biasplot} (if installed), 
{helpb pairplot} (if installed), {helpb batplot} (if installed), 
{helpb baplot} (if installed), {helpb agree} (if installed){p_end}
