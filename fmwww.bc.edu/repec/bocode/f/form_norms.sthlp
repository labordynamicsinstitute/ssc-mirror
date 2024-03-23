{smcl}
{title:Title}

{p2colset 5 17 20 2}{...}
{p2col:{cmd:form_norms}:}Form proximity norms used in the PWMSE. The Command {bf:get_pwmse} is required next for operating the PWMSE evaluation, using the generated norms.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
Form proximity norms used in the PWMSE:

{p 8 15 2} {cmd:form_norms}
{it:indepvar} {cmd:,}
data({it:{help filename}})
tau(#)
unit({varname})
dim_0({varname})
dim_1({varname})
[dim_2({varname})]

{marker option_table}{...}
{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab : Option}
{synopt:{opth dim_2(varname)}}Declare the highest-frequency time dimension (e.g., day).{p_end}
{...}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{bf:indepvar}: Specify a single variable by which the proximity will be calculated (e.g., average temperature).

{pstd}
{bf:data({it:{help filename}})}: Declare the dta file that contains high-frequency historical and projected data as the input for computing proximity norms. Note: The projected data should be appended to the historical data and only have a single period (e.g., year of 2050).

{pstd}
{bf:tau(#)}: Declare the projected time (e.g., 2050).

{pstd}
{bf:unit({varname})}: Declare the variable indicating cross-sectional units in the empirical analysis.

{pstd}
{bf:dim_0({varname})}: Declare the time dimension in the empirical analysis. This dimension should be the lowest frequency one (e.g., year).

{pstd}
{bf:dim_1({varname})}: Declare the second lowest-frequency time dimension (e.g., month). Note: This dimension is required.


{marker options}{...}
{title:Options}

{dlgtab:Options}

{pstd}
{opth dim_2(varname)}: Declare the highest-frequency time dimension (e.g., day). This dimension is optional if the input data do not have this dimension. In such case, leave this option out. The program will still return norms corresponding to this dimension (norms_D1 and norms_D2), but they will be the same as the norms corresponding to dim_1() (i.e., norms_M1 and norms_M2).
{p_end}    

{marker notes}{...}
{title:Additional Notes}

{pstd}
    - The program accomodates the common data structure with three time dimensions (e.g., year, month, and day). 
    At least two dimensions are required for running the program.

{pstd}
    - Users do not need to pre-load data. The dta specified in data() will be loaded as long as path is correctly specified.

{pstd}
    - If there are only two time dimensions (e.g., year and month), norms_D1 (norms_D2) will be the same as norms_M1 (norms_M2).

{pstd}
    - Users must save the program-generated dta after running {bf:form_norms} into the local folder. 
    This dta file will be required for executing the PWMSE procedure for evaluating models.  
{p_end}


{marker references}{...}
{title:References}

{pstd}
Cui, X., Gafarov, B., Ghanem, D., & Kuffner, T. (2024). {browse "https://www.sciencedirect.com/science/article/pii/S0304407623002270":"On model selection criteria for climate change impact studies"}. {it:Journal of Econometrics}, 239(1), 105511.
{p_end}