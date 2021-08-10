{smcl}
help {hi:regsave}
{hline}
{title:Title}

{p 4 4 2}{cmd:regsave} {hline 2} Save regression results to a Stata-formatted dataset.

{title:Syntax}

{p 4 4 2}Replace data in memory with current regression results

{p 8 14 2}{cmd:regsave} [{it:namelist}] [, {cmdab:t:stat} {cmdab:p:val} {cmd:ci} {cmdab:l:evel(}#{cmd:)} {cmd:nose} {cmdab:cmd:line} {cmd:autoid} {cmd:covar(}{it:namelist}{cmd:)} 
{cmd:detail(}{it:type}{cmd:)} {cmd:coefmat(}{it:matname}{cmd:)} {cmd:varmat(}{it:matname}{cmd:)} {cmd:double} 
{cmdab:addlab:el(}{it:newvarname1, label1, newvarname2, label2, ...}{cmd:)} {cmd:addvar(}{it:name1, coef1, stderr1, name2, coef2, stderr2, ...}{cmd:)}
{cmd:table(}{it:table_suboptions}{cmd:)}]

{p 4 4 2}Save current regression results to a Stata-formatted dataset

{p 8 14 2}{cmd:regsave} [{it:namelist}] {cmd:using} {it:filename} [, {cmdab:t:stat} {cmdab:p:val} {cmd:ci} {cmdab:l:evel(}#{cmd:)} {cmd:nose} {cmdab:cmd:line} 
{cmd:autoid} {cmd:covar(}{it:namelist}{cmd:)} 
{cmd:detail(}{it:type}{cmd:)} {cmd:coefmat(}{it:matname}{cmd:)} {cmd:varmat(}{it:matname}{cmd:)} {cmd:double}
{cmdab:addlab:el(}{it:newvarname1, label1, newvarname2, label2, ...}{cmd:)} 
{cmd:addvar(}{it:name1, coef1, stderr1, name2, coef2, stderr2, ...}{cmd:)} {cmd:table(}{it:table_suboptions}{cmd:)} {cmd:append} {cmd:replace}]

{p 4 4 2}where

{p 8 14 2}{it:table_suboptions} are

{p 12 14 2}{cmd:table(}{it:name} [, {cmd:order(}{it:string}{cmd:)} {cmd:format(}{it:%}{help fmt}{cmd:)} {cmdab:paren:theses(}{it:statlist}{cmd:)} {cmdab:brack:ets(}{it:statlist}{cmd:)} {cmdab:aster:isk}{cmd:(}{help numlist}{cmd:)}]{cmd:)}

{p 8 14 2}{it: namelist} corresponds to names of regressors for estimation results currently stored in {cmd:e()},

{p 8 14 2}{it: type} can be either {it:all}, {it:scalars}, or {it:macros}, and

{p 8 14 2}{it: statlist} is one or more of the following: {it: coef, stderr, tstat, pval, ci_lower, ci_upper}




{title:Description}

{p 4 4 2}{cmd:regsave} fetches output from Stata's {cmd:e()} macros, scalars, and matrices and stores them in a Stata-formatted dataset.  It has two main uses:

{p 8 14 2}1. {cmd:regsave} provides a user-friendly way to manipulate a large number of regression results by allowing you to apply Stata's data manipulation commands to those results.
For example, you can save the results of 100 regressions to a dataset and then use Stata to analyze how coefficients change across different regression specifications.
Or, you can {help outsheet:outsheet} these results and analyze them using external utilities like Microsoft Excel's pivot table.

{p 8 14 2}2. {cmd:regsave} saves your regression results to a nicely formatted table when you specify its {cmd:table()} option.  You can then {help outsheet:outsheet} or {help xmlsave:xmlsave} your data and open it in another program.
LaTeX users can use {help texsave:texsave} (if installed) to automatically output their table to LaTeX format (see example 7 below).


{title:Options}

{p 4 8 2}
{cmd:tstat} calculates t-statistics by dividing {it:coef} by {it:stderr}.


{p 4 8 2}
{cmd:pval} calculates two-tailed p-values using the t-statistic and the residual degrees of freedom (as retrieved from {cmd:e(df_r)}).  If the residual degrees of freedom are unavailable, the p-value is calculated by assuming normality.


{p 4 8 2}
{cmd:ci} calculates confidence intervals according to the confidence level set by {cmd:level} (default controlled by {help set level}) and the residual degrees of freedom (as retrieved from {cmd:e(df_r)}).
If the residual degrees of freedom are unavailable, the confidence interval is calculated by assuming normality.


{p 4 8 2}
{cmd:level(}#{cmd:)} specifies the confidence level, as a percentage, for confidence intervals.  The default is level(95) or as set by {help set level}.


{p 4 8 2}
{cmd:nose} drops standard errors from the reported results.


{p 4 8 2}
{cmd:cmdline} stores the Stata command code that produced the estimation results, if it's available from {cmd:e(cmdline)}.


{p 4 8 2}
{cmd:autoid} provides an id number for your saved results. This is useful when saving a large number of results to the same dataset. {cmd:autoid} can be used as a complement to and/or substitute for {cmd:addlabel()}.


{p 4 8 2}
{cmd:covar(}{it:namelist}{cmd:)} instructs Stata to store all possible combinations of covariances for the variables specified in {it:namelist}.


{p 4 8 2}
{cmd:detail(}{it:type}{cmd:)} stores additional statistics.  If {it:type} is {it:all}, {cmd:regsave} retrieves all results available in {cmd:e()}.  The user may alternatively specify
a subset of those results: either {it:scalars} or {it:macros}.


{p 4 8 2}
{cmd:coefmat(}{it:matname}{cmd:)} instructs Stata to retrieve coefficient estimates from {it:matname} instead of {cmd:e(b)}, the default.  See the notes section below for more information.


{p 4 8 2}
{cmd:varmat(}{it:matname}{cmd:)} instructs Stata to retrieve variance estimates from {it:matname} instead of {cmd:e(V)}, the default.  See the notes section below for more information.


{p 4 8 2}
{cmd:double} specifies that all numeric statistics be stored as doubles instead of floats.


{p 4 8 2}
{cmd:addlabel(}{it:newvarname1, label1, newvarname2, label2, ...}{cmd:)} instructs Stata to create additional variables containing label data.  The user-specified {it:label1} is stored in {it:newvarname1}, {it:label2}
is stored in {it:newvarname2}, etc.  This is a good way to label your results when storing lots of regression results together in one dataset.
It is also a good way to store additional statistics that are not automatically retrieved by {cmd:regsave} (see example 4 below).


{p 4 8 2}
{cmd:addvar(}{it:name1, coef1, stderr1, name2, coef2, stderr2, ...}{cmd:)} allows the user to store estimates for variables that are not currently stored in {cmd:e(b)} and {cmd:e(V)} (see example 5 below).


{p 4 8 2}
{cmd:table(}{it:name, suboptions}{cmd:)} stores estimates in a traditional table form, i.e., with standard errors (and t-statistic and p-values, if specified)
listed below coefficient estimates in a single column.  {it:name} specifies the name of the column.  

{p 8 14 2}{ul:{it: suboptions}}:

{p 8 14 2}{cmd:order(}{it:string}{cmd:)} allows the user to specify the table's row order.  The name {it:regvars} can be used to refer to all regression variables retrieved by {cmd:regsave} (see example 6 below).  

{p 8 14 2}{cmd:format(}{it:%}{help fmt}{cmd:)} suboption allows you to specify the formats of the numbers in your table.
For example, a format of %7.2f specifies that numbers are to be rounded to two decimal places.  See {help format:[D] format} for details.  

{p 8 14 2}{cmd:parentheses(}{it:statlist}{cmd:)} suboption puts parentheses around {it:statlist}.  

{p 8 14 2}{cmd:brackets(}{it:statlist}{cmd:)} suboption puts brackets around {it:statlist}.

{p 8 14 2}{cmd:asterisk(}{help numlist}{cmd:)} allows you to specify up to three (descending) significance levels for asterisks.  
For example, {cmd:asterisk(}5 1{cmd:)} place a */** next to coefficients that are significant at the 5/1% level, respectively.
Specifying {cmd:asterisk()} sets a default, which places a */**/*** next to coefficients that are significant at the 10/5/1% level.


{p 4 8 2}
{cmd:append} appends the regression results to the Stata-formatted dataset {it:filename}.


{p 4 8 2}
{cmd:replace} overwrites {it:filename}.


{title:Notes}

{p 4 4 2}
By default, Stata retrieves coefficient and variance estimates from {cmd:e(b)} and {cmd:e(V)}, respectively.  One exception is if the user executes {cmd:regsave} after running a {cmd:dprobit} estimation.  
In that case, {cmd:regsave} retrieves the estimates from {cmd:e(dfdx)} and {cmd:e(se_dfdx)}.
Use options {cmd:coefmat(}{it:matname}{cmd:)} and {cmd:varmat(}{it:matname}{cmd:)} if you want to retrieve estimates from matrices that differ from these defaults.
Note that {cmd:regsave} will take the square root of {cmd:varmat(}{it:matname}{cmd:)} unless the string "se" is detected in {it:matname} (in which case it assumes that standard errors, not variances, are reported).


{title:List of retrieved items}

{p 4 4 2}{cmd:regsave} automatically retrieves the following items from {cmd:e()} when they are available:


{col 8}Matrices
{col 10}{cmd:e(b)}{col 28} Coefficient estimates (can be overridden with option {cmd:coefmat(}{it:matname}{cmd:)})
{col 10}{cmd:e(V)}{col 28} Variance-covariance matrix (can be overridden with option {cmd:varmat(}{it:matname}{cmd:)})

{col 8}Scalars
{col 10}{cmd:e(N)}{col 28} Number of observations
{col 10}{cmd:e(r2)}{col 28} R-squared


{p 4 4 2}If {cmd:detail(}{it:all}{cmd:)} is specified, {cmd:regsave} retrieves all available statistics from {cmd:e()}.


{title:Saved results}

{p 4 4 2}{cmd:regsave} saves the following scalars to {cmd:r()}:

{col 10}{cmd:r(N)}{col 28} Number of rows in the newly created dataset
{col 10}{cmd:r(k)}{col 28} Number of columns in the newly created dataset


{title:Examples}

{p 4 4 2}1. Store regression results in the active dataset:

{col 8}{cmd:. {stata sysuse auto.dta, clear}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length}}

{col 8}{cmd:. {stata regsave}}

{col 8}{cmd:. {stata browse}}


{p 4 4 2}2. Store regression results in a file:

{col 8}{cmd:. {stata sysuse auto.dta, clear}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length}}

{col 8}{cmd:. {stata regsave using results, tstat covar(mpg trunk) replace}}


{p 4 4 2}3. Store regression results in table form:

{col 8}{cmd:. {stata sysuse auto.dta, clear}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length}}

{col 8}{cmd:. {stata regsave, tstat pval table(regression_1, parentheses(stderr) brackets(tstat pval))}}

{col 8}{cmd:. {stata browse}}


{p 4 4 2}4. Store a user-created statistic and label a series of regressions:

{col 8}{cmd:. {stata sysuse auto.dta, clear}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length if gear_ratio > 3}}

{col 8}{cmd:. {stata regsave using results, addlabel(scenario, gear ratio > 3, dataset, auto) replace}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length if gear_ratio <= 3}}

{col 8}{cmd:. {stata regsave using results, addlabel(scenario, gear ratio <=3, dataset, auto) append}}


{p 4 4 2}5. Store regression results and add coefficient and standard error estimates for an additional variable:

{col 8}{cmd:. {stata sysuse auto.dta, clear}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length}}

{col 8}{cmd:. {stata local mycoef = _b[mpg]*5}}

{col 8}{cmd:. {stata local mystderr = _se[mpg]*5}}

{col 8}{cmd:. {stata regsave, addvar(mpg_5, `mycoef', `mystderr')}}

{col 8}{cmd:. {stata browse}}


{p 4 4 2}6. Run a series of regressions and outsheet them into a text file that can be opened by MS Excel:

{col 8}{cmd:. {stata sysuse auto.dta, clear}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length}}

{col 8}{cmd:. {stata regsave mpg trunk using results, table(OLS_stderr, order(regvars r2)) replace}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length, robust}}

{col 8}{cmd:. {stata regsave mpg trunk using results, table(Robust_stderr, order(regvars r2)) append}}

{col 8}{cmd:. {stata use results, clear}}

{col 8}{cmd:. {stata outsheet using table.txt, replace}}


{p 4 4 2}7. Run a series of regressions and output the results in a nice LaTeX format that can be opened by Scientific Word. (This example requires the user-written command
{help texsave:texsave} to be installed.):

{col 8}{cmd:. {stata sysuse auto.dta, clear}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length}}

{col 8}{cmd:. {stata regsave mpg trunk using results, table(OLS, order(regvars r2) format(%5.3f) parentheses(stderr) asterisk()) replace}}

{col 8}{cmd:. {stata regress price mpg trunk headroom length, robust}}

{col 8}{cmd:. {stata regsave mpg trunk using results, table(Robust, order(regvars r2) format(%5.3f) parentheses(stderr) asterisk()) append}}

{col 8}{cmd:. {stata use results, clear}}

{col 8}{cmd:. {stata replace var = subinstr(var,"_coef","",.)}}

{col 8}{cmd:. {stata replace var = "" if strpos(var,"_stderr")!=0}}

{col 8}{cmd:. {stata replace var = "R-squared" if var == "r2"}}

{col 8}{cmd:. {stata rename var Variable}}

{col 8}{cmd:. {stata texsave using "table.tex", title(Regression results) footnote("A */**/*** next to the coefficient indicates significance at the 10/5/1% level") replace}}


{title:Author}

{p 4 4 2}Julian Reif, University of Chicago

{p 4 4 2}jreif@uchicago.edu


{title:Also see}

{p 4 4 2}
{help estimates store:estimates store},
{help outreg2:outreg2} (if installed),
{help sortobs:sortobs} (if installed),
{help texsave:texsave} (if installed),
{help svret:svret} (if installed)

