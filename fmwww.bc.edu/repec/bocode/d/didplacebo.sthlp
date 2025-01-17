{smcl}
{* *! version 2.0 8 Apr 2024}{...}
{cmd:help didplacebo} 
{hline}
{vieweralsosee "help didplacebo" "help didplacebo"}{...}
{vieweralsosee "help xtshuffle" "help xtshuffle"}{...}
{vieweralsosee "help xtrantreat" "help xtrantreat"}{...}
{vieweralsosee "help tofirsttreat" "help tofirsttreat"}{...}
{viewerjumpto "Syntax" "didplacebo##syntax"}{...}
{viewerjumpto "Description" "didplacebo##description"}{...}
{viewerjumpto "Required Settings" "didplacebo##required"}{...}
{viewerjumpto "Options" "didplacebo##options"}{...}
{viewerjumpto "Remarks" "didplacebo##remarks"}{...}
{viewerjumpto "Examples" "didplacebo##examples"}{...}
{viewerjumpto "Note" "didplacebo##note"}{...}
{viewerjumpto "Compatibility" "didplacebo##compatibility"}{...}
{viewerjumpto "Stored results" "didplacebo##stored"}{...}
{viewerjumpto "Resources" "didplacebo##resources"}{...}
{viewerjumpto "Reference" "didplacebo##reference"}{...}
{viewerjumpto "Author" "didplacebo##author"}{...}

{title:Title}

{phang}
{bf:didplacebo} {hline 2} implementation of in-time, in-space and mixed placebo tests for estimating difference-in-differences (DID) models

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:didplacebo} {it:estimatename}
{cmd:,}
{opt treatv:ar}{cmd:(}{it:treatvarname}{cmd:)}
[{it:options}]

{synoptset 50 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Types of Placebo Test}
{synopt:{opth pbot:ime(numlist:numlist)}}in-time placebo test{p_end}
{synopt:{opt pbou:nit}}in-space placebo test{p_end}
{synopt:{opt pbom:ix}([{bf:1} {bf:2} {bf:3}])}mixed placebo test{p_end}

{syntab:Optimization for In-time Placebo Test}
{synopt:{opt nodrop}}keep all observations for the control group (never-treated group){p_end}

{syntab:Optimization for In-space and/or Mixed Placebo Tests}
{synopt:{opth rep:eat(int)}}the number of replications{p_end}
{synopt:{opth seed(int)}}seed used by the random number generator{p_end}

{syntab:Optimization for Mixed Placebo Test}
{synopt:{opth ranu:nitnum(int)}}the number of units randomly selected as fake treated units{p_end}
{synopt:{opt rant:imescope(t_min t_max)}}the range within which fake treatment times are randomly selected{p_end}

{syntab:Reporting}
{synopt:{opt frame(framename)}}frame storing estimated placebo effects{p_end}
{synopt:{opt nofig:ure}}do not display figures{p_end}
{synopt:{cmdab:saveg:raph}({it:prefix}, [{cmdab:asis} {cmdab:replace}])}save all produced graphs to the current path.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{helpb xtset} {it:panelvar} {it:timevar} must be used to declare a panel dataset; see {manhelp xtset XT:xtset}.{p_end}
{p 4 6 2}{it:estimatename} should be an estimation saved by {helpb estimates store}; see {manhelp estimates_store R:estimates store}.{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:didplacebo} implements placebo tests for estimating difference-in-differences (DID) models, where policy adoption may be synchronized or staggered. 
In particular, {cmd:didplacebo} performs in-time placebo tests using fake treatment times, 
in-space placebo tests using fake  treatment units (randomly selected), 
and mixed placebo tests using both fake treatment units and times (both randomly selected). 
Moreover, {cmd:didplacebo} produces convenient graphs for visualization. 

{marker required}{...}
{title:Required Settings}

{p 4 4 2}
To perform a placebo test, it is necessary to specify the estimation name, 
{it:estimatename}, and the treatment variable name, {it:treatvarname}, 
as inputs to the {cmd:didplacebo} command. 
{cmd:didplacebo} automatically executes {helpb estimates restore} {it:estimatename} to capture the command used for DID estimation {bf:e(cmdline)}. The model is then estimated again with the same command using a fake treatment variable to yield an estimate of placebo effect. 

{phang}
{opt treatvar}{cmd:(}{it:treatvarname}{cmd:)} specifies a dummy variable indicating whether a unit is treated in a particular period.

