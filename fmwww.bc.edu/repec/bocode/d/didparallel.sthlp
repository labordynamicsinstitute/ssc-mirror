{smcl}
{* *! version 1.0.0  16apr2026  GuanpengYan}{...}
{viewerjumpto "Syntax" "didparallel##syntax"}{...}
{viewerjumpto "Description" "didparallel##description"}{...}
{viewerjumpto "Options" "didparallel##options"}{...}
{viewerjumpto "Examples" "didparallel##examples"}{...}
{viewerjumpto "Stored results" "didparallel##results"}{...}
{viewerjumpto "Compatibility" "didparallel##compatibility"}{...}
{viewerjumpto "Author" "didparallel##author"}{...}
{title:Title}

{phang}
{bf:didparallel} {hline 2} testing parallel trends assumption (PTA) for difference-in-differences (DID) models

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:didparallel}
{it:estimatename}
{cmd:,}
{cmdab:treat:var(}{varname}{cmd:)}
[{it:options}]

{synoptset 40 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{cmdab:treat:var(}{varname}{cmd:)}}name of treatment variable{p_end}

{syntab:Optional}
{synopt:{cmdab:base:period(}{it:#}{cmd:)}}base (omitted/reference) period; default is -1{p_end}
{synopt:{cmdab:range(}{it:# #}{cmd:)}}range of lags and leads to consider in event study{p_end}
{synopt:{cmdab:frame(}{it:framename}{cmd:)}}name of the Stata frame to store results{p_end}
{synopt:{cmdab:noo:mit}}include omitted (base period) coefficients in the graph{p_end}
{synopt:{opt nofig:ure}}do not display figures{p_end}
{synopt:{cmdab:saveg:raph}({it:prefix}, [{cmdab:asis} {cmdab:replace}])}save all produced graphs to the current path.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{helpb xtset} {it:panelvar} {it:timevar} must be used to declare a panel dataset; see {manhelp xtset XT:xtset}.{p_end}
{p 4 6 2}{it:estimatename} should be an estimation saved by {helpb estimates store}; see {manhelp estimates_store R:estimates store}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:didparallel} provides an easy implementation of event study for difference-in-differences (DID) models, 
where policy adoption may be synchronized or staggered. It only takes three simple steps: 
(1) estimate the DID model; (2) store the result; 
and (3) run {cmd:didparallel} by specifying the stored result and the treatment variable.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt treatvar}{cmd:(}{varname}{cmd:)} specifies a dummy variable indicating whether a unit is treated in a particular period.
{cmd:didparallel} automatically converts the variable into an indicator equal to 1 only in the period when a unit first becomes treated, 
and shifts the indicator backward and forward relative to each unit's own timing to construct the leads and lags used in the test. 
For example, consider a panel of 5 units observed over 5 periods, 
where units start treatment in different periods ({bf:x} denotes a treated observation and {bf:o} an untreated observation):

{space 43}{it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5}
{space 42}{c TLC}{hline 19}{c TRC}
{space 38}{it:i=1} {c |} o   o   o   o   o {c |}
{space 38}{it:i=2} {c |} o   o   o   o   o {c |}
{space 38}{it:i=3} {c |} o   o   o   o   o {c |}
{space 38}{it:i=4} {c |} o   o   o   x   x {c |}
{space 38}{it:i=5} {c |} o   x   x   x   x {c |}
{space 42}{c BLC}{hline 19}{c BRC}
{space 43}{it:original treatment}
{space 52}{c |}
{space 52}v
{space 12}{it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5}{space 12}{it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5}{space 13}{it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5}
{space 11}{c TLC}{hline 19}{c TRC}{space 10}{c TLC}{hline 19}{c TRC}{space 11}{c TLC}{hline 19}{c TRC}
{space 7}{it:i=1} {c |} o   o   o   o   o {c |}{space 6}{it:i=1} {c |} o   o   o   o   o {c |}{space 7}{it:i=1} {c |} o   o   o   o   o {c |}
{space 7}{it:i=2} {c |} o   o   o   o   o {c |}{space 6}{it:i=2} {c |} o   o   o   o   o {c |}{space 7}{it:i=2} {c |} o   o   o   o   o {c |}
{space 7}{it:i=3} {c |} o   o   o   o   o {c |}<{hline 4} {it:i=3} {c |} o   o   o   o   o {c |} {hline 4}>{space 1}{it:i=3} {c |} o   o   o   o   o {c |}
{space 7}{it:i=4} {c |} o   o   x   o   o {c |}{space 6}{it:i=4} {c |} o   o   o   x   o {c |}{space 7}{it:i=4} {c |} o   o   o   o   x {c |}
{space 7}{it:i=5} {c |} x   o   o   o   o {c |}{space 6}{it:i=5} {c |} o   x   o   o   o {c |}{space 7}{it:i=5} {c |} o   o   x   o   o {c |}
{space 11}{c BLC}{hline 19}{c BRC}{space 10}{c BLC}{hline 19}{c BRC}{space 11}{c BLC}{hline 19}{c BRC}
{space 15}{it:1-period lag}{space 13}{it:initial treatment period}{space 14}{it:1-period lead}
{space 21}:{space 62}:
{space 21}{c |}{space 62}{c |}
{space 21}v{space 62}v
{space 12}{it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5}{space 21}{space 1}{space 1}{space 1}{space 1}{space 1}{space 1}{space 1}{space 1}{space 1}{space 1}{space 13}{it:t=1} {it:t=2} {it:t=3} {it:t=4} {it:t=5}
{space 11}{c TLC}{hline 19}{c TRC}{space 10}{space 21}{space 11}{c TLC}{hline 19}{c TRC}
{space 7}{it:i=1} {c |} o   o   o   o   o {c |}{space 6}{space 25}{space 7}{it:i=1} {c |} o   o   o   o   o {c |}
{space 7}{it:i=2} {c |} o   o   o   o   o {c |}{space 6}{space 25}{space 7}{it:i=2} {c |} o   o   o   o   o {c |}
{space 7}{it:i=3} {c |} o   o   o   o   o {c |}{space 1}{space 4}{space 20}{space 5}{space 1}{space 7}{it:i=3} {c |} o   o   o   o   o {c |}
{space 7}{it:i=4} {c |} x   o   o   o   o {c |}{space 6}{space 25}{space 7}{it:i=4} {c |} o   o   o   o   o {c |}
{space 7}{it:i=5} {c |} o   o   o   o   o {c |}{space 6}{space 25}{space 7}{it:i=5} {c |} o   o   o   o   x {c |}
{space 11}{c BLC}{hline 19}{c BRC}{space 10}{space 21}{space 11}{c BLC}{hline 19}{c BRC}
{space 15}{it:3-period lag}{space 16}{space 19}{space 16}{it:3-period lead}

{dlgtab:Optional}

{phang}
{cmdab:base:period(}{it:#}{cmd:)} specifies the reference period as a negative integer, which defaults to -1.
The reference period is dropped from the estimation to avoid perfect multicollinearity.

{phang}
{cmdab:range(}{it:# #}{cmd:)} sets the range of lags and leads to consider in the event study. 
For example, the option {cmd:range(-10 10)} would report a single regression coefficient capturing 10 or more periods prior/post treatment.  
A missing value "{cmd:.}" is allowed to leave either the lower or upper bound unrestricted.  
The default range is to include all
possible lags and leads.

{phang}
{opt frame(framename)} creates a Stata frame storing the estimates generated by the parallel trends test. 
The frame named {it:framename} is replaced if it already exists, and created if not. 

{phang}
{cmdab:noomit} keeps coefficients that Stata drops due to perfect collinearity in the plot. 
By default, these omitted coefficients are excluded from the graph.

{phang}
{opt nofigure} do not display figures. The default is to display all figures from parallel trend test if available.

{phang}
{cmdab:savegraph}({it:prefix}, [{cmdab:asis} {cmdab:replace}]) automatically and iteratively calls the {helpb graph save} to save all produced graphs to the current path, 
where {it: prefix} specifies the prefix added to {it: _graphname} to form a file name, 
that is, the graph named {it: graphname} is stored as {it: prefix_graphname}.gph. 
{cmdab:asis} and {cmdab:replace} are options passed to {helpb graph save}; 
for details, see {manhelp graph G-2: graph save}.
Note that this option only applies when {opt nofigure} is not specified. 

{marker examples}{...}
{title:Example 1: the impact of the Grand Canal's abandonment on rebellions (Cao and Chen, 2022)}

{phang2}{cmd:. use cao_chen.dta, clear}{p_end}
{phang2}{cmd:. xtset county year}{p_end}

{phang2}* Construct the difference-in-differences estimation and store the result{p_end}
{phang2}{cmd:. reghdfe rebel canal_post, absorb(i.county i.year) vce(cluster county)}{p_end}
{phang2}{cmd:. estimates store did_cao_chen}{p_end}

{phang2}* Implement the parallel trends test over a window of 10 periods before and after treatment{p_end}
{phang2}{cmd:. didparallel did_cao_chen, treatvar(canal_post) range(-10 10)}{p_end}

{title:Example 2: the impact of minimum wage increases on county-level teen employment (Callaway and Sant'Anna, 2021)}

{phang2}{cmd:. use mpdta, clear}{p_end}
{phang2}{cmd:. xtset countyreal year}{p_end}

{phang2}* Generate the treatment indicator{p_end}
{phang2}{cmd:. gen treat_post = (first_treat <= year) & (first_treat > 0)}{p_end}

{phang2}* Construct the difference-in-differences estimation and store the result{p_end}
{phang2}{cmd:. reghdfe lemp treat_post, absorb(i.countyreal i.year) vce(cluster countyreal)}{p_end}
{phang2}{cmd:. estimates store mpdta_example}{p_end}

{phang2}* Implement the parallel trends test{p_end}
{phang2}{cmd:. didparallel mpdta_example, treatvar(treat_post)}{p_end}

{title:Example 3: the impact of no-fault divorce reforms on suicide mortality (Stevenson and Wolfers, 2006)}

{phang2}{cmd:. use bacon_example.dta, clear}{p_end}
{phang2}{cmd:. xtset stfips year}{p_end}

{phang2}* Construct the difference-in-differences estimation and store the result{p_end}
{phang2}{cmd:. regress asmrs post pcinc asmrh cases i.stfips i.year, vce(cluster stfips)}{p_end}
{phang2}{cmd:. estimates store bacon_example}{p_end}

{phang2}* Implement the parallel trends test over a window of 10 periods before and after treatment{p_end}
{phang2}{cmd:. didparallel bacon_example, treatvar(post) range(-10 10)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
In addition to the estimation results carried over from the regression command, {cmd:didparallel} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(graph)}}names of all produced graphs{p_end}
{synopt:{cmd:e(frame)}}name of Stata frame{p_end}
{p2colreset}{...}

{marker compatibility}{...}
{title:Compatibility}

{phang}
{cmd:didparallel} is confirmed to be compatible with official commands {helpb regress}, 
{helpb xtreg} and {helpb areg} as well as the third-party command {helpb reghdfe}. 
Other commands, though not specifically tested, may also be compatible with {cmd:didparallel}.

{marker reference}{...}
{title:Reference}

{phang}
Stevenson, B., and Wolfers, J. 2006. Bargaining in the shadow of the law: Divorce laws and family distress. {it:Quarterly Journal of Economics} 121(1): 267-288.

{phang}
Goodman-Bacon, A. 2021. Difference-in-differences with variation in treatment timing. {it:Journal of Econometrics} 225(2): 254-277.

{phang}
Callaway, B., and Sant'Anna, P. H. C. 2021. Difference-in-differences with multiple time periods. {it:Journal of Econometrics} 225(2): 200-230.

{phang}
Cao, Y., and Chen, S. 2022. Rebel on the canal: Disrupted trade access and social conflict in China, 1650-1911. {it:American Economic Review} 112(5): 1555-1590.

{marker author}{...}
{title:Author}

{pstd}
Guanpeng Yan, Shandong University of Finance and Economics, CN{break}
guanpengyan@yeah.net{break}

{pstd}
Qiang Chen (correponding author), Shandong University, CN{break}
{browse "http://www.econometrics-stata.com":www.econometrics-stata.com}{break}
qiang2chen2@126.com{break}