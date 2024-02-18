{smcl}
{* *! version 1.0 Chao Wang 25/05/2022}{...}
{* *! version 1.1 Chao Wang 24/05/2023}{...}
{cmd:help pdi}
{hline}

{title:Title}

{pstd}{hi:pdi} {hline 2} This command calculates the polytomous discrimination index (PDI).

{title:Syntax}

{pstd}{cmd:pdi} {varlist} {ifin}

{title:Description}

{pstd}
{cmd:pdi} 
calculates the polytomous discrimination index (PDI), proposed by Van Calster et al. (2012). This program implements the computation method described by Dover et al. (2021). 
PDI is a measure that extends the well-known binary discrimination measure c-statistic or AUC to nominal (>2 categories) outcome settings. See Van Calster et al. (2012) or Dover et al. (2021) for the rationale and interpretation of PDI.

{pstd}
Overall and PDI for each outcome are calculated. The {varlist}  
must include at least two variables: the outcome variable as the first variable with outcome categories in the format of 1, 2, 3... etc. This is followed by the predictions for each category such as pr1, pr2, pr3... etc.

{pstd}
The program may fail if there are too many distinct values of predicted probabilities, due to the matrix dimension limit in Stata. If this occurs, try doing some rounding for the prediction variables.

{title:Examples}

{phang}{stata "webuse sysdsn1, clear": . webuse sysdsn1, clear}{p_end}
{phang}{stata "mlogit insure age male nonwhite i.site": . mlogit insure age male nonwhite i.site}{p_end}
{phang}{stata "predict pr*": . predict pr*}{p_end}
{phang}{stata "pdi insure pr1-pr3": . pdi insure pr1-pr3}{p_end}

{title:Reference}

{pstd} Dover, DC, Islam, S, Westerhout, CM, Moore, LE, Kaul, P, Savu, A. Computing the polytomous discrimination index. Statistics in Medicine. 2021; 40: 3667– 3681. https://doi.org/10.1002/sim.8991
{p_end}

{pstd} Van Calster, B., Van Belle, V., Vergouwe, Y., Timmerman, D., Van Huffel, S. and Steyerberg, E.W. (2012), Extending the c-statistic to nominal polytomous outcomes: the Polytomous Discrimination Index. Statist. Med., 31: 2610-2626. https://doi.org/10.1002/sim.5321
{p_end}

{title:Author}

{pstd} Chao Wang, BEng MSc DIC PhD, Associate Professor in Health & Social Care Statistics at Kingston University, UK. Email: excelwang@gmail.com.
{p_end}