{marker options}{...}
{title:Options}

{dlgtab:Types of Placebo Test}  

{phang} 
{opth pbotime:(numlist:numlist)} specifies in-time placebo test using a series of fake treatment times prior to the actual treatment time, 
while all treated observations are dropped. The fake treatment times are specified by {it:{help numlist:numlist}}, 
which contains positive integers used to generate fake treatment variables by moving the initial treatment time {it:treatvarname} {it:{help numlist:numlist}}-periods shift back. 
The placebo effects are then estimated using the fake treatment variables. {bf:didplacebo} uses the same method to compute the standard errors as specified by the command used to estimate the DID model. 
For example, if the DID model was previously estimated by "{bf:xtreg, r}", then {bf:didplacebo} uses "{bf:xtreg, r}" as well, which yields cluster-robust standard errors. 
Similarly, if the DID model was previously estimated by "{bf:reghdfe, cluster(clustvar)}", then {bf:didplacebo} uses "{bf:reghdfe, cluster(clustvar)}" too, again yielding cluster-robust standard errors.  

{phang2} 
Here is an example of shifting the initial treatment time 2-period shift back, where "o" means untreated while "x" denotes treated or taken placebo:

          {it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5} {it:t=6} {it:t=7} {it:t=8} {space 34} {it:t=1} {it:t=2} {it:t=3} {it:t=4}
         {c TLC}{hline 31}{c TRC} {space 32} {c TLC}{hline 15}{c TRC}
     {it:i=1} {c |} o   o   o   o   o   o   o   o {c |} {space 28} {it:i=1} {c |} o   o   o   o {c |}
     {it:i=2} {c |} o   o   o   o   o   o   o   o {c |}    drop posttreatment data   {it:i=2} {c |} o   o   o   o {c |}
     {it:i=3} {c |} o   o   o   o   o   o   o   o {c |} {hline 27}> {it:i=3} {c |} o   o   o   o {c |}
     {it:i=4} {c |} o   o   o   o   x   x   x   x {c |}      2-period shift back     {it:i=4} {c |} o   o   x   x {c |}
     {it:i=5} {c |} o   o   o   o   x   x   x   x {c |} {space 28} {it:i=5} {c |} o   o   x   x {c |}
         {c BLC}{hline 31}{c BRC} {space 32} {c BLC}{hline 15}{c BRC}

{phang} 
{opt pbounit} specifies in-space placebo test where units are randomly selected as fake treatment units, while keeping the treatment time intact. 
For DID models with staggered adoption, this implies that the cohort structure (i.e., how many units in each cohort with a same treatment time) is maintained. 
In-space placebo test implements many repetitions, say 500 repetitions. In each repetition, a fake treatment variable is generated by randomly shuffling {it:treatvarname} blockwise along the dimension of {it:panelvar}. 
The model is then estimated again using the fake treatment variable to yield an estimate of the placebo effect. 
After many repetitions, a distribution of estimated placebo effects is obtained. 
For statistical inference, the estimated treatment effect is then compared against the distribution of estimated placebo effects to calculate two-sided, left-sided and right-sided p-values. 

{phang2} 
Here is an example of randomly shuffling {it:treatvarname} blockwise along the dimension of {it:panelvar}:

          {it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5} {it:t=6} {it:t=7} {it:t=8} {space 34} {it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5} {it:t=6} {it:t=7} {it:t=8}
         {c TLC}{hline 31}{c TRC} {space 32} {c TLC}{hline 31}{c TRC}
     {it:i=1} {c |} o   o   o   o   o   o   o   o {c |} {space 28} {it:i=1} {c |} o   o   o   o   x   x   x   x {c |}
     {it:i=2} {c |} o   o   o   o   o   o   o   o {c |}                              {it:i=2} {c |} o   o   o   o   o   o   o   o {c |} 
     {it:i=3} {c |} o   o   o   o   o   o   o   o {c |} {hline 27}> {it:i=3} {c |} o   o   o   o   o   o   o   o {c |} 
     {it:i=4} {c |} o   o   o   o   x   x   x   x {c |}     shuffle by {it:panelvar}      {it:i=4} {c |} o   o   o   o   x   x   x   x {c |} 
     {it:i=5} {c |} o   o   o   o   x   x   x   x {c |} {space 28} {it:i=5} {c |} o   o   o   o   o   o   o   o {c |} 
         {c BLC}{hline 31}{c BRC} {space 32} {c BLC}{hline 31}{c BRC}

