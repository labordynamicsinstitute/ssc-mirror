{smcl}
{* *! version 1.0  2025/01/08}{...}
{hi:help simufe}{right:also see: {help scatterfit}}
{right: {browse "mailto:arlionn@163.com":Yujun Lian, arlionn@163.com}}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: simufe} {hline 2}}Simulate panel data with fixed effects and generate scatter plots with optional fitting lines.{p_end}
{p2colreset}{...}


{marker quickexample}{...}
{title:Quick examples}

{phang}. {stata "simufe"}{p_end}
{phang}. {stata "simufe, n(2) rho(0)"}{p_end}
{phang}. {stata "simufe, n(3) rho(-1) t(500)"}{p_end}
{phang}. {stata "simufe, n(20) rho(0)"}{p_end}
{phang}. {stata "simufe, n(20) rho(-2)"}{p_end}
{phang}. {stata "simufe, n(20) rho(-1) t(50) gap(0)"}{p_end}
{phang}. {stata "simufe, n(30) rho(-0.8) sigmae(0.5) t(40)"}{p_end}


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:simufe}  
[{cmd:,} options 
]

{col 5}{hline 80}
{col 5} {it:options} {col 28}Description
{col 5}{hline 80}
{col 5}Panel Data Settings
{col 5}{hline 32} 			 
{col 7}{cmdab:n(int 5)}    {col 28}Number of individuals (default: 5)
{col 7}{cmdab:t(int 20)}   {col 28}Number of time periods (default: 20)
{col 7}{cmdab:r:ho(real -1)}{col 28}Correlation between x and individual effects (default: -1)
{col 7}{cmdab:g:ap(real 5)} {col 28}Gap between individual effects (default: 5)

{col 5}Model Parameters
{col 5}{hline 15}        
{col 7}{cmdab:b:etax(real 0.5)}   {col 28}Coefficient of x in the model (default: 0.5)
{col 7}{cmdab:s:igmax(real 2)}    {col 28}Standard deviation of x's random component (default: 2)
{col 7}{cmdab:sigmae(real 1)}    {col 28}Standard deviation of the error term (default: 1)

{col 5}Random Seed
{col 5}{hline 10}        
{col 7}{cmdab:seed(int 135)}     {col 28}Random seed for reproducibility (default: 135)

{col 5}Plot Options
{col 5}{hline 10}        
{col 7}{cmdab:nop:lot}            {col 28}Suppress the scatter plot
{col 7}{cmdab:one:fit}            {col 28}Plot a single fitting line instead of by-group lines

{col 5}Save Data
{col 5}{hline 10}        
{col 7}{cmdab:sav:ing(string)}    {col 28}Save the generated dataset to the specified file
{col 5}{hline 80} 


{marker description}{...}
{title:Description}

{pstd}
{cmd:simufe} is a Stata program that simulates panel data with fixed effects and generates scatter plots with optional fitting lines. The data generating process (DGP) is as follows:

{pstd}
1. Individual fixed effects {it:ai} are generated as {it:ai = id * gap}, where {it:id} is the individual identifier and {it:gap} is the gap between individual effects.

{pstd}
2. The explanatory variable {it:x} is generated as {it:x = rho * ai + u_x}, where {it:u_x} is a random component with standard deviation {it:sigmax}.

{pstd}
3. The error term {it:e} is generated from a normal distribution with standard deviation {it:sigmae}.

{pstd}
4. The dependent variable {it:y} is generated as {it:y = ai + betax * x + e}.

{pstd}
The program also provides options to suppress the scatter plot, plot a single fitting line, and save the generated dataset to a file.


{marker examples}{...}
{title:Examples}

{dlgtab:basic usage}

{pstd}
Simulate panel data with default settings and plot the scatter plot:

{phang2}. {stata "simufe"}{p_end}

{pstd}
Simulate data to explain dummy variables:

{phang2}. {stata "simufe, n(2) rho(0) seed(23579)"}{p_end}

{pstd}
Simulate panel data with 3 individuals and 500 time periods:

{phang2}. {stata "simufe, n(3) t(500)"}{p_end}

{pstd}
Simulate panel data without individual effects:

{phang2}. {stata "simufe, n(20) rho(-1) t(50) gap(0)"}{p_end}

{dlgtab:special usage}

{pstd}
Simulate panel data with a larger gap between individual effects and save the dataset:

{phang2}. {stata "simufe, n(20) gap(10) saving(mydata.dta)"}{p_end}

{pstd}
Simulate panel data with a single fitting line instead of by-group lines:

{phang2}. {stata "simufe, n(10) onefit"}{p_end}

{pstd}
Simulate data and suppress the plot:

{phang2}. {stata "simufe, noplot"}{p_end}

{marker author}{...}
{title:Author}

{phang}
{cmd:Yujun Lian (连玉君)} Lingnan College, Sun Yat-Sen University, China.{break}
E-mail: {browse "mailto:arlionn@163.com":arlionn@163.com} {break}
Blog: {browse "https://www.lianxh.cn":lianxh.cn} {break}
{p_end}


{marker also_see}{...}
{title:Also see}

{psee} Online:  
{help scatterfit} (if installed),
{help panel data} (Stata manual)
{p_end}