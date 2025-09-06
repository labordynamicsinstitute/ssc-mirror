{smcl}
{* 2017-07-19 Lutz Bornmann}{...}
{title:Title}
{p2colset 5 14 23 2}{...}

{p2col:{cmd:plotrpys} {hline 2} uses CSV graph export files from CRExplorer ({browse "http://www.crexplorer.net/"}) and plots different types of spectrograms}

{p2colreset}{...}
{title:General syntax}

{p 4 18 10}
{cmdab:plotrpys [varlist]} [if] [in], color(col|mono) curve(both|median) [TWOptions(string)]

{marker overview}
{title:Overview}

{pstd}
{cmd:plotrpys} uses CSV export files from CRExplorer ({browse "http://www.crexplorer.net/"}) and plots several types of spectrograms. After import of the CSV file in Stata, the command needs three variables in this order: (1) reference publication year (year), (2) annual cited references counts (ncr), and (3) deviations from the median (median5). The command demands specifications whether coloured or monochrome spectrograms are required as well as which curves should be plotted. {cmd:plotrpys} requires the Stata module "schemepack" ({browse "https://github.com/asjadnaqvi/stata-schemepack"}). {p_end}

{pstd}
If both graphs are required by the user (annual cited references counts and median deviations), the curve showing the annual cited references counts are shown with confidence intervals (CIs). Since one can assume that cited references counts follow a Poisson distribution, the standard deviation can be computed as the square root of their expected value. So if the observed cited references counts for a reference publication year are large, the standard deviation is also large - which means the CIs become wider in absolute terms. Lower and upper bounds of the CIs are shown in the graph in addition to the cited references counts. The CIs are calculated by using the invchi2 function in Stata: invchi2(2 * x, 0.025)/2 (higher bounds), invchi2(2 * (x + 1), 0.975)/2 (lower bounds), whereby x are the annual cited references counts. {p_end}

{pstd}
If only median deviations are required to be plotted, the positive median deviations are shown to identify the most important peaks in the spectrogram. Additionally, two dotted lines are included in the graph. These lines going back to Turkey's fences are intended to support the identification of the most important peaks. Tukey (1977) proposes a method for detecting outliers, which can be used here to flag important peaks based on the interquartile range of the median deviations (with positive values). If Q1 and Q3 define this range with lower and upper quartiles, the following formula can be used to detect "outlier" peaks above this range: [Q3 + k (Q3 – Q1)]. According to Tukey (1977), k = 1.5 indicates "outliers" and k = 3 cases, which are "far out". The "outlier" reference publication years are labeled in the spectrogram. {p_end}

{marker options}
{title:Options}
{p2colset 5 12 13 0}
{synopt:{opt color(col|mono)}} specifies whether the graph is colored or monochrome.

{synopt:{opt curve(both|median)}} specifies whether both cited references counts and deviations from the median or  only deviations from the median are plotted.

{synopt:{opt twoptions(string)}} several options from the twoway command can be used such as xlabel.

{marker examples}
{title:Examples}

{pstd}
{cmd: . plotrpys year ncr median5, color(mono) curve(both)}
{p_end}

{pstd}
{cmd: . plotrpys year ncr median5, color(col) curve(median)}
{p_end}

{pstd}
{cmd: . plotrpys year ncr median5, color(mono) curve(median)}
{p_end}

{pstd}
{cmd: . plotrpys year ncr median5, color(mono) curve(median) twoptions(xlabel(1900(10)2000) ylabel(0(50)200))}
{p_end}

{pstd}
{cmd: . plotrpys year ncr median5 if inrange(year, 1950, 2020), color(col) curve(both) twoptions(xlabel(1950(5)2000) ylabel(0(500)3000, axis(1)) ylabel(-500(100)500, axis(2)))}
{p_end}

{pstd}
{cmd: . plotrpys year ncr median5 if inrange(year, 1920, 2000), color(col) curve(both) twoptions(xlabel(1920(5)2000) ylabel(-200(50)200, axis(2)))}
{p_end}

{pstd}
{cmd: . plotrpys year ncr median5 if inrange(year, 1950, 2000), color(mono) curve(median) twoptions(xlabel(1950(5)2000) ylabel(0(50)500))}
{p_end}

{title:Literature}

{phang} Tukey, J. W. (1977). Exploratory Data Analysis: Addison-Wesley Publishing Company

{title:Author}

{phang} Lutz Bornmann, Max Planck Society, Munich (bornmann@gv.mpg.de)