{phang} 
{opt pbomix}{bf:(}[{bf:1} {bf:2} {bf:3}]{bf:)} specifies mixed placebo test where both treatment units and times are randomized. 
Mixed placebo test implements many repetitions, say 500 repetitions. 
In each repetition, a fake treatment variable is generated by randomly selecting both fake treatment units and times.
Not less than one of {bf:1}, {bf:2} and {bf:3} must be specified in {cmd:pbomix}{bf:()} to choose the version of implementation, 
where {bf:1} correponds to the version suitable for standard DID, {bf:2} and {bf:3} correpond to the unrestricted and restricted versions suitable for staggered DID, respectively.

{phang2} 
{opt pbomix}{bf:(}{bf:1}{bf:)} is used for standard DID with synchronized policy adoption.
In each repetition, a certain number of fake treatment units is randomly selected, which are then assigned a same fake treatment time randomly chosen.
The number of fake treatment units and the range of fake treatment times are specified by the options {opth ranunitnum(int)} and {opt rantimescope(t_min t_max)} respectively. 

{phang2} 
Here is an example of randomizing both treatment units and times for standard DID with synchronized adoption:

          {it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5} {it:t=6} {it:t=7} {it:t=8} {space 34} {it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5} {it:t=6} {it:t=7} {it:t=8}
         {c TLC}{hline 31}{c TRC} {space 32} {c TLC}{hline 31}{c TRC}
     {it:i=1} {c |} o   o   o   o   o   o   o   o {c |} {space 28} {it:i=1} {c |} o   o   o   o   o   o   x   x {c |}
     {it:i=2} {c |} o   o   o   o   o   o   o   o {c |}       randomly generate      {it:i=2} {c |} o   o   o   o   o   o   x   x {c |} 
     {it:i=3} {c |} o   o   o   o   o   o   o   o {c |} {hline 27}> {it:i=3} {c |} o   o   o   o   o   o   o   o {c |} 
     {it:i=4} {c |} o   o   o   o   x   x   x   x {c |} {space 28} {it:i=4} {c |} o   o   o   o   o   o   o   o {c |} 
     {it:i=5} {c |} o   o   o   o   x   x   x   x {c |} {space 28} {it:i=5} {c |} o   o   o   o   o   o   o   o {c |} 
         {c BLC}{hline 31}{c BRC} {space 32} {c BLC}{hline 31}{c BRC}

{phang2} 
{opt pbomix}{bf:(}[{bf:2} {bf:3}]{bf:)} is used for staggered DID with staggered policy adoption, where {bf:2} and {bf:3} correponds to the unrestricted and the restricted versions, respectively. 
The unrestricted version {opt pbomix}{bf:(}{bf:2}{bf:)} randomly selects a fake treatment time for each unit, without maintaining the original cohort structure (i.e., how many units in each cohort). 
The number of fake treatment units and the range of fake treatment periods are specified by the options {opth ranunitnum(int)} and {opt rantimescope(t_min t_max)} respectively.

{phang2} 
On the other hand, the restricted version {opt pbomix}{bf:(}{bf:3}{bf:)} maintains the cohort structure. 
Specifically, suppose the treatment times in the sample consist of t_1, t_2,...,t_G, and the correponding cohorts contain N_1, N_2,...,N_G units respectively. 
In each repetition, we randomly partition all units in the sample into G cohorts containing N_1, N_2,...,N_G units respectively, 
then randomly assign G different times from {opt rantimescope(t_min t_max)} to these cohorts as their fake treatment times. 
The range of fake treatment times specified by the options {opt rantimescope(t_min t_max)} must be greater than or equal to the number of periods in the actual treatment variable.

{phang2} 
The model is then estimated again using the fake treatment variable to yield an estimate of the placebo effect. 
After many repetitions, we end up with a distribution of estimated placebo effects. 
For statistical inference, the estimated treatment effect is then compared against the distribution of estimated placebo effects to calculate two-sided, left-sided and right-sided p-values.

{dlgtab:Optimization for In-space and/or Mixed Placebo Test}  

{phang}
{opt nodrop} specifies to keep all observations for the control group (never-treated group). 
If the {opt nodrop} option is not specified, {opt didplacebo} will automatically drops all posttreatment observations, including those for the control group. 
		 
