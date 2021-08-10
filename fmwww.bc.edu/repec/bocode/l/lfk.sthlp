{smcl}
{* 09abr2020}{...}
{cmd:help lfk}{right: ({browse "https://www.epigear.com/index_files/metaxl.html"})}
{hline}

{title:Title}

{pstd} {cmd:lfk} {hline 2} LFK index and Doi plot for detection of publication bias in meta-analysis



{title:Syntax}

{p 8 14 2} {cmd: lfk} {it:varlist} {ifin} [, options]
	
{pstd} As in {helpb admetan}, {it:varlist} should contain either four or two variables in the form of:

{pstd} Four variables:

{p2col 9 52 44 2:{it:t_cases} {it:t_non-cases} {it:c_cases} {it:c_non-cases}} cell counts from 2x2 contingency table

{pstd} Two variables:

{p2col 9 52 53 2:{it:ES} {it:seES}} effect size and standard error. It is recommended that ratio-based effect estimates are log transformed.



{title:Description}

{pstd} {cmd:lfk} generates the Doi plot and estimates the LFK index to detect and quantify asymmetry of study effects.
The Doi plot replaces the conventional scatter (funnel) plot of precision versus effect with a folded normal quantile (Z-score) versus effect plot.
The studies form the limbs of this plot, if there is asymmetry there will be unequal deviation of both limbs of the plot from the mid-point or more studies making up one limb compared to the other.
In the absence of asymmetry, it would be expected that a perpendicular line to the X-axis from the tip of the Doi plot would divide the plot into two regions with similar areas.
The LFK index quantifies the difference between these two regions in terms of their respective areas under the plot and the difference in the number of studies included in each limb.
The closer the value of the LFK index to zero, the more symmetrical the Doi plot.
LFK index values outside the interval between -1 and +1 are deemed consistent with asymmetry (i.e. publication bias).



{title:Options}

{pstd} {cmd:or} (the default for binary data) uses odds ratios as the effect estimate of interest.

{pstd} {cmd:rr} specifies that risk ratios rather than odds ratios as the effect estimate. 

{pstd} {cmd:nograph} suppresses the Doi plot. 



{title:Saved results}

{synoptset 25 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(lfk)}}Value of LFK index{p_end}



{title:Examples}

{phang2}{cmd:. lfk event_treat noevent_treat event_ctrl noevent_ctrl, or} {p_end}
{phang2}{cmd:. lfk es se_es, nograph} {p_end}



{title:Authors}

{pstd} Luis Furuya-Kanamori, Research School of Population Health, Australian National University, Australia{p_end}
{pstd} {browse "mailto:luis.furuya-kanamori@anu.edu.au?subject=LFK Stata enquiry":luis.furuya-kanamori@anu.edu.au}{p_end}

{pstd} Suhail AR Doi, Department of Population Medicine, College of Medicine, Qatar University, Qatar


	
{title:Reference}

{pstd} Furuya-Kanamori L, Barendregt JJ, Doi SAR. 2018.  A new improved graphical and quantitative method for detecting bias in meta-analysis. {it:Int J Evid Based Healthc} 16: 195-203.



{title:Funding}

{pstd} This work was supported by Program Grant #NPRP10-0129-170274 from the Qatar National Research Fund (a member of Qatar Foundation). The findings herein reflect the work and are solely the responsibility of the authors.
{pstd} LFK was supported by an Australian National Health and Medical Research Council Fellowship (APP1158469).
