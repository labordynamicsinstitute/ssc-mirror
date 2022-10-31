{smcl}
{* 28 April 2022}{...}
{hline}
help for {hi:oneclick}
{hline}


{title:Title}

{p 4 4 2}
{hi:oneclick} —— Helps you to quickly screen for control variables that keep 
the explanatory variables at a certain level of significance.{p_end}


{title:Syntax}

{p 4 4 2}
{cmdab:oneclick} y controls, 
{cmdab:m:ethod:}{cmd:(}regression{cmd:)}
{cmdab:p:value:}{cmd:(}p-value{cmd:)}
{cmdab:fix:var:}{cmd:(}x and other FE{cmd:)}
[
{cmdab:o:ptions:}
{cmdab:z:value:}
]
{p_end}

{p 4 4 2}
If you're using the reghdfe command, put the fixed effects into the absorb as 
much as possible to speed up the calculations.
{p_end}


{title:Description}

{p 4 4 2}
{cmd:oneclick} By entering your control variables, the {it:oneclick} command
helps you to select all true subsets of the control variables and add them to 
the regression in turn, and at the end only the combinations at the level of 
significance you are satisfied with are listed. It is important to note that 
the {hi:tuples} command must be downloaded in advance. This command is a new 
development based on the {hi:tuples} command and it's very useful, especially 
when we do not know what control variables are appropriate.
{p_end}


{title:Requirements}

{p 4 4 2}
{hi:varlist} specifies the dependent variable and control variables to be screened. 
If you type {hi:oneclick a b c}, then a is your dependent variable, b and c are 
your control variables.
{p_end}

{p 4 4 2}
{cmd:method(}{it:regression}{cmd:)} specifies the estimator you want to use. 
{p_end}

{p 4 4 2}
{cmd:pvalue(}{it:real}{cmd:)} specifies the level of significance.
{p_end}

{p 4 4 2}
{cmd:fixvar(}{it:varlist}{cmd:)} specifies the inddependent variable and other 
variables that you want to fix in regression. If you type a b c, then a is you 
inddependent variable, b and c are the integral control variables.
{p_end}

{p 4 4 2}
{cmd:options(}{it:varname}{cmd:)} specifies the additional options in regression.
If you use reghdfe, you can add {hi:o(absorb(#))}.
{p_end}

{p 4 4 2}
{it:zvalue}{cmd:)} specifies whether regression is judged by z-values.If you use 
a regression like logit, you must add the z option
{p_end}


{title:Results}

{p 4 4 2}
After running {hi:oneclick}, you will see a dta file named subset in the current 
working directory. Among them, the variable subset represents the control variable 
that can make the explanatory variable significant, the variable positive takes 
1 to indicate positive significance, and takes 0 to indicate negative significance.
{p_end}


{title:Examples}

{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 10% level in OLS. {p_end}

{p 4 4 2}{inp:.} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"oneclick price mpg rep78, fix(weight) p(0.1) m(reg)"'}
{p_end}


{title:Author}

{p 4 4 2}
{cmd:Shutter Zor(左祥太)}{break}
School of Accountancy, Wuhan Textile University.{break}
E-mail: {browse "mailto:Shutter_Z@outlook.com":Shutter_Z@outlook.com}. {break}


{title:Acknowledgments}

{p 4 4 2}
Thank you to Professor {hi:Yujun,Lian (arlionn)} for his programming syntax guidance and 
Professor {hi:Christopher F. Baum} for his careful bug checking.
Thanks to Bilibili users for their suggestions on the initial construction of 
this project.
{p_end}

