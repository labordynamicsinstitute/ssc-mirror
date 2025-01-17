{smcl}
{* *! version 1.0 16 Jun 2023}{...}
{cmd:help xtrantreat} 
{hline}
{vieweralsosee "help didplacebo" "help didplacebo"}{...}
{vieweralsosee "help xtshuffle" "help xtshuffle"}{...}
{vieweralsosee "help xtrantreat" "help xtrantreat"}{...}
{vieweralsosee "help tofirsttreat" "help tofirsttreat"}{...}
{viewerjumpto "Syntax" "xtrantreat##syntax"}{...}
{viewerjumpto "Description" "xtrantreat##description"}{...}
{viewerjumpto "Options" "xtrantreat##options"}{...}
{viewerjumpto "Resources" "xtrantreat##resources"}{...}
{viewerjumpto "Reference" "xtrantreat##reference"}{...}
{viewerjumpto "Author" "xtrantreat##author"}{...}

{title:Title}

{phang}
{bf:xtrantreat} {hline 2} randomizing a treatment variable in a panel dataset 

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:xtrantreat} {varname} {cmd:,} {opt me:thod}{bf:(}{{bf:1}|{bf:2}|{bf:3}}{bf:)} [{opth i:d(panelvar)} {opth t:ime(timevar)} {opth ranu:nitnum(int)} {opt rant:imescope(t_min t_max)} {opth gen:erate(newvar)}]

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:xtrantreat} randomizes a treatment variable (a dummy variable specifed by {varname}) in a panel dataset.
A typical scenario of application is in implementing mixed placebo test for difference-in-differences (DID) models. 
{cmd:xtrantreat} converts a treatment variable to a fake treatment variable where both treatment units and times are randomized.
The random assignment process can be specified by the options {opth ranunitnum(int)}, {opt rantimescope(t_min t_max)} and {cmd:method}{bf:(}{{bf:1}|{bf:2}|{bf:3}}{bf:)},
where {cmd:method}{bf:(}{{bf:1}|{bf:2}|{bf:3}}{bf:)} corresponds to three different ways of randomizing the treatment variable.

{marker options}{...}
{title:Options}

{phang} 
{opt id(panelvar)} specifies {it:panelvar} as the panel variable of the dataset, which is used to identify the units (individuals) in the panel dataset. 
If {opt id(panelvar)} is not specified, {helpb xtset} must be used to declear a panel variable before implementing {cmdab:xtrantreat}.

{phang} 
{opt time(timevar)} specifies {it:timevar} as the time variable of the panel dataset. 
If {opt time(timevar)} is not specified, {helpb xtset} must be used to declear a time variable before implementing {cmdab:xtrantreat}.

{phang}
{opth ranunitnum(int)} specifies the number of units randomly selected as fake treatment units.
If {opth ranunitnum(int)} is not specified, {it:{help int}} defaults to the actual number of treatment units in the sample.
All units in the sample have the same probability of being randomly selected as fake treatment units. 

{phang}
{opt rantimescope(t_min t_max)} specifies the range within which fake treatment times are randomly selected. 
All periods within the range of {it:t_min} to {it:t_max} have the same probability of being randomly assigned as a fake treatment time via a uniform distribution on this range.

{phang2} For the standard DID design, if {opt rantimescope(t_min t_max)} is not specified, {it:t_min} and {it:t_max} default to the second period and the last period in the sample respectively. 

{phang2} For the staggered DID design, if {opt rantimescope(t_min t_max)} is not specified, 
{it:t_min} defaults to the earliest treatment time (or the first period in the sample, 
whichever is larger), and {it:t_max} defaults to the latest treatment time in the sample. 
Another possible choice is for users to set  {it:t_min} and {it:t_max} as the first period and the last period in the sample respectively.

{phang}
{cmd:method}{bf:(}{{bf:1}|{bf:2}|{bf:3}}{bf:)} specifies one of the following three methods for generating the fake treatment variable.

{phang2}
{cmd:method}{bf:(}{bf:1}{bf:)} is suitable for implementing mixed placebo test for standard DID models with synchronized adoption. 
Using {cmd:method}{bf:(}{bf:1}{bf:)}, a certain number of fake treatment units is randomly selected, which are then assigned a same fake treatment time randomly chosen.  
The number of fake treatment units and the range of fake treatment times are specified by the options {opth ranunitnum(int)} and {opt rantimescope(t_min t_max)} respectively.

{phang2}
{cmd:method}{bf:(}{bf:2}{bf:)} and {cmd:method}{bf:(}{bf:3}{bf:)} are suitable for implementing mixed placebo test for staggered DID models with staggered adoption, where {bf:2} and {bf:3} correponds to the unrestricted version and the restricted version, respectively. 
{cmd:method}{bf:(}{bf:2}{bf:)} (the unrestricted version) randomly selects a fake treatment time for each unit, 
without maintaining the original cohort structure (i.e., how many units in each cohort). 
The number of fake treatment units and the range of fake treatment times are specified by the options {opth ranunitnum(int)}  and {opt rantimescope(t_min t_max)} respectively.
On the other hand, {cmd:method}{bf:(}{bf:3}{bf:)} (the restricted version) maintains the cohort structure.  
Specifically, suppose the treatment times in the sample consist of t_1, t_2,...,t_G, and the correponding cohorts contain N_1, N_2,...,N_G units respectively.
We randomly partition all units in the sample into G cohorts containing N_1, N_2,...,N_G units respectively, 
then randomly assign G different treatment times from {opt rantimescope(t_min t_max)} to these cohorts as their fake treatment times.
Note that the range of fake treatment times specified by the options {opt rantimescope(t_min t_max)} must be greater than or equal to the number of periods in the actual treatment variable.

{phang} 
{opth generate(newvar)} specifies a new variable named {it:{help newvar}} to store the transformed version of {varname}. If {opth generate(newvar)} is not specified, the transformed version of {varname} will replace the original {varname}.

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
{phang2}{cmd:. {space 4}xtrantreat _intra, method(2)}{p_end}
{phang2}{cmd:. {space 4}xtreg log_gini _intra $cov i.wrkyr, fe r}{p_end}
{phang2}{cmd:. {space 4}return scalar pbo_eff = _b[_intra]}{p_end}
{phang2}{cmd:. end}{p_end}

{phang2}{cmd:. simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest}{p_end}
{phang2}{cmd:. graph twoway (histogram pbo_eff) (kdensity pbo_eff)}{p_end}

{marker resources}{...}
{title:Resources}

{phang}{helpb didplacebo} implements placebo tests for estimating difference-in-differences (DID) models{p_end}
{phang}{helpb xtshuffle} shuffles a variable in a panel dataset blockwise along the dimension of the panel variable{p_end}
{phang}{helpb tofirsttreat} converts a treatment variable in a panel dataset from a dummy variable to a variable specifying the first treatment period{p_end}

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
