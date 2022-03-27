{smcl}
{* *! version 1.0  29 Apr 2021}{...}
{cmd:help xtmoran}
{hline}

{title:Title}

{phang}
{bf:xtmoran} {hline 2} Calculating the Moran's I and Moran's Ii for panel data and displaying a Moran scatterplot

{title:Syntax}

{p 8 14} {cmd:xtmoran} {it:varname} {cmd:,}
{cmdab:wname}{cmd:(}{it:matrix}{cmd:)}
[ {cmdab:morani(numlist)} {cmdab:graph}
{cmdab:symbol(varname)}  ]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt wname(string)}} spatial weight matrix in dta format.{p_end}
{synopt:{opt morani(numlist)}} year of calculation of the Moran's {it:Ii}. {p_end}
{synopt:{opt graph}} display a Moran scatterplot.{p_end}
{synopt:{opt symbol(varname)}} identification of locations in the Moran scatter plot.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}  1. A panel variable and a time variable must be specified; use xtset (xtmoran requires balanced panel data !!!) {p_end}
{p 4 6 2}  2. Only one variable can be calculated for the Moran's I and Moran's Ii ! {p_end}
{p 4 6 2}  3. wname(name) : The spatial weight matrix can only be used in dta format
              and by default this matrix will be normalised. {p_end}



{title:Description}

{p} {cmd:xtmoran} computes the global spatial autocorrelation statistic: Moran's {it:I} and local spatial autocorrelation statistics: Moran's {it:Ii}. 
{cmd:xtmoran} computes anddisplays in tabular form the statistic itself, the expected value of the statistic under the null hypothesis of global spatial independence, the standard deviation of the statistic, the {it:z}-value, and the corresponding 2-tail {it:p}-value.
{cmd:xtmoran} also displays a Moran scatterplot.

{title:Stored results}

{pstd}
{cmd:xtmoran} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}Number of cross-sections.{p_end}
{synopt:{cmd:r(T)}}Number of time periods.{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(moran)}} A (T x 5) matrix containing the results of Moran's {it:I}.{p_end}
{synopt:{cmd:r(morani{it:time})}} A (N x 6) matrix containing the results of Moran's {it:Ii}.{p_end}




{marker Examples}{...}

{title:Examples}

{phang}{cmd:. use panel.dta}

{phang}{cmd:. xtset id year}

{phang}{cmd:. xtmoran y, wname(w.dta) }

{phang}{cmd:. xtmoran y, wname(w.dta) morani(2012 2013 2014 2015)}

{phang}{cmd:. xtmoran y, wname(w.dta) morani(2012 2013 2014 2015) graph}

{phang}{cmd:. xtmoran y, wname(w.dta) morani(2012 2013 2014 2015) graph symbol(name)}

{title:Authors}

{p 8} Zihou,Chen {p_end}
{p 8} Party School of the Guangdong Provincial Committee of CPC,China {p_end}
{p 8} Email: {browse "mailto:econometricalc@outlook.com":econometricalc@outlook.com} {p_end}

{p 8} Xiangge,Liu {p_end}
{p 8} Party School of the Guangdong Provincial Committee of CPC,China {p_end}
{p 8} Email: {browse "mailto:1920888280@qq.com":1920888280@qq.com} {p_end}

{p 8} Jiahui,Xu {p_end}
{p 8} Party School of the Guangdong Provincial Committee of CPC,China {p_end}
{p 8} Email: {browse "xujiahui0106@163.com":xujiahui0106@163.com} {p_end}

{title:Also see}

{p 0 19}On-line:  help for {help splagvar}, {help spatgsa} ,{help spatlsa} if installed
{p_end}

