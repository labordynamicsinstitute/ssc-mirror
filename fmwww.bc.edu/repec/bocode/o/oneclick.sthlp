{smcl}
{* 28 April 2022}{...}
{hline}
help for {hi:oneclick}
{hline}


{title:Title}
{p 4 4 2}
{bf:oneclick} —— Helps you to quickly screen for control variables that keep 
the explanatory variables at a certain level of significance.{p_end}


{title:Syntax}
{p 4 4 2}
{cmdab:oneclick} {varlist}, 
{cmdab:dep:endentvariable:}{cmd:(}varname{cmd:)}
{cmdab:ind:ependentvariable:}{cmd:(}varname{cmd:)}
{cmdab:s:ignificance:}{cmd:(}real{cmd:)}
{cmdab:m:ethod:}{cmd:(}regression{cmd:)}
[
{cmdab:r:obust:}
{cmdab:cl:uster:}
]
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
{cmd:dependentvariable(}{it:varname}{cmd:)} specifies the dependent variable.
{cmd:independentvariable(}{it:varname}{cmd:)} specifies the inddependent variable.
{cmd:significance(}{it:varname}{cmd:)} specifies the level of significance 
you want for the explanatory variable.
{cmd:method(}{it:varname}{cmd:)} specifies the estimator you want to use. 
Remember that {hi:oneclick} uses the significance level calculated by the 
t-distribution, so the estimator can only be specified if it has a degree of 
freedom option in its return value.
{p_end}

{title:Results}
{p 4 4 2}
After running {hi:oneclick}, a list of results will appear on your screen and a 
new variable will be generated in the stata window, represents all subsets that 
satisfy your significance requirement. And under your current work path, a file 
called subset is generated containing the true subset of control variables that 
meet the significance requirements as well as the coefficients of the explanatory 
variables, the standard errors of the explanatory variables, the t-values of the 
explanatory variables and the r-squared of the model.
{p_end}

{title:Examples}
{p 4 4 2} *- Selecting the combination from mpg and rep78 that will make weight
significant at the 1% level. {p_end}
{p 4 4 2}{inp:.} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"oneclick mpg rep78, dep(price) ind(weight) s(0.1) m(reg)"'}
{p_end}


{title:Author}
{p 4 4 2}
{cmd:Shutter Zor(左祥太)}{break}
School of Accountancy, Wuhan Textile University.{break}
E-mail: {browse "mailto:Shutter_Z@outlook.com":Shutter_Z@outlook.com}. {break}

{title:Acknowledgments}
{p 4 4 2}
Thanks to Professor {hi:Yujun,Lian (arlionn)} for his programming syntax guidance and 
Professor {hi:Christopher F. Baum} for his careful bug checking.
Thanks to Bilibili users for their suggestions on the initial construction of 
this project.
{p_end}