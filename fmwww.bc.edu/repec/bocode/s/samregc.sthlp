{smcl}
{* *! version 1.0  12Apr2025} {...}
{hline}

{title:Title}

{p2colset 5 16 18 2} {...}
{p2col:{hi:samregc}: Sensitivity Analysis of Main Regression Coefficients } {p_end}
{p2colreset} {...}

{title:Syntax}

{p 8 16 2}
{cmd:samregc} {depvar} Main_Varlist {ifin} {weight} 
{cmd:, } 
{opt it:erateover(Iteration_Varlist)} | {opt grit:erateover(Groups_Iteration_Varlist)} 
[{opt nc:omb(#1,#2)}
{opt f:ixvar(Fix_Varlist)}
{opt cmde:st(commandname)}
{opt cmdo:ptions(commandoptions)}
{opt cmdi:veq(Endogenous_Varlist = Instrument_Varlist)}
{opt res:ultsdta(newbasename)}
{opt rep:lace}
{opt co:unt}
{opt do:uble}
{opt noe:xcel}
{opt nog:raph}
{opt graphty:pe(extension)}
{opt graphti:tle(varnames|varlabels)}
{opt grapho:ptions(twowayoptions)}
{opt level(#)}
{opt at(#)}
{opt same:sample}
{opt unb:alanced}
{opt sis:ters(scatter|pcarrow|both)}]

{phang2} {cmd:fweight}s, {cmd:aweight}s, and {cmd:pweight}s are allowed depending on the estimation command specified in {opt cmdest(commandname)}; see {help weight}. {p_end}

{*:*****************************************************************************************}
{title:Sections}
{*:*****************************************************************************************}
{pstd}  Main sections are presented under the following headings: {p_end}

{phang2} {it:{help samregc##Description:Description}} {p_end}
{phang2} {it:{help samregc##Options:Options}} {p_end}
{phang2} {it:{help samregc##Examples:Examples}} {p_end}
{phang2} {it:{help samregc##Saved_results:Saved results}} {p_end}

{*:*****************************************************************************************}
{marker Description} {...}
{title:Description}
{*:*****************************************************************************************}
{pstd} {cmd:samregc} is a useful command to develop sensitivity and robustness analyzing for selected coefficients in regression models. By default, {cmd:samregc} performs all possible sub-set regressions, with variables in Main_Varlist always included as regressors, and iterating over all possible combinations among iteration variables specified in {it:Iteration_Varlist} and/or {it:Groups_Iteration_Varlist}. By default, the command stores regression results in a dta file named {it:samregc.dta}. This file contains one row per regression/estimation and includes the following columns: {p_end}
{marker list1} {...}
{phang} 1) regression id (regression {it:order}){p_end}
{phang} 2) covariate regression coefficients (named {it:v_1_b, v_2_b... , etc.}, and labeled with the full covariate name plus the word coeff.) {p_end}
{phang} 3) coefficient t-statistics (named {it:v_1_t, v_2_t..., etc.}, and labeled with the full covariate name plus the word t-stat.) {p_end}
{phang} 4) number of observations (named {it:obs}) {p_end}
{phang} 5) number of covariates -including the intercept- (named {it:nvar}) {p_end}
{phang} 6) number of non-collinear covariantes (named {it:rank}) {p_end}
{phang} 7) dummy variable indicating regressions with some collinear -and omitted- variable (named {it:omitted}) {p_end}


{phang} The first row of the dataset ({it:order}=0) will include the estimation without any iteration variable. {p_end}

{phang} A simple syntax could be: {p_end}

{phang} {cmd:.samregc depvar main, iterateover(svar1 svar2)} {p_end}

{pstd} which runs the following 4 regressions {p_end}
{pstd} {it: regress depvar main } {p_end}
{pstd} {it: regress depvar main svar1} {p_end}
{pstd} {it: regress depvar main svar2} {p_end}
{pstd} {it: regress depvar main svar1 svar2} {p_end}
{pstd} and generates a {it:samregc.dta} database as follows: {p_end}

order v_1_b v_1_t v_2_b v_2_t v_3_b v_3_t v_4_b v_4_t obs nvar rank omitted 
0       #     #                             #     #    #   2    2    0  
1       #     #     #     #                 #     #    #   3    3    0  
2       #     #                 #     #     #     #    #   3    3    0  
3       #     #     #     #     #     #     #     #    #   4    4    0  

{pstd} Below is a description of each variable in the dataset:{p_end}

{phang} {cmd:.use samregc.dta} {p_end}
{phang} {cmd:.describe} {p_end}
        
variable    variable label
---------    --------------                    
order        Order number of estimation
v_1_b        main coeff.
v_1_t        main t-stat.
v_2_b        svar1 coeff.
v_2_t        svar1 t-stat.
v_3_b        svar2 coeff.
v_3_t        svar2 t-stat.
v_4_b        Constant coeff.
v_4_t        Constant tstat.
obs          Number of observations
nvar         Number of variables
rank         Rank (excluding omitted variables)
omitted      =1 if one or more variables were omitted because of collinearity

{phang} By default {cmd:samregc} also provides an Excel file named samregc.xlsx, which includes tables summarizing the number (and percentage) of regressions in which main variable coefficients are positive/negative, and significant/not significant. The Excel file also includes a set of tables for each main variable, with summary statistics of all iteration variables. These tables contain useful information about how the coefficient and t-statistic of each main variable behave. Iteration variables are sorted by the number of regression in which the main variable estimated coefficient changes from significant to non-significant, along with other relevant statistics.{p_end}

{phang} {cmd:samregc} also generates kernel density plots for coefficients and t-statistics of the main variables to go beyond aggregate quantities and provide a comprehensive overview of all-subset-regression results.{p_end}

{phang} By default, all results, including figures and tables, are saved in the working directory. {p_end}

{phang} Variable lists (such as {it:Main_Varlist} and {it:Iteration_Varlist}) do not allow factor-variable operators (see {it:{help fvvarlist}}). While time-series operators (see {it:{help tsvarlist}}) are permitted, they should be used with caution, as "time" variables may be repeated across different variable lists, potentially leading to unexpected errors. {p_end}

{phang} The {cmd:xi:} command can be used with {cmd:samregc} to convert categorical variables into indicator/dummy variables (see {it:{help xi}}). However, it should be used with caution, as it can frequently cause the omission of variables due to collinearity. {p_end}

{pstd} Back to {it:{help samregc}} {p_end}

{*:*****************************************************************************************}
{marker Options} {...}
{title:Options}
{*:*****************************************************************************************}
{marker genoption} {...}
{syntab:{it:General options}}

{phang} {opt it:erateover(Iteration_Varlist)} this option specifies the list of variables that will be used to generate all possible combinations of regressors (i.e., all-subset regressions), taken from 0 to n at a time, where n is the number of iteration variables. For example, {it:iterateover(var1 var2 var3 var4 var5)} will run estimations using different combinations of these 5 variables — that is, all combinations of 5 variables taken from 0 to 5 at a time. See {it:{help samregc##egncomb:Examples of using ncomb}} {p_end}

{phang} {opt grit:erateover(Groups_Iteration_Varlist)} This option specifies the list of variable groups over which the estimations will iterate. For example, {it:griterateover(var5 var6 | var7 var8 var9)} will iterate over two groups: "var5 var6" and "var7 var8 var9" and running 4 estimations including none of these variables, variables of group 1, variables of group 2, and variables of both groups.{p_end}

{phang} {opt it:erateover(Iten_Varlist)} and {opt grit:erateover(Groups_Iteration_Varlist)}: At least one of these options must be included. They specify the variables (and/or groups of variables) to iterate over and evaluate their incidence on the main variable's coefficient. See {it:{help samregc##egitover:Examples of using iterateover and griterateover}}.{p_end}

{marker fixvar} {...}
{phang} {opt f:ixvar(Fix_Varlist)} allows users to specify a subset of covariates that must be included in all regressions. However, these variables are of no other interest than be used as ubiquitous control variables (i.e., they are not part of the main variables), so no graphs or tables are generated for these variables. See {it:{help samregc##egfixvar:Examples of using fixvar}} {p_end}

{phang} A variable included in one list cannot be included in any other list. For example, if a variable is included in {it:Iteration_Varlist}, the same variable must not be in {it:Main_Varlist}, {it:Groups_Iteration_Varlist}, or {it:Fix_Varlist}. {p_end}

{phang} {opt nc:omb(#1,#2)} specifies the minimum and maximum number of covariates to be included in the iteration procedure. With this option, {cmd:samregc} will perform a subsample of all-subset regressions, using combinations taken from {it:#1} to {it:#2} variables at a time, plus the -allways estimated- regression without any iteration variable. {it:#1} must be less than or equal to {it:#2}, and additionally, the number of iteration variables must be greater than or equal to {it:#2}. For example, ncomb(k) — or ncomb(k,k) — will perform all possible combinations of n taken k at a time, without repetition (plus the no-iteration variable regression). This option is specially useful when n is too high, and the number of all-possible subset regressions (2^n) becomes prohibitive.{p_end}

{*:*****************************************************************************************}
{marker commandopt} {...}
{syntab:{it:Regression command options}}

{phang} {opt cmde:st(commandname)} allows the user to choose the estimation command to be used. If the option is not specified, the default command is {it:{help regress:regress}}. This option allows using {it:{help regress:regress}}, {it:{help xtreg:xtreg}}, {it:{help areg:areg}}, {it:{help qreg:qreg}} and {it:{help plreg:plreg}}, but it can also accept other estimation commands with a similar syntax and that saves results in the same way ({it:matrices e(b) and e(V)}). {it:{help ivregress:ivregress}} is also accepted using option {opt cmdiveq(Endogenous_Varlist = Instrument_Varlist)}. See {it:{help samregc##egcommand:Examples of using cmdest, cmdoptions and cmdiveq}} {p_end}

{phang} {opt cmdo:ptions(commandoptions)} allows adding additional options supported by {it:commandname} for each regression. See {it:{help samregc##egcommand:Examples of using cmdest, cmdoptions and cmdiveq}} {p_end}

{phang} {opt cmdi:veq(Endogenous_Varlist = Instrument_Varlist)} is a special option that allows including a varlist of endogenous variables ({it:Endogenous_Varlist}) and of instruments ({it:Instrument_Varlist}) when the estimator command is {it:{help ivregress:ivregress}}. When using this option, {opt cmdest(ivregress 2sls)}, {opt cmdest(ivregress liml)} or {opt cmdest(ivregress gmm)} must be specified. The endogenous variables must also be included in {it:Main_Varlist}. See {it:{help samregc##egcommand:Examples of using cmdest, cmdoptions and cmdiveq}} {p_end}

{phang} {opt co:unt} displays on screen each regression, the regression number (used for identification purposes), and the total number of regressions to be estimated. If this option is not specified, samregc will hide from the screen the number of regressions being estimated. This option increases the execution time, especially in cases with a large number iteration variables. {p_end}

{*:*****************************************************************************************}
{marker posestimopt} {...}
{syntab:{it:Post-estimation options}}

{phang} {opt lev:el(#)} sets the significance level (p-value) for the sensitivity analysis. By default, the level is 95%. {p_end}

{phang} {opt at(#)} allows evaluating the statistical significance of coefficients at a specific value. By default, the coefficient analysis evaluates significant differences relative to 0. {p_end}

{phang} {opt same:sample} forces all regressions to be performed on the same sample of observations, which is the largest common sample. By default, {cmd:samregc} performs each regression using the maximum number of common observations available for the covariate subset in each case. Option {opt samesample} cannot be combined with options {opt unbalanced} or {opt sisters}. See {it:{help samregc##egunbalanced:Examples of changes in observations due to iteration variables}} {p_end}

{phang} {opt unb:alanced} This is a useful option when the number of observations varies between the interaction variables (i.e. some variables have missing values). This option generates (and stores) scatterplots of coefficients and t-statistics for each main variable, along with the number of observations. Otherwise, only kernel density figures are created. These figures show raw/composite (omitted-variable/collinearity + sample) effects of {it:Iteration_Varlist} on {it:Main_Varlist} and can be useful to detect the impact of asymmetric missing values distribution among {it:Iteration_Varlist} on estimated coefficients and t-statistics.{p_end}

{phang} {opt sis:ters(scatter|pcarrow|both)} implies {opt unbalanced}. Runs a set of paired estimations (i.e. "sister" regressions): for each estimation already performed, an additional comparative (sister) regression is made, using the same sample but without any iteration variable. For each {it:Main_Varlist},figures show t-statistics from original and sister estimations against the number of observations. With option {opt sis:ters(scatter)} the figure use scatter plots (including linear trends), while with option {opt sis:ters(pcarrow)} the figure uses arrows to show the shift in the coefficient between original and sister estimations. The option {opt sis:ters(both)} generates both figures. These graphs allow the user to observe both omitted-variable/collinearity effects and sample effects of each {it:Iteration_Varlist} combination. See {it:{help samregc##egunbalanced:Examples of changes in observations due to iteration variables}} {p_end}

{*:*****************************************************************************************}
{marker outputopt} {...}
{syntab:{it:Output options}}

{phang} {opt res:ults([path]name)} allows the user to define the name of both, the output database that includes coefficients and statistics obtained from estimated results, and the Excel file including result's tables. By default, the command stores results in the working directory with names {it:samregc.dta} and {it:samregc.xlsx}. Depending on the chosen options, the command saves additional graphs for main variables in the same path. Graph names will depend on the option itself and on the names of the Main Variable. If these filenames already exist, the user should include the option {opt replace} to overwrite them. {p_end}

{phang} {opt rep:lace} replaces previously created output database, spreadsheet file with results's tables and figures in the working directory. {p_end}

{phang} {opt do:uble} forces the results to be saved in {it:{help data_types:double}} precision. {p_end}

{phang} {opt nog:raph} suppress the generation of kernel densities and other graphs. {p_end}

{phang} {opt noe:xcel} avoid Excel files generation. Tables will be only stored as r-class matrices. {p_end}

{phang} {opt graphty:pe(extension)}: By default, graphs are saved in editable Stata format (.gph). This option allows graphics to be exported using the specified extension. Supported formats are {it: png, ps, eps, svg, emf, pdf, tif, gif} and {it: jpg}. {p_end}

{phang} {opt graphti:tle(varnames|varlabels)}: By default, main variable's graph titles are displayed using variable names or labels, depending on the user's choice. {p_end}

{phang} {opt grapho:ptions(twowayoptions)}: allows adding twoway options for graphs. {p_end}



{*:*****************************************************************************************}
{marker Examples} {...}
{title:Examples}
{*:*****************************************************************************************}
{phang2} {cmd:. sysuse auto} {p_end}
{phang2} {cmd:. samregc price mpg, iterateover(weight length)} {p_end}

{pstd} In this case, there is one main variable (mpg), samregc will perform the sensitivity analysis of the mpg coefficient {p_end}
{pstd} If there are two iteration covariates (e.g., {it:weight} and {it:length}), {cmd:samregc} will perform full all-subset regressions — that is, taking 0 to 2 variables at a time from the set of two.{p_end}
{pstd} {it: regress price mpg } {p_end}
{pstd} {it: regress price mpg weight} {p_end}
{pstd} {it: regress price mpg length} {p_end}
{pstd} {it: regress price mpg weight length} {p_end}

{phang2} {cmd:. samregc price mpg foreign, iterateover(weight length)} {p_end}

{pstd} In this case, there are two main variables (mpg and foreign), samregc will perform the sensitivity analysis of mpg and foreign coefficients. {p_end}
{pstd} {cmd:samregc} will perform: {p_end}
{pstd} {it: regress price mpg foreign } {p_end}
{pstd} {it: regress price mpg foreign weight} {p_end}
{pstd} {it: regress price mpg foreign length} {p_end}
{pstd} {it: regress price mpg foreign weight length} {p_end}

{*:*****************************************************************************************}
{marker egncomb} {...}
{dlgtab: Examples of using ncomb}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3) ncomb(1,1)} {p_end}

{pstd} or equivalently {p_end}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3) ncomb(1)} {p_end}

{pstd} In this case, there are three iteration covariates, {cmd:samregc} samregc will perform the regression without iteration variables plus all possible combinations without repetition of "3 choose 1":{p_end}
{pstd} {it: regress depvar main } {p_end}
{pstd} {it: regress depvar main svar1} {p_end}
{pstd} {it: regress depvar main svar2} {p_end}
{pstd} {it: regress depvar main svar3} {p_end}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3) ncomb(2,3)} {p_end}

{pstd} {cmd:samregc} will perform all possible combinations (i.e., regressions) without repetition using 3 iteration variables, taken from 2 to 3 at a time, plus the baseline regression with no iteration variables. That is, it will perform the following 5 regressions:{p_end}
{pstd} {it: regress depvar main } {p_end}
{pstd} {it: regress depvar main svar1 svar2} {p_end}
{pstd} {it: regress depvar main svar1 svar3} {p_end}
{pstd} {it: regress depvar main svar2 svar3} {p_end}
{pstd} {it: regress depvar main svar1 svar2 svar3} {p_end}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3) ncomb(1,3)} {p_end}

{pstd} or equivalently {p_end}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3) } {p_end}

{pstd} {cmd:samregc} will perform all possible regressions using combinations without repetition of 0 to 3 variables out of 3:{p_end}
{pstd} {it: regress depvar main } {p_end}
{pstd} {it: regress depvar main svar1} {p_end}
{pstd} {it: regress depvar main svar2} {p_end}
{pstd} {it: regress depvar main svar3} {p_end}
{pstd} {it: regress depvar main svar1 svar2} {p_end}
{pstd} {it: regress depvar main svar1 svar3} {p_end}
{pstd} {it: regress depvar main svar2 svar3} {p_end}
{pstd} {it: regress depvar main svar1 svar2 svar3} {p_end}

{pstd} Back to {it:{help samregc##genoption:General options}} {p_end}
{pstd} Back to {it:{help samregc:Top}} {p_end}


{*:*****************************************************************************************}
{marker egitover} {...}
{dlgtab: Examples of using iterateover and griterateover}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3)} {p_end}

{pstd} {cmd:samregc} will perform all-subset regressions, taking combinations of variables from {it:Iteration_Varlist}, from 0 to 3 at a time:{p_end}

1st regression without iteration variables:
{pstd} {it: regress depvar main } {p_end}

plus 3 regressions based on combinations of 3 taken 1 at a time:
{pstd} {it: regress depvar main svar1} {p_end}
{pstd} {it: regress depvar main svar2} {p_end}
{pstd} {it: regress depvar main svar3} {p_end}

plus 3 regressions based on combinations of 3 taken 2 at a time:
{pstd} {it: regress depvar main svar1 svar2} {p_end}
{pstd} {it: regress depvar main svar1 svar3} {p_end}
{pstd} {it: regress depvar main svar2 svar3} {p_end}

plus 1 regression, based on combinations of 3 taken 3 at a time:
{pstd} {it: regress depvar main svar1 svar2 svar3} {p_end}

{phang2} {cmd:. samregc depvar main, griterateover(gvar1 gvar2 | gvar3 gvar4 gvar5)} {p_end}

{pstd} {cmd:samregc} will perform all possible combinations (without repetition), using two groups of variables, taken from 0 to 2 at a time:{p_end}

1st regression without covariates
{pstd} {it: regress depvar main } {p_end}

plus 1 regression, for the first group
{pstd} {it: regress depvar main gvar1 gvar2 } {p_end}

plus 1 regression, for the second group
{pstd} {it: regress depvar main gvar3 gvar4 gvar5} {p_end}

plus 1 regression, for both groups together
{pstd} {it: regress depvar main gvar1 gvar2 gvar3 gvar4 gvar5} {p_end}

{phang2} {cmd:. samregc depvar main1 main2, iterateover(svar1 svar2 svar3) griterateover(g1var1 g1var2 g1var3 | g2var1 g2var2) ncomb(2,3)} {p_end}

{pstd} {cmd:samregc} estimates all possible regression combinations derived from 3 individual iteration variables and 2 iteration groups — yielding a total of 5 combinatorial elements — taken from 2 to 3 at a time. The estimation also includes the baseline model without individual iteration variables and iteration groups:{p_end}

1st regression without individual iteration variables and iteration groups
{pstd} {it: regress depvar main1 main2 } {p_end}

plus 10 regressions based on combinations of 5 taken 2 at a time
{pstd} {it: regress depvar main1 main2 svar1 svar2} {p_end}
{pstd} {it: regress depvar main1 main2 svar1 svar3} {p_end}
{pstd} {it: regress depvar main1 main2 svar1 g1var1 g1var2 g1var3} {p_end}
{pstd} {it: regress depvar main1 main2 svar1 g2var1 g2var2} {p_end}
{pstd} {it: regress depvar main1 main2 svar2 svar3} {p_end}
{pstd} {it: regress depvar main1 main2 svar2 g1var1 g1var2 g1var3} {p_end}
{pstd} {it: regress depvar main1 main2 svar2 g2var1 g2var2} {p_end}
{pstd} {it: regress depvar main1 main2 svar3 g1var1 g1var2 g1var3} {p_end}
{pstd} {it: regress depvar main1 main2 svar3 g2var1 g2var2} {p_end}
{pstd} {it: regress depvar main1 main2 g1var1 g1var2 g1var3 g2var1 g2var2} {p_end}

plus 10 regressions based on combinations of 5 taken 3 at a time
{pstd} {it: regress depvar main1 main2 svar1 svar2 svar3} {p_end}
{pstd} {it: regress depvar main1 main2 svar1 svar2 g1var1 g1var2 g1var3} {p_end}
{pstd} {it: regress depvar main1 main2 svar1 svar2 g2var1 g2var2} {p_end}
{pstd} {it: regress depvar main1 main2 svar1 svar3 g1var1 g1var2 g1var3} {p_end}
{pstd} {it: regress depvar main1 main2 svar1 svar3 g2var1 g2var2} {p_end}
{pstd} {it: regress depvar main1 main2 svar1 g1var1 g1var2 g1var3 g2var1 g2var2} {p_end}
{pstd} {it: regress depvar main1 main2 svar2 svar3 g1var1 g1var2 g1var3} {p_end}
{pstd} {it: regress depvar main1 main2 svar2 svar3 g2var1 g2var2} {p_end}
{pstd} {it: regress depvar main1 main2 svar2 g1var1 g1var2 g1var3 g2var1 g2var2} {p_end}
{pstd} {it: regress depvar main1 main2 svar3 g1var1 g1var2 g1var3 g2var1 g2var2} {p_end}

{phang2} {cmd:. samregc depvar main1 main2, iterateover(svar1 svar2 svar3) griterateover(g1var1 g1var2 g1var3 | g2var1 g2var2) } {p_end}

{pstd} {cmd:samregc} will perform all possible combinations (i.e., regressions) without repetition of 5 elements, taken from 0 to 5 at a time, which implies a total of 2^5 = 32 regressions (including the regression without any iteration variable or group). {p_end}

{phang2} {cmd:. samregc depvar main1 main2, iterateover(svar1 svar2 svar3) griterateover(g1var1 g1var2 g1var3 | g2var1 g2var2 | g3var1 g3var3 ) ncomb(3,4)} {p_end}

{pstd} {cmd:samregc} will perform all possible combinations (regressions) without repetition of 6 taken from 0 to 6 which implies a total of 2^6 = 64 regressions (including the regression without any iteration variable or group). {p_end}

{pstd} Back to {it:{help samregc##genoption:General options}} {p_end}
{pstd} Back to {it:{help samregc:Top}} {p_end}

{*:*****************************************************************************************}
{marker egunbalanced} {...}
{dlgtab: Examples of changes in observations due to iteration variables}

{pstd} suppose {it:depvar}, {it:main} and {it:svar1} have 50 nonmissing observations, {it:svar2} have 46 nonmissing observations and {it:svar3} has only 48 nonmissing values, then: {p_end}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3) ncomb(1)} {p_end}

{pstd} will perform the following 4 regressions: {p_end}
{pstd} {it: regress depvar main }, with 50 observations {p_end}
{pstd} {it: regress depvar main svar1}, with 50 observations {p_end}
{pstd} {it: regress depvar main svar2}, with 46 observations {p_end}
{pstd} {it: regress depvar main svar3}, with 48 observations {p_end}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3) ncomb(1) sisters(scatter)} {p_end}

{pstd} will additionally perform the following 3 paired/sisters regressions (one for each original estimation): {p_end}

{pstd} {it: regress depvar main}, with 50 observations {p_end}
{pstd} {it: regress depvar main}, with the same 46 observations {p_end}
{pstd} {it: regress depvar main}, with the same 48 observations {p_end}

{pstd} The Coefficients of paired/sisters regressions will be added to the results database (samregc.dta). Additional plots will be shown and stored. {p_end}

{pstd} Tables for each main variable included in the Excel file (samregc.xlsx) will now compare coefficients of each original estimation and its paired/sister regression. {p_end}

{pstd} Alternatively: {p_end}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2 svar3) ncomb(1) samesample} {p_end}

{pstd} will perform the following 4 regressions: {p_end}
{pstd} {it: regress depvar main }, with 46 observations {p_end}
{pstd} {it: regress depvar main svar1}, with 46 observations {p_end}
{pstd} {it: regress depvar main svar2}, with 46 observations {p_end}
{pstd} {it: regress depvar main svar3}, with 46 observations {p_end}

{pstd} In this case, the option {it:samesample} forces all estimations to use the same minimum common sample.{p_end}

{pstd} Back to {it:{help samregc##genoption:General options}} {p_end}
{pstd} Back to {it:{help samregc:Top}} {p_end}

{*:*****************************************************************************************}
{marker egfixvar} {...}
{dlgtab: Examples of using fixvar}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2) ncomb(1) fixvar(fixvar1 fixvar2)} {p_end}

{pstd} will perform the following 3 regressions: {p_end}
{pstd} {it: regress depvar main fixvar1 fixvar2} {p_end}
{pstd} {it: regress depvar main fixvar1 fixvar2 svar1} {p_end}
{pstd} {it: regress depvar main fixvar1 fixvar2 svar2} {p_end}

{pstd} Back to {it:{help samregc##fixvar:Fixed variable options}} {p_end}
{pstd} Back to {it:{help samregc:Top}} {p_end}

{*:*****************************************************************************************}
{marker egcommand} {...}
{dlgtab: Examples of using cmdest, cmdoptions and cmdiveq}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2) cmdoptions(robust) } {p_end}
{pstd} will perform the following 4 regressions: {p_end}
{pstd} {it: regress depvar main , robust} {p_end}
{pstd} {it: regress depvar main svar1, robust} {p_end}
{pstd} {it: regress depvar main svar2, robust} {p_end}
{pstd} {it: regress depvar main svar1 svar2, robust} {p_end}


{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2) cmdest(xtreg) cmdoptions(fe vce(robust)) } {p_end}

{pstd} will perform the following 4 regressions: {p_end}
{pstd} {it: xtreg depvar main , fe vce(robust)} {p_end}
{pstd} {it: xtreg depvar main svar1, fe vce(robust)} {p_end}
{pstd} {it: xtreg depvar main svar2, fe vce(robust)} {p_end}
{pstd} {it: xtreg depvar main svar1 svar2, fe vce(robust)} {p_end}

{phang2} {cmd:. samregc depvar main1 main2, iterateover(svar1 svar2) cmdest(ivregress liml) cmdiveq(main2 = ivar1 ivar2)} {p_end}

{pstd} will perform the following 4 regressions: {p_end}
{pstd} {it: ivregress liml depvar main1 main2 (main2= ivar1 ivar2)} {p_end}
{pstd} {it: ivregress liml depvar main1 main2 svar1 (main2= ivar1 ivar2)} {p_end}
{pstd} {it: ivregress liml depvar main1 main2 svar2 (main2= ivar1 ivar2)} {p_end}
{pstd} {it: ivregress liml depvar main1 main2 svar1 svar2 (main2= ivar1 ivar2)} {p_end}

{pstd} Back to {it:{help samregc##commandopt:Regressions command options}} {p_end}
{pstd} Back to {it:{help samregc:Top}} {p_end}

{*:*****************************************************************************************}
{marker egoutputopt} {...}
{dlgtab: Examples of using resultsdta, replace, double}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2) resultsdta(myresults) } {p_end}

{pstd} Generates a results database named {it:myresults.dta} and an Excel report named {it:myresults.xlsx}, instead of the default output files {it:samregc.dta} and {it:samregc.xlsx}.{p_end}
{pstd} Note that all graph names will depend on the selected options and the names of the {it:Main Variables}. In this case, the generated plot files will be named: {it:b_svar1.gph}, {it:b_svar2.gph}, {it:t_svar1.gph}, and {it:t_svar2.gph}. These files must not already exist unless the {it:replace} option (see below) is specified to allow overwriting existing files.{p_end}

{phang2} {cmd:. samregc depvar main, iterateover(svar1 svar2) resultsdta(myresults) replace double level(99)} {p_end}

{pstd} Replaces {it:myresults.dta}, {it:myresults.xlsx}, and graph files if they already exist in the working directory.{p_end}
{pstd} All estimation results in {it:myresults.dta} will be stored with double precision.{p_end}
{pstd} Finally, the entire analysis will be conducted using a 99% confidence interval.{p_end}


{pstd} Back to {it:{help samregc##outputopt:Output options}} {p_end}
{pstd} Back to {it:{help samregc:Top}} {p_end}

{*:*****************************************************************************************}
{marker Saved_results} {...}
{title:Saved results}
{*:*****************************************************************************************}
{pstd} {cmd:samregc} creates a dta file with outcome information for all estimated regressions. By default, it includes the following columns for each regression: {p_end}

{phang} 1) Regression ID (variable {it:order}).{p_end}
{phang} 2) Covariate regression coefficients, named {it:v_1_b}, {it:v_2_b}, etc., and labeled with the full covariate name followed by the word "coeff.".{p_end}
{phang} 3) Coefficient t-statistics, named {it:v_1_t}, {it:v_2_t}, etc., and labeled with the full covariate name followed by the word "tstat.".{p_end}
{phang} 4) Number of observations (variable {it:obs}).{p_end}
{phang} 5) Number of covariates (variable {it:nvar}).{p_end}
{phang} 6) If there are omitted variables due to collinearity, variables {it:rank} and {it:omitted} are automatically added.{p_end}


{*:*****************************************************************************************}
{marker Stored_results} {...}
{title:Stored results}
{*:*****************************************************************************************}
{pstd}
{cmd:samregc} stores the following results in {cmd:r()}:

{synoptset 23 tabbed}{...}
{pstd}For each column in matrices storing aggregate and detailed results: {p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:r(MainVarColnames)}}Enumeration of colnames included in each main variable results matrix stored in {cmd:r({it:mainvarname}_Table)}. {p_end}
{synopt:{cmd:r(Table1Colnames)}}Enumeration of table 1 colnames stored in {cmd:r(table1)} matrix. {p_end}
{synopt:{cmd:r(colname)}}Description of each column in {cmd:r(table1)} matrix and in {cmd:r({it:mainvarname}_Table)} matrices. {p_end}

{p2col 5 23 26 2: Matrices:}{p_end}
{synopt:{cmd:r(table1)}}Matrix with aggregate results showing the overall impact of iteration variables on each main variable’s coefficient values and significance.{p_end}
{synopt:{cmd:r({it:mainvarname}_Table)}}Matrices with detailed results showing how each individual iteration variable affects the coefficient values and significance of each main variable ({it:mainvarname}).{p_end}

{*:*****************************************************************************************}
{marker Authors} {...}
{title:Authors}

{pstd }Pablo Gluzmann {p_end}
{pstd} CEDLAS-fce-UNLP and CONICET {p_end}
{pstd} La Plata, Argentina {p_end}
{pstd} gluzmann@yahoo.com {p_end}

{pstd} Demian Panigo{p_end}
{pstd} Instituto Malvinas, UNLP and CONICET{p_end}
{pstd} La Plata, Argentina{p_end}
{pstd} panigo@gmail.com {p_end}

{pstd} Back to {it:{help samregc:Top}} {p_end}

{*:*****************************************************************************************}
{title:Also see}

{p 7 14 2}Help: {it:{help checkrob:checkrob}}

