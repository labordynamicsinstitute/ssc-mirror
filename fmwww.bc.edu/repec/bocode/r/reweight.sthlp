{smcl}




{phang}
{opth svalues(matrix)} specifies user-provided starting values. Starting values must be put in a Stata 1xK matrix following the same order as the variables in {varlist}. 
The default is a vector with the Lagrange multipliers obtained from the chi-squared distance function.

The first is that the difference between the estimated and the external totals must be lower than the tolerance level. 
The second criterion is that - from one iteration to the other - the percentage variations of the estimated distance between the new and the original weights must be lower than the tolerance level for each observation in the sample.
{phang}
{opth ntries(#)} specifies the maximum number of �tries� when the algorithm doeas not achieve convergence within the maximum number of iterations. 
This option can be useful when the external totals are significantly different from the survey totals. 
In such situations the algorithm automatically restarts with new random starting values up to {opt #} times. The default is {opt ntries(0)}.

The default is {cmd:upbound(3)}. Note that this value must be bigger than 1. 
The default is {cmd:lowbound(0.2)}. Note that this value must be between 0 and 1. 
{opth mlowbound(#)} and {opth mupbound(#)} are relevant options only for the DS distant function when the option {opt ntries(#)} is effective. 
In this case, if the recursion does not achieve convergence the routine starts again with a new set of starting values and of new random bounds.
{opth mlowbound(#)} specifies the maximum deviation from the highest value of the lower bound and {opt mupbound(#)} specifies the maximum deviation from the lowest value of the upper bound. 
As an example, if {opth mlowbound(#)} is set to 0.5 than the new random value for the lower bound will be drawn from a uniform distribution in the range 0.5-1 
and if {opt mupbound(#)} is set to 5 than the new random value for the upper bound will be drawn from a uniform distribution in the range 1-5. The default is 0.1 and 6 respectively. 


{cmd}
. use http://fmwww.bc.edu/RePEc/bocode/r/reweight, clear
. list

{cmd}
{cmd}
reweight x1 x2 x3 x4, sw(weight) nw(wa) tot(t) df(a)
reweight x1 x2 x3 x4, sw(weight) nw(wb) tot(t) df(b)
reweight x1 x2 x3 x4, sw(weight) nw(wc) tot(t) df(c)
list w*
3	2.753   2.674   2.654   2.697   2.706 
3	2.109   2.228   2.260   2.193   2.178 
5	5.945   5.998   6.012   5.982   5.976 
4	4.005   3.944   3.926   3.963   3.974 
2	2.484   2.514   2.521   2.505   2.501 
5	4.589   4.456   4.423   4.495   4.510 
5	5.752   5.729   5.717   5.739   5.747 
4	4.005   3.944   3.926   3.963   3.974 
3	2.109   2.228   2.260   2.193   2.178 
3	3.120   3.086   3.074   3.098   3.106 
5	5.945   5.998   6.012   5.982   5.976 
4	3.985   3.814   3.762   3.870   3.897 
4	5.019   5.108   5.136   5.080   5.065 
3	3.490   3.490   3.487   3.491   3.494 
5	4.678   4.665   4.666   4.667   4.665 
3	2.345   2.370   2.380   2.360   2.355 
4	5.070   5.191   5.232   5.150   5.128 
5	4.614   4.603   4.604   4.603   4.600 
4	4.967   5.028   5.043   5.010   5.001 
3	2.109   2.228   2.260   2.193   2.178{txt}


{phang} Pacifico 2010. {it: reweight: A Stata module to reweight survey data to external totals}, CAPPaper N.79.

