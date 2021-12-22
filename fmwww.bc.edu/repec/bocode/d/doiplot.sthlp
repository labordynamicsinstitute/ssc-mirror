{smcl}
{* 25oct2021}{...}
{cmd:help doiplot}{right: (See also: {browse "https://www.epigear.com/index_files/metaxl.html"})}
{hline}



{title:Title}

{pstd} {cmd:doiplot} {hline 2} A postestimation program after {helpb metan} for the visualization of asymmetry and heterogeneity in meta-analysis



{title:Syntax}

{p 8 14 2} {cmd: doiplot} {it:varlist} {ifin} [, options]
	
{pstd} {it:varlist} should contain the two variables created by a prior run of  {helpb metan} as part of the {it:result set} in the form of:

{p2col 9 22 23 3:{it:_ES} {it:_seES}}    (effect size and standard error) {it:Ratio-based or proportion effect estimates will automatically be appropriately transformed by} {helpb metan}.



{title:Description}

{pstd} {cmd:doiplot} generates the Doi plot and its variants (combinations with the funnel and Galbraith plots). 
The plots also include the LFK index and Egger's test P-value as a note. 
The Doi plot replaces the conventional scatter (funnel) plot of precision versus effect with a folded normal quantile (Z-score) versus effect plot. 
Combined with the Galbraith plot, the Doi-Galbraith plot delivers a combined graphical overview of both study symmetry and heterogeneity at a glance. 



{title:Options}

{pstd} {cmd:dg} (the default) plots an overlay of the Doi plot and Galbraith plot with a note reporting the LFK index.

{pstd} {cmd:df} plots an overlay of the Doi plot and the funnel plot with a note reporting the LFK index and Egger’s P-value.

{pstd} {cmd:dp} plots only the Doi plot with the LFK index as a note.

{pstd} {cmd:fp} plots the conventional funnel plot with a note reporting Egger’s P-value.

{pstd} {cmd:gp} plots the Galbraith plot.



{title:Examples}

{pstd} The data for the example is taken from Ross Harris (2006), originally prepared for {stata "help metan9":metan9}. {p_end}
{phang2} {stata "use http://fmwww.bc.edu/repec/bocode/m/metan_example_data, clear":. use http://fmwww.bc.edu/repec/bocode/m/metan_example_data, clear} {p_end}

{pstd} Generating _ES _seES with metan. {p_end}
{phang2}{stata "quietly metan tdeath tnodeath cdeath cnodeath, or ivhet nograph":. quietly metan tdeath tnodeath cdeath cnodeath, or ivhet nograph} {p_end}

{pstd} The Doi-Galbraith plot. {p_end}
{phang2}{stata "doiplot _ES _seES":. doiplot _ES _seES} {p_end}

{pstd} The Doi-Funnel plot. {p_end}
{phang2}{stata "doiplot _ES _seES, df":. doiplot _ES _seES, df} {p_end}



{title:Authors}

{pstd} Chang Xu, Department of Population Medicine, College of Medicine, Qatar University, Qatar{p_end}
{pstd} {browse "mailto:xuchang2016@runbox.com?subject=XC Stata enquiry":xuchang2016@runbox.com}{p_end}


{pstd} Luis Furuya-Kanamori, UQ Centre for Clinical Research, The University of Queensland, Australia{p_end}


{pstd} Suhail A.R. Doi, Department of Population Medicine, College of Medicine, Qatar University, Qatar{p_end}
{pstd} {browse "mailto:sardoi@gmx.net?subject=Stata enquiry":sardoi@gmx.net}{p_end}


	
{title:References}

{pstd} Egger M, Davey Smith G, Schneider M, Minder C. Bias in meta-analysis detected by a simple, graphical test. BMJ. 1997;315(7109):629-634.{p_end}

{pstd} Furuya-Kanamori L, Barendregt JJ, Doi SAR. 2018.  A new improved graphical and quantitative method for detecting bias in meta-analysis. Int J Evid Based Healthc 16: 195-203.{p_end}

{pstd} Furuya-Kanamori L, Xu C, Lin L, Doan T, Chu H, Thalib L, Doi SAR. P value-driven methods were underpowered to detect publication bias: analysis of Cochrane review meta-analyses. J Clin Epidemiol. 2020;118:86-92. {p_end}

{pstd} Galbraith R. Graphical display of estimates having differing standard errors. Technometrics, 1988; 30(3): 271–281 {p_end}


{title:Funding}

{pstd} This work was supported by Program Grant #NPRP10-0129-170274 from the Qatar National Research Fund (a member of Qatar Foundation). The findings herein reflect the work and are solely the responsibility of the authors.{p_end}
{pstd} LFK was supported by an Australian National Health and Medical Research Council Fellowship (APP1158469).
