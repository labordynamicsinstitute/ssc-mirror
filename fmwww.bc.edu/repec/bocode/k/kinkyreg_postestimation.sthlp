{smcl}
{* *! version 1.1.1  16mar2021}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{* *! Jan F. Kiviet, sites.google.com/site/homepagejfk/}{...}
{vieweralsosee "kinkyreg" "help kinkyreg"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] predict" "help predict"}{...}
{vieweralsosee "[R] regress postestimation" "help regress_postestimation"}{...}
{viewerjumpto "Postestimation commands" "kinkyreg_postestimation##description"}{...}
{viewerjumpto "predict" "kinkyreg_postestimation##predict"}{...}
{viewerjumpto "estat" "kinkyreg_postestimation##estat"}{...}
{viewerjumpto "Example" "kinkyreg_postestimation##example"}{...}
{viewerjumpto "Authors" "kinkyreg_postestimation##authors"}{...}
{viewerjumpto "References" "kinkyreg_postestimation##references"}{...}
{title:Title}

{p2colset 5 32 34 2}{...}
{p2col :{bf:kinkyreg postestimation} {hline 2}}Postestimation tools for kinkyreg{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are of special interest after {cmd:kinkyreg}:

{synoptset 14}{...}
{p2coldent:Command}Description{p_end}
{synoptline}
{synopt:{helpb kinkyreg postestimation##estat:estat test}}perform test of linear hypotheses{p_end}
{synopt:{helpb kinkyreg postestimation##estat:estat exclusion}}perform test of exclusion restrictions{p_end}
{synopt:{helpb kinkyreg postestimation##estat:estat reset}}perform the Ramsey regression specification error test{p_end}
{synopt:{helpb kinkyreg postestimation##estat:estat hettest}}perform test for heteroskedasticity{p_end}
{synopt:{helpb kinkyreg postestimation##estat:estat durbinalt}}perform Durbin's alternative test for serial correlation{p_end}
{synopt:{helpb kinkyreg postestimation##estat:estat rcr}}compute sensitivity parameters for RCR estimation{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The following standard postestimation commands are available after {cmd:kinkyreg} with option {opt correlation(#)}:

{synoptset 14}{...}
{p2coldent:Command}Description{p_end}
{synoptline}
{p2col:{helpb estat}}VCE and estimation sample summary{p_end}
INCLUDE help post_estimates
INCLUDE help post_hausman
INCLUDE help post_lincom
INCLUDE help post_nlcom
{synopt:{helpb kinkyreg postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:{help kinkyreg_postestimation##predict_statistics:statistic}}]


{marker predict_statistics}{...}
{synoptset 13 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{syntab:Main}
{synopt:{opt xb}}calculate linear prediction; the default{p_end}
{synopt:{opt r:esiduals}}calculate the residuals{p_end}
{synopt:{opt stdp}}calculate standard error of the prediction{p_end}
{synoptline}
{p2colreset}{...}


{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing predictions such as fitted values, residuals, and standard errors based on the postulated endogeneity correlation specified in option {opt correlation(#)} of {cmd:kinkyreg}.


{title:Options for predict}

{dlgtab:Main}

{phang}
{opt xb} calculates the linear prediction from the fitted model; see {helpb predict##options:[R] predict}. This is the default.

{phang}
{opt residuals} calculates the residuals from the fitted model.

{phang}
{opt stdp} calculates the standard error of the linear prediction; see {helpb predict##options:[R] predict}.


{marker estat}{...}
{title:Syntax for estat}

{phang}
Test of linear hypotheses

{p 8 16 2}
{cmd:estat} {cmd:test} {cmd:(}{it:{help kinkyreg_postestimation##options_spec:test_spec}}{cmd:)} [{cmd:(}{it:{help kinkyreg_postestimation##options_spec:test_spec}}{cmd:)} ...]
[{cmd:,} {it:{help kinkyreg_postestimation##estat_test_options:test_options}} {it:{help kinkyreg_postestimation##estat_graph_options:graph_options}}]

{phang}
Test of exclusion restrictions

{p 8 16 2}
{cmd:estat} {cmdab:excl:usion} [{varlist}] [{cmd:,} {it:{help kinkyreg_postestimation##estat_excl_options:excl_options}} {it:{help kinkyreg_postestimation##estat_graph_options:graph_options}}]

{phang}
Ramsey regression equation specification error test

{p 8 16 2}
{cmd:estat} {cmd:reset} [, {it:{help kinkyreg_postestimation##estat_reset_options:reset_options}} {it:{help kinkyreg_postestimation##estat_graph_options:graph_options}}]

{phang}
Tests for heteroskedasticity

{p 8 16 2}
{cmd:estat} {cmdab:hett:est} [{cmd:(}{varlist}{cmd:)} {cmd:(}{varlist}{cmd:)} ...] [{cmd:,} {it:{help kinkyreg_postestimation##estat_hett_options:hett_options}} {it:{help kinkyreg_postestimation##estat_graph_options:graph_options}}]

{phang}
Durbin's alternative test for serial correlation

{p 8 16 2}
{cmd:estat} {cmdab:dur:binalt} [, {it:{help kinkyreg_postestimation##estat_dur_options:dur_options}} {it:{help kinkyreg_postestimation##estat_graph_options:graph_options}}]

{phang}
Sensitivity parameters for relative correlation restriction estimation

{p 8 16 2}
{cmd:estat} {cmd:rcr} [, {it:{help kinkyreg_postestimation##estat_rcr_options:rcr_options}} {it:{help kinkyreg_postestimation##estat_graph_options:graph_options}}]


{marker estat_test_options}{...}
{synoptset 24 tabbed}{...}
{synopthdr:test_options}
{synoptline}
{syntab:Model}
{synopt:{it:{help test##test_options:test_options}}}standard options of the {cmd:test} command{p_end}

{syntab:Reporting}
{synopt:{opt corr:elation(#)}}postulated endogeneity for test output{p_end}
{synoptline}

{marker estat_excl_options}{...}
{synoptset 24 tabbed}{...}
{synopthdr:excl_options}
{synoptline}
{syntab:Model}
{synopt:{opt nojoi:nt}}do not compute joint exclusion test{p_end}
{synopt:{opt noind:ividual}}do not compute individual exclusion tests{p_end}
{synopt:{opt ek:urtosis(#)}}specify kurtosis of error term{p_end}
{synopt:{opt xk:urtosis(#)}}specify kurtosis of right-hand side variables{p_end}

{syntab:Reporting}
{synopt:{opt corr:elation(#)}}postulated endogeneity for test output{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt notab:le}}suppress results table{p_end}
{synoptline}

{marker estat_reset_options}{...}
{synoptset 24 tabbed}{...}
{synopthdr:reset_options}
{synoptline}
{syntab:Model}
{synopt:{opt xb}}use fitted values; the default{p_end}
{synopt:{opt rhs}}use right-hand side variables{p_end}
{synopt:{opth o:rder(numlist)}}specify polynomial orders{p_end}
{synopt:{opt ek:urtosis(#)}}specify kurtosis of error term{p_end}
{synopt:{opt xk:urtosis(#)}}specify kurtosis of right-hand side variables{p_end}

{syntab:Reporting}
{synopt:{opt corr:elation(#)}}postulated endogeneity for test output{p_end}
{synoptline}

{marker estat_hett_options}{...}
{synoptset 24 tabbed}{...}
{synopthdr:hett_options}
{synoptline}
{syntab:Model}
{synopt:{opt xb}}use fitted values{p_end}
{synopt:{opt rhs}}add right-hand side variables{p_end}

{syntab:Reporting}
{synopt:{opt minp}}show minimum p-value for individual variables{p_end}
{synopt:{opt corr:elation(#)}}postulated endogeneity for test output{p_end}
{synoptline}

{marker estat_dur_options}{...}
{synoptset 24 tabbed}{...}
{synopthdr:dur_options}
{synoptline}
{syntab:Model}
{synopt:{opth o:rder(numlist)}}specify serial correlation lag orders{p_end}
{synopt:{opt ek:urtosis(#)}}specify kurtosis of error term{p_end}
{synopt:{opt xk:urtosis(#)}}specify kurtosis of right-hand side variables{p_end}

{syntab:Reporting}
{synopt:{opt corr:elation(#)}}postulated endogeneity for test output{p_end}
{synoptline}

{marker estat_rcr_options}{...}
{synoptset 24 tabbed}{...}
{synopthdr:rcr_options}
{synoptline}
{syntab:Model}
{synopt:{opt lambda}}compute sensitivity parameter of Krauth (2016){p_end}
{synopt:{opt delta}}compute sensitivity parameter of Oster (2019){p_end}

{syntab:Reporting}
{synopt:{opt corr:elation(#)}}postulated endogeneity for parameter output{p_end}
{synoptline}

{marker estat_graph_options}{...}
{synopthdr:graph_options}
{synoptline}
{syntab:Reporting}
{synopt:{opt tw:oway}{cmd:(}{it:{help kinkyreg_postestimation##options_spec:twoway_spec}}{cmd:)}}specify options for twoway graphs{p_end}
{synopt:{opt pvalp:lot}{cmd:(}{it:{help kinkyreg_postestimation##options_spec:pvalplot_spec}}{cmd:)}}specify options for p-value or parameter plots{p_end}
{synopt:{opt nogr:aph}}suppress creation of graph{p_end}
{synoptline}
{p2colreset}{...}

{marker options_spec}{...}
{p 4 6 2}
{it:{help test##spec:test_spec}} is one of

{p 8 8 2}{it:coeflist}{p_end}
{p 8 8 2}{it:exp} {cmd:=} {it:exp} [{cmd:=} {it:exp}]{p_end}

{p 4 6 2}
{it:twoway_spec} is

{p 8 8 2}
[{cmd:,} {it:{help twoway_options}} {opt yrange(#_1 #_2)} {cmd:addplot(}{it:{help addplot_option:plot}}{cmd:)}]

{p 4 6 2}
{it:pvalplot_spec} is

{p 8 8 2}
[{it:name}|{it:#}] [{cmd:,} {it:{help line_options}} {cmd:recast(}{it:{help advanced_options:newplottype}}{cmd:)}]


{title:Description for estat}

{pstd}
{cmd:estat test} computes linear hypotheses tests; see {helpb test:[R] test}.

{pstd}
{cmd:estat exclusion} computes Wald tests for the valid exclusion of the variables in {it:varlist} from the KLS regression, as described by Kiviet (2020).
These are Wald tests for individual and joint insignificance after a KLS estimation of the regression model augmented with the respective variables.
The p-values of the tests are graphically shown over the range of postulated endogeneity correlations used to compute the KLS estimates with {cmd:kinkyreg}.
The null hypothesis is that the exclusion restrictions are valid. By default, {it:varlist} are the instrumental variables specified with {cmd:kinkyreg}.

{pstd}
{cmd:estat reset} computes the Ramsey (1969) regression equation specification error test.
These are Wald tests for joint insignificance after a KLS estimation of the regression model augmented with powers of the fitted values or the right-hand side variables.
The p-values of the tests are graphically shown over the range of postulated endogeneity correlations used to compute the KLS estimates with {cmd:kinkyreg}. The null hypothesis is that the regression model is correctly specified.

{pstd}
{cmd:estat hettest} computes the Breusch and Pagan (1979) tests for heteroskedasticity of the KLS error term. These are Wald tests in an auxiliary regression of the squared residuals separately on each specified {it:varlist}.
The p-values of the tests are graphically shown over the range of postulated endogeneity correlations used to compute the KLS estimates with {cmd:kinkyreg}. The null hypothesis is that the errors are homoskedastic.

{pstd}
{cmd:estat durbinalt} computes the alternative test of Durbin (1970) for serial correlation of the KLS error term. These are Wald tests for joint insignificance after a KLS estimation of the regression model augmented with lagged residuals.
The p-values of the tests are graphically shown over the range of postulated endogeneity correlations used to compute the KLS estimates with {cmd:kinkyreg}. The null hypothesis is that their is no serial correlation up to the specified order.
This test requires time series data.

{pstd}
{cmd:estat rcr} computes the sensitivity parameters {it:lambda} and {it:delta} for the relative correlation restriction (RCR) estimators of Krauth (2016) and Oster (2019), respectively.
For a given value of the endogeneity correlation, the KLS estimates can be replicated with the RCR estimators by using the corresponding values for these sensitivity parameters.


{title:Options for estat}

{dlgtab:Model}

{phang}
{opt nojoint} requests not to compute the joint exclusion test of all variables.

{phang}
{opt noindividual} requests not to compute the individual exclusion tests for each variable.

{phang}
{opt xb} requests to use the fitted values. Only the exogenous variation of the endogenous right-hand side variable is used to compute the fitted values.

{pmore}
With {cmd:estat reset}, powers of the fitted values are used. This is the default.

{pmore}
With {cmd:estat hettest}, a test with fitted values only is computed, in addition to tests with other specified varlists, if any. This option is the default if no varlists are specified.

{phang}
{opt rhs} requests to use the right-hand side variables of the fitted regression model. Only the exogenous variation of the endogenous variable is used.

{pmore}
With {cmd:estat reset}, powers of the individual right-hand side variables are used instead of the fitted values.

{pmore}
With {cmd:estat hettest}, the right-hand side variables are added to each {it:varlist}. This option allows {it:varlist} to be empty but parentheses are still required if multiple varlists are specified.

{phang}
{opth order(numlist)} specifies the orders to be used for the test. A separate test is computed for each value in {it:numlist}.

{pmore}
With {cmd:estat reset}, these are the polynomial orders of the fitted values or right-hand side variables. The default is {cmd:order(2 3 4)}.

{pmore}
With {cmd:estat durbinalt}, these are the maximum lag orders of the residuals. The default is {cmd:order(1)}.

{phang}
{opt ekurtosis(#)} specifies a value for the kurtosis of the error term to be used in the variance calculation. By default, the kurtosis is estimated based on the KLS estimates.

{phang}
{opt xkurtosis(#)} specifies a value for the kurtosis of the independent variables to be used in the variance calculation. By default, the maximum of the estimated kurtosis for all right-hand side variables is used.

{phang}
{opt lambda} and {opt delta} request to either compute Krauth's {it:lambda} or Oster's {it:delta} for the replication of the KLS estimates with the respective RCR estimator. By default, both sensitivity parameters are computed.

{dlgtab:Reporting}

{phang}
{opt minp} returns for each endogeneity correlation the minimum p-value of individual significance tests among all variables in the respective variable list.
By default, {cmd:estat hettest} computes joint significance tests of all variables in the auxiliary regression.

{phang}
{opt correlation(#)} requests to display test results or parameter values for the specified endogeneity correlation. If {it:#} does not match a value on the estimation grid, the results for the closest grid point to {it:#} are displayed.

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] estimation options}.

{phang}
{cmd:twoway(}[{cmd:,} {it:{help twoway_options}} {opt yrange(#_1 #_2)} {cmd:addplot(}{it:{help addplot_option:plot}}{cmd:)}]{cmd:)} specifies options for twoway graphs; see {helpb graph_twoway:[G-2] graph twoway}.

{pmore}
If the twoway option {cmd:name(}{it:{help name_option:name}}{cmd:)} is not specified, {cmd:name(}{it:namestub}{cmd:_}{it:test}{cmd:, replace)} is assumed,
where {it:test} is either {cmd:test}, {cmd:excl}, {cmd:reset}, {cmd:hett}, {cmd:dur}, or {cmd:rcr}, according to the minimum abbreviation of the respective {cmd:estat} subcommand.
The prefix is set with the {cmd:kinkyreg} option {opt namestub(namestub)}.

{pmore}
{opt yrange(#_1 #_2)} specifies that the p-value or parameter value plots be restricted to the interval [{it:#_1}, {it:#_2}] on the {it:y} axis.
A missing value for {it:#_1} or {it:#_2} refers to minus or plus infinity, respectively.

{pmore}
{cmd:addplot(}{it:{help addplot_option:plot}}{cmd:)} allows to overlay the twoway graph with additional plots; see {it:{help addplot_option}}.

{phang}
{cmd:pvalplot(}[{it:name}|{it:#}] [{cmd:,} {it:{help line_options}} {cmd:recast(}{it:{help advanced_options:newplottype}}{cmd:)}]{cmd:)} determines the look of the p-value or parameter value plots.
By default, these are options for twoway line plots; see {helpb line:[G-2] graph twoway line}.

{pmore}
With {cmd:estat test}, neither {it:name} nor {it:#} must be specified.

{pmore}
With {cmd:estat exclusion}, {it:name} must be a variable name for the individual exclusion tests. For the joint exclusion test, {it:name} must not be specified.

{pmore}
With {cmd:estat reset} or {cmd:estat durbinalt}, {it:#} must be the integer value of an order specified with option {cmd:order()}.

{pmore}
With {cmd:estat hettest}, {it:#} must be the integer value referring to the {it:#}-th specified {it:varlist}. If option {cmd:xb} was specified, the corresponding test is ordered last.

{pmore}
With {cmd:estat rcr}, {it:name} must be {cmd:lambda} for Krauth's lambda or {cmd:delta} for Oster's delta.

{pmore}
{cmd:recast(}{it:{help advanced_options:newplottype}}{cmd:)} allows to treat the plot as {it:newplottype} instead of a line plot; see {it:{help advanced_options}}.

{phang}
{opt nograph} suppresses the creation of the graph for KLS inference.

{phang}
{opt notable} suppresses display of the results table.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}. {stata "use http://www.stata-press.com/data/imeus/griliches"}{p_end}

{pstd}Graphical inference for KLS estimation{p_end}
{phang2}. {stata kinkyreg lw s expr tenure rns smsa _I* (kww = iq), range(-0.7 0.7)}{p_end}

{pstd}Graphical inference for linear hypothesis test{p_end}
{phang2}. {stata estat test expr = tenure}{p_end}

{pstd}Graphical inference for the exclusion restrictions tests{p_end}
{phang2}. {stata estat exclusion}{p_end}
{phang2}. {stata estat exclusion age mrt}{p_end}

{pstd}Graphical inference for the RESET test{p_end}
{phang2}. {stata estat reset, order(2 3)}{p_end}
{phang2}. {stata estat reset, rhs order(2 3)}{p_end}

{pstd}Graphical inference for the heteroskedasticity test{p_end}
{phang2}. {stata estat hettest () (iq), xb rhs}{p_end}
{phang2}. {stata estat hettest () (iq), rhs minp}{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}

{pstd}
Jan F. Kiviet, University of Amsterdam, {browse "https://sites.google.com/site/homepagejfk/"}


{marker references}{...}
{title:References}

{phang}
Breusch, T. S., and A. R. Pagan. 1979.
A simple test for heteroscedasticity and random coefficient variation.
{it:Econometrica} 47: 1287-1294.

{phang}
Durbin, J. 1970.
Testing for serial correlation in least-squares regression when some of the regressors are lagged dependent variables.
{it:Econometrica} 38: 410-421.

{phang}
Kiviet, J. F. 2020.
Testing the impossible: identifying exclusion restrictions.
{it:Journal of Econometrics} 218: 294-316.

{phang}
Kiviet, J. F. 2020.
Instrument-free inference under confined regressor endogeneity and mild regularity.
{it:Stellenbosch Economic Working Papers}: WP09/2020.

{phang}
Krauth, B. 2016.
Bounding a linear causal effect using relative correlation restrictions.
{it:Journal of Econometric Methods} 5: 117-141.

{phang}
Oster, E. 2019.
Unobservable selection and coefficient stability: Theory and evidence.
{it:Journal of Business & Economic Statistics} 37: 187-204.

{phang}
Ramsey, J. B. 1969.
Tests for specification errors in classical linear least-squares regression analysis.
{it:Journal of the Royal Statistical Society, Series B} 31: 350-371.
