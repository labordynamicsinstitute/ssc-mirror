{smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:robustpf} {hline 2} Executes estimation of production functions robustly against errors in proxy variables.

{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:robustpf}
{it:y}
{it:k}
{it:l1}
...
{it:lJ}
{ifin}
[{cmd:,} {bf:proxy}({it:varname}) {bf:m1}({it:varname}) ... {bf:m5}({it:varname}) {bf:onestep} {bf:init_k}({it:real}) {bf:init_l}({it:real}) {bf:init_m}({it:real})]

{marker description}{...}
{title:Description}

{phang}
{cmd:robustpf} estimates production functions robustly against errors in proxy variables, based on the identification and estimation theories developed in 
{browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407619302027":Hu, Huang, and Sasaki (2020)}. 
The command takes as input an output variable {it:y}, a capital variable {it:k}, and {it:J} types of labor variables {it:l1}...{it:lJ}. 
In addition, for estimation of a {it:gross-output} production function, a user can set up to five intermediate input variables as options {bf:m1()}...{bf:m5()}. 
A user must set a proxy variable by calling the option {bf:proxy()}, which often takes one of the intermediate input variables or an investment variable. 
Displayed results consist of returns to scale and coefficients of each input variable.


{marker options}{...}
{title:Options}

{phang}
{bf:proxy({it:varname})} takes the proxy variable used for estimation of the production function. 
Receiving no input for this option, the command produces no estimation results.

{phang}
{bf:m1({it:varname})}...{bf:m5({it:varname})} take up to five intermediate input variables for estimation of the gross-output production function. 
Receiving no input for any of these options, the command estimates the net-output production function.

{phang}
{bf:onestep} sets an indicator for implementing just one step of the GMM estimation. Not calling this option will lead to the two-step efficient GMM estimation by default.

{phang}
{bf:init_k({it:real})} sets the initial value of the capital coefficient for an optimization routine of the GMM estimation. 
The default value is {bf: init_k(0.0)}.

{phang}
{bf:init_l({it:real})} sets the initial value(s) of the labor coefficient(s) for an optimization routine of the GMM estimation. 
The default value is {bf: init_l(0.0)}.

{phang}
{bf:init_m({it:real})} sets the initial value(s) of the intermediate input coefficient(s) for an optimization routine of the GMM estimation. 
The default value is {bf: init_m(0.5)}.

{phang}(The moment function for GMM estimation is nonlinear, and hence it is recommended to try multiple initial values to improve the possibility of attaining the globally optimal solution.
The value of the objective is stored in {bf:e(Objective)} after implementing the command){p_end}

{marker examples}{...}
{title:Examples}

{phang}
(Variables: {bf:id} ID, {bf:year} year, {bf:y} output, {bf:k} capital, {bf:ls} skilled labor, {bf:lu} unskilled labor, {bf:m} material, {bf:e} electricity, {bf:u} fuel)

{phang}Estimation of {it:net-output} production function with material as a proxy:

{phang}{cmd:. use "example_Chile.dta"}{p_end}
{phang}{cmd:. xtset id year}{p_end}
{phang}{cmd:. robustpf y k ls lu, proxy(m)}{p_end}

{phang}Estimation of {it:gross-output} production function with material as a proxy:

{phang}{cmd:. use "example_Chile.dta"}{p_end}
{phang}{cmd:. xtset id year}{p_end}
{phang}{cmd:. robustpf y k ls lu, proxy(m) m1(m) m2(e)}{p_end}

{marker stored}{...}
{title:Stored results}

{phang}
{bf:robustpf} stores the following in {bf:e()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:e(NT)} {space 9}observations
{p_end}
{phang2}
{bf:e(N)} {space 10}firms
{p_end}
{phang2}
{bf:e(T)} {space 10}time periods
{p_end}
{phang2}
{bf:e(minT)} {space 7}first time period
{p_end}
{phang2}
{bf:e(maxT)} {space 7}last time period
{p_end}
{phang2}
{bf:e(objective)} {space 2}value of the GMM objective
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:e(cmd)} {space 8}{bf:robustpf}
{p_end}
{phang2}
{bf:e(properties)} {space 1}{bf:b V}
{p_end}

{phang}
Matrices
{p_end}
{phang2}
{bf:e(b)} {space 10}coefficient vector
{p_end}
{phang2}
{bf:e(V)} {space 10}variance-covariance matrix of the estimators
{p_end}
{phang2}
{bf:e(br)} {space 9}returns to scale (RTS)
{p_end}
{phang2}
{bf:e(Vr)} {space 9}variance of the RTS estimator
{p_end}

{phang}
Functions
{p_end}
{phang2}
{bf:e(sample)} {space 5}marks estimation sample
{p_end}

{title:Reference}

{p 4 8}Hu, Y., G. Huang, and Y. Sasaki. 2020. Estimating Production Functions with Robustness Against Errors in the Proxy Variables. {it:Journal of Econometrics}, 215 (2), pp. 375-398.
{browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407619302027":Link to Paper}.
{p_end}

{title:Authors}

{p 4 8}Yingyao Hu, Johns Hopkins University, Baltimore, MD.{p_end}

{p 4 8}Guofang Huang, Purdue University, West Lafayette, IN.{p_end}

{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}



