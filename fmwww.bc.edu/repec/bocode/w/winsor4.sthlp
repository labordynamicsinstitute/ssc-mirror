{smcl}

{title:Title}


{pstd}
{bf:winsor4} - trims or winsorizes a variable based on outliers defined by either percentiles or interquartile range. 


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd: winsor4} {varname} {ifin}, {ul:met}hod(string) {ul:out}lier(string) {ul:l}evel(string) [{ul:new}var(string)] [{ul:pos}itive] [{ul:gr}oup(string)]
{p_end}



{marker description}{...}
{title:Description}

{pstd}
{bf: winsor4} provides methods for handling outliers in your data by either trimming (i.,e., replacing the outliers with missing values) or winsorizing (i.e., replacing outliers with the maximum and minimum specified).
Outliers can either be identified by specifying a pre-determined level in the distribution (e.g., bottom 5% and top 95%), or by using the interquartile range (IQR) method. 
The distribution can be computed unconditionally over the full distribution of {varname}, or within specified groups (e.g., for each year). Only one variable at a time is supported.
{p_end}


{marker options}{...}
{title:Options}

{phang}{opt method(string)}: Specifies the method to be applied. This is a required option. Must be one of the following:
{p_end}

{synoptset 8 tabbed}{...}
{synopt : {it:trim}}: Replace the outliers with missing values. {p_end}
{synopt : {it:winsor}}: Replace the outliers with the maximum and minimum specified. {p_end}


{phang}{opt outlier(string)}: Specifies outliers' definition. This is a required option. Must be one of the following:
{p_end}

{synoptset 8 tabbed}{...}
{synopt : {it:tail}}: Outliers are defined based on percentiles. {p_end}
{synopt : {it:iqr}}: Outliers are defined based on the IQR. {p_end}


{phang}{opt level(string)}: Specifies the threshold level for determining outliers. For {cmd:outlier(tail)} this represents the percentile cut-off. For {cmd:outlier(iqr)}, this represents the multiplier of the interquartile range. For example, {cmd:level(5)} combined with {cmd:outlier(tail)} would correspond to the 5th and 95th percentiles. Similarly, {cmd:level(5)} combined with {cmd:outlier(iqr)} would correspond to 5 times the interquartile range. {cmd:level} is a required option.
{p_end}



{phang}{opt newvar(string)}: Specifies the name of a new variable where the results will be stored. If not provided, the original variable is replaced. {cmd:newvar} is not a required option.
{p_end}



{phang}{opt positive}: Applies the operation only to strictly positive values of the variable. Values less than or equal to zero are set to zero. {cmd:positive} is not a required option.
{p_end}


{phang}{opt group(string)}: Specifies a grouping variable. The operations are applied within each group separately. {cmd:group} is not a required option.
{p_end}



{marker example}{...}
{title:Example}


{phang2} *- Winsor based on (p1 p99) percentiles and replace the variable. {p_end}
{phang2}{inp:.} {stata "sysuse nlsw88, clear":  sysuse nlsw88, clear}{p_end}
{phang2}{inp:.} {stata "winsor4 wage, method(winsor) outlier(tail) level(1)":  winsor4 wage, method(winsor) outlier(tail) level(1)}{p_end}

{phang2} *- Same but create a new variable and preserve the old one without changes. {p_end}
{phang2}{inp:.} {stata "winsor4 wage, method(winsor) outlier(tail) level(1) newvar(wage_winsor)":  winsor4 wage, method(winsor) outlier(tail) level(1) newvar(wage_winsor)}{p_end}

{phang2} *- Same but winsorize only the strictly positive values {p_end}
{phang2}{inp:.} {stata "winsor4 tenure, method(winsor) outlier(tail) level(1) newvar(tenure_winsor) positive":  winsor4 wage, method(winsor) outlier(tail) level(1) newvar(tenure_winsor) positive}{p_end}

{phang2} *- Trim based on (p1 p99) percentiles and replace the variable. {p_end}
{phang2}{inp:.} {stata "winsor4 wage, method(trim) outlier(tail) level(1)":  winsor4 wage, method(trim) outlier(tail) level(1)}{p_end}

{phang2} *- Winsor based on one time the IQR and replace the variable. {p_end}
{phang2}{inp:.} {stata "winsor4 wage, method(winsor) outlier(iqr) level(1)":  winsor4 wage, method(winsor) outlier(iqr) level(1)}{p_end}

{phang2} *- Winsor based on (p1 p99) percentiles by industry and replace the variable {p_end}
{phang2}{inp:.} {stata "winsor4 wage, method(winsor) outlier(tail) level(1) group(industry)":  winsor4 wage, method(winsor) outlier(tail) level(1) group(industry)}{p_end}


{marker author}{...}
{title:Authors}

{pstd}
Adrien Matray (adrien.matray@gmail.com), Pablo E. Rodriguez (pablo6@mit.edu)
{p_end}

{title:Comments}

{pstd}
Send any suggestions or feedback to Adrien Matray (adrien.matray@gmail.com).
{p_end}




