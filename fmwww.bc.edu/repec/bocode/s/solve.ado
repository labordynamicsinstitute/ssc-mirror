/*
c:\adop\solve.ado
DK, 2021feb08.

Based on parts of [a recent Life-Science project]\statawork\estimate_sigma.do, which
is essentially the same as the same-named file in c:\life_science_1\dkwork5, plus
a minor fix which had no effect in that situation.

BUT we are generalizing the solving algorithm. Thus, moving forward, anything resembling
that estimate_sigma process should make use of this. That is, if estimate_sigma
were to be written today, large parts of it would be replaced by a call to -solve-.

This may not be exactly the same as what was found in estimate_sigma.do.
As noted, there was a minor fix done (see notes therein).
And we have eliminated the swapping; that is obviated by the use of `relop'.
We are loosening the monotonicity requirement; instead we issue a warning.

2021feb09: develop & debug.
2021feb10: Annotate. Convert debug -disp- commands to operate under a -debug- option.
(Later removed; the verbose option takes over.)
Implement a maxiter_default of 60; previously used `=c(maxiter)', which is 16000,
and which is absurdly large for the present purpose.

Note that this option has the same name as a system setting (obtainable from c(maxiter)).
They are not the same thing, and I hope that is not a source of confusion.

Changing the syntax to use the retname=exp form.

2021feb11 ?

2021apr13: edited comments only.
2022apr08: tolerance may be abbreviated tol.
2022apr28: targetval is a tempname that refers to a scalar, rather than a named
scalar that lingers, or could be existing one that would get overwritten.
The same was done for arga, argb, argm, vala, valb, valm -- epsilon_a, etc.

Also, changed the prog option to PROGram.
Also, we assure that `tolerance' >0.

2022may02: An idea: in check_arg, in place of hole1 etc., give it one "holes" option --
(numlist).
PS: we can do the same for the syntax of solve, but allow the old hole1 (etc)
syntax as well, for backward-compatibility.

PPS: DON'T do that! I had thought of it already, previously. It has a problem in
that you lose precision! Option  umlist has less precision than real!

2022may03: Put in a "verbose" option; make most of the textual output go out only
under this option.


*/


prog def solve, rclass
/*
Say that the program implements a function; call it (the function) F.
We have target value y.
We want to find x such that F(x) = y

-solve- aims to close-in on a solution to that equation -- by bisecting the interval
that supposedly surrounds the solution.

You need to implement F as an rclass program. It must return its yield as a scalar
value in r(); in particular, r(`retname'). (See the syntax.)
(I guess a macro is okay, but you may lose precision.)

We pay attention to only one returned scalar value.

We solve only ONE argument. The program may have multiple arguments (presumably as options,
but that's up to the user to decide), but we solve for only ONE argument.

It shall take its argument-of-interest in a real-valued option.

Syntax is, symbolically...
	solve retname = exp, prog(progname) argname(name_of_arg)

progname is the name of the program that does the work of calculating a value.
exp is the targeted output value -- the y in the F(x) = y equation.
retname is the name of the returned value from progname. That is, progname does
	return scalar retname = some_expression

name_of_arg represents the name of the option to progname that passes the input
value.

Example:

solve vsl = `vsl_target', prog(calc_vsl) argname(sigma)
	arg_low(`sigma_low') arg_high(`sigma_high')
	tolerance(`vsl_precision') ...

Thus, calc_vsl has, in its syntax,
	, sigma(real)

among other options. It also does this near the end:
	return scalar vsl = `vsl'[`max_age_index']

(What's to the right of the = is internal to calc_vsl; it's just an expression.)

Generally, the function program (progname) may have other options; they are to be passed
through from -solve- into `progname' via the "other_prog_options" option.

~~As of 2021feb09, -solve- does not accommodate programs having a `varlist', `namelist',
or `anything', `=exp', `using', `if', `in' or weights. We can later put those in
if that becomes desirable.

*/
version 14

local maxiter_default "60"


