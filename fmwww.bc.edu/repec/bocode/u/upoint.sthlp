{smcl}
{* 20jul2025}{...}
{hline}
help for {hi:upoint}
{hline}

{title:Calculate the change value of inflection point of U or inverted U curve: b1 * b4 - b2 * b3}

{p 8 15 2} {cmd:upoint}
	{it:varlist}
	[{cmd:if} {it:exp}]
	[{cmd:in} {it:range}]
	,
	{cmdab:gen:erate(}{it:mevar}{cmd:)}
	


{title:Description}

{p 4 4 2} {cmd:upoint} Calculate the change value of inflection point of U or inverted U curve. One variable of times series must be

included in memory dataset, which be declared as times series or panel data (using {cmd:tsset}, or {cmd:xtset}).

{p 4 4 2} Use the {it:mevar} to specify mediating effect variable.

{p 4 4 2} {cmd:upoint} allows factor variables; see {help fvvarlist}.


{p 4 4 2} Technical note about the computation of the change value of inflection point: For a regression, the point are computed as

           upoint = beta1 * beta4 - beta2 * beta3

{p 4 4 2} where beta1, beta2, beta3, beta4  are the regression coefficients of the below regressors:
          
	x1, x1^2, x1 * mevar, (x1^2)* mevar


{title:Options}


{p 4 8 2} {cmdab:gen:erate(}{it:mevar}{cmd:)} specifies the name of the
new variable to be created({it:mevar}). 


{title:Examples}

        {inp}. sysuse auto, clear

        . gen t = _n

        . tsset t

        . generate pricesq = price^2

        . regress mpg price pricesq weight, vce(robust)

        . utest price pricesq

        . save auto2, replace

        . preserve

        . upoint mpg price pricesq weight, gen(foreign)

        . restore

        . upoint mpg price pricesq weight L.rep78, gen(foreign)

        . use auto2, clear

        . upoint mpg price pricesq weight i.rep78, gen(foreign)

        . use conservatism, clear

        . preserve
	
        . regress Score C_SCORE C_SCORE2 industry, vce(robust)
	
        . utest C_SCORE C_SCORE2
	
        . upoint Score C_SCORE C_SCORE2 industry, gen(D)

        . restore
        {txt}


{title:References}

{p 4 8 2} Baum, C.F. 2009, 2016. An Introduction to Stata Programming. 


{title:Author}

{p 4 4 2}
Wu LiangHai, Chen LiWen. School of Business, University of Anhui Technology.

{p 4 4 2}
E-mail: agd2010@yeah.net

{title:Also see}

{p 4 13 2}
Manual:  {hi:[R] syntax}

{p 4 13 2}
On-line:  help for {help syntax}