{smcl}
{* version 1.0.0}
{cmd: help flagout}
{hline}

{p2colset 8 20 22 2}{...}
{p2col :{hi:flagout} {hline 2}}Flag outliers using a robust Z-score{p_end} {p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:flagout} {varname} 
{ifin}
{weight}
 {cmd:,} {opt item(varname)}
[{opt over(varlist)} {opt z(#)} {opt minn(#)}]

{p 4 6 2}
{opt pweight}s are allowed; see {help weight}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt flagout} flags outliers in the supplied variable, using a robust Z-score based on the median and IQR.  The robust Z-score is defined as (x-p50)/((p75-p25)/1.35)  
or (x-p50)/((p90-p10)/2.56) if p75-p25 = 0.
The scale factors of 1.35 and 2.56 make it equivalent to a standard Z-score on a normally distributed variable as IQR = 1.35 * sd and p90-p10 = 2.56 * sd for such variables.  
The use of the median and re-scaled interquartile range makes it more robust to the presence of outliers in the distribution which can bias the estimatation of the 
mean and standard deviation.

{dlgtab:Main}
 
{phang}
{opt item(varname)} define the over which the distributions are assumed to be independent, and will be treated entirely separately.  
If your dataset only contains one kind of item, or you want to analyze all observations together, define a variable which is constant to use in this option.

{phang}
{opt over(varname)} specify level(s) of disaggreation.  The median and IQR will be constructed over the most disagregated level for which at least {cmd:minn} observations are available.  
The least disagregated level is all observations for each value of {cmd:item}.  More disagregated levels are defined the variables supplied in the {cmd:over} option in order.  
Thus if {cmd: over(var1 var2)} is specified, {cmd: flagout} will try to construct the median and IQR for each value of {cmd: var1} if enough observations are available; if not
they will be constructed for each value of {cmd: var2} if enough observations are available; if not, they will be constructed using all the observations for each value of {cmd: item}.

{phang}
{opt z(#)} specify the Z-score beyond which observations are considered outliers.  The default is {cmd: z(3.5)}

{phang}
{opt minn(#)} specify the minimum number of observations to construct the median and IQR.  See notes on {cmd: over(varname)}.  The default is {cmd: n(30)}

{marker Constructed}
{title:Constructed Variables}

{pstd}
The program produces 4 variables. 

{p 8 4 2}{cmd:_flag} = -1 for lower outlier, 0 for nonoutlier, 1 for upper outlier.

{p 8 4 2}{cmd:_min} = the minimum nonoutlier value for each observation

{p 8 4 2}{cmd:_max} = the maximum nonoutlier value for each observation

{p 8 4 2}{cmd:_median} = the median value for each observation (within the lowest allowed level of disagregation)

{pstd}
If these variables already exist, a warning message will be displayed and they will be dropped.

{marker Remarks}
{title:Remarks}

{pstd}
{cmd: flagout} was designed for identifying outliers in consumption expenditure in household-item level data when constructing nominal consumption aggregates for poverty estimation,
but it may be useful in other casses as well.

{pstd}
Any transformations to the variable (log, per capita) should be made by the user, and the transformed variable supplied.

{pstd}
If the IQR is equal to 0, {cmd: flagout} uses a scaled version of the 10th – 90th percentile range (again, scaled to be equivalent to a standard deviation on a normal distribution).  
If this is also 0, any observations outside of the 10th – 90th percentile range are considered outliers.  A warning message will be displayed.

{pstd}
If less than {cmd: nmin} observations are available globally for any value of {cmd: item}, no values will flagged as outliers.  A warning message will be displayed.

{pstd}
The command {cmd: outdetect} provides more options for the robust scale measure and normalization, and well as additional options for graphing etc.  It is much slower, especially
when using household-item level data.  

{marker Examples}
{title:Examples}

{hline}
{pstd}
Look for outliers in {cmd:consexp} for each item {cmd:itemcode}, taking into account sampling weights {cmd:hhweight}.  This assumes {cmd:consexp} is normally distributed.

{phang2}
{cmd:. flagout consexp [pw = hhweight], item(itemcode)}

{pstd}
Assume instead that {cmd:consexp} per capita is log-normally distributed.

{phang2}
{cmd:. gen logpc_consexp = log(consexp/hhsize)}

{phang2}
{cmd:. flagout logpc_consexp [pw = hhweight], item(itemcode)}

{pstd}
Construct median/IQR over district*urban if possible, or district, or urban.

{phang2}
{cmd:. gen dist_x_urb = district * 10 + urban}

{phang2}
{cmd:. flagout logpc_consexp [pw = hhweight], item(itemcode) over(dist_x_urb district urban)}

{pstd}
Specify Z-score threshold and minimum number of observations.

{phang2}
{cmd:. flagout logpc_consexp [pw = hhweight], item(itemcode) over(dist_x_urb district urban) z(4) minn(20)}

{hline}
{pstd}
Use constructed variables to winsorize outliers and impute missing values (no transformation).

{phang2}
{cmd:. flagout consexp [pw = hhweight], item(itemcode) over(dist_x_urb district urban)}

{phang2}
{cmd:. replace consexp = _max if _flag == 1     // winsorize upper outliers}

{phang2}
{cmd:. replace consexp = _min if _flag == -1    // winsorize lower outliers}

{phang2}
{cmd:. replace consexp = _med if consexp == .   // impute missing}

{hline}
{pstd}
Use constructed variables to winsorize outliers and impute missing values (log per capita transformation).

{phang2}
{cmd:. flagout logpc_consexp [pw = hhweight], item(itemcode) over(dist_x_urb district urban)}

{phang2}
{cmd:. replace consexp = hhsize * exp(_max) if _flag == 1     // winsorize upper outliers}

{phang2}
{cmd:. replace consexp = hhsize * exp(_min) if _flag == -1    // winsorize lower outliers}

{phang2}
{cmd:. replace consexp = hhsize * exp(_med) if consexp == .   // impute missing}


{marker Author}
{title:Author}

{phang}Liz Foster, Poverty and Equity GD, The World Bank, efoster1@worldbank.org / djiboliz@gmail.com

{phang}Inspired by conversations with colleagues at FAO and code produced by the EHCVM survey harmonization project of the World Bank, WAEMU and member countries.  

{title:Also see}
{psee}
{* add link to outdetect}





