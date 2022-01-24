 {smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:testout} {hline 2} Executes diagnostic testing of outliers by statistical tests of the bound first- and second-moment conditions for credible point estimates and credible standard errors, respectively.


{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:testout}
{it:y}
{it:x1 x2 ...}
{ifin}
[{cmd:,} {bf:iv}({it:varname}) {bf:k}({it:real}) {bf:alpha}({it:real}) {bf:maxw}({it:real}) {bf:prec}({it:real})]


{marker description}{...}
{title:Description}

{phang}
{cmd:testout} executes diagnostic testing of outliers by statistical tests of the bounded first- and second-moment conditions for consistency and root-n asymptotic normality based on 
{browse "https://doi.org/10.1080/07350015.2021.2019047":Sasaki & Wang (2021)}.
The command takes as input a scalar dependent variable {bf:y} and a list of independent variables {bf:x1}, {bf:x2}, ...
An {bf:iv} is an option, and {bf:x1} is treated as an endogenous variable if the option {bf:iv} is invoked.
The output of the command includes the p-values of the tests and the indicators of whether the tests reject the null hypotheses at the significance level {bf:alpha}.
If the test rejects the null hypothesis of the bounded first-moment condition for consistency, then the point estimates of {bf:reg} (or {bf:ivreg} when the option {bf:iv} is invoked) are unreliable.
If the test rejects the null hypothesis of the bounded second-moment condition for root-n asymptotic normality, then the standard errors of {bf:reg} (or {bf:ivreg} when the option {bf:iv} is invoked) are unreliable.


{marker options}{...}
{title:Options}

{phang}
{bf:iv({it:varname})} sets an instrumental variable.
If this option is not invoked, then the command executes the outlier tests for the OLS ({bf:reg}).
If this option is invoked, then the command executes the outlier tests for the 2SLS ({bf:ivreg}) where the first independent variable {bf:x1} is treated as an endogenous variable instrumented by the {bf:iv}.

{phang}
{bf:k({it:real})} sets the number of extreme order statistics to be used for the tests. 
This number has to be an integer no smaller than 3. 
Not invoking this option will automatically set {bf:k} to the five percent of the sample size.

{phang}
{bf:alpha({it:real})} sets the significace level of the statistical tests. 
The default value is {bf: alpha(0.05)}.

{phang}
{bf:maxw({it:real})} sets the maximum value of the set of the tail index in the composite alternative over which the likelihood function in the numerator of the likelihood ratio test statistic is integrated with respect to the Lebesgue measure. 
The default value is {bf: maxw(2)}.

{phang}
{bf:prec({it:real})} sets the precision of approximating the null distribution of the test statistic by simulations.
Setting this number to a smaller value results in more accurate tests and p-values at the expense of a longer execution time of the command.
The default value is {bf: prec(0.00025)}.


{marker examples}{...}
{title:Examples}

{phang}Consider the following regression:

{phang}{cmd:. use "tip_chicago.dta"}{p_end}
{phang}{cmd:. regress wh_pop_change indicat min* income vacant rent single public}{p_end}

{phang}The outlier tests for this regression can be implemented by:

{phang}{cmd:. testout wh_pop_change indicat min* income vacant rent single public}{p_end}

{phang}We can repeat these lines for another city:

{phang}{cmd:. use "tip_washington.dta"}{p_end}
{phang}{cmd:. regress wh_pop_change indicat min* income vacant rent single public}{p_end}
{phang}{cmd:. testout wh_pop_change indicat min* income vacant rent single public}{p_end}


{marker stored}{...}
{title:Stored results}

{phang}
{bf:testout} stores the following in {bf:r()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:r(N)} {space 10}observations
{p_end}
{phang2}
{bf:r(k)} {space 10}number of extreme order statistics
{p_end}
{phang2}
{bf:r(alpha)} {space 6}level of statistical significance
{p_end}
{phang2}
{bf:r(pval1)} {space 6}p-value for the test of consistency
{p_end}
{phang2}
{bf:r(pval2)} {space 6}p-value for the test of root-n normality
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:r(cmd)} {space 8}{bf:testout}
{p_end}
{phang2}
{bf:r(mtd)} {space 8}{bf:reg} or {bf:ivreg}
{p_end}
{phang2}
{bf:r(test1)} {space 6}result of the test of consistency
{p_end}
{phang2}
{bf:r(test2)} {space 6}result of the test of root-n normality
{p_end}


{title:Reference}

{p 4 8}Y. Sasaki & Y. Wang. 2021. Diagnostic Testing of Finite Moment Conditions for the Consistency and Root-N Asymptotic Normality of the GMM and M Estimators,
{it:Journal of Business & Economic Statistics}, forthcoming.
{browse "https://doi.org/10.1080/07350015.2021.2019047": Link to Paper}.
{p_end}


{title:Authors}

{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}

{p 4 8}Yulong Wang, Syracuse University, Syracuse, NY.{p_end}
