{smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:xtusreg} {hline 2} Executes estimation and inference for fixed-effect dynamic panel data models when panel data consist of unequally spaced time periods.

{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:xtusreg}
{it:depvar}
[{it:indepvars}]
{ifin}
[{cmd:,} {bf:twostep} {bf:nonormalization} {bf:gamma}({it:real}) {bf:beta}({it:real})]

{marker description}{...}
{title:Description}

{phang}
{cmd:xtusreg} estimates coefficients of fixed-effect linear dynamic panel models under unequal spacing of time periods in data, based on the identification and estimation theories developed in 
{browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407616301932":Sasaki and Xin (2017)}. 
The admissible pattern of unequal spacing is the {it:US Spacing} -- see Definition 2 and Example 2 in 
{browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407616301932":Sasaki and Xin (2017)}. 
This spacing pattern is characterized by the availability of {it:two pairs of two consecutive time gaps}. For example, a data set that includes observations from surveys in years 1966, 1967, and 1970 is unequally spaced. However, it exhibits the {it:US Spacing} with two pairs, (0,1) and (3,4), of two consecutive time gaps, as there are 0-year gap between 1966 and 1966, 1-year gap between 1966 and 1967, 3-year gap between 1967 and 1970, and 4-year gap between 1966 and 1970. One may simply run the fixed-effect dynamic panel autoregression of the dependent variable alone. Alternatively, one may run the fixed-effect dynamic panel autoregression with {it:time-varying} covariate(s). The estimator is based on the normalization (see 
{browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407616301932":Sasaki and Xin, 2017, Appendix C.1}) for robustness by default.

{marker options}{...}
{title:Options}

{phang}
{bf:twostep} sets an indicator for the two-step GMM estimation. 
Not calling this option leads to a one-step GMM estimation.
This option will not make a difference in the results if parameters are just identified.

{phang}
{bf:nonormalization} sets an indicator for not executing the location-scale normalization. 
Not calling this option leads to an implementation of the location-scale normalization by default.
Appendix C.1 of
{browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407616301932":Sasaki and Xin (2017)}
recommends to implement the location-scale normalization. 

{phang}
{bf:gamma({it:real})} sets the initial value of the autoregressive coefficient for a numerical optimization in the GMM estimation. The default value is {bf: gamma(0)}.

{phang}
{bf:beta({it:real})} sets the initial value of the regression coefficients for a numerical optimization in the GMM estimation. The default value is {bf: beta(0)}.

{marker examples}{...}
{title:Examples}

{phang}Loading the NLS Original Cohorts: Older Men:

{phang}{cmd:. use "NLS_Original_Cohort.dta"}{p_end}

{phang}Set {bf:i} and {bf:t} variables:

{phang}{cmd:. xtset id year}{p_end}

{phang}Estimation of the AR(1) coefficient of {bf:logincome}:

{phang}{cmd:. xtusreg logincome}{p_end}

{phang}Estimation of the AR(1) coefficient of {bf:logincome} along with the regression coefficient of {bf:age}:

{phang}{cmd:. xtusreg logincome age}{p_end}

{phang}Time-invariant variables cannot be included for fixed-effect panel regressions.
To account for heterogeneity across time-invariant variables, one can run a regression for each category as:

{phang}{cmd:. xtusreg logincome if !white}{p_end}
{phang}{cmd:. xtusreg logincome if white}{p_end}

{title:Reference}

{p 4 8}Sasaki, Y. and Y. Xin 2017. Unequal Spacing in Dynamic Panel Data: Identification and Estimation. {it:Journal of Econometrics}, 196 (2), pp. 320-330.
{browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407616301932":Link to Paper}.
{p_end}

{title:Authors}

{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}

{p 4 8}Yi Xin, California Institute of Technology, Pasadena, CA.{p_end}



