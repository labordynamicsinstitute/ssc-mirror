{smcl}
{* *! version 1.40 17 June 2021}{...}
{right: version 1.40. 17 June 2021}

{viewerjumpto "Syntax" "spgen##syntax"}{...}
{viewerjumpto "Description" "spgen##description"}{...}
{viewerjumpto "Outcome" "spgen##outcome"}{...}
{viewerjumpto "Options" "spgen##options"}{...}
{viewerjumpto "Remarks" "spgen##remarks"}{...}
{viewerjumpto "Examples" "spgen##examples"}{...}
{viewerjumpto "Stored results" "spgen##results"}{...}
{viewerjumpto "Author" "spgen##author"}{...}
{viewerjumpto "References" "spgen##references"}{...}
{viewerjumpto "Disclaimer" "spgen##disclaimer"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{bf:spgen} {hline 2}}Generate Spatially Lagged Variables{p_end}
{p2col :}({browse "https://keisukekondokk.github.io/software/doc/spgen.pdf":View PDF manual online}){p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:spgen} {varlist} {ifin}, {cmd:lon({varname})} {cmd:lat({varname})} {opt swm(swmtype)} {opt dist(#)} {opt dunit}{bf:(km|mi)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth lon(varname)}} specifies the variable of longitude.{p_end}
{p2coldent:* {opth lat(varname)}} specifies the variable of latitude.{p_end}
{p2coldent:* {opt swm(swmtype)}} specifies a type of the spatial weight matrix.{p_end}
{p2coldent:* {opt dist(#)}} specifies the threshold distance for the spatial weight matrix.{p_end}
{p2coldent:* {opt dunit}{bf:(km|mi)}} specifies the unit of distance ({bf:km}, kilometers; {bf:mi}, miles).{p_end}
{synopt:{opt o:rder(#)}} uses {it:#}th order of the spatial weight matrix.{p_end}
{synopt:{opt wvar(varname)}} specifies a weight variable for the spatial weight matrix.{p_end}
{synopt:{opt rowif(varname)}} specifies an indicator variable for targeted observations.{p_end}
{synopt:{opt suf:fix(string)}} appends a suffix to names of output variables.{p_end}
{synopt:{opt nostd}} specifies non row-standardized spatial weight matrix.{p_end}
{synopt:{opt nomat:save}} does not save the bilateral distance matrix and spatial weight matrix on the memory.{p_end}
{synopt:{opt dms}} converts DMS format to decimal format.{p_end}
{synopt:{opt app:rox}} uses distance based on the simplified version of the Vincenty formula.{p_end}
{synopt:{opt det:ail}} displays descriptive statistics of distance.{p_end}
{synopt:{opt large:size}} is suited for large sized data.{p_end}
{synopt:{opt rep:lace}} overwrites the existing outcome variables in the dataset.{p_end}
{synoptline}
{p2colreset}{...}
{pstd}* {cmd:lat()}, {cmd:lon()}, {cmd:swm()}, {cmd:dist()}, and {cmd:dunit()}
are required.

{marker description}{...}
{title:Description}

{pstd}
{cmd: spgen} generates the spatially lagged variables of {varlist}. 
{p_end}

{marker outcome}{...}
{title:Outcome}

{pstd}{cmd: spgen} generates the spatially lagged variables, {cmd:splag{it:#}_{it:varname}_{it:swmtype}[_{it:wvar}][{it:suffix}]}, on the dataset.

{phang}{space 1}o{space 2}{it:#} of {it:splag#} is automatically inserted in accordance with {opt o:rder(#)}.{p_end}

{phang}{space 1}o{space 2}{it:varname} is automatically inserted for each of {it:varlist}.{p_end}

{phang}{space 1}o{space 2}{it:swmtype} is automatically inserted from either {bf:b} for {bf: swm(pow)}, {bf:k} for {bf: swm(knn {it: #})}, {bf:e} for {bf: swm(exp {it: #})}, or {bf: p} for {bf:swm(pow {it: #})} in accordance with {opt swm(swmtype)}.{p_end}

{phang}{space 1}o{space 2}{it:wvar} is optionally inserted as th name of weight variable when specified.{p_end}

{phang}{space 1}o{space 2}{it:suffix} is optionally inserted as user specified string when specified.{p_end}

{marker options}{...}
{title:Options}
{phang}
{opt lon(varname)} specifies the variable of longitude in the dataset. The decimal format is expected in the default setting. The positive value denotes the east longitude. The negative value denotes the west longitude.
{p_end}

{phang}
{opt lat(varname)} specifies the variable of latitude in the dataset. The decimal format is expected in the default setting. The positive value denotes the north latitude. The negative value denotes the south latitude.
{p_end}

{phang}
{opt swm(swmtype)} specifies a type of the spatial weight matrix. One of the following four types of spatial weight matrix must be specified: {bf: bin} (binary), {bf: knn} ({it:k}-nearest neighbor), {bf: exp} (exponential), or {bf: pow} (power). The parameter {it:k} must be specified for the {it:k}-nearest neighbor as a natural number ({it:k} = 1, 2, 3, ...) as follows: {bf:swm(knn {it:#})}. The distance decay parameter {it:#} must be specified for the exponential and power functional types of spatial weight matrix as follows: {bf:swm(exp {it:#})} and {bf:swm(pow {it:#})}. The bilateral distance is calculated by Vincenty formula (Vincenty, 1975).
{p_end}

{phang}
{opt dist(#)} specifies the threshold distance for the spatial weight matrix. This option is ignored if the {cmd:swm(knn {it:#})} option is specified.

{phang}
{opt dunit}{bf:(km|mi)} specifies the unit of distance. Either {bf:km} (kilometers) or {bf:mi} (miles) must be specified. 
{p_end}

{phang}
{opt o:rder(#)} uses {it:#}th order of spatial weight matrix. The default setting calculates the 1st order of spatially lagged variable.
{p_end}

{phang}
{opt wvar(varname)} specifies a weight variable for the spatial weight matrix. A weight variable is not used in the default setting.
{p_end}

{phang}
{opt rowif(varname)} specifies an indicator variable that takes the value 1 for targeted observations for which users calculate spatially lagged variables and 0 otherwise. The default setting returns spatially lagged variables for all observations in the dataset. It takes much time in large size dataset. The {cmd:rowif()} option allows to users to calculate spatially lagged variables for subset of observations. The {opt rowif()} option is not used in the default setting.
{p_end}

{phang}
{opt suf:fix(string)} appends a suffix to names of output variables. It is helpful when {cmd:spgen} is used in {cmd: foreach} or {cmd: forvalues}. The {opt suf:fix(string)} option is not used in the default setting.
{p_end}

{phang}
{opt nostd} uses the spatial weight matrix that is not row-standardized during the calculation process. The row-standardized spatial weight matrix is used in the default setting.
{p_end}

{phang}
{opt nomat:save} does not save the bilateral distance matrix {bf:r(D)} and spatial weight matrix {bf:r(W)} on the memory. It is used to save memory space for a low spec computer. The {opt nomat:save} option is not used in the default setting.
{p_end}

{phang}
{opt dms} converts the DMS (Degrees, Minutes, Seconds) format to a decimal format. The default setting is the decimal format.
{p_end}

{phang}
{opt app:rox} uses bilateral distance approximated by the simplified version of the Vincenty formula. The {opt app:rox} option is not used in the default setting.
{p_end}

{phang}
{opt det:ail} displays descriptive statistics of distance. The {opt det:ail} option is not used in the default setting.
{p_end}

{phang}
{opt large:size} is suited for large-sized data. When this option is specified, {opt nomat:save}, {opt app:rox}, and {opt order(1)} options are automatically applied. The {opt det:ail} option displays only minimum and maximum distances. The {opt large:size} option is not used in the default setting.
{p_end}

{phang}
{opt rep:lace} is used to overwrite the existing output variables in the dataset. The {opt rep:lace} option is not used in the default setting.
{p_end}


{marker examples}{...}
{title:Examples: baseline}

{phang}See Kondo (2017) for the dataset used in this example.{p_end}

{phang}Spatially lagged variable using power functional type of spatial weight matrix{p_end}

{phang2}{cmd:. spgen} CRIME, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(pow 8) dist(.) dunit(km){p_end}

{phang}Spatially lagged variable using exponential functional type of spatial weight matrix{p_end}

{phang2}{cmd:. spgen} CRIME, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(exp 0.15) dist(.) dunit(km){p_end}

{phang}Spatially lagged variable using binary type of spatial weight matrix{p_end}

{phang2}{cmd:. spgen} CRIME, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(bin) dist(5) dunit(km){p_end}

{phang}Spatially lagged variable using {it:k}-nearest neighbor type of spatial weight matrix{p_end}

{phang2}{cmd:. spgen} CRIME, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(knn 1) dist(.) dunit(km){p_end}


{title:Examples: multiple variables}

{phang}{cmd:spgen} accepts multiple variables ({cmd:spgen} ver. 1.40 or later).{p_end}

{phang2}{cmd:. spgen} CRIME INC HOVAL, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(pow 1) dist(.) dunit(km){p_end}


{title:Examples: {opt nostd} option}

{phang}{opt nostd} option is helpful for the calculation of market potential ({cmd:spgen} ver. 1.10 or later).{p_end}

{phang2}{cmd:. spgen} gdp, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(pow 1) dist(.) dunit(km) nostd{p_end}
{phang2}{cmd:. gen} mp = gdp + splag1_gdp_p{p_end}


{title:Examples: rowif() option}

{phang}{cmd:rowif()} option is helpful if users calculate spatially lagged variables for particular observations ({cmd:spgen} ver. 1.40 or later).{p_end}

{phang2}{cmd:. gen} d_rowif = (id_state == 13){p_end}
{phang2}{cmd:. spgen} gdp, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(pow 1) dist(.) dunit(km) nostd rowif(d_rowinf){p_end}


{title:Examples: {opt large:size} option}

{phang}{opt large:size} option is helpful for large size datasets, such as 10,000 observations or more ({cmd:spgen} ver. 1.30 or later). This option avoids matrix manipulations during the calculation process.{p_end}

{phang2}{cmd:. spgen} CRIME, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(pow 1) dist(.) dunit(km) large{p_end}


{title:Examples: {opt rep:lace} option}

{phang}{opt rep:lace} option is helpful to avoid error message of overwriting the existing output variables. {p_end}

{phang2}{cmd:. spgen} CRIME, lat(y_cntrd) {cmd:lon}(x_cntrd) swm(pow 1) dist(.) dunit(km) replace{p_end}


{marker s}{...}
{title:Stored results}

{phang}{cmd:spgen} stores the following in {opt r()}.{p_end}

{synoptset 20 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:r(N)}} number of observations{p_end}
{synopt:{cmd:r(K)}} number of variables{p_end}
{synopt:{cmd:r(td)}} threshold distance{p_end}
{synopt:{cmd:r(dd)}} parameter {it:k} for {cmd:swm(knn {it:#})} or distance decay parameter for {cmd:swm(exp {it:#})} and {cmd:swm(pow {it:#})}{p_end}
{synopt:{cmd:r(od)}} order of spatial lag{p_end}
{synopt:{cmd:r(dist_mean)}} mean of distance{p_end}
{synopt:{cmd:r(dist_sd)}} standard deviation of distance{p_end}
{synopt:{cmd:r(dist_min)}} minimum value of distance{p_end}
{synopt:{cmd:r(dist_max)}} maximum value of distance{p_end}

{synoptset 20 tabbed}{...}
{syntab:Macros}
{synopt:{cmd:r(cmd)}} {cmd:spgen}{p_end}
{synopt:{cmd:r(varlist)}} variable names{p_end}
{synopt:{cmd:r(swm)}} type of spatial weight matrix{p_end}
{synopt:{cmd:r(swm_std)}} row-standardization of spatial weight matrix{p_end}
{synopt:{cmd:r(dunit)}} unit of distance{p_end}
{synopt:{cmd:r(dist_type)}} exaxt of approximation of Vincenty formula{p_end}
{synopt:{cmd:r(weight)}} variable name specified in wvar() option{p_end}
{synopt:{cmd:r(wtype)}} type of weight in wvar() option{p_end}
{synopt:{cmd:r(rowif)}} variable name specified in rowif() option{p_end}

{synoptset 20 tabbed}{...}
{syntab:Matrices}
{synopt:{cmd:r(D)}} lower triangle of distance matrix{p_end}
{synopt:{cmd:r(W)}} spatial weight matrix{p_end}


{marker author}{...}
{title:Author}

{pstd}Keisuke Kondo{p_end}
{pstd}Research Institute of Economy, Trade and Industry (RIETI). Tokyo, Japan.{p_end}
{pstd}METI Annex 11F, 1-3-1 Kasumigaseki, Chiyoda-ku, Tokyo, 100-8901, Japan.{p_end}
{pstd}(URL: {browse "https://keisukekondokk.github.io/":https://keisukekondokk.github.io/}){p_end}


{marker references}{...}
{title:References}

{marker K2017}{...}
{phang}
Kondo, K. (2017) "Introduction to spatial econometric analysis: Creating spatially lagged variable in Stata,"
 Mimeo. (URL: {browse "https://keisukekondokk.github.io/software/doc/spgen.pdf":https://keisukekondokk.github.io/software/doc/spgen.pdf})
{p_end}

{marker V1975}{...}
{phang}
Vincenty, T. (1975) "Direct and inverse solutions of geodesics on the ellipsoid with application of nested equations," {it:Survey Review} 23(176), pp. 88-93.
{p_end}


{marker disclaimer}{...}
{title:Disclaimer}

{phang}(a) Keisuke Kondo makes the utmost effort to maintain, but nevertheless does not guarantee, the accuracy, completeness, integrity, usability, and recency of {cmd:spgen}.{p_end}
{phang}(b) Keisuke Kondo and any organization to which Keisuke Kondo belongs hereby disclaim
responsibility and liability for any loss or damage that may be incurred by users as a result
of using {cmd:spgen}. Keisuke Kondo and any organization to which Keisuke Kondo belongs are neither responsible nor liable for any loss or damage that users of {cmd:spgen} may cause to any third party as a result of using {cmd:spgen}.{p_end}
{phang}(c) {cmd:spgen} may be modified, moved or deleted without prior notice.{p_end}
