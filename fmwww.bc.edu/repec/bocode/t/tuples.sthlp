{smcl}
{* 4april2016}{...}
{hline}
help for {hi:tuples}
{hline}

{title:Selecting tuples from a list} 

{p 8 17 2} 
{cmd:tuples} 
{it: list}
[{cmd:,}
[{cmd:asis} {c |} {cmdab:var:list}] 
{cmdab:di:splay}
{cmd:max(}{it:#}{cmd:)}
{cmd:min(}{it:#}{cmd:)}
{cmdab:nom:ata}
{cmd:cvp}
{cmd:kronecker}
{cmd:{ul on}nos{ul off}ort}
{cmdab:cond:itionals(}{it:string}{cmd:)}
]


{title:Description}

{p 4 4 2}
{cmd:tuples} produces a set of {help macro:local macros}, each containing a list of
the items defining a tuple selected from a given list. By default the
set of macros is complete, other than the tuple containing no
selections. By default the given list is tried as a variable list, but
if it is not a variable list any other kind of list is acceptable,
except that no other kind of expansion takes place.   


{title:Remarks} 

{p 4 4 2} 
Given a list of n items, {cmd:tuples} by default produces 2^n - 1
macros, named {cmd:tuple1} upwards, which are all possible distinct
singletons (each individual item); all possible distinct pairs; and so
forth. Thus given {cmd:frog toad newt}, local macros {cmd:tuple1}
through {cmd:tuple7} contain 

    {cmd:newt}
    {cmd:toad} 
    {cmd:frog} 
    {cmd:toad newt} 
    {cmd:frog newt} 
    {cmd:frog toad} 
    {cmd:frog toad newt} 

{p 4 4 2}Here n = 3, 2^n - 1 = 7 = {cmd:comb(3,1) + comb(3,2) + comb(3,3)}. 
     
{p 4 4 2} 
Note that no tuple is the empty tuple with no selections. Users wishing
to cycle over a set of tuples including the empty tuple can exploit the
fact that the local macro {cmd:tuple0} is undefined, and so empty
(unless the user has previously defined it explicitly), so that
{cmd:tuple0} can invoked with the correct result. 

{p 4 4 2} 
As usual, double quotes may be used to bind. Thus {cmd:"a b c" d e} is a
list of three items, not five. 

{p 4 4 2} 
Remember that the number of possible macros will explode with the number
of items supplied. For example, if 10 items are supplied, there will be
1,023 macros. The number of macros created by {cmd:tuples} is returned
in local macro {cmd:ntuples}. 

{p 4 4 2}
The algorithm used for the {opt nomata} option is naive and will be slow
for above n ~ 10.  {opt cvp} is computationally intensive and is slow 
for above n ~ 13. {opt kronecker} is less efficient than the default 
method and is slow for above n ~ 17.

{p 4 4 2}
Note: As of January 2011, this command is declared to supersede Nicholas
J. Cox's {cmd:selectvars}. 

{title:Options} 

{p 4 8 2}{cmd:asis} specifies that a list should be treated as is, and
thus not {help unab:unabbreviated} as a {help varlist}. 

{p 4 8 2}{cmd:varlist} specifies that the list supplied should be a
{help varlist}, so that it is an error if the list is not in fact a
varlist. 

{p 8 8 2}{cmd:asis} and {cmd:varlist} are incompatible. 

{p 4 8 2}{cmd:display} specifies that tuples should be displayed. 

{p 4 8 2}{cmd:max(}{it:#}{cmd:)} specifies a maximum value for the
number of items in a tuple. 

{p 4 8 2}{cmd:min(}{it:#}{cmd:)} specifies a minimum value for the
number of items in a tuple. 

{p 4 8 2}{cmd:nomata} generates all tuples outside of the {help mata:Mata}
environment and is the only option for Stata versions 8 or 9, issued 
before the introduction of several of the Mata functions used by {cmd:tuples}.

{p 4 8 2}{cmd:cvp} generates all tuples using the {cmd:tuples} version 
3.0-3.1 method based on {help [M-5] cvpermute():cvpermute()} within Mata. 
{cmd:cvp} cannot be combined with {cmd:nomata} or {cmd:kronecker}.

{p 4 8 2}{cmd:kronecker} generates all tuples using the {cmd:tuples} version 
3.2 method based on staggered Kronecker products within Mata. 
{cmd:cvp} cannot be combined with {cmd:nomata} or {cmd:cvp}.

{p 4 8 2}{cmd:nosort} the default tuples generation algorithm produces 
tuples in a different order than past implementations and, to maintain 
consistency in terms of expected tuple order, the tuples are sorted 
prior to being generated as local macros.  {opt nosort} 
overrides the default sorting of macros and speeds execution time of 
{cmd:tuples}, which can be desirable with longer lists when tuple
order is irrelevant.

{p 4 8 2}{cmd:conditionals()} specifies conditional statements to
eliminate possible tuples according to the rule(s) specified.
{cmd:conditionals()} accepts the logicals {cmd:&} for intersections or
"and" statements, {cmd:|} for unions or "or" statements, {cmd:()} for
binding statements and giving statements priority, and {cmd:!} for
complements or "not" statements.  

{p 8 8 2}Other than the foregoing logicals, {cmd:conditionals()} only
accepts positional arguments.  That is, to refer to the first element of
the list, use "1"; to refer to the second element, use "2"; and so 
forth.  Inapplicable positional arguments (e.g., referring to "4" in a list
of size 3) will produce an error.  

{p 8 8 2}Spaces are used to separate conditional statements with
{cmd:conditionals()}.  A single statement must, then, contain no spaces.  

{p 8 8 2}{cmd:conditionals()} cannot be combined with {cmd:nomata}.


{title:Using conditionals()}

{p 4 4 2}{cmd:conditionals()} is useful for eliminating potential tuple
macros with combinations of the elements from the list based on logical
statements.

{p 4 4 2}What is most important to remember about the use of
{cmd:conditionals()} is that the conditional statements apply across
{it:all} tuples.  Thus, {cmd:conditionals(1)} will force
{it:all} tuples to contain the first element in the list.

{p 4 4 2}For example, {cmd:conditionals()} can be used to eliminate
combinations of variables to model in an estimation command that contain
products without first-order (linear) terms (see Example #2 below).  To do
so, consider what is to be done.  Imagine 2 variables and their product:
{cmd:A}, {cmd:B}, and {cmd:AxB}.  Assume they are listed as

{p 4 4 2}{cmd: A B AxB}

{p 4 4 2}in the list offered to {cmd:tuples}. You need to make sure that
{cmd:AxB} never appears without both {cmd:A} and {cmd:B}.  The challenge
is then translating that language into a logical
statement.  Begin with an easy component: 
"{res}...{cmd:AxB} never appears without both {cmd:A} and {cmd:B}{txt}" 
contains 
"{res}{cmd:A} and {cmd:B}{txt}" 
which can be represented as
"{res}{cmd:A}&{cmd:B}{txt}" 
or {c -} because {cmd:conditionals()} requires a
positional statement {c -} "{res}1&2{txt}".  Thus, you are left with
"{res}...{cmd:AxB} never appears without both 1&2{txt}".

{p 4 4 2}In addition, 
"{res}...{cmd:AxB} never appears without both 1&2{txt}" 
contains the term "{res}both{txt}".  The "{res}both{txt}"
implies that "{res}1&2{txt}" is a unit and, therefore, should be put in
parentheses, leading to 
"{res}...{cmd:AxB} never appears without (1&2){txt}".  
Next, consider the word "{res}without{txt}" which can be
represented as a "{res}and not{txt}" statement.  Including the 
"{res}and not{txt}" statement,  
"{res}...{cmd:AxB} never appears &!(1&2)){txt}".

{p 4 4 2}Finally, the most tricky component: you need to represent the
fact that {cmd:AxB} and not both {cmd:A} and {cmd:B} cannot be allowed.
Hence, the language "{res}appears{txt}" can be translated first into a
statement binding the positional statement for {cmd:AxB} to the existing
logical statement, producing "{res}...never 3&!(1&2){txt}".  The last
component is simpler, as the "{res}never{txt}" is clearly a
"{res}not{txt}" statement.  Because that "{res}never{txt}" refers to the
notion of {cmd:AxB} appearing with {cmd:A} and {cmd:B}, the
statement must be bound in parentheses, then negated.  Incorporating the
last component results in "{res}!(3&!(1&2)){txt}".

{p 4 4 2}In most cases, eliminating specific sets of combinations will
require the skillful use of the "{res}!{txt}" operator.


{title:Examples}

Example #1: Use of {cmd:tuples} to collect and display {cmd:e(r2)}s following {cmd:regress}
{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. tuples headroom trunk length displacement}{p_end}
{p 4 8 2}{cmd:. gen rsq = .}{p_end}
{p 4 8 2}{cmd:. gen predictors = ""}{p_end}
{p 4 8 2}{cmd:. qui forval i = 1/`ntuples' {c -(}}{p_end}
{p 4 8 2}{cmd:. {space 8}regress mpg `tuple`i''}{p_end}
{p 4 8 2}{cmd:. {space 8}replace rsq = e(r2) in `i'}{p_end}
{p 4 8 2}{cmd:. {space 8}replace predictors = "`tuple`i''" in `i'}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}
{p 4 8 2}{cmd:. gen p = wordcount(predictors) if predictors != ""}{p_end}
{p 4 8 2}{cmd:. sort p rsq}{p_end}
{p 4 8 2}{cmd:. l predictors rsq in 1/`ntuples'}{p_end} 

Example #2: Extension of #1, with AIC and an interaction using
{cmd:conditionals()} {bf:(N.B. requires Mata)}
{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. tuples headroom trunk length displacement c.trunk#c.length, cond(!(5&!(2&3)))}{p_end}
{p 4 8 2}{cmd:. gen aic = .}{p_end}
{p 4 8 2}{cmd:. gen predictors = ""}{p_end}
{p 4 8 2}{cmd:. qui forval i = 1/`ntuples' {c -(}}{p_end}
{p 4 8 2}{cmd:. {space 8}regress mpg `tuple`i''}{p_end}
{p 4 8 2}{cmd:. {space 8}estat ic}{p_end}
{p 4 8 2}{cmd:. {space 8}mata: st_store(`i', "aic",  st_matrix("r(S)")[1,5])}{p_end}
{p 4 8 2}{cmd:. {space 8}replace predictors = "`tuple`i''" in `i'}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}
{p 4 8 2}{cmd:. gen p = wordcount(predictors) if predictors != ""}{p_end}
{p 4 8 2}{cmd:. sort p aic}{p_end}
{p 4 8 2}{cmd:. l predictors aic in 1/`ntuples'}{p_end}

Example #3: Obtain all possible tuples from a list
{p 4 8 2}{cmd:. tuples 1 2 3 4}

Example #4: Obtain tuples where two synonyms ("big" and "large") are not to appear together {bf:(N.B. requires Mata)}
{p 4 8 2}{cmd:. tuples the big large red fast car, cond(1&6 !(2&3))}


{title:Authors}

{p 4 4 2}Joseph N. Luchman, Fors Marsh Group LLC{break}
jluchman@forsmarshgroup.com{break}
Daniel Klein, Universit{c a:}t Kassel{break}
klein.daniel.81@gmail.com{break}
and{break}
Nicholas J. Cox, Durham University{break} 
n.j.cox@durham.ac.uk


{title:Acknowledgments} 

{p 4 4 2}Sebastian Orbe reported a problem which led to a bug fix.  
Volodymyr Vovchack suggested including the {cmd:min()} option.


