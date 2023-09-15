{smcl}
{* *! version 1.0.1  12sep2023}{...}
{title:Title}

{phang}
{bf:xtloglin} {hline 2} robust Lagrange multiplier test of linear and log-linear models
against Box-Cox alternatives after {help regress} or {help xtreg}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtloglin,}
{opt null:}(model)
[{opt neg:ative}
{opt notr:obust}
{opt rob:ust}
{opt clus:ter}({varname})]

{marker description}{...}
{title: Description}

{pstd}
{cmd:xtloglin} implements a Lagrange multiplier test for testing the null of linear and log-linear regression models 
against Box-Cox alternatives. The test can be run after {help regress} or {help xtreg} and is based on a non-linear instrumental 
variables estimator of the Box-Cox model proposed by Amemiya and Powell (1981). For further details, please see Vincent, D. (2023, September)

{marker options}{...}
{title:Options}

{phang}
{opt null:}({it:linear|log}) specifies the linear or log-linear model to be tested under the null. This must correspond to the model that has been estimated.

{phang}
{opt negative:} used for testing the linear model when the dependent variable contains zero or negative values. This invokes the transformation 
proposed by MacKinnon and Magee (1990). This can also be used when the dependent variable is strictly positive.

{phang}
{opt notrobust:} computes the test-statistic under the assumption that the error terms are independent and homoskedastic. 

{phang}
{opt robust:} computes the test-statistic that is robust to arbitrary forms of heteroskedasticity provided that the error terms are independent.

{phang}
{opt cluster:}({it:clustvar}) computes the test-statistic that is robust to heteroskedasticity and correlation within clusters, provided that the 
errors are independent across clusters. The variable {it:clustvar} specifies which cluster (group) each observation belongs to.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd: xtloglin} defaults to the version of the test-statistic, that corresponds to the assumptions made about the covariance structure of the errors in 
{help vce()}, when the regression being tested is estimated. Specifying {opt notrobust}, {opt robust} or {opt cluster()} will override this.

	
{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd: xtloglin} tests the suitability of the model that has been fitted. For testing the linear model against the Box-Cox alternative, one must first estimate a 
regression that explains the levels of the dependent variable and then specify {opt model(linear)}. For testing the log-linear model, a regression that
explains the log-transformed outcomes must be fitted and {opt model(log)} specified.

{pstd}
As the Box-Cox transformation is not defined for negative outcomes, an alternative method is required for testing the suitability of the linear model
in such cases. Note that this should not be an issue when testing the log-linear model, as only positive observations can be log-transformed. The approach 
taken in {cmd: xtloglin} is to use the transformation suggested by MacKinnon & Magee (1990), which is defined for both positive and negative values. This 
is implemented by including the option {opt negative} together with {opt model(linear)}.


{marker TechnicalNote}{...}
{title:Technical Note}

{pstd}
The Box-Cox regression first introduced by Box and Cox (1964), assumes that for some value of the transformation parameter {it:lambda}, the transformed dependent 
variable is a linear function of the explanatory variables. This nests both the linear and log-linear models as special cases, making it possible to
test the suitability of these functional forms. 

{pstd}
The test is based on a non-linear instrumental variables estimator, which is consistent for arbitrary error term distributions. Under the null restriction, the 
coefficient estimates on the explanatory variables are identical to those after {help regress} and {help xtreg}. The first, second, third and fourth powers of the 
fitted values are then generated and used in the test-statistic as additional instruments to identify the transformation parameter.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. sysuse auto,clear}{p_end}

{title: Linear model}

{phang2}{cmd:. reg mpg weight length displacement, robust}{p_end}

{phang2}{cmd:. xtloglin, null(linear)}{p_end}
{res}
{txt}Robust LM test of linear and log-linear functional forms
H0: linear dependent variable
H1: Box-Cox transformation
{hline 57}
{col 5}LM-chi2(1) = {res}     4.725
{txt}{col 5}Prob > LM  = {res}     0.0297
{txt}{hline 57}
Error Variance: robust

{title: Log-linear model}

{phang2}{cmd:. gen l_mpg=log(mpg)}{p_end}

{phang2}{cmd:. qui reg l_mpg weight length  displacement, robust}{p_end}

{phang2}{cmd:. xtloglin, null(log)}{p_end}
{res}
{txt}Robust LM test of linear and log-linear functional forms
H0: log dependent variable
H1: Box-Cox transformation
{hline 57}
{col 5}LM-chi2(1) = {res}     0.454
{txt}{col 5}Prob > LM  = {res}     0.5004
{txt}{hline 57}
Error Variance: robust



{title:References}

{phang}
Amemiya, T., & Powell, J. L. (1981). 
A comparison of the Box-Cox maximum likelihood estimator and the non-linear two-stage least squares estimator. Journal of Econometrics, 17(3), 351-381.

{phang} Box, G. E., & Cox, D. R. (1964). 
An analysis of transformations. Journal of the Royal Statistical Society Series B: Statistical Methodology, 26(2), 211-243.

{phang} MacKinnon, J. G., & Magee, L. (1990). 
Transforming the dependent variable in regression models. International Economic Review, 315-339.

{phang} Vincent, D. (2023, September). 
A robust test for linear and log-linear models against Box-Cox alternatives. In London Stata Conference 2023  Stata Users Group.{p_end}

{title:Author}

{phang}This command was written by David Vincent (dvincent@dveconometrics.co.uk).
Comments and suggestions are welcome. {p_end}
