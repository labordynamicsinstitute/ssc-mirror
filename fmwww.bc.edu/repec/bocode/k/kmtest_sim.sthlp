{smcl}
{* *! version 1.0.0  23jan2026}{...}
{vieweralsosee "kmtest" "help kmtest"}{...}
{viewerjumpto "Syntax" "kmtest_sim##syntax"}{...}
{viewerjumpto "Description" "kmtest_sim##description"}{...}
{viewerjumpto "Options" "kmtest_sim##options"}{...}
{viewerjumpto "Examples" "kmtest_sim##examples"}{...}
{title:Title}

{phang}
{bf:kmtest_sim} {hline 2} Simulate integrated processes for testing


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:kmtest_sim}
{newvar}
{cmd:,}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Parameters}
{synopt:{opt n(#)}}number of observations; default is {cmd:n(100)}{p_end}
{synopt:{opt y0(#)}}initial value; default is {cmd:y0(1)}{p_end}
{synopt:{opt mu(#)}}drift parameter; default is {cmd:mu(0.01)}{p_end}
{synopt:{opt sigma(#)}}innovation standard deviation; default is {cmd:sigma(0.01)}{p_end}
{synopt:{opt ar1(#)}}AR(1) coefficient; default is {cmd:ar1(0)}{p_end}

{syntab:Model}
{synopt:{opt log}}generate logarithmic I(1) process instead of linear{p_end}

{syntab:Other}
{synopt:{opt seed(#)}}set random number seed{p_end}
{synopt:{opt replace}}replace variable if it exists{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:kmtest_sim} generates simulated integrated processes for use in testing
the {cmd:kmtest} command or for Monte Carlo experiments.

{pstd}
By default, the command generates a linear I(1) process:

{p 8 8 2}
y_t = y_{t-1} + e_t + μ

{pstd}
With the {opt log} option, it generates a logarithmic I(1) process:

{p 8 8 2}
log(y_t) = log(y_{t-1}) + u_t + η


{marker options}{...}
{title:Options}

{dlgtab:Parameters}

{phang}
{opt n(#)} specifies the number of observations to generate. Default is 100.

{phang}
{opt y0(#)} specifies the initial value of the series. Must be positive.
Default is 1.

{phang}
{opt mu(#)} specifies the drift parameter. For linear model, this is the
mean of the first differences. For log model, this is the mean of log returns.
Default is 0.01.

{phang}
{opt sigma(#)} specifies the standard deviation of the white noise innovations.
Default is 0.01.

{phang}
{opt ar1(#)} specifies the first-order autoregressive coefficient for the
innovations. Must be less than 1 in absolute value. Default is 0 (white noise).

{dlgtab:Model}

{phang}
{opt log} specifies that a logarithmic I(1) process should be generated
instead of a linear I(1) process.

{dlgtab:Other}

{phang}
{opt seed(#)} sets the random number seed for reproducibility.

{phang}
{opt replace} allows the variable to be replaced if it already exists.


{marker examples}{...}
{title:Examples}

{pstd}Generate a linear I(1) process with 200 observations{p_end}
{phang2}{cmd:. kmtest_sim y_linear, n(200) y0(100) mu(0.5) sigma(2)}{p_end}

{pstd}Generate a logarithmic I(1) process{p_end}
{phang2}{cmd:. kmtest_sim y_log, n(200) y0(100) mu(0.01) sigma(0.02) log}{p_end}

{pstd}Generate with AR(1) innovations{p_end}
{phang2}{cmd:. kmtest_sim y_ar, n(200) ar1(0.7) seed(12345)}{p_end}

{pstd}Test the simulated data{p_end}
{phang2}{cmd:. kmtest y_linear}{p_end}
{phang2}{cmd:. kmtest y_log}{p_end}


{title:Author}

{pstd}
Dr. Merwan Roudane


{title:Also see}

{psee}
{space 2}Help: {manhelp kmtest TS}
{p_end}
