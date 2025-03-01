{smcl}
{hline}
help for {cmd:s2s}
{right:Hai-Anh H. Dang}
{right:Minh Cong Nguyen}
{right:Kseniya Abanokova}
{hline}

{title:{cmd:s2s} - survey to survey imputation tool}

{pstd}
{opt s2s} {depvar} {indepvars} {ifin} [{it:{help weight##weight:weight}}]
{cmd:,} by{cmd:(}{it:varname}{cmd:)} from{cmd:(}{it:numlist}{cmd:)} 
to{cmd:(}{it:numlist}{cmd:)} pline{cmd:(}{it:varname}{cmd:)} cluster{cmd:(}{it:varname}{cmd:)} [method{cmd:(}{it:string}{cmd:)} {it:options}]{p_end}

{title:Description}

{pstd}
Obtaining consistent estimates on poverty over time as well as monitoring 
poverty trends on a timely basis is essential for poverty reduction. However, 
these objectives are not readily achieved in practice where household 
consumption data are infrequently collected or not constructed using consistent
 and transparent criteria. The challenge can be broadly regarded as one 
 involving missing data: consumption (or income) data are available in one 
 period but are either unavailable or incomparable in the next period(s). {p_end}

{pstd}
Dang, Lanjouw, and Serajuddin (2017) propose a method that imputes headcount 
poverty in these settings. Dang et al. (2024) employ this method and provide 
further validation evidence for other poverty indicators in the 
Foster–Greer–Thorbecke (FGT) family of poverty indicators, several other 
vulnerability indicators, and mean consumption (income) data. {p_end}

{p 4 4 2}  {cmd:s2s} implements their imputation procedures.{p_end}

{p 4 4 2}  Recent papers that review this method and its applications include 
Dang, Jolliffe and Carletto (2019) and Dang and Lanjouw (2023).{p_end}

{p 4 4 2}  This program is designed for datasets with at least two surveys, 
where consumption data are available in the survey that we impute from (the 
base survey) but are missing in the survey(s) of interest (the target survey(s) 
that we impute into). The control variables are non-missing in both 
surveys.{p_end} 

{p 4 4 2}  The base survey and the target survey can be of a similar design 
(i.e., imputing from a household consumption survey into another household 
consumption survey) or a different design (i.e., imputing from a household 
consumption survey into a labor force survey). Users should check that the same 
control (predictor) variables have comparable distributions in both surveys. 
If not, it can be useful to implement standardization procedures to ensure 
these control variables have similar distributions 
(Dang et al., 2017; Sarr et al., 2025).{p_end} 

{p 4 4 2}  It is also useful to inspect and remove missing observations with 
the control variables in both the base survey and the target survey to avoid 
potential issues before running the program. That is, the control variables 
for each survey should have the same number of observations.{p_end} 

{p 4 4 2}  The estimated standard errors are obtained using the bootstrap 
method, except for the {opt method(probit)} and {opt method(logit)} options 
where the standard errors are analytical.{p_end} 

{pstd}  
To appropriately control for complex survey design, users should 
apply the Stata complex survey design command {cmd:svyset} before running 
{cmd:s2s}. If the data are not svyset, the program will apply the basic 
svysetting based on users' inputs from {opt cluster()}, {opt strata()}, 
and {opt wtstats()} as below: 
{cmd:svyset `cluster' [w= `wtstats'], strata(`strata') singleunit(certainty)}.{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt by(varname)} specifies the variable that indicates the survey year 
(or round). This variable has a numeric format.

{phang}
{opt from(#)} specifies the survey year (or round) that has consumption data 
and that provides the underlying regression for imputation. This is the base 
survey that we impute from. The number for this base survey takes one of the 
values specified in the variable used in the {opt by(varname)} option. For 
example, if the year variable has two values 2008 and 2010, either of which 
can be specified as a number to be used.

{phang}
{opt to(#)} specifies the survey year (or round) that has missing consumption 
data and needs to be imputed into. This is the target survey that we impute 
into. The number for this survey year takes one of the values specified in the 
variable used in the {opt by(varname)} option. For example, if the year 
variable has two values 2008 and 2010, either of which can be specified 
as a number to be used.

{phang}
{opt method(string)} specifies the imputation method. Four methods are allowed.

{pmore} 
{cmd:normal}: using the linear regression (OLS) model with the distributions 
of the error terms assumed to be normal. This is the default option.

{pmore} 
{cmd:empirical}: using the linear regression (OLS) model with the empirical 
distributions of the error terms.

{pmore}
{cmd:probit}: using the probit regression model. This option only applies to 
headcount poverty. If this option is specified, the estimated standard errors 
are analytical.

{pmore}
{cmd:logit}: using the logit regression model. This option only applies to 
headcount poverty. If this option is specified, the estimated standard errors 
are analytical.

{phang}
{opt pline(varname)} specifies the variable that indicates the poverty line. 
This variable has a numeric format.
	
{phang}
{opt cluster(varname)} specifies the cluster variable or the primary sampling 
unit. This variable has a numeric format.

{dlgtab:Optional}

{phang}
{opt wt:stats(varname)} specifies the weight variable for the summary 
statistics.  If left blank, unweighted estimates are provided. Note that 
weights should generally be used for the summary statistics unless the data 
are self-weighted, but unweighted estimates are an optional feature. This 
variable has a numeric format.

{phang}
{opt alpha(integer)} specifies the power of the parameter alpha as defined in 
the Foster–Greer–Thorbecke (FGT) family of poverty indicators. The default 
alpha is 1.

{phang}
{opt strata(varname)} specifies the strata variable. This variable has a 
numeric format.

{phang}
{opt pline2(varname)} specifies the variable that indicates the extreme 
poverty line. The extreme poverty line should be lower than the (regular) 
poverty line that is specified in the option {opt pline()}. This variable 
has a numeric format.

{phang}
{opt vline(varname)} specifies the variable that indicates the vulnerability 
line. The vulnerability line should be larger than the poverty line. This 
variable has a numeric format.

{phang}
{opt lny} specifies that the left-hand side variable is converted to 
logarithmic terms. Note that the poverty line variables always remain in 
level terms.
 
{phang}
{opt rep(#)} specifies the number of simulations. We recommend using 1,000 
simulations or more for robust estimation of standard errors. If left blank, 
the default number of replications in Stata is 50.

{phang}
{opt brep(#)} specifies the number of bootstraps for standard errors. We 
recommend using 400 bootstraps or more for robust estimation of standard 
errors. If left blank, the default number of bootstraps in Stata is 10.

{phang}
{opt seed(#)} specifies the random seed number that can be used for 
replication of results. The default seed is 1234567.

{phang}
{opt bseed(#)} specifies the random seed number that can be used for 
bootstraps of results. The default seed is 7654321.
 
{phang}
{opt sav:ing(string)} specifies the filename and filepath to save the 
imputed data.

{pmore} 
{cmd:replace}: to overwrite the existing imputed data 

{title:Saved Results}

{cmd:s2s} returns results in {hi:e()} format. 
By typing {it:ereturn list}, the following results are reported:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(cmdline)}}the code line used in the session {p_end}

{synopt:{cmd:e(pov_imp)}}headcount poverty rate (alpha= 0) based on 
imputed data {p_end}
{synopt:{cmd:e(pov_var)}}bootstrap variance of headcount poverty based 
on imputed data {p_end}
   
{synopt:{cmd:e(fgt1_imp)}}FGT poverty indicator with the specified alpha 
based on imputed data {p_end}
{synopt:{cmd:e(fgt1_var)}}bootstrap variance of FGT poverty indicator with 
the specified alpha based on imputed data {p_end}

{synopt:{cmd:e(pfgt1_imp)}}FGT poverty indicator with the specified alpha 
among the poor based on imputed data {p_end}
{synopt:{cmd:e(pfgt1_var)}}bootstrap variance of FGT poverty indicator with 
the specified alpha among the poor based on imputed data {p_end}

{synopt:{cmd:e(exp_imp)}}extreme poverty rate based on imputed data {p_end}
{synopt:{cmd:e(exp_var)}}bootstrap variance of extreme poverty rate based 
on imputed data {p_end}

{synopt:{cmd:e(np_imp)}}near poverty (vulnerability) rate based on imputed 
data {p_end}
{synopt:{cmd:e(np_var)}}bootstrap variance of near poverty (vulnerability) 
rate based on imputed data {p_end}

{synopt:{cmd:e(mean_imp)}}mean of dependent variable based on imputed 
data {p_end}
{synopt:{cmd:e(mean_var)}}bootstrap variance of dependent variable based 
on imputed data {p_end}

{synopt:{cmd:e(p#_imp)}}percentile mean of dependent variable based on imputed 
data. Available percetiles (p#) are 5, 10, 25, 50, 75, 90, 95 {p_end}
{synopt:{cmd:e(p#_var)}}bootstrap variance of percentile mean of dependent 
variable based on imputed data {p_end}

{synopt:{cmd:e(N1)}}estimation sample in the base survey {p_end}
{synopt:{cmd:e(N2)}}estimation sample in the target survey {p_end}

{title:Examples}

{pstd}
We provide some illustrative examples using the Tanzania National Panel 
Survey (TZNPS) 2019/20 and 2020/21 rounds. These datasets were collected 
by the Living Standards Measurement Unit (LSMS), World Bank and were 
analyzed in Dang et al. (2024). 
The example data are provided in the {cmd:s2s} package.{p_end}

{pstd}
Note: the data may be downloaded into the current working folder instead of 
the suggested path ../t/Tanzania_dataset.dta. User can type {cmd:net get s2s} 
to download the data and subsequently type {cmd:pwd} to identify the current 
working folder. {p_end}

{dlgtab:Example 1}

{pstd} For illustration, assume that consumption data are available in the 
2019/20 survey round but are either missing or not comparably constructed in 
the 2020/2021 survey round. We impute from the 2019/20 survey into the 
2020/21 survey. The outcomes of interest include {p_end}

{pstd} i)	the headcount poverty rate{p_end}
{pstd} ii)	the near-poverty rate {p_end}
{pstd} iii)	the extreme poverty rate{p_end}
{pstd} iv)	the poverty gap index (Foster-Greer-Thorbecke (FGT) index with alpha = 1){p_end}
{pstd} v)	a variant of poverty gap that focuses on the poor population (the USAID poverty gap), and{p_end}
{pstd} vi)	mean consumption levels.  {p_end}

{pstd} We use the normal linear regression model, with the distribution of 
the error terms assumed to be normal. The given poverty line is 475630.7 TZS, 
and the given extreme poverty line is 377785.1 TZS (both poverty lines are 
annual and per adult equivalent). The vulnerability line is specified at 
125% of the poverty line in 2019.{p_end}

{pstd} The results are similar to those shown in Table 1 in Dang et al. (2024).{p_end}

{phang2}{cmd:. use Tanzania_dataset.dta, clear}{p_end}
{phang2}{cmd:. clonevar dep = lnpcex}{p_end}
{phang2}{cmd:. replace dep = . if year == 2021}{p_end}
{phang2}{cmd:. gen vline = povline*1.25}{p_end}

{pstd}* Model 1 {p_end}    
{phang2}{cmd:. global xvars hhsize age female pri lws ups age0to14sh age15to24sh age60tosh wageemp selfemp area_1 area_2 area_4   }{p_end}
{phang2}{cmd:. s2s dep $xvars, by(year) from(2019) to(2021) pline(povline) method(normal) cluster(psu) wt(hhszwt) strata(strata) pline2(epovline) vline(vline) lny rep(1000) brep(1000)}{p_end}

{pstd}* Model 9 {p_end} 
{phang2}{cmd:. s2s dep $xvars lnpcewg, by(year) from(2019) to(2021) pline(povline) method(normal) cluster(psu) wt(hhszwt) strata(strata) pline2(epovline) vline(vline) lny rep(1000) brep(1000)}{p_end}

{pstd}* Comparing with estimates using the actual consumption data {p_end} 
{phang2}{cmd:. use Tanzania_dataset.dta, clear}{p_end}    
{phang2}{cmd:. svyset psu [w= hhszwt ], strata( strata) singleunit(certainty)}{p_end}
{phang2}{cmd:. gen vline = povline*1.25}{p_end}
{phang2}{cmd:. generate poor = lnpcex<ln(povline)}{p_end}
{phang2}{cmd:. generate epoor = lnpcex<ln(epovline)}{p_end}
{phang2}{cmd:. gen vpoor = ( lnpcex >= ln( povline) & lnpcex < ln( vline ))}{p_end}
{phang2}{cmd:. generate pcex = exp( lnpcex)}{p_end}
{phang2}{cmd:. generate fgt = poor*(( povline - pcex )/ povline )^(1)}{p_end}
{phang2}{cmd:. svy: mean poor epoor vpoor fgt if year == 2021}{p_end}
{phang2}{cmd:. svy, subpop(poor): mean fgt if year == 2021}{p_end}

{dlgtab:Example 2}

{pstd} We can generate a dataset with imputed consumption for each household. 
The example below shows a dataset ("predicted_data.dta") that has 100 imputed 
consumption variables for each household. The number of imputed consumption 
variables is specified by the number in the {opt rep()} option. The imputed 
data is saved in the current working folder, see {cmd: pwd}.{p_end}

{phang2}{cmd:. use Tanzania_dataset.dta, clear}{p_end}
{phang2}{cmd:. clonevar dep = lnpcex}{p_end}
{phang2}{cmd:. replace dep = . if year == 2021}{p_end}
{phang2}{cmd:. global xvars hhsize age female pri lws ups age0to14sh age15to24sh age60tosh wageemp selfemp area_1 area_2 area_4 lnpcewg}{p_end}
{phang2}{cmd:. s2s dep $xvars, by(year) from(2019) to(2021) pline(povline) method(normal) cluster(psu) wt(hhszwt) strata(strata) lny rep(100) brep(100) saving("predicted_data.dta") replace}{p_end}

{dlgtab:Example 3}

{pstd} We can give more weight to poorer people by using a higher value for 
alpha in the FGT index, including the variant of poverty gap that focuses 
on the poor population.{p_end}

{phang2}{cmd:. use Tanzania_dataset.dta, clear}{p_end}
{phang2}{cmd:. clonevar dep = lnpcex}{p_end}
{phang2}{cmd:. replace dep = . if year == 2021}{p_end}
{phang2}{cmd:. global xvars hhsize age female pri lws ups age0to14sh age15to24sh age60tosh wageemp selfemp area_1 area_2 area_4 lnpcewg}{p_end}
{phang2}{cmd:. s2s dep $xvars, by(year) from(2019) to(2021) pline(povline) method(normal) cluster(psu) wt(hhszwt) strata(strata) lny rep(10) brep(100) a(5)}{p_end}

{dlgtab:Example 4}

{pstd} We can impute for headcount poverty using the probit model instead 
of the linear regression model.{p_end}

{phang2}{cmd:. use Tanzania_dataset.dta, clear}{p_end}
{phang2}{cmd:. clonevar dep = lnpcex}{p_end}
{phang2}{cmd:. replace dep = . if year == 2021}{p_end}
{phang2}{cmd:. global xvars hhsize age female pri lws ups age0to14sh age15to24sh age60tosh wageemp selfemp area_1 area_2 area_4 lnpcewg}{p_end}
{phang2}{cmd:. s2s dep $xvars, by(year) from(2019) to(2021) pline(povline) method(probit) cluster(psu) wt(hhszwt) strata(strata) lny rep(1000) brep(1000)}{p_end}

{dlgtab:Example 5}

{pstd} We can use the empirical distribution of the error terms instead of 
the default normal linear regression. {p_end}

{phang2}{cmd:. use Tanzania_dataset.dta, clear}{p_end}
{phang2}{cmd:. clonevar dep = lnpcex}{p_end}
{phang2}{cmd:. replace dep = . if year == 2021}{p_end}
{phang2}{cmd:. global xvars hhsize age female pri lws ups age0to14sh age15to24sh age60tosh wageemp selfemp area_1 area_2 area_4 lnpcewg}{p_end}
{phang2}{cmd:. s2s dep $xvars, by(year) from(2019) to(2021) pline(povline) method(empirical) cluster(psu) wt(hhszwt) strata(strata) lny rep(1000) brep(1000) a(1)}

{title:References}

{p 4 4 2} Dang, H.-A. H. and Nguyen, M.C. (2014) POVIMP: Stata Module to 
Provide Poverty Estimates in the Absence of Actual Consumption Data. 
Statistical Software Components S457934, Boston College, 
Department of Economics.{p_end}

{p 4 4 2} Dang, H.-A. H. and Lanjouw, P. F. (2023). "Regression-based 
Imputation for Poverty Measurement in Data Scarce Settings". In Jacques Silber. (Eds.). 
{it:Handbook of Research on Measuring Poverty and Deprivation.} Edward Elgar Press.{p_end}

{p 4 4 2} Dang, H.-A. H., Jolliffe, D., & Carletto, C. (2019). Data gaps, 
data incomparability, and data imputation: A review of poverty measurement 
methods for data‐scarce environments. {it:Journal of Economic Surveys,} 33(3), 757-797. {p_end}

{p 4 4 2} Dang, H.-A. H., Lanjouw, P. F., & Serajuddin, U. (2017). Updating 
poverty estimates in the absence of regular and comparable consumption data: 
methods and illustration with reference to a middle-income country. 
{it:Oxford Economic Papers,} 69(4), 939-962.{p_end}

{p 4 4 2} Dang, H.-A. H., Kilic, T., Abanokova, K., & Carletto, C. (2024). 
Imputing Poverty Indicators without Consumption Data. World Bank Policy 
Research Working Paper no. 10867. {p_end}

{p 4 4 2} Sarr, I., Dang, H. A. H., Guzman Gutierrez, C. S., Beltramo, T., & 
Verme, P. (2025). Using cross-survey imputation to estimate poverty for 
Venezuelan refugees in Colombia. {it:Social Indicators Research.} 
DOI: {browse "https://doi.org/10.1007/s11205-024-03492-8":https://doi.org/10.1007/s11205-024-03492-8} {p_end}

{title:Authors}
	{p 4 4 2}Hai-Anh H. Dang, Senior Economist, World Bank, USA, hdang@worldbank.org{p_end}
	{p 4 4 2}Minh Cong Nguyen, Senior Economist, World Bank, USA, mnguyen3@worldbank.org{p_end}
	{p 4 4 2}Kseniya Abanokova, Economist, World Bank, USA, kabanokova@worldbank.org{p_end}

{title:Suggested citation}

{p 4 4 2} Dang, H. A. H., Nguyen, M. C., and Abanokova, K. (2025). 
s2s: Stata module to impute poverty in the absence of consumption (income) data.
 World Bank, Development Data Group and Global Poverty Department. 
 Available from (insert Repec link) {p_end}

{title:Acknowledgements}

{p 4 4 2}We use the user-written program {cmd:epctile} from 
{browse "https://staskolenikov.net/stata":{it:https://staskolenikov.net/stata}} 
that provides estimation and inference for percentiles.{p_end}

{p 4 4 2}We would like to thank Kit Baum and various colleagues at and outside 
the World Bank for comments on previous versions of the program. This is a work
in progress. This program builds on and adds more modelling options to a
previous version named {cmd:povimp} (Dang and Nguyen, 2014). (But note 
{cmd:povimp} offers additional test statistics for imputed headcount poverty).{p_end}

{p 4 4 2}We would like to thank the United States Agency for International 
Development (USAID) and UK Foreign Commonwealth and Development Office 
(FCDO) for funding assistance. {p_end}

{p 4 4 2}All errors and omissions are exclusively our responsibility.{p_end}