{smcl}
{* *! version 1.0 03Sep2024}{...}
{cmd:help dynamic_est}
{hline}

{pstd}

{title:dynamic_est}

{p2colset 5 16 16 2}{...}
{p2col:{hi: dynamic_est} {hline 2}}Visualizing dynamic effects in TWFE models. {stata "help dynamic_est":help dynamic_est}.{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 21 2}
{cmd:dynamic_est y [if]} 
[{cmd:,}
    {cmdab:treat}{cmd:(}{it:varlist}{cmd:)}
    {cmdab:time}{cmd:(}{it:varlist}{cmd:)}
    {cmdab:ref}{cmd:(}{it:integer}{cmd:)}
    {cmdab:absorb}{cmd:(}{it:string}{cmd:)}
    {cmdab:cluster}{cmd:(}{it:varlist}{cmd:)}
    {cmdab:cov}{cmd:(}{it:string}{cmd:)}
    {cmdab:level}{cmd:(}{it:string}{cmd:)}
    {cmdab:figname}{cmd:(}{it:string}{cmd:)}
    {cmdab:figtitle}{cmd:(}{it:string}{cmd:)}
    {cmdab:figsubtitle}{cmd:(}{it:string}{cmd:)}
    {cmdab:regtype}{cmd:(}{it:string}{cmd:)}
    ]

{p 8 21 2}where {it:y}, {it:treat}, {it:time}, {it:ref} are required.



{title:installation}
{phang2} *- net install {p_end}
{phang2}{inp:.} {stata "net install dynamic_est, from(https://mengke25.github.io/files/function/stata/dynamic_est) replace": net install dynamic_est, from(https://mengke25.github.io/files/function/stata/dynamic_est) replace }{p_end}



{title:Description}

{pstd}
simplifies the visualization of dynamic effects in two-way fixed effects (TWFE) models. It is ideal for use in event 
study or Difference-in-Differences (DID) analyses. This command allows users to visualize time-varying effects by 
specifying key regression parameters and reference points.
{p_end}



{p 4 8 2} {opt y(varlist)} (required) – The dependent variable.

{p 4 8 2} {opt treat(varlist)} (required) – A binary or intensity variable indicating the treatment assignment.

{p 4 8 2} {opt time(varlist)} (required) – The time variable in the panel dataset, it can be natural time or relative time.

{p 4 8 2} {opt ref(integer)} (required) – The reference period for the dynamic analysis.

{p 4 8 2} {opt absorb(string)} (optional) – The fixed effects or control variables to be absorbed.

{p 4 8 2} {opt cov(string)} (optional) – Covariates to be included in the model.

{p 4 8 2} {opt cluster(varlist)} (optional) – The clustering variable.

{p 4 8 2} {opt level(string)} (optional) – Confidence level for confidence intervals (default is 90). Options: 90, 95, 99.

{p 4 8 2} {opt regtype(string)} (optional) – Regression type, either {cmd:reg} (OLS, default) or {cmd:ppml} (Poisson Pseudo Maximum Likelihood).

{p 4 8 2} {opt figname(string)} (optional) – Name for the output graph.

{p 4 8 2} {opt figtitle(string)} (optional) – Title for the figure.

{p 4 8 2} {opt figsubtitle(string)} (optional) – Subtitle for the figure.



{title:Examples}

{phang2} *- Run example1 {p_end}
{phang2} standard-DID-specifaction {p_end}
{phang2}{inp:.} {stata "use https://mengke25.github.io/files/function/stata/dynamic_est/dynamic_est_sample2.dta,clear": use sample1.dta, clear }{p_end}
{phang2}{inp:.} {stata "dynamic_est lnv , treat(treat) time(year) ref(2009)  ":  dynamic_est lnv , treat(treat) time(year) ref(2009)  }{p_end}


{phang2} *- Run example2 {p_end}
{phang2} standard-DID-specifaction {p_end}
{phang2}{inp:.} {stata "use https://mengke25.github.io/files/function/stata/dynamic_est/dynamic_est_sample2.dta,clear": use sample1.dta, clear }{p_end}
{phang2}{inp:.} {stata "dynamic_est lnv , treat(treat_intens) time(year) ref(2009) absorb(id year) cluster(id) regtype(reg)":  dynamic_est lnv , treat(treat_intens) time(year) ref(2009) absorb(id year) cluster(id) regtype(reg)  }{p_end}


{phang2} *- Run example3 {p_end}
{phang2} standard-DID-specifaction {p_end}
{phang2}{inp:.} {stata "use https://mengke25.github.io/files/function/stata/dynamic_est/dynamic_est_sample2.dta,clear": use sample1.dta, clear }{p_end}
{phang2}{inp:.} {stata "dynamic_est v , treat(treat) time(year) ref(2009) absorb(id year) cluster(id) regtype(ppml) figname(fig) figtitle(my fig) ":  dynamic_est v , treat(treat) time(year) ref(2009) absorb(id year) cluster(id) regtype(ppml) figname(fig) figtitle(my fig) }{p_end}



{phang2} *- Run example4 {p_end}
{phang2} staggered-DID-specifaction {p_end}
{phang2}{inp:.} {stata "use https://mengke25.github.io/files/function/stata/dynamic_est/dynamic_est_sample1.dta,clear": use sample2.dta, clear }{p_end}
{phang2}{inp:.} {stata "dynamic_est lnv , treat(treat) time(t) ref(-1)  ": dynamic_est lnv , treat(treat) time(t) ref(-1)  }{p_end}


{phang2} *- Run example5 {p_end}
{phang2} staggered-DID-specifaction {p_end}
{phang2}{inp:.} {stata "use https://mengke25.github.io/files/function/stata/dynamic_est/dynamic_est_sample1.dta,clear": use sample2.dta, clear }{p_end}
{phang2}{inp:.} {stata "dynamic_est lnv , treat(treat_intens) time(t) ref(-1) absorb(id year) cluster(id) ":  dynamic_est lnv , treat(treat_intens) time(t) ref(-1) absorb(id year) cluster(id)  }{p_end}





{title:Author}

{phang}
{cmd:MengKe} China Institute for WTO studies, University of International Business and Economics, China.{break}
E-mail: {browse "mailto:uibemk@126.com":uibemk@126.com}. {break}
Blog: {browse "https://mengke25.github.io":mengke25.github.io} {break}
{p_end}

