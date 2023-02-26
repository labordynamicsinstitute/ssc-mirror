{smcl}
{* *! version 1.0 2023/02/21}{...}
{hline}
{cmd:help for {hi:eacf}}{right: ({browse "https://github.com/TlightZ/eacf-stata":Github})}
{hline}

{title:Extended Sample Autocorrelation Function}


{title:Syntax}

{p 4 19 2}
{cmdab:eacf} {varlist} {ifin},  
[
{cmdab:ar}{cmd:(}integer{cmd:)}
{cmdab:ma}{cmd:(}integer{cmd:)}
]

{title:Description}

{p 4 4 2}
{cmd:eacf} calculates and displays the EACF table, used to specify the order of AR and MA for stationary and nonstationary ARMA models.

{title:Options}

{p 4 8 2}{cmd:ar(}{it:integer}{cmd:)} max autoregressive term. Default is 7.

{p 4 8 2}{cmd:ma(}{it:integer}{cmd:)} max moving-average term. Default is 13.

{title:Examples}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. use seriesA.dta}{p_end}
{phang2}{cmd:. tsset time}{p_end}
{hline}
{pstd}Calculate EACF Tables{p_end}
{phang2}{cmd:. eacf dataA}{p_end}
{phang2}{cmd:. eacf dataA, ar(5)}{p_end}
{phang2}{cmd:. eacf dataA in 1/150, ar(3) ma(6)}{p_end}

{title:Stored results}
{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmdab:r(symbol)}} x&o Table derived from r(seacf) of size (ar+1)x(mr+1){p_end}
{synopt:{cmdab:r(seacf)}} EACF Table of size (ar+1)x(mr+1){p_end}

{title:References}

{p 4 8 2}Tsay, Ruey S., and George C. Tiao. "Consistent Estimates of Autoregressive Parameters and Extended Sample Autocorrelation Function for Stationary and Nonstationary ARMA Models." {it:Journal of the American Statistical Association}, vol. 79, no. 385, 1984, pp. 84–96.

{title:Acknowledgements}

{p 4 8 2}
Algorithm in eacf.R from The R Package "TSA" by K.S. CHAN, department of statistics and actuarial science, University of IOWA, is referred.

{title:Author}

{phang}
{cmd:H.W. Zheng} {break}
Github: {browse "https://github.com/TlightZ":https://github.com/TlightZ}. {break}
Email: {browse "mailto:zhenghw25@mail2.sysu.edu.cn":zhenghw25@mail2.sysu.edu.cn}. {break}
{p_end}