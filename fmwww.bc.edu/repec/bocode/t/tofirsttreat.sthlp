{smcl}
{* *! version 1.0 16 Jun 2023}{...}
{cmd:help tofirsttreat} 
{hline}
{vieweralsosee "help didplacebo" "help didplacebo"}{...}
{vieweralsosee "help xtshuffle" "help xtshuffle"}{...}
{vieweralsosee "help xtrantreat" "help xtrantreat"}{...}
{vieweralsosee "help tofirsttreat" "help tofirsttreat"}{...}
{viewerjumpto "Syntax" "tofirsttreat##syntax"}{...}
{viewerjumpto "Description" "tofirsttreat##description"}{...}
{viewerjumpto "Options" "tofirsttreat##options"}{...}
{viewerjumpto "Resources" "tofirsttreat##resources"}{...}
{viewerjumpto "Reference" "tofirsttreat##reference"}{...}
{viewerjumpto "Author" "tofirsttreat##author"}{...}

{title:Title}

{phang}
{bf:tofirsttreat} {hline 2} converting a treatment variable in a panel dataset from an indicator variable to a variable specifying the first treatment period

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:tofirsttreat} {varname} [{cmd:,} {opth i:d(panelvar)} {opth t:ime(timevar)} {opth gen:erate(newvar)}]

{marker description}{...}
{title:Description}

{p 4 4 2}
The {cmd:tofirsttreat} command converts a treatment variable named {varname} in a panel dataset from an indicator variable to a variable specifying the first treatment period. 
If a unit is not treated throughout the sample period, {cmd:tofirsttreat} designates the first treatment period as a missing value.

{marker options}{...}
{title:Options}

{phang} 
{opt id(panelvar)} specifies {it:panelvar} as the panel variable of the dataset, which is used to identify the units (individuals) in the panel dataset. 
If {opt id(panelvar)} is not specified, {helpb xtset} must be used to declear a panel variable before implementing {cmdab:tofirsttreat}.

{phang} 
{opt time(timevar)} specifies {it:timevar} as the time variable of the panel dataset. If {opt time(timevar)} is not specified, {helpb xtset} must be used to declear a time variable before implementing {cmdab:tofirsttreat}.

{phang} 
{opth generate(newvar)} specifies a new variable named {it:{help newvar}} to store the transformed version of {varname}. If {opth generate(newvar)} is not specified, the transformed version of {varname} will replaces the original {varname}.

{marker examples}{...}
{title:Example: the impact of bank deregulation on income inequality (Beck et al., 2010)}

{phang2}{cmd:. use bbb.dta, clear}{p_end}
{phang2}{cmd:. xtset statefip wrkyr}{p_end}
{phang2}{cmd:. tofirsttreat _intra, generate(branch_reform_new)}{p_end}
{phang2}{cmd:. list statefip wrkyr _intra branch_reform_new in 1/124}{p_end}

{marker resources}{...}
{title:Resources}

{phang}{helpb didplacebo} implements placebo tests for estimating difference-in-differences (DID) models{p_end}
{phang}{helpb xtshuffle} shuffles a variable in a panel dataset blockwise along the dimension of panel variable{p_end}
{phang}{helpb xtrantreat} randomizes a treatment variable in a panel dataset{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Beck, T., Levine, R., and Levkov, A. 2010. Big bad banks? The winners and losers from bank deregulation in the United States. {it:Journal of Finance} 65(5): 1637-1667.

{phang}
Chen, Q., Qi, J., and Yan, G. 2023. didplacebo: Implementing placebo tests for difference-in-differences estimations. {it:Shandong University working paper}.

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

