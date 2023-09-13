{smcl}
{* 2021feb11}
{hline}
help for {hi:solve}
{hline}

{title:Find a solution to an equation of the form F(x) = y.}

{title:Syntax}

{p 8 10 2}
{cmd:solve }{it:retname} 
{cmd:=}{it:{help exp}}
{cmd:,}
{opt prog:ram(progname)}
{opt argname(argname)}
{opt arg_low(#)}
{opt arg_high(#)}
{opt tol:erance(#)}
[
{opt maxiter(#)}
{opt hole1(#)}
{opt hole2(#)}
{opt hole3(#)}
{opt hole4(#)}
{opt nudgeval(#)}
{opt other_prog_options(options_to_prog)}
{opt ver:bose}
]

{synoptset 20 tabbed}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt prog:ram(progname)}}Specify the name of a program that implements the function of interest.
This is required.{p_end}
{synopt:{opt argname(argname)}}Specify the name of the targeted argument for {it:progname};
it is also used as the name of the returned result from {cmd:solve}. This is required.{p_end}
{synopt:{opt arg_low(#)}}One bound of the search interval. This is required.{p_end}
{synopt:{opt arg_high(#)}}The other bound of the search interval. This is required.{p_end}
{synopt:{opt tol:erance(#)}}The maximal acceptable difference between the produced value and {it:exp}.
This is required.{p_end}
{synopt:{opt maxiter(#)}}The maximal number of iterations allowed; default=60.{p_end}
{synopt:{opt hole1(#)} etc.}Specify an argument for which the function has a "hole" (explained below).{p_end}
{synopt:{opt nudgeval(#)}}The amount by which an argument should be incremented to avoid a hole; default=0.00001.{p_end}
{synopt:{opt other_prog_options(options_to_prog)}}Other options to {it:progname}.{p_end}
{synopt:{opt ver:bose}}Display the sequence of intermediary results.{p_end}

{title:Preliminary Remarks}

{p 4 4 2}
Suppose F is a real-valued function of one real variable. Let y be a fixed value.
The goal is to find an x such that {bind:F(x) = y}.

{p 4 4 2}
As a practical matter, the goal is to find x such that F(x) is within {it:tolerance} of y.
Also, it would be desirable for the solution to be unique, but let's put that aside for a while.

{p 4 4 2}
In the syntax,{p_end}
{p 8 8 2}
{it:exp} corresponds to y;{p_end}
{p 8 8 2}
{it:argname} corresponds to x.{p_end}
{p 8 8 2}
{it:progname} corresponds to F;{p_end}
{p 8 8 2}
{it:retname} corresponds to F(x);{p_end}

{p 4 4 2}
It is necessary to create, or you may already have, a {help program} that implements the function. 
The name of the program is specified in {opt prog:ram(progname)}.

{p 4 4 2}
{it:progname} must...{p_end}
{p 8 8 2}be declared as {cmd:rclass};{p_end}
{p 8 10 2}include a {help syntax} command, with real-typed option named {it:argname}
to serve as the argument of interest
(see optional_real_value in {help syntax});{p_end}
{p 8 8 2}{help return} its resulting value in {it:retname}, preferably as a scalar.{p_end}

{p 4 4 2}
Thus, the program {it:progname} must be established in advance of calling {cmd:solve}.
Its "input" is {it:argname}, and its "output" is {it:retname}. You inform
{cmd:solve} of these names via the {it:argname} option and {it:retname} feature.

{p 4 4 2}
It is possible for {it:progname} and {it:retname} to be the same. You may find this
convenient {c -} or confusing.

{p 4 4 2}
The returned value is best produced as a scalar. Thus in {it:progname}, there should be
the command{p_end}
{p 8 8 2} {cmd:return scalar} {it:retname} {cmd:=} {it:some_expression}

{p 4 4 2}
({cmd:return macro} is a possibility, but you may lose precision.) 

{p 4 4 2}
You also need to specify a targeted interval
in which to search for the solution; this interval is bounded by
{opt arg_low(#)} and {opt arg_high(#)}. Usually, it is necessary that F({it:arg_low}) and
F({it:arg_high}) occur on opposite sides of {it:exp}. That is, they straddle {it:exp}.

{p 4 4 2}
If {it:progname} requires that you specify other options in addition to
{it:argname}, place them in the {cmd:other_prog_options} option. Thus, you will
specify options inside an option specification. See the examples.


{title:Examples}

{p 4 8 2}{cmd:. prog def square, rclass}{p_end}
{p 4 8 2}{cmd:. syntax, x(real)}{p_end}
{p 4 8 2}{cmd:. return scalar sq = `x' * `x'}{p_end}
{p 4 8 2}{cmd:. end}{p_end}

{p 4 8 2}{cmd:. solve sq= 2, prog(square) argname(x) arg_low(0) arg_high(3) tol(.0001)}{p_end}
{p 4 4 2}[output omitted]{p_end}
{p 4 4 2}solve result: x = 1.4142151{p_end}

{p 4 8 2}{cmd:. prog def raise, rclass}{p_end}
{p 4 8 2}{cmd:. syntax, x(real) p(real)}{p_end}
{p 4 8 2}{cmd:. return scalar r = `x' ^`p'}{p_end}
{p 4 8 2}{cmd:. end}{p_end}

{p 4 8 2}{cmd:. solve r = 2, prog(raise)  argname(x) arg_low(0) arg_high(3) tol(.0001) other_prog_options(p(2))}{p_end}
{p 4 4 2}[output omitted]{p_end}
{p 4 4 2}solve result: x = 1.4142151{p_end}

{p 4 8 2}{cmd:. solve r = 2, prog(raise)  argname(x) arg_low(0) arg_high(3) tol(.0001) other_prog_options(p(3))}{p_end}
{p 4 4 2}[output omitted]{p_end}
{p 4 4 2}solve result: x = 1.259903{p_end}

{p 4 8 2}{cmd:. ret list x}{p_end}
{p 4 4 2}scalar r(x)  =  1.259902954101563{p_end}

{p 4 4 2}Of course, there are more effective ways to obtain a square or cube root, but this
demonstrates the use of {cmd:solve}. Note that the prior result is not particularly
precise. We can redo it to greater precision:

{p 4 8 2}{cmd:. solve r = 2, prog(raise)  argname(x) arg_low(0) arg_high(3) tol(.00000001) other_prog_options(p(3))}{p_end}
{p 4 4 2}[output omitted]{p_end}
{p 4 4 2}solve result: x = 1.259921{p_end}

{p 4 8 2}{cmd:. disp  2^(1/3)}{p_end}
{p 4 4 2}1.259921{p_end}

{p 4 4 2}Following is the original usage that motivated the creation of {cmd:solve}.
The program calc_vsl is not shown, as it is lengthy. but suffice it to say that it has
many options in its syntax, including {cmd:sigma}.
It does some of its work in data, and calls other programs.
The {cmd:vsl} option refers to a variable name; the returned value is also named
{cmd:vsl} (it is the sum of the vsl variable).

{p 4 8 2}{cmd:. #delimit ;}{p_end}
{p 4 8 2}{cmd:. solve vsl = 2757032.2, prog(calc_vsl) argname(sigma)}{p_end}
{p 8 8 2}{cmd:arg_low(.5) arg_high(6.5)}{p_end}
{p 8 8 2}{cmd:tolerance(1e-8) maxiter(150)}{p_end}
{p 8 8 2}{cmd:hole1(1)}{p_end}
{p 8 8 2}{cmd:other_prog_options(}{p_end}
{p 12 8 2}{cmd:age(age) z0_z_ratio(z0_z_ratio) y_f_hat(y_f_hat) c_f_hat(c_f_hat)}{p_end}
{p 12 8 2}{cmd:discount_factor(`discount_factor')}{p_end}
{p 12 8 2}{cmd:ref_age_index(`ref_age_index') max_age_index(`max_age_index')}{p_end}
{p 12 8 2}{cmd:survprob(`survprob_modified') phi(`phi') integrandA(`integrandA')}{p_end}
{p 12 8 2}{cmd:vsl(`vsl')}{p_end}
{p 8 8 2}{cmd:)}{p_end}
{p 8 8 2}{cmd:;}{p_end}
{p 4 4 2}[output omitted]{p_end}
{p 4 4 2}solve result: sigma = 1.3616268

{p 4 4 2}Note the presence of the {cmd:hole1(1)} option. calc_vsl has a hole at
sigma=1; it yields a missing value. (In an earlier version, it yielded 0, which was
out-of-line with its neighboring values.) See below for an explanation of holes.

{title:Additional Remarks}
 
{p 4 4 2}In a more general case, F may have a multitude of arguments, that is, it has the form{p_end}
{p 10 10 2}F(x, {it:other_arguments}){p_end}
{p 4 4 2}
but your interest is focused on only x; you are concerned only with how F behaves as x varies,
while {it:other_arguments} are held at some particular fixed value (or tuple of values).
Thus, F can be viewed as a function of x alone, while
{it:other_arguments} are considered as parameters that adjust the behavior of F.

{p 4 4 2}
This would correspond to {it:progname} having additional options ({it:options_to_prog}), though there are
other avenues for influencing the result, as will be discussed shortly.

{p 4 4 2}
Similarly, {it:progname} may return other values in addition to {it:retname}, but
for the present purpose, you would be interested in only {it:retname}.

{p 4 4 2}
As noted, there are many potential factors that could influence the resulting value of
{it:retname}. These include...{p_end}
{p 10 10 2}{it:argname},{p_end}
{p 10 10 2}{it:options_to_prog} (if {it:progname} has such options),{p_end}
{p 10 10 2}data,{p_end}
{p 10 10 2}scalars,{p_end}
{p 10 10 2}global macros,{p_end}
{p 10 10 2}system parameters (see {help creturn}),{p_end}
{p 10 10 2}{help char}acteristics and {help notes},{p_end}
{p 10 10 2}any similar influencing factors to programs that are called by {it:progname}.

{p 4 4 2}
{cmd:solve} will issue multiple invocations of {it:progname} while varying {it:argname}
as it seeks a solution.
It should be the case (it is the user's responsibility) that all other influencing factors
(other than {it:argname}) remain constant as {cmd:solve} makes these invocations of {it:progname}.
This way, for the duration of running {cmd:solve}, {it:progname} can be viewed as a
function of {it:argname} only; it should yield consistent results in repeat call with the same
value of {it:argname} (and {it:options_to_prog} if applicable).

{p 4 4 2}
({it:options_to_prog} may contain names of variables or other named entities.
So, while its textual value is fixed for the duration of running {cmd:solve}, the
values in the referent entities could possibly vary; it is important to not have such
variation.)

{p 4 4 2}
{it:progname} may alter data or other entities in the process of calculating its result,
but the data elements that it relies on should not be altered. Thus, it might
{help generate} or {help replace} some data variables in the process of calculating a result,
but such variables should not be referenced as a source of information in the calculation
of {it:retname}. For example, say that a, b, and c are variables in the data. You then
may generate d as some calculation that depends on a, b, c, and {it:argname}, followed by
summing d, and returning the value of that sum in {it:retname}. Note that, while you
have made changes to the data, you have not changed a, b, or c; the changes are
only in d, which has no effect on a subsequent call. (You might {help drop} d, or
it may have been a {help tempvar}.)

{p 4 4 2}
Usually, {it:progname} should be such that it does not alter the set of observations;
it should not {help drop} or create new observations, or {help collapse} the data.
The exception would be if it reloads the (same) data in each invocation.

{p 4 4 2}
{it:exp} is evaluated once, prior to seeking a solution. Thus, it is not a moving target.
Typically it would be a constant, but generally may be an expression. As such, it
would be evaluated as a scalar quantity, meaning that any variable references that
are not specifically indexed default to index 1.

{p 4 4 2}
{opt maxiter(#)}} specifies the maximum number of iterations that will be performed.
It is not the same as the maxiter system parameter {cmd:c(maxiter)}, which is used in
maximum likelihood estimation procedures. (See {help creturn} and {help maximize}.)

{p 4 4 2}Note that the result is not necessarily exact;
generally it is "close enough", where {it:tolerance} sets the standard of what
that means. You may specify a tolerance of 0, signifying that you desire an exact
solution, but you are likely to not achieve such a solution in general.

{p 4 4 2}The result is returned in {cmd:r(}{it:argname}{cmd:)}. Thus, {it:argname}
serves two purposes: the name of the argument to {it:progname}, and the returned
result from {cmd:solve}.

{p 4 4 2}
It is important that the function be continuous within the specified range (except for possible holes, see below).
It is also somewhat important that it be monotonic. If it is not continuous,
then {cmd:solve} may fail to yield a result, even if a solution does exist.
If is is not monotonic, then {cmd:solve} may find one of possibly many solutions.

{p 4 4 2}
{cmd:solve} will attempt to detect and issue warnings about non-monotonicity.
However, it cannot detect all instances of non-monotonicity.

{p 4 4 2}
The function may have "holes". A hole is an argument that yields a value that is
out-of-line with its neighbors, or yields a missing value. Thus, a hole is a point
of benign discontinuity. The function is "almost continuous", in that its
right and left limits are equal, but not equal to its value at that argument.
A classic example is F(x) = x^2/x, which has a hole at x=0 (in Stata terms, it yields missing),
but otherwise, is the same as F(x) = x, which is continuous.

{p 4 4 2}
Another possible type of hole is one where the function
has a non-missing value that jumps out of line at a particular point. This may seem hypothetical,
but it happened in the original application that motivated the creation of {cmd:solve}, and
thus motivated the inclusion of the {opt hole1()} (etc.) options.

{p 4 4 2}
If one of the candidate arguments should land on a designated hole, it will be
altered a slight bit to avoid the hole; it is moved out of the way by 
incrementing it by {it:nudgeval}.

{p 4 4 2}
Note that, if the value at a hole is non-missing and equals
{it:exp}, then the given argument is a solution, but will not be detected.

{p 4 4 2}
It is the user's responsibility to determine the location of holes, if they exist.

{p 4 4 2}
The syntax allows up to four holes to be specified. Contact the author if more are needed.

{p 4 4 2}
Of course, a jump discontinuity may prevent a solution from being found, even if
one exists.

{p 4 4 2}
{opt arg_low(#)} and {opt arg_high(#)} are the bounds of the search interval.
They may be regarded as initial estimates for
the solution, where the solution is believed to lie between these two arguments.
It is usually necessary that a solution exists between these arguments; the exeption
would be if one of them qualifies as a solution.

{p 4 4 2}
{opt arg_low(#)} and {opt arg_high(#)} may occur in either order; it is not necessary that
{opt arg_low(#)} < {opt arg_high(#)}.

{p 4 4 2}
Note that the resulting soultion may be sensitive to the choice of these arguments, as
well as to {it:tolerance}.

{p 4 4 2}
{cmd:solve} does not allow for {it:progname} to have varlist, namelist, anything, if, in, using,
=exp, or weights. Contact the author if these limitations present a problem.


{title:Methodology}

{p 4 4 2}
{cmd:solve} uses the bisection method, which is just one of several established methods
for numerically solving such equations.
It starts by evaluating {it:progname} at two arguments, call them A and B,
which may be regarded as preliminary guesses to the solution.
Initially, A and B are {it:arg_low} and {it:arg_high}.

{p 4 4 2}Let...{p_end}
{p 8 8 2}valA be the result of evaluating {it:progname} at {it:argname}=A;{p_end}
{p 8 8 2}valB be the result of evaluating {it:progname} at {it:argname}=B.{p_end}

{p 4 4 2}
If valA is within {it:tolerance} of {it:exp}, then A is the solution;{p_end}
{p 4 4 2}
If valB is within {it:tolerance} of {it:exp}, then B is the solution.{p_end}

{p 4 4 2}
If both valA and valB are within {it:tolerance} of {it:exp}, then choose the one
that is closer to {it:exp}, giving preference to valA, and a solution of A, if they are equally close.

{p 4 4 2}Otherwise, bisect the interval, evaluate at the midpoint, and turn your
attention to the half-interval that straddles {it:exp}. Repeat the process on this
new, smaller interval; repeat until a solution is found.

{title:Also See}

{p 4 4 2}
Bisection is regarded as the least sophisticated among several methods for solving
such equations. Other methods include{p_end}
{p 8 8 2}Newton-Raphson method;{p_end}
{p 8 8 2}Brents's method.{p_end}

{p 4 4 2}See the Wikipedia articles on those methods.

{p 4 4 2}Also, see {cmd:mm_finvert} in the Moremata module, available on {help ssc}.
This is intended for functions defined in {help Mata}. Type "ssc desc moremata".

{p 4 4 2}Thus, {cmd:mm_finvert} is useful for functions defined in Mata, while 
{cmd:solve} is useful for functions defined in Stata. But it is presumably possible to
use mm_finvert for Stata functions, or solve for Mata functions, though this may
involve some convoluted programming techniques.

{title:Author}
{p 4 4 2}
David Kantor; email {browse "mailto:kantor.d@att.net":kantor.d@att.net}
