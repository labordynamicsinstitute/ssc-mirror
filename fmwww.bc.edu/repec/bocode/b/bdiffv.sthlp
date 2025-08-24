{smcl}
{hline}
help {hi:bdiffv}{right: 14Aug2025, {browse "https://shutterzor.cn":blog}}
{hline}

{title:Title}

{p 4 16 2}
{hi:bdiffv} —— Extended commands for bdiff, visualizing differences (Bootstrap and Permutaion tests) between two groups.{p_end}


{title:Syntax}

{p 8 14 4}{cmd:bdiffv,} 
{cmdab:g:roup:(}{it:groupvar}{cmd:)}
{cmdab:m:odel:(}{it:string}{cmd:)}
[{it:bdiff_options}]
[{it:bdiffv_options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:({it:bdiff}) Main}
{synopt :{opt g:roup(varname)}}specify a dummy variable to tag the sample into two groups.{p_end}
{synopt :{opt m:odel(string)}}define the regression model, e.g., model(reg y x).{p_end}

{syntab:({it:bdiff}) Test parameters}
{synopt :{opt r:eps(#)}}set number of repetitions to {it:#}. Defult is 100.{p_end}
{synopt :{opt seed(#)}}set random-number seed to {it:#}.{p_end}
{synopt :{opt bs:ample}}use bootstrap sample (sampling with replacement) to perform Fisher's Permuation test. In default, {help bdiff} uses the original sample to perform the Fisher's Permuation test.{p_end}
{synopt :{opt sur:test}}perform SUR test, see {help suest}.{p_end}

{syntab:({it:bdiff}) Reporting}
{synopt :{opt f:irst}}report the coeffiencts difference and empirical p-value for the first regressor in the model.{p_end}
{synopt :{opt g:ap}}to add extra spacing between rows.{p_end}
{synopt :{opt no:dots}}suppress replication dots.{p_end}
{synopt :{opt d:ec(#)}}to display # decimal places for all statistics. Defult is 3.{p_end}
{synopt :{opt bd:ec(#)}}to display # decimal places for just the coefficient. Defult is 3.{p_end}
{synopt :{opt pd:ec(#)}}to display # decimal places for just the empirical p-value. Defult is 3.{p_end}
{synopt :{opt det:ail}}report the regression results for both groups.{p_end}

{syntab:({it:bdiffv}) Reporting}
{synopt :{opt nor:eport}}suppress {help bdiff} test results.{p_end}

{syntab:({it:bdiffv}) General Plotting}
{synopt :{opt xs:hift(#)}}set the horizontal axis group offset to change the interval of the confidence interval. This value must be controlled between 0 and 0.5 (the default value is 0.1).{p_end}
{synopt :{opt con:tour}}set whether to display significance levels at the same height.{p_end}

{syntab:({it:bdiffv}) Advanced Plotting}
{syntab:1. Change the look of confidence intervals}
{synopt :{opt cic:olor()}}change the color of the confidence intervals. For details, refer to {help colorstyle}.{p_end}
{synopt :{opt cip:attern()}}change the line pattern of the confidence intervals. For details, refer to {help linepatternstyle}.{p_end}

{syntab:2. Change the look of scatter points}
{synopt :{opt scac:olor()}}change the color of the scatter points (coefficients). For details, refer to {help colorstyle}.{p_end}
{synopt :{opt scas:ize()}}change the size of the scatter points (coefficients). For details, refer to {help markersizestyle}.{p_end}
{synopt :{opt scasy:mbol()}}change the symbol of the scatter points (coefficients). For details, refer to {help symbolstyle}.{p_end}

{syntab:3. Change the look of connection lines}
{synopt :{opt linec:olor()}}change the color of the connection lines. For details, refer to {help colorstyle}.{p_end}
{synopt :{opt linep:attern()}}change the line pattern of the connection lines. For details, refer to {help linepatternstyle}.{p_end}
{synopt :{opt linew:idth()}}change the width of the connection lines. For details, refer to {help linewidthstyle}.{p_end}

{syntab:4. Change the look of significant labels}
{synopt :{opt labc:olor()}}change the color of the significant labels. For details, refer to {help colorstyle}.{p_end}
{synopt :{opt labpos:ostion()}}change the size of the significant labels. For details, refer to {help clockposstyle}.{p_end}
{synopt :{opt labs:ize()}}change the symbol of the significant labels. For details, refer to {help textsizestyle}.{p_end}

{syntab:5. Other options}
{synopt :{opt *}}other options for the {it:twoway} command. For details, refer to {help twoway_options}.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}1. {it:weights} are not allowed in {it:model}().{p_end}
{p 4 6 2}2. If you do not specify any plotting options, the results of {help bdiffv} will be identical to those of {help bdiff}.{p_end}
{p 4 6 2}3. In the above options, if {it:bdiff} is displayed in parentheses, it means that the option is inherited from {help bdiff}. If {it:bdiffv} is displayed, it means that the option is a new feature of this command.{p_end}


{title:Description}

{dlgtab:Introduction}

{p 4 4 2}
Yujun, Lian (arlionn) released a package called {help bdiff} on November 24, 2020, which can perform between-group difference analysis.

{p 4 4 2}
However, existing research can no longer simply be satisfied with displaying the differences between two sets of regression specific explanatory variables in digital form. Therefore, we urgently need a visual solution.

{p 4 4 2}
Based on the above background, I rewrote a visual solution based on the {help bdiff} package and named it {help bdiffv}. In addition to helping us perform intergroup difference tests after regression, this package can also display the differences graphically.


{dlgtab:The Fisher's permutation test}

{p 4 4 2}
The Fisher's permutation test can be used to test the significance of difference between two groups of any estimator. 

{p 4 4 2}
In case of regression coefficients difference, Cleary (1999, pp.684-685) uses this method to determine whether there is a significant difference of "investment-cash flow sensitivity" coefficients between financial constraint (FC) firms and non-financial constraint (NFC) firms. Cleary states that: A bootstrapping procedure is used to calculate empirical p-values that estimate the likelihood of obtaining the observed differences in coefficient estimates if the true coefficients are, in fact, equal. 

{p 6 6 4}
{it: Step} 1: Observations are pooled from the two groups whose coefficient estimates are to be compared. Using {it:n}1 and {it:n}2 to denote the number of observations available from each group, we end up with a total of {it:n}1 + {it:n}2 observations every year. 

{p 6 6 2}
{it: Step} 2: Each simulation randomly selects {it:n}1 and {it:n}2 observations from the pooled distribution and assigns them to group 1 and group 2, respectively. Coefficient estimates are then determined for each group using these observations. The difference between coefficient estimates of group 1 and group 2 is denoted as ({it:di})

{p 6 6 2}
{it: Step} 3: This procedure (Step 1 and Step 2) is repeated 5000 times. 

{p 6 6 2}
The empirical {it:p}-value is the percentage of simulations where the difference between coefficient estimates ({it:di}) exceeds the actual observed difference in coefficient estimates (dSample). 

{p 6 6 2}
This p-value tests against the one-tailed alternative hypothesis that the coefficient of one group is greater than that of the other group (H1: {it:d} > 0). For example, a {it:p}-value of 0.01 indicates that only 50 out of 5000 simulated outcomes exceeded the sample result, which implies the sample difference is significant, and supports the notion that {it:d} > 0.

{p 6 6 2}
Note that, the procedures in Cleary (1999, pp.684-685) is in fact a Fisher's permutation test, because Cleary do not use samping with replacement. So, the "A bootstrapping procedure" argument in Cleary (1999, pp.684) may be misleading. For details, see Efron and Tibshirani (1993, Section 15.2, pp.202).

{dlgtab:For panel data}

{p 4 6 2}
If the command used for Panel data is specified in {opt model(string)}, e.g, xtreg, xtabond, etc., then the samping is clusted by {it:id} vairable specified by {help xtset}. {p_end}

{dlgtab:SUR test}

{p 4 6 2}
{help bdiff}'s {it: surtest} option provides a convenient way to perform test for "Do coefficients vary between groups? ". For details, see {help suest} (example 2).{p_end}

{dlgtab:Visualisation solution}

{p 4 6 2}
{help bdiffv} provides a visualization solution for intergroup differences in bdiff. To achieve this, I mainly did the following:

{p 6 6 2}
{it: step} 1: Retain {help bdiff}'s method of calculating bwtween-group differences to avoid unnecessary errors.

{p 6 6 2}
{it: step} 2: Obtain the regression coefficients, confidence intervals, and p-values from the difference test provided by {help bdiff} during the calculation process.

{p 6 6 2}
{it: step} 3: Use the {help twoway_rcap:rcap}, {help scatter}, and {help twoway_pcarrow:pcarrow} commands to draw individual graphs. Some of the code was referenced from a solution provided by {browse "https://asjadnaqvi.github.io/":Asjad Naqvi}.

{p 6 6 2}
{it: step} 4: Based on Professor {browse "https://www.bc.edu/bc-web/schools/morrissey/departments/economics/people/faculty-directory/christopher-baum.html":Christopher F. Baum}'s suggestions for improving my modplot command, I have incorporated some of the features from modplot.{p_end}


{title:Examples}

{dlgtab:Basic usage code}

{p 8 4 2}{stata `"sysuse auto.dta, clear"'}{p_end}
{p 8 4 2}{stata `"bdiffv, model(reg price rep78 headroom turn gear_ratio) group(foreign)"'}{p_end}

{p 3 4 2}{it:Note} If your code runs successfully, you will get: 1. A group difference test table that is identical to the {help bdiff} command; 2. A beautiful group difference test graph.{p_end}
{p 8 4 2}You can also click {stata `"bdiff, model(reg price rep78 headroom turn gear_ratio) group(foreign)"':here} to perform a secondary verification and see if the results match those of bdiff.{p_end}
{p 8 4 2}However, you should note that since {it:{help bdiffv##seed(#):seed(#)}} has not been set here for the time being, the p-value of the results will fluctuate to a certain extent.{p_end}

{dlgtab:Fully reproducible results of intergroup difference tests}

{p 8 4 2}{stata `"sysuse auto.dta, clear"'}{p_end}
{p 8 4 2}{stata `"bdiffv, model(reg price rep78 headroom turn gear_ratio) group(foreign) seed(12138)"'}{p_end}

{p 3 4 2}{it:Note} As long as {it:{help bdiffv##seed(#):seed(#)}} is set, the result will be reproducible.{p_end}
{p 8 4 2}However, you should note that, as with the {help bdiff} command, changing the order of the data will cause the p-value of the difference test to fluctuate to a certain extent.{p_end}

{dlgtab:Do not report the results of the difference test table}

{p 8 4 2}{stata `"sysuse auto.dta, clear"'}{p_end}
{p 8 4 2}{stata `"bdiffv, model(reg price rep78 headroom turn gear_ratio) group(foreign) seed(12138) noreport"'}{p_end}

{p 3 4 2}{it:Note} In this case, the table showing the results of the difference test will not be reported, and only the image will be drawn. However, the progress bar will remain.{p_end}

{dlgtab:Bootstrap sample + permutation test}

{p 8 4 2}{stata `"sysuse auto.dta, clear"'}{p_end}
{p 8 4 2}{stata `"bdiffv, model(reg price rep78 headroom turn gear_ratio) group(foreign) seed(12138) reps(100) bsample"'}{p_end}

{dlgtab:Keep the significance markers at the same height}

{p 8 4 2}{stata `"sysuse auto.dta, clear"'}{p_end}
{p 8 4 2}{stata `"bdiffv, model(reg price rep78 headroom turn gear_ratio) group(foreign) seed(12138) contour"'}{p_end}

{dlgtab:Increase the distance between the two confidence intervals}

{p 8 4 2}{stata `"sysuse auto.dta, clear"'}{p_end}
{p 8 4 2}{stata `"bdiffv, model(reg price rep78 headroom turn gear_ratio) group(foreign) seed(12138) xshift(0.3)"'}{p_end}

{dlgtab:Advanced drawing options}

{p 8 4 2}It's fun to stay curious, and I hope my friends here will try out the advanced options settings for themselves.{p_end}

{dlgtab:Other situations where bdiff is applicable.}

{p 8 4 2}For other situations, such as SUR tests, Logit regression, and IV regression, please refer to the bdiff help file or click on the {help bdiff:hyperlink} (if installed).{p_end}



{title:Also see}

{p 4 13 2}
Online:  help for {help bdiff} (if installed), {help chowtest} (if installed), {help bsample}, {help permute}, {help suest}. 


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
{synopt:{help oneclick} (if installed)} {stata ssc install oneclick} (to install){p_end}
{synopt:{help onetext} (if installed)} {stata ssc install onetext} (to install){p_end}
{synopt:{help econsig} (if installed)} {stata ssc install econsig} (to install){p_end}
{synopt:{help wordcloud} (if installed)} {stata ssc install wordcloud} (to install){p_end}
{synopt:{help modplot} (if installed)} {stata ssc install modplot} (to install){p_end}
{p2colreset}{...}


{title:Acknowledgments}

{p 4 4 2}
Thanks to Bilibili users (导导们). Thanks to Professor Christopher F. Baum for the 
information that gave me a better understanding of Stata programming.
{p_end}


{title:References}

{p 4 8 2}
Cleary, S., 1999, The Relationship between Firm Investment and Financial Status, 
{it:Journal of Finance}, 54(2): 673-692.
http://onlinelibrary.wiley.com/doi/10.1111/0022-1082.00121/full.{p_end}

{p 4 8 2}
Efron, B., Tibshirani, R., 1993. 
An Introduction to the Bootstrap, Chapmann & Hall. {p_end}