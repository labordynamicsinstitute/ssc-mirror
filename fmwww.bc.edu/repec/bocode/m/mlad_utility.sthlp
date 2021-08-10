{smcl}
{*      *! version 1.0 2021-08-03}{...}
{vieweralsosee "mlad" "help mlad"}{...}
{vieweralsosee "ml" "help ml"}{...}
{vieweralsosee "python" "help python"}{...}

{hline}

{title:Title}
{p2colset 5 13 17 2}{...}
{p2col :{hi:mlad }{hline 2}}Python utility finctions for {help mlad}.{p_end}
{p2colreset}{...}


{pstd}
{cmd: mlad} has a number of utility functions written in Python. They been accessed after importing in Python, e.g. by using {cmd:import mladutil as mu}

The functions are described below.

{pstd}
{cmd:invlogit}({it:z}) 
Transforms from the log odds scale to the probability scale.

{pstd}
{cmd:linpred}({it:beta},{it:X},{it:eq}) - extract linear predictor.

{phang2}
{it:beta} - full beta matrix

{phang2}
{it:X} - full covariates list

{phang2}
{it:eq} - equation number

{pstd}
{cmd:rcsgen_beta}({it:x},{it:knots},{it:beta},{it:rmatrix}) Restricted cubic splines basis functions  multiplied by beta matrix.

{phang2}
{it:x} - orginal variable

{phang2}
{it:knots} - knots 

{phang2}
{it:beta} - beta matrix
 
{phang2}
{it:rmatrix} - rmatrix for orthogonalization. Use {cmd:jnp.ones((1,1))} if not orthogonalized.

{pstd}
{cmd:rcsgen}({it:x},{it:knots},{it:rmatrix}) Restricted cubic splines basis functions.

{phang2}
{it:x} - orginal variable

{phang2}
{it:knots} - knots 

{phang2}
{it:rmatrix} - rmatrix for orthogonalization. Use {cmd:jnp.ones((1,1))} if not orthogonalized.

{phang2}
Use {cmd:vrcsgen} for a vectorized version of rcsgen.

{pstd}
{cmd:drcsgen}({it:x},{it:knots},{it:rmatrix}) 1st derivatove of restricted cubic splines basis functions.

{phang2}
{it:x} - orginal variable

{phang2}
{it:knots} - knots 

{phang2}
{it:rmatrix} - rmatrix for orthogonalization. Use {cmd:jnp.ones((1,1))} if not orthogonalized.

{phang2}
Use {cmd:vdrcsgen} for a vectorized version of drcsgen.

{pstd}
{cmd:sumoverid}({it:id},{it:x},{it:Nid}) - sum X over id

{phang2}
{it:id} - id indicator

{phang2}
{it:x} - variables to be summed

{phang2}
{it:Nid} - Number of unique individuals

{pstd}
{cmd:vecquad_gl}({it:fn},{it:a},{it:b},{it:Nnodes},{it:arglist}) Gauss-Legendre quadrature 

{phang2}
{it:fn} - function to be integrated

{phang2}
{it:a} - lower limit of integral

{phang2}
{it:b} - upper limit of integral

{phang2}
{it:Nnodes} - Number of nodes

{phang2}
{it:arglist} - List of additional arguments for function {it:fn}

{pstd}
{cmd:vecquad_gh}({it:fn},{it:Nnodes},{it:arglist}) Gauss-Hermite quadrature 

{phang2}
{it:fn} - function to be integrated

{phang2}
{it:Nnodes} - Number of nodes

{phang2}
{it:arglist} - List of additional arguments for function {it:fn}

{pstd}
{cmd:weibsurv}({it:t},{it:lam},{it:gam}) - Weibull survival function.

{phang2}
{it:t} - time

{phang2}
{it:lam} - lambda

{phang2}
{it:gam} - gamma

{pstd}
{cmd:weibdens}({it:t},{it:lam},{it:gam}) - Weibull density function.

{phang2}
{it:t} - time

{phang2}
{it:lam} - lambda

{phang2}
{it:gam} - gamma

{pstd}
{cmd:mlvecsum}({it:Z},{it:X},{it:eq}) - equivalent of mlvecsum in Stata

{phang2}
{it:Z} - expression

{phang2}
{it:X} - full list of covariates

{phang2}
{it:eq} - equation number


{pstd}
{cmd:mlmatsum}({it:Z},{it:X},{it:eq}) - equivalent of mlvecsum in Stata

{phang2}
{it:Z} - expression

{phang2}
{it:X} - full list of covariates

{phang2}
{it:eq} - equation number