#delimit ;
syntax name(name=retname id="return value name") =exp
	, PROGram(name) argname(name)
	arg_low(real) arg_high(real)
	TOLerance(real) /* a small positive number */
	[other_prog_options(string asis)]
	[maxiter(integer `maxiter_default')
	hole1(passthru) hole2(passthru) hole3(passthru) hole4(passthru) nudgeval(real .00001)
	VERbose /* debug */ ]
	;
#delimit cr


/*
arg_low and arg_high are two guesses as to the value of `argname' such that
the resulting values straddle `exp' (later, `targetval').

The method is to close in on a solution by bisecting the argument interval, seeking
the half-interval that yields values that straddle the target.

We must assume that `program' is reasonably smooth and has only one solution in that
interval. If there are multiple solutions, this may fail, or it may pick one of the
solutions (**), without any indication that it was not unique.

It helps if `program' is monotonic in that interval.

This makes use of some scalars. As of 2022apr28, they were coded as tempnames.

`argname' is an option to `program'. We assume it is a real() option, but we may
~~later~~ enable it to (optionally) be a scalar name. This may enable greater
precision in the input values.


`retname': the name in which `program' returns its value.
-solve-will also return a value, but that's a different name; actually the return
name will be `argname' -- reused for a different purpose.
That is, `argname' serves two purposes:
	the input argument name to `program';
	the return name for -solve-.

other_prog_options pertains to `program' -- the "function" that is to be called.

**: deterministic, but without any real logic to the choice.

hole1, hole2, etc.: a set of values for which `program' has spooky behavior:
discontinuous or missing. BUT we expect that the left and right limits are the same.
E.g., the expression x^3/x is spooky at 0, but has the same right and left limit.
That is, it looks just like x^2, but has a hole at x=0.

Another possibility is a nonmissing value that is a singular discontinuity,
where an otherwise continmuous function abruptly jumps out of its trajectory,
but where the left and right limits are the same. Imagine that in the expression
x^3/x, we substitute a result of 21 at x=0; we filled in the hole, but with a
singular discontinuity.

calc_vsl, in an earlier form, was like that at sigma=1, yielding 0. (Later, it was
altered to yield missing. The behavior of yielding 0 was partly due to some Stata
idiosyncracies.)

Such singular discontinuities -- where missing or not -- we shall call holes.
It is up to the user to know about them in advance (or to learn of their existence
while working with the function)! You specify them in the hole1 (etc.) options.

If an argument lands on a hole, it will be "nudged" over by a small amount, `nudgeval'.
Thus, we step around the hole.

Note that if there is any jump discontinuity or wild behavior, that cannot be handled,
and may cause a failure.

My first inclination was to set up a holes option as a numlist. There is a problem with
precision here. You get more precision with a real option. The disadvantage is that
you have a small limited number of values: `hole1', `hole2'.

I am setting them up as passthru; then they will be passed on to -check_arg-,
which expects them as real.

I have written to Stata Tech Support about this -- on 2021feb11.


IMPORTANT: This works by closing in on the targetted value. Generally, that is
not the right way to do such an operation. The right way is to observe the "input"
to see when it ceases to change -- or it stays (or cycles) within epsilon of
some value, where epsilon is very small (such as the limit of computational precision).
This is a more challenging programming task.

Furthermore, if tolerance is very small, then the present algorithm
may possibly not converge; will run forever. But if we keep it reasonlble,
then we should be okay.

*/

if mi(`arg_low') {
	disp as err "arg_low must not be missing"
	exit 198
}
if mi(`arg_high') {
	disp as err "arg_high must not be missing"
	exit 198
}
if mi(`tolerance') {
	disp as err "tolerance must not be missing"
	exit 198
}

/* -- option optional_real_value allows missing values. This may be a bug in Stata (14.2) ??
Sent email to Stata Tech Support, 2022apr28.
*/

if `tolerance' <0 {
	disp as err "tolerance must not be negative"
	/* 0 is allowed; it signifies an exact match. */
	exit 198
}

tempname targetval
scalar `targetval' `exp'

tempname arga argb argm vala valb valm solve_val epsilon_a epsilon_b epsilon_m
scalar `arga' = `arg_low'
scalar `argb' = `arg_high'

if "`verbose'" ~= "" {
	disp "iter" _col(12) "arga" _col(24) "vala" _col(36) "argb" _col(48) "valb"
	disp _dup(60) "-"
}

check_arg `arga', `hole1' `hole2' `hole3' `hole4' nudgeval(`nudgeval')
`program', `argname'(`=scalar(`arga')') `other_prog_options'
scalar `vala' = r(`retname')
check_retval `vala', progname(`program')
scalar `epsilon_a' = abs(scalar(`vala') - scalar(`targetval'))

check_arg `argb', `hole1' `hole2' `hole3' `hole4' nudgeval(`nudgeval')
`program', `argname'(`=scalar(`argb')') `other_prog_options'
scalar `valb' = r(`retname')
check_retval `valb', progname(`program')
scalar `epsilon_b' = abs(scalar(`valb') - scalar(`targetval'))




