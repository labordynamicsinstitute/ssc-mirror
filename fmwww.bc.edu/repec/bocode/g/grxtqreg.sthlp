{smcl}
{* 26Nov2018}{...}
{hline}
help for {hi:grxtqreg}
{hline}

{title:Graph the Coefficients of the Quantile Regression for Panel Data (QRPD)}

{cmd:grxtqreg} graphs the coefficients of the quantile regression for panel data. It also has the option to graph the confidence interval, 
         the general FE (fixed effect) coefficient and the FE confidence interval on the same graph. The command is based on {helpb xtqreg}.
         A panel variable and a time variable must be specified; use {helpb xtset}.


{marker syntax}{...}
{title:Syntax}

{p 5 5 2}
{cmd:grxtqreg} {depvar} [{indepvars}] {ifin} [, {opt q:num(integer)} {opt ci fxe fxeci} {opt com:bine} {opt sch:eme(schemename)}]{p_end}


{title:Options}

{phang}
{opt q:num(integer)} use # quantile in quantile regression for panel data. The default is {cmd:qnum(20)}.

{phang}
{cmd:ci} graph confidence interval of quantile regression for panel data. Default off.

{phang}
{cmd:fxe} graph the general fixed effect (FE) model coefficients. Default off.

{phang}
{cmd:fxeci} graph confidence interval of the general fixed effect (FE) model. Default off.

{phang}
{opt com:bine} combine multiple graphs about coefficients of the quantile regression for panel data into one. Default off.

{phang}
{opt sch:eme(schemename)} sets the default scheme, the default is {cmd:scheme(s1color)}. See {helpb scheme} for details.


{title:Examples}

{pstd}Setup {p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

{pstd}Graph the coefficients of the quantile regression for panel data{p_end}
{phang2}{cmd:. grxtqreg ln_wage tenure union}{p_end}

{res}{txt}
{pstd}Same as above, but add FE estimate coefficients {p_end}
{phang2}{cmd:. grxtqreg ln_wage tenure union , fxe}{p_end}

{res}{txt}
{pstd}Same as above, but add confidence interval (QRPD & FE){p_end}
{phang2}{cmd:. grxtqreg ln_wage tenure union , fxe ci fxeci}{p_end}

{res}{txt}
{pstd}Same as above, but use 10 quantile{p_end}
{phang2}{cmd:. grxtqreg ln_wage tenure union , fxe ci fxeci qnum(10)}{p_end}

{res}{txt}
{pstd}Same as above, but combine all graphs into one and set s1mono scheme{p_end}
{phang2}{cmd:. grxtqreg ln_wage tenure union , fxe ci fxeci qnum(10) combine scheme(s1mono)}{p_end}


{title:References}

{phang}
Canay, I. A. (2011). "A Simple Approach to Quantile Regression for Panel Data". {it:Econometrics Journal}, 14(3): 368–386.

{phang}
Galvao, A. F. (2011). "Quantile Regression for Dynamic Panel Data with Fixed Effects". {it:Journal of Econometrics}, 164(1): 142-157.

{phang}
Harding, M., Lamarche, C. (2009). "A Quantile Regression Approach for Estimating Panel Data Nodels Using Instrumental Variables". 
{it:Economics Letters}, 104(3): 133-135.

{phang}
Koenker, R., Basset G. (1978). "Regression Quantiles". {it:Econometrica}, 46(1): 33-50.

{phang}
Koenker, R., Hallock K. F. (2001). "Quantile Regression". {it:Journal of Economic Perspectives}, 15(4): 143-156.

{phang}
Powell, D. (2015). "Quantile Regression with Nonadditive Fixed Effects". {it:RAND Labor and Population Working Paper}.

{phang}
Powell, D., Wagner, J. (2014). "The Exporter Productivity Premium along the Productivity Distribution: Evidence from Quantile Regression 
with Nonadditive Firm Fixed Effects". {it:Review of World Economics}, 150(4): 763-785.


{title:Authors}

{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}. {break}


{title:Also see}

{p 4 14 2}Help:  {helpb qreg}; {helpb grqreg}(if install), {helpb xtqreg}(if install), {helpb genqreg}(if install).{p_end}
