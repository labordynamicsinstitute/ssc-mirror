{smcl}
{* *! version 1.0 16 Jun 2023}{...}
{cmd:help xtshuffle} 
{hline}
{vieweralsosee "help didplacebo" "help didplacebo"}{...}
{vieweralsosee "help xtshuffle" "help xtshuffle"}{...}
{vieweralsosee "help xtrantreat" "help xtrantreat"}{...}
{vieweralsosee "help tofirsttreat" "help tofirsttreat"}{...}
{viewerjumpto "Syntax" "xtshuffle##syntax"}{...}
{viewerjumpto "Description" "xtshuffle##description"}{...}
{viewerjumpto "Options" "xtshuffle##options"}{...}
{viewerjumpto "Resources" "xtshuffle##resources"}{...}
{viewerjumpto "Reference" "xtshuffle##reference"}{...}
{viewerjumpto "Author" "xtshuffle##author"}{...}

{title:Title}

{phang}
{bf:xtshuffle} {hline 2} shuffling a variable in a panel dataset blockwise along the dimension of panel variable 

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:xtshuffle} {varname} [{cmd:,} {opth i:d(panelvar)} {opt t:ime(timevar)} {opth gen:erate(newvarname)}]

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:xtshuffle} shuffles the variable {varname} in a panel dataset blockwise along the dimension of panel variable. 
A typical scenario of application is in implementing in-space placebo test for difference-in-differences (DID) models. 
In that case, the treatment variable is randomly shuffled blockwise to generate fake treatment units, whereas the treatment times are kept the same. 
Note that {cmd:xtshuffle} is applicable to both standard DID models with synchronized adoption and staggered DID models with staggered adoption. 
 
{marker options}{...}
{title:Options}

{phang}
{opt id(panelvar)} specifies {it:panelvar} as the panel variable of the dataset, which is used to identify the units (individuals) in the panel dataset. 
If {opt id(panelvar)} is not specified, {helpb xtset} must be used to declear a panel variable before implementing {cmdab:xtshuffle}.

{phang} 
{opt time(timevar)} specifies {it:timevar} as the time variable of the panel dataset. 
If {opt time(timevar)} is not specified, {helpb xtset} must be used to declear a time variable before implementing {cmdab:xtshuffle}.

{phang}
{opth generate(newvarname)} specifies a new variable named {it:{help newvarname}} to store the shuffled version of {varname}. 
If {opth generate(newvarname)} is not specified, the shuffled version of {varname} replaces the original {varname}.

{marker examples}{...}
{title:Example: the impact of bank deregulation on income inequality (Beck et al., 2010)}

{phang2}{cmd:. use bbb.dta, clear}{p_end}
{phang2}{cmd:. xtset statefip wrkyr}{p_end}
{phang2}{cmd:. global cov gsp_pc_growth prop_blacks prop_dropouts prop_female_headed unemploymentrate}{p_end}
{phang2}{cmd:. xtreg log_gini _intra $cov i.wrkyr, fe r}{p_end}
{phang2}{cmd:. local tr_eff = _b[_intra]}{p_end}

{phang2}{cmd:. capture program drop InSpacePlaceboTest}{p_end}
{phang2}{cmd:. program define InSpacePlaceboTest, rclass}{p_end}
{phang2}{cmd:. {space 4}preserve}{p_end}
{phang2}{cmd:. {space 4}xtshuffle _intra}{p_end}
{phang2}{cmd:. {space 4}xtreg log_gini _intra $cov i.wrkyr, fe r}{p_end}
{phang2}{cmd:. {space 4}return scalar pbo_eff = _b[_intra]}{p_end}
{phang2}{cmd:. end}{p_end}

{phang2}{cmd:. simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest}{p_end}
{phang2}{cmd:. graph twoway (histogram pbo_eff) (kdensity pbo_eff)}{p_end}

{marker resources}{...}
{title:Resources}

{phang}{helpb didplacebo} implements placebo tests for estimating difference-in-differences (DID) models{p_end}
{phang}{helpb xtrantreat} randomizes a treatment variable in a panel dataset {p_end}
{phang}{helpb tofirsttreat} converts a treatment variable from a dummy variable to a variable specifying the first treatment period{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Beck, T., Levine, R., and Levkov, A. 2010. Big bad banks? The winners and losers from bank deregulation in the United States. {it:Journal of Finance} 65(5): 1637-1667.

{marker author}{...}
{title:Author}

{pstd}
Qiang Chen, Shandong University, CN{break}
{browse "http://www.econometrics-stata.com":www.econometrics-stata.com}{break}
qiang2chen2@126.com{break}

{pstd}
Ji Qi, Shandong University, CN{break}
miracle4556@163.com{break}

{pstd}
Guanpeng Yan (correponding author), Shandong University of Finance and Economics, CN{break}
guanpengyan@yeah.net{break}
