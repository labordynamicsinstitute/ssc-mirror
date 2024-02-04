{smcl}
{cmd:help compreg}
{hline}

{title:Title}

{pstd}{cmd:compreg} {hline 2} Command to estimate a compositional regression with isometric log-ratio (ILR) transformation of the components{p_end}


{title:Syntax}

{pstd}{cmd:compreg} {it:depvar} [{it:varlist}], comp({it:varlist2}) [{it:options}]{p_end}


{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{synopt:{cmd:ilr}} Saves the isometric log-ratio (ILR) transformations in the dataset {p_end}


{title:Description}

{pstd}{cmd:compreg} estimates a compositional regression with isometric log-ratio (ILR) transformation of the components. Compositional regression with isometric log-ratio (ILR) transformation is a statistical method used when dealing with compositional data, independent variables represent parts of a whole and sum up to a constant, e.g. 1, 100%, or any number (1440 for the minutes in a day). Such data are common in multiple fields, for example economics, environment, ecology, in which data are often proportions or percentages. The challenge with compositional data is their constrained nature, which can lead to spurious correlations and statistical issues if standard regression techniques are applied directly. The ILR transformation is a solution to this problem. It converts the compositional data into log-ratios, removing the constant sum constraint and allowing the data to be analysed in a Euclidean space. This transformation facilitates the use of standard statistical methods, such as linear regression, while preserving the relative information in the data. ILR-based compositional regression can be used to understand relationships between parts of a composition, as it provides a more accurate and meaningful analysis than traditional methods applied to individual components.{p_end}

{pstd}{cmd:compreg} computes a isometric log-ratio (ILR) transformation of the different components and estimates a linear regression for each set of ILRs using the command {helpb regression}. {cmd:compreg} requires {helpb ilr} to be installed.{p_end}

{pstd}{it:varlist2} must include the set of variables (n>2) for the components. The programme checks the sum of {it:varlist2} adds up to the same number and reports an error if it is not the case.


{title:Options}
{dlgtab:Main}
{phang}

{pstd}{cmd:ilr} saves the isometric log-ratio (ILR) transformed variables in the dataset.


{title:Remarks}

{pstd}The command {cmd:compreg} requires {helpb ilr}. {p_end}


{title:Example}

{pstd}{cmd:use http://fmwww.bc.edu/repec/bocode/g/gdp.dta, clear}

{pstd}Compositional regression with {it:GDP} as dependent variable and with the components {it:agriculture industry services} as independent variables.{p_end}
{phang2}{cmd:. compreg GDP, comp(agriculture industry services)}{p_end}

{pstd}Compositional regression with {it:GDP} as dependent variable, with the components {it:agriculture industry services} as independent variables, and {it:population} as control variable.{p_end}
{phang2}{cmd:. compreg GDP population, comp(agriculture industry services)}{p_end}

{pstd}Compositional regression with {it:GDP} as dependent variable, with the components {it:agriculture industry services} as independent variables, and {it:population} as control. Save the ILRs in the dataset.{p_end}
{phang2}{cmd:. compreg GDP population, comp(agriculture industry services) ilr}{p_end}


{title:Author}

{pstd}{browse "https://giacomozanello.com/":Giacomo Zanello}{p_end}
{pstd}University of Reading{p_end}
{pstd}Reading, UK{p_end}

{pstd}If you use the command, please consider citing this software as follows:

{pmore}
    Giacomo Zanello, 2024. "Command to estimate a compositional regression with isometric log-ratio (ILR) transformation of the components" Statistical Software Components, Boston College Department of Economics. {p_end}
	
	
{title:Last updated}

{pstd} 1 February 2024{p_end}