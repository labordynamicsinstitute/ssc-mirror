{smcl}
{cmd:help ilr}
{hline}

{title:Title}

{pstd}{cmd:ilr} {hline 2} Command to compute a isometric log-ratio (ILR) transformation on a set of variables{p_end}


{title:Syntax}

{pstd}{cmd:ilr} {it:varlist}{p_end}


{title:Description}

{pstd}{cmd:ilr} computes a isometric log-ratio (ILR) transformation on a set of variables (n>2). ILR transformation is a mathematical technique used in compositional data analysis. Compositional data are parts of a whole and carry relative information, typically constrained by a constant sum, such as 100% or 1440 (e.g. the minutes in a day). This type of data often arises in economics, environmental science, ecology, and other fields.

{pstd}Compositional data have a closure problem, meaning that the data are not free to vary independently and standard statistical techniques cannot be applied directly. The ILR transformation is one of several methods designed to overcome this issue by transforming the compositional data into unconstrained, real-valued coordinates. The ILR transformation maintains the relative information in the data but represents it in a Euclidean space, where the usual assumptions of statistical analysis (like normality, constant variance, etc.) are more appropriate. This transformation is an isometric transformation, which means it preserves the geometry of the data.

{pstd}The ILR transformation involves taking logarithms of ratios of the parts. For a D-part composition, the ILR coordinates are defined as follows: {cmd:z_i = sqrt(i / (i + 1)) * log(x_i / (prod(j = i+1 to D) x_j)^(1 / (i + 1))} for {cmd:i} = 1, ..., D - 1 where {cmd:z} represents the set of variables and {cmd:D} the dimensional Euclidean space. 

{pstd}{cmd:ilr} checks the sum of {it:varlist} adds up to the same number (at 0.0001 precision level) and reports an error if it is not the case.{p_end}


{title:Remarks}

{pstd}The {cmd:ilr} command creates a set of new variables for each {it:var} in {it:varlist} at the end of the dataset following the naming {it:var_ilr`N'}, where N is equal to the number of variables in the composition minus one.{p_end}

{pstd}The programme is not executed if less than three variables are listed in {it:varlist}.{p_end}


{title:Example}

{pstd}{cmd:use http://fmwww.bc.edu/repec/bocode/g/gdp.dta, clear}

{pstd}Isometric log-ratio (ILR) transformation of the components {it:agriculture industry services}{p_end}
{phang2}{cmd:. ilr agriculture industry services}{p_end}


{title:Author}

{pstd}{browse "https://giacomozanello.com/":Giacomo Zanello}{p_end}
{pstd}University of Reading{p_end}
{pstd}Reading, UK{p_end}

{pstd}If you use the command, please consider citing this software as follows:

{pmore}
    Giacomo Zanello, 2024. "ilr: Command to compute a isometric log-ratio (ILR) transformation on a set of variables" Statistical Software Components, Boston College Department of Economics.{p_end}
	
	
{title:Last updated}

{pstd} 1 February 2024{p_end}