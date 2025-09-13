{smcl}
{* *! version 1.0.0  09sep2025}{...}
{p2colset 1 12 14 2}{...}
{p2col:{bf:nca} {hline 2}}Necessary Condition Analysis (NCA) {p_end}
{p2colreset}{...}


{title:Description}

{pstd}
The {bf: nca} package implements Necessary Condition Analysis (NCA) as developed by Dul (2016). The nca commands support data analysis, outlier analysis and simulation in the framework of NCA. {bf:nca} requires Stata 17.0 or a more recent version.

{pstd}
The {bf:nca} commands are

{p2colset 9 30 32 2}{...}
{p2col :{helpb nca_analysis}}Run multiple types of NCA analyses on a dataset{p_end}
{p2col :{helpb nca_outliers}}Outlier detection in the framework of NCA{p_end}
{p2col :{helpb nca_random}}Random number generation in the framework of NCA{p_end}
{p2col :{helpb nca_power}}Function to evaluate power, test if a sample size is large enough to detect necessity.{p_end}
{p2colreset}{...}

{pstd}
The package also includes {bf:ncaexample} and {bf:ncaexample2} datasets as well as a do-file ({bf:nca_examples.do}) with basic examples.

{title:Dependencies}

{pstd}
{bf: nca} depends on community-contributed commands {bf:grc1leg}, {bf:submatrix}, {bf:moremata} and {bf:rowsort}. Dependencies are automatically downloaded the first time any {bf:nca} command is used.

{title:References}
{pstd} Dul, J. (2016). Necessary condition analysis (NCA) logic and methodology of "necessary but not sufficient" causality. Organizational Research Methods, 19(1), 10-52. {p_end}

{pstd} Dul, J. (2020) "Conducting Necessary Condition Analysis"   SAGE Publications, ISBN: 9781526460141   https://uk.sagepub.com/en-gb/eur/conducting-necessary-condition-analysis-for-business-and-management-students/book262898 {p_end}

{pstd}  Dul, J., van der Laan, E., & Kuik, R. (2020).   A statistical significance test for Necessary Condition Analysis."   Organizational Research Methods, 23(2), 385-395.   https://journals.sagepub.com/doi/10.1177/1094428118795272 {p_end}

{title:Authors}
{pstd}Daniele Spinelli{p_end}
{pstd}Department of Statistics and Quantitative Methods {p_end}
{pstd}University of Milano-Bicocca{p_end}
{pstd}Milan, Italy{p_end}
{pstd}daniele.spinelli@unimib.it{p_end}

{pstd}Jan Dul{p_end}
{pstd}Department of Technology & Operations Management{p_end}
{pstd}Rotterdam School of Management{p_end}
{pstd}Rotterdam, The Netherlands{p_end}
{pstd}jdul@rsm.nl{p_end}

{title:Contributors}
{pstd}Govert Buijs{p_end}
{pstd}Department of Technology & Operations Management{p_end}
{pstd}Rotterdam School of Management{p_end}
{pstd}Rotterdam, The Netherlands{p_end}
{pstd}buijs@rsm.nl{p_end}