{dlgtab:Optimization for In-space and/or Mixed Placebo Test}  

{phang}
{opth repeat(int)} specifies the number of repetitions, which defaults to 500.

{phang}
{opth seed(int)} specifies the random seed for reproducible results, which defaults to ".", that is, no seed is set.

{dlgtab:Optimization for Mixed Placebo Test}  

{phang}
{opth ranunitnum(int)} specifies the number of units randomly selected as fake treatment units in each repetition. 
If {opth ranunitnum(int)} is not specified, {it:{help int}} defaults to the actual number of treatment units in the sample. 
All units in the sample have the same probability of being randomly selected as fake treatment units. 

{phang}
{opt rantimescope(t_min t_max)} specifies the range within which fake treatment times are randomly selected in each repetition. 
All periods within the range of {it:t_min} to {it:t_max} have the same probability of being randomly assigned as a fake treatment time via a uniform distribution on this range.

{phang2} For the standard DID design, if {opt rantimescope(t_min t_max)} is not specified, {it:t_min} and {it:t_max} default to the second period and the last period in the sample respectively. 

{phang2} For the staggered DID design, if {opt rantimescope(t_min t_max)} is not specified, {it:t_min} defaults to the earliest treatment time (or the first period in the sample, whichever is larger), and {it:t_max} defaults to the latest treatment time in the sample. Another possible choice is for users to set  {it:t_min} and {it:t_max} as the first period and the last period in the sample respectively.

{dlgtab:Reporting}

{phang}
{opt frame(framename)} creates a Stata frame storing placebo effects generated by in-space and/or mixed placebo tests. The frame named {it:framename} is replaced if it already exists, and created if not.

{phang}
{opt nofigure} do not display figures. The default is to display all figures from placebo tests if available.

{phang}
{cmdab:savegraph}({it:prefix}, [{cmdab:asis} {cmdab:replace}]) automatically and iteratively calls the {helpb graph save} to save all produced graphs to the current path, 
where {it: prefix} specifies the prefix added to {it: _graphname} to form a file name, 
that is, the graph named {it: graphname} is stored as {it: prefix_graphname}.gph. 
{cmdab:asis} and {cmdab:replace} are options passed to {helpb graph save}; for details, see {manhelp graph G-2: graph save}.
Note that this option only applies when {opt nofigure} is not specified. 

