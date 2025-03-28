{smcl}
{* *! version 1.31  23 March 2025}{...}
{right: version 1.31. 23 March 2025}
{cmd:help moransi}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:moransi} {hline 2}}Calculate global and local Moran's I statistics{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:moransi} {varname} {ifin}{cmd:,}
{opth lat(varname)}
{opth lon(varname)}
{opt swm(swmtype)}
{opt dist(#)}
{opt dunit}{cmd:(km}|{cmd:mi)}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth lat(varname)}}specifies the variable of latitude{p_end}
{p2coldent:* {opth lon(varname)}}specifies the variable of longitude{p_end}
{p2coldent:* {opt swm(swmtype)}}specifies a type of spatial weight matrix{p_end}
{p2coldent:* {opt dist(#)}}specifies the threshold distance for the spatial weight matrix{p_end}
{p2coldent:* {opt dunit}{cmd:(km}|{cmd:mi)}}specify the unit of distance (kilometers or miles){p_end}
{synopt:{opt wvar(varname)}}specifies a weight variable for the spatial weight matrix{p_end}
{synopt:{opt dms}}converts the degrees, minutes, and seconds format to a decimal format{p_end}
{synopt:{opt large:size}}is used for large sized data to increase calculation speed{p_end}
{synopt:{opt app:rox}}uses bilateral distance approximated by the simplified version of the Vincenty formula{p_end}
{synopt:{opt det:ail}}displays summary statistics of the bilateral distance{p_end}
{synopt:{opt nomat:save}}does not save the bilateral distance matrix on the memory{p_end}
{synopt:{opt rep:lace}}overwrites the existing outcome variables in the dataset{p_end}
{synopt:{opt graph}}draws a Moran scatterplot.{p_end}
{synoptline}
{p2colreset}{...}
{pstd}* {cmd:lat()}, {cmd:lon()}, {cmd:swm()}, {cmd:dist()}, and {cmd:dunit()}
are required.

{marker description}{...}
{title:Description}

{pstd}
{cmd:moransi} calculates global and local Moran's {it:I} statistics.
{p_end}


{marker outcome}{...}
{title:Outcome}

{pstd}{cmd: moransi} generates the spatial lag and the local Moran's I statistics of {varname} on the dataset. {p_end}

{phang}{space 1}o{space 2}{cmd:splag_{it:varname}_{it:swmtype}}: Spatial lag of {varname} based on the type of the {opt swm(swmtype)} option.{p_end}

{phang}{space 1}o{space 2}{cmd:lmoran_i_{it:varname}_{it:swmtype}} Local Moran's I statistics of {varname} based on the type of the {opt swm(swmtype)} option.{p_end}

{phang}{space 1}o{space 2}{cmd:lmoran_e_{it:varname}_{it:swmtype}} Expected value of local Moran's I statistics of {varname} based on the type of the {opt swm(swmtype)} option.{p_end}

{phang}{space 1}o{space 2}{cmd:lmoran_v_{it:varname}_{it:swmtype}} Variace of local Moran's I statistics of {varname} based on the type of the {opt swm(swmtype)} option.{p_end}

{phang}{space 1}o{space 2}{cmd:lmoran_z_{it:varname}_{it:swmtype}} z-value of local Moran's I statistics of {varname} based on the type of the {opt swm(swmtype)} option.{p_end}

{phang}{space 1}o{space 2}{cmd:lmoran_p_{it:varname}_{it:swmtype}} p-value of local Moran's I statistics of {varname} based on the type of the {opt swm(swmtype)} option.{p_end}

{phang}{space 1}o{space 2}{cmd:lmoran_cat_{it:varname}_{it:swmtype}} Four Categories (High-high, High-low, Low-high, Low-low) of local Moran's I statistics of {varname} based on the type of the {opt swm(swmtype)} option.{p_end}

{pstd}{it:varname} is automatically inserted. {it:swmtype} is automatically inserted from either {bf:b} for {bf: swm(bin)}, {bf:k} for {bf: swm(knn {it: #})}, {bf:e} for {bf: swm(exp {it: #})}, or {bf: p} for {bf:swm(pow {it: #})} in accordance with {opt swm(swmtype)}.{p_end}

{marker options}{...}
{title:Options}

{phang}
{opth lat(varname)} specifies the variable of latitude in the dataset. The
decimal format is expected in the default setting. A positive value denotes
the north latitude, whereas a negative value denotes the south latitude. {cmd:lat()} is required.
{p_end}

{phang}
{opth lon(varname)} specifies the variable of longitude in the dataset. The
decimal format is expected in the default setting. A positive value denotes
the east longitude, whereas a negative value denotes the west longitude. {cmd:lon()} is required.
{p_end}

{phang}
{opt swm(swmtype)} specifies a type of spatial weight matrix. One of the
following four types of spatial weight matrix must be specified: {opt bin}
(binary), {opt knn} ({it:k}-nearest neighbor), {opt exp} (exponential), or
{opt pow} (power). The parameter {it:k} must be specified for the {it:k}-nearest
neighbor as follows: {cmd:swm(knn} {it:#}{cmd:)}. The distance decay parameter
{it:#} must be specified for the exponential and power function
types of spatial weight matrix as follows: {cmd:swm(exp} {it:#}{cmd:)} and
{cmd:swm(pow} {it:#}{cmd:)}. {cmd:swm()} is required.
{p_end}

{phang}
{opt dist(#)} specifies the threshold distance {it:#} for the spatial weight
matrix. The unit of distance is specified by the {opt dunit()} option. Regions
located within the threshold distance {it:#} take a value of 1 in the
binary spatial weight matrix or a positive value in the nonbinary spatial
weight matrix, and take 0 otherwise. An error message appears and the {cmd:moransi} command ends if there are no neighors in any region within dist(#) km. {cmd:dist()} is required.
{p_end}

{phang}
{opt dunit}{cmd:(km}|{cmd:mi)} specifies the unit of distance. Either {cmd:km}
(kilometers) or {cmd:mi} (miles) must be specified. {cmd:dunit()} is required.
{p_end}

{phang}
{opt wvar(varname)} specifies a weight variable for the spatial weight matrix. A weight variable is not used in the default setting.
{p_end}

{phang}
{opt dms} converts the degrees, minutes, and seconds format to a decimal
format.
{p_end}

{phang}
{opt large:size} is used for large sized data to increase calculation speed. The {opt large:size} option is not used in the default setting.
{p_end}

{phang}
{opt app:rox} uses the bilateral distance approximated by the simplified
version of the Vincenty formula.
{p_end}

{phang}
{opt det:ail} displays summary statistics of the bilateral distance.
{p_end}

{phang}
{opt nomat:save} does not save the bilateral distance matrix {bf:r(D)} and spatial weight matrix {bf:r(W)} on the memory.
{p_end}

{phang}
{opt rep:lace} is used to overwrite the existing output variables in the dataset. The {opt rep:lace} option is not used in the default setting.
{p_end}

{phang}
{opt graph} draws a Moran scatterplot. The {opt graph} option is not used in the default setting.
{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
Consider the Columbus dataset provided by GeoDa (2025).
{p_end}

{pstd}
Case 1: Binary spatial weight matrix: neighbors within 50 km.{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(bin) dist(50) dunit(km)}
{p_end}

{pstd}
Case 2: K-Nearest Neighbor spatial weight matrix (k=1).{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(knn 1) dist(50) dunit(km)}
{p_end}

{pstd}
Case 3: Nonbinary spatial weight matrix by exponential function.{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(exp 0.03) dist(.) dunit(km)}
{p_end}

{pstd}
Case 4: Nonbinary spatial weight matrix by power function.{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(pow 4) dist(.) dunit(km)}
{p_end}

{pstd}
Case 5: {opt large:size} option to increase calculation speed for the large-sized spatial weight matrix.{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(pow 4) dist(.) dunit(km) large}
{p_end}

{pstd}
Case 6: {opt app:rox} option to increase the speed of distance calculations. {opt large:size} option can be used simultaneously.{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(pow 4) dist(.) dunit(km) approx large}
{p_end}

{pstd}
Case 7: {opt wvar(varname)} option to consider an additional weight variable between regions in the spatial weight matrix.{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(pow 4) dist(.) dunit(km) wvar(INC)}
{p_end}

{pstd}
Case 8: {opt rep:lace} option to overwrite outcome variables generated by the moransi command.{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(pow 4) dist(.) dunit(km) replace}
{p_end}

{pstd}
Case 9: {opt graph} option to draw a Moran scatterplot.{p_end}
{phang2}
{cmd:. moransi CRIME, lat(y_cntrd) lon(x_cntrd) swm(pow 4) dist(.) dunit(km) graph}
{p_end}

{pstd}
If users have the shapefile of the study area, the results obtained by the {cmd:moransi} command can be displayed in a map using the {cmd:spshape2dta} and {cmd:grmap} commands for Stata 15
or later (for the earlier version, {cmd:shp2dta} and {cmd:spmap} commands). 


{title:Stored results}

{pstd}
{cmd:moransi} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(I)}}Moran's I statistic{p_end}
{synopt:{cmd:r(EI)}}Expected value of I{p_end}
{synopt:{cmd:r(seI)}}Standard Error of I{p_end}
{synopt:{cmd:r(zI)}}z-value of I{p_end}
{synopt:{cmd:r(pI)}}p-value of I{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(td)}}threshold distance{p_end}
{synopt:{cmd:r(dd)}}distance decay parameter{p_end}
{synopt:{cmd:r(knn)}}parameter {it:k} for swm(knn #){p_end}
{synopt:{cmd:r(dist_mean)}}mean of distance{p_end}
{synopt:{cmd:r(dist_sd)}}standard deviation of distance{p_end}
{synopt:{cmd:r(dist_min)}}minimum value of distance{p_end}
{synopt:{cmd:r(dist_max)}}maximum value of distance{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:moransi}{p_end}
{synopt:{cmd:r(varname)}}name of variable{p_end}
{synopt:{cmd:r(swm)}}type of spatial weight matrix{p_end}
{synopt:{cmd:r(dunit)}}unit of distance{p_end}
{synopt:{cmd:r(dist_type)}}exact or approximation{p_end}
{synopt:{cmd:r(wvar)}}name of weight variable{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(D)}}lower triangle distance matrix{p_end}
{synopt:{cmd:r(W)}}spatial weight matrix{p_end}

{marker author}{...}
{title:Author}

{pstd}Keisuke Kondo{p_end}
{pstd}Research Institute of Economy, Trade and Industry{p_end}
{pstd}Tokyo, Japan{p_end}
{pstd}kondo-keisuke@rieti.go.jp{p_end}
{pstd}https://keisukekondokk.github.io/{p_end}


{marker references}{...}
{title:References}

See also related Stata commands:

{phang}
GeoDa (2025). "Columbus Crime 1980," {it:GeoDa: An Introduction to Spatial Data Science},
 {browse "https://geodacenter.github.io/data-and-lab/columbus/":https://geodacenter.github.io/data-and-lab/columbus/} (Accessed March 20, 2025)
{p_end}

{phang}
Kondo, K. (2016). "Hot and cold spot analysis using Stata," {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0446":st0446}
{p_end}

{phang}
Kondo, K. (2017). "SPGEN: Stata module to generate spatially lagged variables,"
 Statistical Software Components, S458105, Boston College. {browse "https://ideas.repec.org/c/boc/bocode/s458105.html"}
{p_end}

{phang}
Kondo, K. (2018). "MORANSI: Stata module to compute Moran's I,"
 Statistical Software Components, S458473, Boston College. {browse "https://ideas.repec.org/c/boc/bocode/s458473.html"}
{p_end}