local iteration 0
while 1 {
	if `iteration ' > `maxiter' {
		disp as err "-solve- exceeded allowable iterations"
		exit 430
	}
	local ++iteration
	if "`verbose'" ~= "" {
		local astyle "text"
		local bstyle "text"
	
		if "`mchoice'" == "a" {
			local astyle "inp"
		}
		else if "`mchoice'" == "b" {
			local bstyle "inp"
		}
		#delimit ;
		disp as text `iteration'
		_col(12) as `astyle' scalar(`arga')
		_col(24) as text scalar(`vala')
		_col(36) as `bstyle' scalar(`argb')
		_col(48) as text scalar(`valb')
		;
		#delimit cr
	}



	if scalar(`epsilon_a') <= scalar(`epsilon_b') {
		if scalar(`epsilon_a') <= `tolerance' {
			scalar `solve_val' = scalar(`arga')
			continue, break
		}
	}
	else /* epsilon_b is smaller. See note 2. */ {
		if scalar(`epsilon_b') <= `tolerance' {
			scalar `solve_val' = scalar(`argb')
			continue, break
		}
	}

	if scalar(`vala') <= scalar(`valb') {
		local relop "<="
	}
	else {
		local relop ">="
	}

	if ~(scalar(`vala') `relop' scalar(`targetval') & scalar(`targetval') `relop' scalar(`valb')) {
		disp as err "values fail to straddle the target value"
		exit 459
	}

	/*~~~ We may need or prefer a constraint on precision */
	scalar `argm' = (scalar(`arga') + scalar(`argb')) /2 // midway between a and b

	check_arg `argm', `hole1' `hole2' `hole3' `hole4' nudgeval(`nudgeval')
	`program', `argname'(`=scalar(`argm')') `other_prog_options'
	scalar `valm' = r(`retname')
	check_retval `valm', progname(`program')
	scalar `epsilon_m' = abs(scalar(`valm') - scalar(`targetval'))



	if ~(scalar(`vala') `relop' scalar(`valm') & scalar(`valm') `relop' scalar(`valb')) {
		disp as err "warning: `program' fails monotonicity condition"
		local non_monotonic "y"
	}
	if scalar(`valm') `relop' scalar(`targetval') {
		/* valm is on the same side of the target as vala. Move m into a. */
		scalar `arga' = scalar(`argm')
		scalar `vala' = scalar(`valm')
		scalar `epsilon_a' = scalar(`epsilon_m')
		local mchoice "a"
	}
	else {
		/* valm is on the same side of the target as valb. Move m into b. */
		scalar `argb' = scalar(`argm')
		scalar `valb' = scalar(`valm')
		scalar `epsilon_b' = scalar(`epsilon_m')
		local mchoice "b"
	}
}

if "`non_monotonic'" ~= "" {
	disp as err "`program' has been detected as non-monotonic in the given range."
	disp as err "This may imply multiple solutions, though only one solution is derived."
	/* There is no guarantee that non-monotonicity will be detected. */
}

disp as text "iterations: " `iteration'
disp "solve result: `argname' = " scalar(`solve_val')

return scalar `argname' = scalar(`solve_val')
end /* solve */

/*
Note 2: (There was a Note 1; became moot on 2022may04.)

If epsilon_a==epsilon_b (highly unlikely), then this process favors arga,
whereas, either one of them is an equally-close solution.

Prior to 2022apr28, it favored argb. The change to favoring arga is the result of comparing
	scalar(epsilon_a) <= scalar(epsilon_b);
previously, it was
	scalar(epsilon_a) < scalar(epsilon_b).

*/



prog def check_retval
syntax name, progname(name)
/* `name' is taken as a scalar name. */
if mi(scalar(`namelist')) {
	disp as err "`progname' failed to return a value"
	disp as txt "This could be due to,..."
	disp "  `progname' yielded a missing value,"
	disp "  `progname' was not declared rclass,"
	disp as res "  solve" as text " was not given the correct retname."
	exit 459
}
end /* check_retval */


prog def check_arg
syntax name, [hole1(real `=c(mindouble)') hole2(real `=c(mindouble)') ///
	hole3(real `=c(mindouble)') hole4(real`=c(mindouble)')] nudgeval(real)
/* `name' is taken as a scalar name.
We potentially alter it; we rely on it being a global quantity.
One nudgeval serves for all holes.

We use `=c(mindouble)' as he default hole value, but it signifies "not specified".
This precludes the use of that value, but it shouldn't bother anyone.
*/

local max_holes 4
forvalues jj = 1/`max_holes' {
	if `hole`jj'' ~= c(mindouble) & scalar(`namelist') == `hole`jj'' {
		disp "Nudge operation; `namelist', value `=scalar(`namelist')', being incremented by `nudgeval'."
		scalar `namelist' = scalar(`namelist') + `nudgeval'
		continue, break /* Once is enough. */
	}
}
end /* check_arg */

