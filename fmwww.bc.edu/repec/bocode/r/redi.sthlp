{smcl}
{* *! version 1.1 11 October 2021}{...}

{title:Title}

{p2colset 5 15 20 2}{...}
{p2col:{hi:redi} {hline 1}} A Random Empirical Distribution Imputation method for estimating continuous incomes {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd: redi}
{help varname: incvar}
{help varname: year}
{cmd:,}
Generate({newvar})
[
{help options: CPStype(string)}
{help options: INFlationyear(int)}
]

{p 4 4 2}
where {it:incvar} is

{p 8 17 2}
the name of the categorical income variable in the original research dataset, and
{it:incvar} may be either a string variable (with the categories as text) or a numeric variable
(with the categories storied as value labels);

{p 4 4 2}
{it:year} is

{p 8 17 2}
the name of the year variable in the original research dataset; and

{p 4 4 2}
{it:Generate(newvar)} specifies

{p 8 17 2}
a name for the new continuous income variable calculated using the {cmd:redi} method.


{title:Description}

{p 8 17 2}
{cmd:redi} is a method for cold-deck imputation of a continuous distribution
from binned incomes, using a real-world reference dataset (in this case, the CPS ASEC).

{p 4 4 2}
The Random Empirical Distribution Imputation ({cmd:redi}) method imputes
discrete observations using binned income data. The user may wish to combine
or compare income data across years or surveys, stymied by incompatible categories.
{cmd:redi} converts categorical to continuous incomes through random
cold-deck imputation from a real world reference dataset. The {cmd:redi} method
reconciles bins between datasets or across years and handles top incomes.
{cmd:redi} has other advantages of computing an income distribution that is
nonparametric, bin consistent, area- and variance-preserving, and continuous.
 For a complete discussion of the method's features and
limitations, see the "REDI for Binned Data" paper, listed under the references.
If you find this method useful for your research, please consider citing this reference.


{title:Options}

{dlgtab:Main}

{phang}
{opt CPStype(string)} specifies the type of income reference variable to use from the CPS ASEC reference dataset.
Options are "household", "family", or "respondent"-level income.

{phang}
{opt INFlationyear(int)} specifies the year to which the data should be inflated using the R-CPI-U-RS (see remarks).
The year should be specified as a 4-digit number. If no inflation adjustment is desired, do not specify.



{title:Remarks}

{p 4 4 2}
{it:Reference Data}

{p 4 4 2}
Prior to using this command, you must download and place a reference dataset into your
current working directory.
The default reference dataset (the Current Population Survey ASEC) is available for download from
the IPUMS CPS website ({browse "cps.ipums.org":cps.ipums.org}).
To use the CPS ASEC as the reference dataset, the researcher must download this
dataset for the year(s) of interest before using the CPS ASEC as a reference
dataset with this command. The variables needed are: YEAR, ASECWTH, HHINCOME,
and PERNUM. Place this dataset in your current working directory and name the file "cps_reference.dta".
Additional
{browse "https://www.census.gov/topics/population/foreign-born/guidance/cps-guidance/using-cps-asec-microdata.html":details on using the CPS ASEC Public Use Microdata},
including technical documentation and details about analysis using survey weights, may also be useful.

{p 4 4 2}
{it:Program Output}

{p 4 4 2}
Without specifying an inflation year, the {cmd:redi} command produces the
continuous income variable {newvar} calculated in the dollar value corresponding to the year of the
original research dataset.

{p 4 4 2}
With the inflation option, the {cmd:redi} command
produces both this same continuous income variable {newvar} calculated using the {cmd:redi}
method, and another new variable adjusted for inflation using the specified inflation dataset and year.
In the process of producing the continuous value, the {cmd:redi} command will also
generate a lower-bound variable ({it:incvar}_lb) and an upper-bound variable
({it:incvar}_ub) for the continuous income variable drawn from the reference dataset.
These can be used to verify the new continuous variable or dropped at the researcher's
convenience.

{p 4 4 2}
{it:Inflation}

{p 4 4 2}
The Consumer Price Index retroactive series using current methods with all items
(R-CPI-U-RS) is available from the U.S. Bureau of Labor Statistics website
({browse "http://www.bls.gov/cpi/research-series/r-cpi-u-rs-home.htm":http://www.bls.gov/cpi/research-series/r-cpi-u-rs-home.htm}).
The Retroactive Series (R-CPI-U-RS) estimates the Consumer Price Index for Urban
Consumers from 1978, using current methods that incorporate these improvements
over the entire time span. Using the {opt inflation_year} option for
automatically downloads this dataset for use in inflation adjustment. The year
specified indicates the year that should be used for inflation-adjusted dollars.
Using this option produces a variable named ({newvar})_inf({it:int})


{p 4 4 2}
{it:Missing Values}

{p 4 4 2}
Note that the command handles missing values in the {it:incvar} variable input by
translating all missing values for the {it:incvar} variable to the code 98.
The user will want to verify that none of the existing codes for {it:incvar} are
meaningfully assigned 98 prior to using the {cmd:redi} command. At the end of the
program, 98 values for {it:incvar} are automatically decoded back to missing values.
Unfortunately, these may not be the exact missing code from the original research data.


{title:Examples}

{p 4 4 2}
// Calculate a new continuous income variable named finc_continuous from categorical
household income variable {it:incfamily} and year variable {it:year}.
The family income type needs to be specified as an option.{p_end}
{p 8 17 2}
{help cmd: redi} {help var: incfamily} {help var: yr}, generate(finc_continuous) cpstype(family)

{p 4 4 2}
// Inflate the resulting continuous household income values to 2020 dollars using the R-CPI-U-RS. This example will produce not only household_cont but also household_cont_inf2020,
a version of the continuous variable inflated to 2020 dollars. Here we see the shorthand versions of the program options. {p_end}
{p 8 17 2}
{help cmd: redi} {help var: incfamily} {help var: yr}, g(finc_continuous) cps(family) {help options: inf(2020)}


{title:Author}

{p 4 4 2}
     Molly M. King {break}
		 Department of Sociology, Santa Clara University {break}
		 {browse "https://www.mollymking.com/":https://www.mollymking.com/} {break}
		 {browse "mailto:mollymkingphd@gmail.com?subject=redi":mollymkingphd@gmail.com}{p_end}

{title:Acknowledgments}

{p 4 4 2}
I am grateful to Jeremy Freese for his significant help with the syntax and implementation of this program.
I thank Christof Brandtner, Jeremy Freese, and David Grusky for their feedback on the methodological paper underlying this program.
I also thank Nicholas J. Cox for his useful Stata programs and help files, which have served as a model for this help file.

{title:References}

{p 4 8 2}
Baum, C.F. 2020. {browse "http://repec.org/bocode/s/sscsubmit.html":Submitting and retrieving materials from the SSC Archive}.

{p 4 8 2}
King, Molly M. 2022. "REDI for Binned Data: A Random Empirical Distribution Imputation method for estimating continuous incomes."
Forthcoming in {it:Sociological Methodology.} {browse "https://doi.org/10.31235/osf.io/eswm8":Available on the SocArXiv Pre-print server.}

{break}
