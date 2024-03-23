{smcl}
{title:Title}

{p2colset 5 17 20 2}{...}
{p2col:{cmd:get_pwmse}:}Execute the PWMSE-based model evaluation, after forming proximity norms with the Command {bf:form_norm}.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
Execute the PWMSE-based model evaluation:

{p 8 15 2} {cmd:get_pwmse}
{bf:using} {help filename} {cmd:,}
yvar({depvar})
xvar({indepvars})
[trends({varlist})]
unit({varname})
time({varname})
t(#)
train_ratio(#)
num_simulations(#)
[norms(chars)]
h(#)
seed(#)
[quiet]


{marker option_table}{...}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Option}
{synopt:{opt trends(varlist)}}Specify additional controls such as time trends.{p_end}
{synopt:{opt norms(chars)}}Choose the specific MSEs to be reported. Options include: N, D1, D2, M1, M2, Y1, Y2 as in Cui, Gafarov, Ghanem, and Kuffner (2024).{p_end}
{synopt:{opt quiet}}If not specified, the program will report the running of each round of simulations.{p_end}
{...}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{bf:{help filename}}: Declare the dta file that contains the proximity norms (previously obtained using {bf:form_norms}).

{pstd}
{bf:yvar({depvar})}: Declare the dependent variable in the regression model of interest. Note: this variable will be demeaned as in a FE estimation framework.

{pstd}
{bf:xvar({indepvars})}: Declare the list of explanatory variables in the regression model of interest. Note: all these variables will be demeaned as in a FE estimation framework.

{pstd}
{bf:unit({varname})}: Declare the variable indicating cross-sectional units in the empirical analysis.

{pstd}
{bf:time({varname})}: Declare the time dimension in the empirical analysis. This dimension should be the lowest frequency one as in dim_0() in {bf:form_norms}.

{pstd}
{bf:t(#)}: Declare the last period of the historical data. All data after this period will be dropped in the model evaluation.

{pstd}
{bf:train_ratio(#)}: Specify the training-to-full sample ratio of the cross-validation procedure. This number must be between 0 and 1.

{pstd}
{bf:num_simulations(#)}: Specify the number of times for cross-validation.

{pstd}
{bf:h(#)}: Specify the tuning parameter h in specifying the weight. This should be an integer number.

{pstd}
{bf:seed(#)}: Declare the seed for replication.


{marker options}{...}
{title:Options}

{dlgtab:Options}

{phang}
{opt trends(varlist)}: Specify additional controls such as time trends. This is optional and can be left out if not applied. Note: these variables will NOT be demeaned.

{phang}
{opt norms(chars)}: Choose the specific MSEs to be reported. Options include: N, D1, D2, M1, M2, Y1, Y2 as in Cui, Gafarov, Ghanem, and Kuffner (2024). All norms will be reported if not specified.

{phang}
{opt quiet}: If not specified, the program will report the running of each round of simulations. 


{marker notes}{...}
{title:Additional Notes}

{pstd}
    - Running this program requires first obtaining the proximity norms for constructing weights.

{pstd}
    - Running this program requires pre-loading the data for regressions, with necessary variables for different model specifications.

{pstd}
    - MSEs are not comparable across different weights. They are only comparable across different models under the same weight specification.
{p_end}


{marker references}{...}
{title:References}

{pstd}
Cui, X., Gafarov, B., Ghanem, D., & Kuffner, T. (2024). {browse "https://www.sciencedirect.com/science/article/pii/S0304407623002270":"On model selection criteria for climate change impact studies"}. {it:Journal of Econometrics}, 239(1), 105511.
{p_end}