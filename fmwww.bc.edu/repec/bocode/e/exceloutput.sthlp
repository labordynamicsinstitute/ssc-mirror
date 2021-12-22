{smcl}
{* 16 August 2021}{...}
{viewerjumpto "Syntax" "exceloutput##syntax"}{...}
{viewerjumpto "Options" "exceloutput##options"}{...}
{viewerjumpto "Examples" "exceloutput##examples"}{...}

{title:Title}
{p2colset 5 19 23 2}{...}
{p2col :{cmd:exceloutput} {hline 2}} Output several results to specified cell in putexcel file
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:exceloutput} {cell}
[{cmd:,} {it:{help hashsort##options:options}}]


{marker menu}{...}
{title:Menu}

{marker description}{...}
{title:Description}

{pstd}
{opt exceloutput} can be invoked after an estimation takes place and takes as an argument an excel cell. It will then place regression coefficients in the selected cell and standard error in the cell 
beneath along with stars for p-values. Helps make cleaner do files and removes multiple lines of putexcel code that would be required. A decent alternative to estout and custum putexcel commands if quick output is required.

{pstd}
The command has options to choose the number of coefficients and S.E.'s to output, the desired number of decimal places, and an option to add summary statistics
such as number of observations, R^2, and the mean of the dependent variable. 


{marker options}{...}
{title:Options}

{dlgtab:Options}


{phang}
{opth be:tas(#)} Number of coeffcients and S.E. to output. Will begin with first specified in estimation and go down. Default is 1.

{phang}
{opt ti:tle(string)} Create bold title in first specified cell and coeffcients and S.E. come under

{phang}
{opt b:_decimal(#)} Number of decimal places for coeffcients

{phang}
{opt se:_decimal(#)} Number of decimal places for standard errors

{phang}
{opt d:etail} Include dependent varible mean, R2, and Number of observations underneath coeffcients and S.E.

{phang}
{opt me:an_decimal(#)} Number of decimal places for mean

{phang}
{opt r2:_decimal(#)} Number of decimal places for R^2


{marker examples}{...}
{title:Examples}

{hline}
    Setup
	
{phang2}{cmd:. sysuse auto}

{phang2}{cmd:. putexcel set exceloutput_example.xlsx, replace}

{phang2}{cmd:. reg mpg price rep78}

{pstd} Place mpg coeffcient and s.e in Cell A2 of exceloutput_example.xlsx

{phang2}{cmd:. exceloutput A2}

{pstd} Place mpg and price coeffcients and s.e's in Cell B2 of exceloutput_example.xlsx

{phang2}{cmd:. exceloutput B2, be(2)} 

{pstd} Place mpg and price coeffcients and s.e's in Cell C2 of exceloutput_example.xlsx, give it title of "Example", show y-mean, R2 and number of obs

{phang2}{cmd:. exceloutput C2, be(2) ti("Example") d}





