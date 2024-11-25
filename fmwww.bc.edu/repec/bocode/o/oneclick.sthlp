{smcl}
{* 23 November 2024}{...}
{hline}
help for {hi:oneclick}
{hline}


{title:Title}

{p 4 16 2}
{hi:oneclick} —— Helps you to quickly screen for control variables that keep 
the explanatory variables at a certain level of significance.{p_end}


{title:Syntax}

{p 4 13 2}
{cmdab:oneclick} y controls, 
{cmdab:m:ethod:}{cmd:(}regression{cmd:)}
{cmdab:p:value:}{cmd:(}p-value{cmd:)}
{cmdab:fix:var:}{cmd:(}x and other FE{cmd:)}
[
{cmdab:o:ptions:}{cmd:(}extra-options{cmd:)}
{cmdab:z:value:}
{cmdab:t:hreshold:}{cmd:(}int{cmd:)}
{cmdab:s:aveplace:}{cmd:(}filename{cmd:)}
{cmdab:best}
{cmdab:full}
]
{p_end}

{p 4 4 2}
If you're using the reghdfe command, put the fixed effects into the absorb as 
much as possible to speed up the calculations.
{p_end}

{p 4 4 2}
If you're not used to the new version of {it:oneclick}, I've kept {it:oneclick5} in this 
version. you can use {cmd:oneclick5} to implement the functionality of the previous version.
{p_end}

{title:Description}

{p 8 4 2}
By entering your control variables, the {it:oneclick} command
helps you to select all true subsets of the control variables and add them to 
the regression in turn, and at the end only the combinations at the level of 
significance you are satisfied with are listed. I constructed the subset 
filtering method from scratch based on the bitmap algorithm, which is faster 
than {it:tuples}.
{p_end}


{title:Requirements}

{phang}
{hi:varlist} specifies the dependent variable and control variables to be screened. 
If you type {hi:oneclick a b c}, then a is your dependent variable, b and c are 
the control variables waiting to be filtered.
{p_end}

{phang}
{cmdab:m:ethod:(}{it:regression}{cmd:)} specifies the estimator you want to use. 
{p_end}

{phang}
{cmdab:p:value:(}{it:p-value}{cmd:)} specifies the level of significance.
{p_end}

{phang}
{cmdab:fix:var:(}{it:varlist}{cmd:)} specifies the independent variable and other 
variables that you want to fix in regression. If you type a b c, then a is you 
independent variable, b and c are the integral control variables.
{p_end}

{phang}
{cmdab:o:ptions:(}{it:extra-options}{cmd:)} specifies the additional options in regression.
If you use reghdfe, you can add {hi:o(absorb(#))}.
{p_end}

{phang}
{cmdab:z:value:} specifies whether regression is judged by z-values.If you use 
a regression like logit, probit, or xtreg (with default), you must add the z option
{p_end}

{phang}
{cmdab:t:hreshold:} specifies the minimum number of optional control variables you 
need to keep in the result.
{p_end}

{phang}
{cmdab:s:aveplace:} specifies what you need to rename the result file to.
{p_end}

{phang}
{cmdab:best:} let oneclick automatically pick the best regression results for you.
{p_end}

{phang}
{cmdab:full:} let oneclick fill in the results for you to make it more readable.
{p_end}

{title:Results}

{p 8 4 2}
After running {hi:oneclick}, you will see a dta file named subset in the current 
working directory. Among them, the variable subset represents the control variable 
that can make the explanatory variable significant, the variable positive takes 
1 to indicate positive significance, and takes 0 to indicate negative significance.
{p_end}


{title:Code examples}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:regress}. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight) p(0.1) m(reg)"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:regress} with fixed-effect. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight i.foreign) p(0.1) m(reg)"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:regress} with fixed-effect and robust
standard error. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight i.foreign) p(0.1) m(reg) o(vce(robust))"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:regress} with fixed-effect and cluster
standard error. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight i.foreign) p(0.1) m(reg) o(vce(cluster foreign))"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:xtreg} with fixed-effect. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}
{p 4 4 2} **- Time fixed-effect: year. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"bys foreign: gen year = _n"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"xtset foreign year"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight i.year) p(0.1) m(xtreg) o(fe)"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:xtreg} with fixed-effect and robust
standard error. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}
{p 4 4 2} **- Time fixed-effect: year. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"bys foreign: gen year = _n"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"xtset foreign year"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight i.year) p(0.1) m(xtreg) o(fe vce(robust))"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:xtreg} with fixed-effect and cluster
standard error. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}
{p 4 4 2} **- Time fixed-effect: year. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"bys foreign: gen year = _n"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"xtset foreign year"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight i.year) p(0.1) m(xtreg) o(fe vce(cluster foreign))"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:reghdfe} with fixed-effect. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}
{p 4 4 2} **- Time fixed-effect: year. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"bys foreign: gen year = _n"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight) p(0.1) m(reghdfe) o(absorb(foreign year))"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:reghdfe} with fixed-effect and robust 
standard error. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}
{p 4 4 2} **- Time fixed-effect: year. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"bys foreign: gen year = _n"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight) p(0.1) m(reghdfe) o(absorb(foreign year) vce(robust))"'}
{p_end}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in {cmd:reghdfe} with fixed-effect and cluster 
standard error. {p_end}
{p 4 4 2} **- Individual fixed-effect: foreign. {p_end}
{p 4 4 2} **- Time fixed-effect: year. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"bys foreign: gen year = _n"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick price mpg rep78, fix(weight) p(0.1) m(reghdfe) o(absorb(foreign year) vce(cluster foreign))"'}
{p_end}

{p 4 4 2} *- If you use regression methods such as logit or probit that base significance 
judgments on z-values rather than t-values, don't forget to add the z option to the end 
of {cmd:oneclick}. {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick foreign mpg rep78, fix(weight) p(0.1) m(logit) z"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"oneclick foreign mpg rep78, fix(weight) p(0.1) m(probit) z"'}
{p_end}


{title:Video tutorial}

{p 4 4 2}
Watch the latest video at this link: {browse "https://space.bilibili.com/40545247/channel/collectiondetail?sid=386923":oneclick video tutorial} {break}


{title:Author}

{p 4 4 2}
{cmd:Basic information}{break}
Name: Shutter Zor (左祥太){break}
Affiliation: Accounting Department, Xiamen University.{break}
E-mail: {browse "mailto:Shutter_Z@outlook.com":Shutter_Z@outlook.com} {break}

{p 4 4 2}
{cmd:Other information}{break}
Blog: {browse "https://shutterzor.cn/":blog link} {break}
Bilibili: {browse "https://space.bilibili.com/40545247/":拿铁一定要加冰} {break}
WeChat Official Account: {browse "https://shutterzor.cn/images/QRcode.png":OneStata} {break}

{title:Other commands i have written}

{pstd}

{synoptset 30 }{...}
{synopt:{help onetext} (if installed)} {stata ssc install onetext} (to install){p_end}
{synopt:{help econsig} (if installed)} {stata ssc install econsig} (to install){p_end}
{synopt:{help wordcloud} (if installed)} {stata ssc install wordcloud} (to install){p_end}
{p2colreset}{...}


{title:Acknowledgments}

{p 4 4 2}
Thank you to Professor {hi:Yujun,Lian (arlionn)} for his programming syntax guidance and 
Professor {hi:Christopher F. Baum} for his careful bug checking.
{p_end}
{p 4 4 2}
Thanks to Bilibili users (导导们) for their suggestions on the initial construction of 
this project.
{p_end}


