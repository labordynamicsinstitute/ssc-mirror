{smcl}

help for {hi:spsiv}			Version 1.0, 02 Sep 25

{title:{cmd:spsiv} - Create synthetic instrumental variables in spatial regression}


{title:Syntax}

{p 8 16 2} {cmd:spsiv} {varlist} {ifin} {cmd:,} {cmdab:m:mat(matname)} [{cmdab:a:lpha(#)}]


{title:Description}

{p 4 8 2}{cmd:spsiv} generates synthetic instrumental variables from endogenous variables and spatial filters derived from a symmetric connectivity matrix. The synthetic instruments satisfy the conditions of a standard instrumental variable and generally avoid the weak instrumental variable problem due to relatively high correlation with the endogenous variable. {cmd:spsiv} works for both cross-sectional and panel data, provides IV-type instruments for use with {help spivreg}, {help spivregress}, {help xtdpdp}, {help xtabond2}, etc. For details, see Gallo & Paez (2013) and Fingleton (2023).

{p 4 8 2}The {help spmat} command is required and data must be {help spset}.

{p 4 8 2}The latest version of {cmd:spsiv} can be found at the following link: {browse "https://github.com/ManhHB94/":https://github.com/ManhHB94/}{p_end}


{title:Options}

{p 4 8 2}*{cmdab:m:mat(matname)} specifies a symmetric connectivity matrix, which can be an adjacency matrix or based on some other distance measure. It is important that they are symmetric, so a convenient option is to use an unnormalized matrix. This option is required.

{p 4 8 2}{cmdab:a:lpha(#)} specifies the significance level used in the spatial filter generation process. The default value is 0.05.


{title:Citation}

{p 4 8 2}{cmd:spsiv} is not an official Stata command. It is a free contribution to the research community. Please cite it as such: {p_end}
{p 8 8 2}Manh Hoang Ba, 2025. "SPSIV: Create synthetic instrumental variables in spatial regression," Statistical Software Components, Boston College Department of Economics.{p_end}


{marker example}{...}
{title:Examples}

{pstd}* Cross-sectional data{p_end}
{phang2} {stata "copy https://www.stata-press.com/data/r19/homicide1990.dta ., replace"}{p_end}
{phang2} {stata "copy https://www.stata-press.com/data/r19/homicide1990_shp.dta ., replace"}{p_end}
{phang2} {stata use homicide1990, clear }{p_end}
{phang2} {stata spset }{p_end}
{phang2} {stata spmat idistance m _CX _CY, id(_ID) dfunction(dhaversine) replace }{p_end}
{phang2} {stata spsiv ln_population ln_pdensity gini, m(m) a(0.1) }{p_end}

{pstd}* Panel data{p_end}
{phang2} {stata "copy https://www.stata-press.com/data/r19/homicide_1960_1990.dta ., replace"}{p_end}
{phang2} {stata "copy https://www.stata-press.com/data/r19/homicide_1960_1990_shp.dta . , replace"}{p_end}
{phang2} {stata use homicide_1960_1990, clear }{p_end}
{phang2} {stata xtset _ID year }{p_end}
{phang2} {stata spset }{p_end}
{phang2} {stata preserve }{p_end}
{phang2} {stata keep if year==1990 }{p_end}
{phang2} {stata spmat idistance m _CX _CY, id(_ID) dfunction(dhaversine) replace }{p_end}
{phang2} {stata restore }{p_end}
{phang2} {stata spsiv ln_population ln_pdensity gini if year==1990, m(m) a(0.1) }{p_end}

	
{title:References}

{pstd}Fingleton, B. (2023). Estimating dynamic spatial panel data models with endogenous regressors using synthetic instruments. Journal of Geographical Systems, 25(1), 121-152.

{pstd}Le Gallo, J., & Paez, A. (2013). Using synthetic variables in instrumental variable estimation of spatial series models. Environment and Planning A, 45(9), 2227-2242.


{title:Authors}

    Manh Hoang Ba, Eureka Uni Team, Vietnam
    hbmanh9492@gmail.com

{title:Also see}

{p 4 8 2}Online: help for {help spset}, {help spmat} {if installed}, {help spivreg} (if installed), {help xtabond2} (if installed), {help spxtabond2} (if installed).