{marker examples}{...}
{title:Example 1 (Standard DID): the effects of the abandonment of China's Grand Canal (Cao and Chen, 2022)}

{phang2}{cmd:. use cao_chen.dta, clear}{p_end}
{phang2}{cmd:. xtset county year}{p_end}
{phang2}{cmd:. reghdfe rebel canal_post, absorb(i.county i.year) cluster(county)}{p_end}
{phang2}{cmd:. estimates store did_cao_chen}{p_end}
{phang2}* Implements in-time placebo tests using fake treatment time shifted back by 1-10 periods{p_end}
{phang2}{cmd:. didplacebo did_cao_chen, treatvar(canal_post) pbotime(1(1)10)}{p_end}
{phang2}* Implements in-space placebo test {p_end}
{phang2}{cmd:. didplacebo did_cao_chen, treatvar(canal_post) pbounit seed(1)}{p_end}
{phang2}* Implements mixed placebo test suitable for standard DID {p_end}
{phang2}{cmd:. didplacebo did_cao_chen, treatvar(canal_post) pbomix(1) seed(1)}{p_end}
{phang2}* Implements in-time, in-space and mixed placebo tests simultaneously{p_end}
{phang2}{cmd:. didplacebo did_cao_chen, treatvar(canal_post) pbotime(1(1)10) pbounit pbomix(1) seed(1)}{p_end}

{title:Example 2 (Staggered DID): the impact of bank deregulation on income inequality (Beck et al., 2010)}

{phang2}{cmd:. use bbb.dta, clear}{p_end}
{phang2}{cmd:. xtset statefip wrkyr}{p_end}
{phang2}{cmd:. global cov gsp_pc_growth prop_blacks prop_dropouts prop_female_headed unemploymentrate}{p_end}
{phang2}{cmd:. xtreg log_gini _intra $cov i.wrkyr, fe r}{p_end}
{phang2}{cmd:. estimates store did_bbb}{p_end}
{phang2}* Implements in-time placebo test using fake treatment time shifted back by 1-10 periods{p_end}
{phang2}{cmd:. didplacebo did_bbb, treatvar(_intra) pbotime(1(1)10)}{p_end}
{phang2}* Implements in-space placebo test{p_end}
{phang2}{cmd:. didplacebo did_bbb, treatvar(_intra) pbounit seed(1)}{p_end}
{phang2}* Implements the free version of mixed placebo test suitable for staggered DID{p_end}
{phang2}{cmd:. didplacebo did_bbb, treatvar(_intra) pbomix(2) seed(1)}{p_end}
{phang2}* Implements the restricted version of mixed placebo test suitable for staggered DID{p_end}
{phang2}{cmd:. didplacebo did_bbb, treatvar(_intra) pbomix(3) seed(1)}{p_end}
{phang2}* Implements in-time, in-space and mixed placebo tests{p_end}
{phang2}{cmd:. didplacebo did_bbb, treatvar(_intra) pbotime(1(1)10) pbounit pbomix(2 3) seed(1)}{p_end}

{marker note}{...}
{title:Note} 

{phang}To conduct placebo tests using heterogeneity-robust estimators (say, CSDID by Callaway and Sant'Anna, 2021) other than the traditional two-way fixed effects estimator (TWFE), one can make use of our companion commands {helpb xtshuffle}, 
{helpb xtrantreat} and {helpb tofirsttreat}. 
For detailed illustrations, refer to Chen, Qi and Yan (2023).   

{marker compatibility}{...}
{title:Compatibility}

{phang}
{cmd:didplacebo} is confirmed to be compatible with official commands {helpb regress}, {helpb xtreg}, {helpb areg} and {helpb xtdidregress} as well as the third-party command {helpb reghdfe}. 
Other commands, though not specifically tested, may also be compatible with {cmd:didplacebo}.

{marker stored}{...}
{title:Stored Results}

{pstd}
{cmd:didplacebo} stores the following in e():

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(didestname)}}name of DID estimation generated by {bf: estimates store}{p_end}
{synopt:{cmd:e(didcmd)}}Stata command used for DID estimation{p_end}
{synopt:{cmd:e(didcmdline)}}Stata command line used for DID estimation{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(treatvar)}}name of treatment variable{p_end}
{synopt:{cmd:e(cmd)}}{bf:didplacebo}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(seed)}}seed used by the random number generator for reproducible results{p_end}
{synopt:{cmd:e(graph)}}names of all produced graphs{p_end}
{synopt:{cmd:e(frame)}}name of Stata frame storing placebo effects{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(pbounit)}}matrix containg coefficient of treatment effect and p-values of placebo effects generated by in-space placebo test{p_end}
{synopt:{cmd:e(pbotime)}}matrix containg coefficients and confidence intervals of placebo effects generated by in-time placebo test{p_end}
{synopt:{cmd:e(pbomix1)}}matrix containg coefficient of treatment effect and p-values of placebo effects generated by mixed placebo test for standard DID{p_end}
{synopt:{cmd:e(pbomix2)}}matrix containg coefficient of treatment effect and p-values of placebo effects generated by mixed placebo test for staggered DID (free version){p_end}
{synopt:{cmd:e(pbomix3)}}matrix containg coefficient of treatment effect and p-values of placebo effects generated by mixed placebo test for staggered DID (restricted version){p_end}

{marker resources}{...}
{title:Resources}

{phang}{helpb xtshuffle} shuffles a variable in a panel dataset blockwise along the dimension of panel variable{p_end}
{phang}{helpb xtrantreat} randomizes a treatment variable in a panel dataset{p_end}
{phang}{helpb tofirsttreat} converts a treatment variable from an indicator variable to a variable specifying the first treatment period{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Beck, T., Levine, R., and Levkov, A. 2010. Big bad banks? The winners and losers from bank deregulation in the United States. {it:Journal of Finance} 65(5): 1637-1667.

{phang}
Callaway, B., and Sant'Anna, P.H.C. 2021. Difference-in-differences with Multiple Time Periods. {it:Journal of Econometrics} 225: 200-230.

{phang}
Cao, Y., and Chen, S. 2022. Rebel on the canal: Disrupted trade access and social conflict in China, 1650–1911. {it:American Economic Review} 112(5): 1555-1590.

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
