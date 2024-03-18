 {smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:testex} {hline 2} Executes a statistical test of the exclusion restriction of an instrumental variable (IV).


{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:testex}
{it:y}
{it:x}
{it:z}
{ifin}
[{cmd:,} {bf:numboot}({it:real})]


{marker description}{...}
{title:Description}

{phang}
{cmd:testex} executes a statistical test of the exclusion restriction of an instrumental variable (IV) based on 
{browse "https://doi.org/10.1016/j.jeconom.2020.09.012":D'Haultfoeuille, Hoderlein, & Sasaki (2021)}.
The command takes as input a scalar outcome variable {it:y}, a scalar endogenous variable {it:x} that is continuous, and a scalar instrumental variable {it:z}.
If the instrument is not binary, then the program transforms the original instrument into a binary one.
The output of the command includes the p-value of the test and the indicators of whether the test rejects the null hypothesis at various levels of statistical significance.
The program gives a caution when there is no crossing of conditional CDFs required by Assumption 5 in 
{browse "https://doi.org/10.1016/j.jeconom.2020.09.012":D'Haultfoeuille, Hoderlein, & Sasaki (2021)}.


{marker option}{...}
{title:Option}

{phang}
{bf:numboot({it:real})} sets the number of multiplier bootstrap iterations to compute the critical value of the test statistic. The default value is {bf: numboot(1000)}.


{marker examples}{...}
{title:Examples}

{phang}
{bf:y} outcome variable, {bf:x} endogenous variable, {bf:z} instrumental variable

{phang}Test of the exclusion restriction:

{phang}{cmd:. testex y x z}{p_end}

{phang}Setting the number of multiplier bootstrap iterations to 2000:

{phang}{cmd:. testex y x z, numboot(2000)}{p_end}

{phang}Including additive {bf:controls}:

{phang}{cmd:. reg y controls}{p_end}
{phang}{cmd:. predict residy, resid}{p_end}
{phang}{cmd:. reg x controls}{p_end}
{phang}{cmd:. predict residx, resid}{p_end}
{phang}{cmd:. reg z controls}{p_end}
{phang}{cmd:. predict residz, resid}{p_end}
{phang}{cmd:. testex residy residx residz}{p_end}


{marker stored}{...}
{title:Stored results}

{phang}
{bf:testex} stores the following in {bf:r()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:r(N)} {space 10}observations
{p_end}
{phang2}
{bf:r(nb)} {space 9}Number of multiplier bootstrap iterations
{p_end}
{phang2}
{bf:r(bw)} {space 9}Bandwidth
{p_end}
{phang2}
{bf:r(KS)} {space 9}KS statistic
{p_end}
{phang2}
{bf:r(p)} {space 10}P-value
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:r(cmd)} {space 8}{bf:testex}
{p_end}


{title:Reference}

{p 4 8}D'Haultfoeuille, X., S. Hoderlein, & Y. Sasaki. 2021. Testing and Relaxing the Exclusion Restriction in the Control Function Approach.
{it:Journal of Econometrics}, forthcoming.
{browse "https://doi.org/10.1016/j.jeconom.2020.09.012": Link to Paper}.
{p_end}


{title:Authors}

{p 4 8}Xavier D'Haultfoeuille, CREST-ENSAE, Palaiseau, France.{p_end}

{p 4 8}Stefan Hoderlein, Emory University, Atlanta, GA.{p_end}

{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}
