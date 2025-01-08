{smcl}
{* *! version 2.0.0 2024-07-07}{...}
{vieweralsosee "[R] help" "help drawnorm "}{...}
{viewerjumpto "Syntax" "ovbd##syntax"}{...}
{viewerjumpto "Description" "ovbd##description"}{...}
{viewerjumpto "Options" "ovbd##options"}{...}
{viewerjumpto "Remarks" "ovbd##remarks"}{...}
{viewerjumpto "Examples" "ovbd##examples"}{...}
{title:Title}

{phang}
{bf:ovbd} {hline 2} Generate correlated random binomial variables{p_end}
{p 3}
{bf:ovbdc} {hline 2} Called by {cmd:ovbd}; may be called directly{p_end}
{p 3}
{bf:ovbdr} {hline 2} Called by {cmd:ovbd}; may be called directly{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ovbd }[{help varlist}]{cmd:,} 
{cmdab:m:eans(}{it:name}{cmd:)} 
{cmd:corr(}{it:name}{cmd:)}
[{it:options}]

{p 8 17 2}
{cmd:ovbdc ,} 
{cmdab:m:eans(}{it:name}{cmd:)} 
{cmd:corr(}{it:name}{cmd:)}
[{it:options}]

{p 8 17 2}
{cmd:ovbdr }{help newvarlist}{cmd:,} 
{cmd:z(}{it:name}{cmd:)} 
{cmd:a(}{it:name}{cmd:)}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt m:eans(name)}}Stata matrix containing vector of proportions{p_end}
{synopt:{opt corr(name)}}Stata matrix containing correlation structure{p_end}
{synopt:{opt n(#)}}generate # observations; default is current number*{p_end}
{synopt:{opt st:ub(string)}}stub for new variable names*{p_end}
{synopt:{opt clear}}replace the current dataset*{p_end}

{syntab :Options}
{synopt:{opt v:erbose}}allows notification when matrix is not positive definite{p_end}
{synopt :{opt seed(#)}}seed for random-number generator*{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations for root finder{p_end}
{synopt:{opt tol:erance(#)}}tolerance for root finder{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
Options marked with an asterisk are available only for {cmd:ovbd}.{p_end}
{p 4 6 2}
{cmdab:m:eans()} and {cmd:corr()} are not optional for {cmd:ovbd} or {cmd:ovbdc}.{p_end}
{p 4 6 2}
{cmd:ovbdr} has no options; {it:newvarlist}, {cmd:z()} and {cmd:a()} are not optional.


{marker description}{...}
{title:Description}

{pstd}
{cmd:ovbd} generates correlated random binomial variables. The 
correlation matrix fed to {cmd:ovbd} may contain negative or positive 
coefficients, allowing for simulation of underdispersion as well as 
overdispersion.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt m:eans(name)} name of a Stata matrix that is a vector of the desired 
proportions in the generated variables. It is not optional.

{phang}
{opt corr(name)} name of a Stata matrix of the desired correlation structure of 
the generated variables. It is not optional.

{phang}
{opt n(#)} specifies the number of observations to be generated.

{phang}
{opt st:ub(string)} stub for new variable names if {it:{help varlist}} is not 
specified.  At least one of {it:{opt stub()}} or {it:{help varlist}} must be 
specified.

{phang}
{opt clear} specifies that the dataset in memory be replaced, even though the
current dataset has not been saved on disk.

{dlgtab:Options}
{phang}
{opt verbose} requests diplay of a message whenever the transformed correlation 
matrix is not positive definite.

{phang}
{opt seed(#)} specifies the initial value of the random-number seed used in 
generating the random binomial variables.  The default is the current 
random-number seed.  Specifying {it:{opt seed()}} is the same as typing 
{cmd:set seed} {it:#} before issuing the {cmd:ovbd} command.

{phang}
{opt iter:ate(#)} perform maximum of # iterations for root finder; default is 
30; this should never need to be changed.

{phang}
{opt tol:erance(#)} tolerance for declaring convergence by the root finder; 
default is 1e-10; this should never need to be changed.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:ovbd} follows the algorithm of Ahn and Chen (1995), and is roughly modeled 
after the implementation described by Gregori, Di Consiglio and Carmeci (1995), 
from whose Fortran-77 subroutine the command's name derives.

{pstd}
{cmd:ovbd} calls {cmd:ovbdc} in order to find the bivariate normal correlation 
coefficients that will give rise to the desired correlations between the 
end-result pairs of binomial variables.  Finding this correlation coefficient 
for each pair where the desired correlation coefficient is not zero is 
accomplished by an iterative root-finding algorithm (Ridders), and will not be 
successful if the root is not bracketed by the parameter space, which in 
practice here is ±[0.001, 0.999]. {cmd:ovbdc} will automatically report all 
pairs (matrix elements) where the root-finding algorithm fails.  This is 
intended to aid the user in determining a more judicious construction of the 
mean vector and correlation matrix to feed to {cmd:ovbd}.

{pstd}
Upon completion, {cmd: ovbdc} returns the transformed correlation matrix and 
transformed means (proportions) vector to {cmd:ovbd}, which then forwards them 
along with the variable list to {cmd:ovbdr} in order to generate the correlated 
binomial variables.  The option to use {help varlist} with {cmd:ovbd} (which 
must be a {help newvarlist} if any variable name in the list already exists in 
the dataset and the {cmd:clear} option is not also specified) allows greater 
flexibility in naming the generated variables, but the use of {cmd:stub()} 
might be more convenient for workaday use.

{pstd}
{cmd:ovbdc} and {cmd:ovbdr} may be directly invoked by the user.  Calling the 
two commands directly will be more efficient in the typical simulation use case 
in that the iterative root finding of each element that is involved in creation 
of the transformed correlation matrix need be undertaken just once by 
{cmd:ovbdc}, and the transformed proportions vector and transformed correlation 
matrix that are returned by it can be fed to {cmd:ovbdr} repeatedly by the 
simulation program.


{marker examples}{...}
{title:Examples}

{pstd}
Generate 250 observations ({cmd:response1}, {cmd:response2});
{cmd:response1} with proportion 0.6, 
{cmd:response2} with proportion 0.4
and correlation 0.5

{phang2}{cmd:. matrix input M = (0.6, 0.4)}{p_end}
{phang2}{cmd:. matrix input C = (1 0.5 \ 0.5 1)}{p_end}
{phang2}{cmd:. ovbd response1 response2, means(M) corr(C)} n(250){p_end}

{pstd}
Equivalently,

{phang2}{cmd:. matrix input M = (0.6, 0.4)}{p_end}
{phang2}{cmd:. matrix input C = (1 0.5 \ 0.5 1)}{p_end}
{phang2}{cmd:. ovbd , means(M) corr(C) stub(response) n(250)}{p_end}

{pstd}
Invoking {cmd:ovbdc} and {cmd:ovbdr} directly

{phang2}{cmd:. matrix input M = (0.6, 0.4)}{p_end}
{phang2}{cmd:. matrix input C = (1 0.5 \ 0.5 1)}{p_end}
{phang2}{cmd:. ovbdc , means(M) corr(C)}{p_end}
{phang2}{cmd:. matrix define Z = r(Z)}{p_end}
{phang2}{cmd:. matrix define A = r(A)}{p_end}
{phang2}{cmd:. drop _all}{p_end}
{phang2}{cmd:. set obs 250}{p_end}
{phang2}{cmd:. ovbdr response1 response2, z(Z) a(A)}{p_end}


{title:Author}

{pstd}
Joseph Coveney
https://www.statalist.org/forums/member/159-joseph-coveney


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ovbd} and {cmd:ovbdc} store the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:r(A)}}upper-triangular Cholesky factor (if positive definite) or 
analogous factor by spectral decomposition (otherwise) of transformed 
orrelation matrix{p_end}
{synopt:{cmd:r(Z)}}transformed means (proportions) vector{p_end}
{p2colreset}{...}

{pstd}Neither {cmd:ovbd} nor {cmd:ovbdc} clears {cmd:r()} and when invoked will 
overwrite only the two matrices above if present.{p_end}


{title:References}

{pstd}
H. Ahn and J. J. Chen, Generation of overdispersed and underdispersed binomial 
variables. {it:Journal of Computational and Graphical Statistics} 
{bf:4}:55{c 150}64, 1995.

{pstd}
D. Gregori, L. Di Consiglio and G. Carmeci, A Fortran77 routine for 
overdispersed binary data generation. Presented at the 
{it:1st Conference of the Biometric Society, Italian Region} June 16 and 17, 
1995.
http://lib.stat.cmu.edu/general/corbin

{pstd}
W. H. Press, S. A. Teukolsky, W. T. Vetterling, B. P. Flannery, {it:Numerical }
{it: Recipes in Fortran 77:  The Art of Scientific Computing.  Second Edition. }
pp. 351–52. Cambridge University Press, 1992.
