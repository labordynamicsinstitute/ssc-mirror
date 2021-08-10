{smcl}
{hline}
help for {cmd:wridit} and {cmd:fridit}{right:(Roger Newson)}
{hline}

{title:Generate weighted ridits}

{p 8 21 2}
{cmd:wridit} {varname} {ifin} {weight} , {cmdab:g:enerate}{cmd:(}{help varname:{it:newvarname}}{cmd:)} 
  {break}
  [  {cmd:by(}{varlist}{cmd:)}
  {cmdab:ha:ndedness}{cmd:(}{it:handedness}{cmd:)} {cmdab:fol:ded} {cmdab:rev:erse} {cmdab:perc:ent} {cmd:float}
  ]

{p 8 21 2}
{cmd:fridit} {varname} {ifin} , {cmdab:g:enerate}{cmd:(}{help varname:{it:newvarname}}{cmd:)}
  {break}
  {cmdab:ffr:ame}{cmd:(}{it:framename} [, {cmdab:w:eightvar}{cmd:(}{varname}{cmd:)}  {cmdab:x:var}{cmd:(}{varname}{cmd:)}] {cmd:)}
  {break}
  [  {cmd:by(}{varlist}{cmd:)}
  {cmdab:ha:ndedness}{cmd:(}{it:handedness}{cmd:)} {cmdab:fol:ded} {cmdab:rev:erse} {cmdab:perc:ent} {cmd:float}
  ]

{pstd}
where {it:handedness} is

{pstd}
{cmdab:c:enter} | {cmdab:l:eft} | {cmdab:r:ight}

{pstd}
{cmd:fweight}s, {cmd:pweight}s,  {cmd:aweight}s, and {cmd:iweight}s are allowed for {cmd:wridit};
see {help weight}.


{title:Description}

{pstd}
{cmd:wridit} inputs a variable and generates its weighted ridits.
If no weights are provided, then all weights are assumed equal to 1,
so unweighted ridits are generated.
Zero weights are allowed,
and imply that the ridits calculated for the observations with zero weights
will refer to the distribution of weights in the observations with nonzero weights.
{cmd:fridit} inputs a variable and generates its weighted foreign ridits,
with respect to a distribution identified by the data in a {help frame:data frame}.


{title:Options for {cmd:wridit} and {cmd:fridit}}

{p 4 8 2}
{cmd:generate(}{help varname:{it:newvarname}}{cmd:)} must be specified.
It specifies the name of the generated output variable,
containing the weighted ridits.

{p 4 8 2}
{cmd:by(}{varlist}{cmd:)} specifies a list of by-variables.
If {cmd:by()} is specified,
then the weighted ridits are computed within by-groups.

{p 4 8 2}
{cmd:handedness(}{it:handedness}{cmd:)} specifies the handedness of the ridits to be generated.
It may be {cmd:center} (the default), {cmd:left}, or {cmd:right}.
If {cmd:left} is specified, then the left-continuous ridit is generated.
If {cmd:right} is specified, then the right-continuous ridit is generated.
If {cmd:center} is specified (or the {cmd:handedness()} option is absent),
then the standard center ridits
(equal in each observation to the mean of the left ridit and the right ridit)
are generated.

{p 4 8 2}
{cmd:folded} specifies that the weighted ridits generated will be folded ridits.
A folded ridit, on a proportion scale from -1 to 1,
is defined as {cmd:2*R-1},
where {cmd:R} is the corresponding unfolded ridit (on a proportion scale from 0 to 1).

{p 4 8 2}
{cmd:reverse} specifies that the weighted ridits will be reverse ridits,
based on reverse cumulative probabilities.

{p 4 8 2}
{cmd:percent} specifies that the weighted ridits will be generated on a percentage scale
from 0 to 100,
or from -100 to 100 if {cmd:folded} is specified.
If {cmd:percent} is not specified,
then the weighted ridits will be generated on a proportion scale from 0 to 1,
or from -1 to 1 if {cmd:folded} is specified.

{p 4 8 2}
{cmd:float} specifies that the weighted ridits will be generated with {help data types:storage type} {cmd:float}.
If {cmd:float} is not specified, then the weighted ridits will be generated
with {help data types:storage type} {cmd:double}.
The generated variable will then be compressed,
if that can be done without loss of information.


{title:Options for {cmd:fridit} only}

{p 4 8 2}
{cmd:fframe(}{it:framename} [, {cmd:weightvar(}{varname} {cmd:xvar(}{varname}{cmd:)}] {cmd:)}
must be specified.
It specifies an existing {help frame:data frame},
knowwn as the foreign frame,
and specifying a distribution with respect to which the ridits will be generated.
This data frame must contain a variable with the same mode (numeric or string)
as the input variable,
with the name specified by the {cmd:xvar()} option if present
and the same name as the input variable otherwise,
plus variables with the same names and modes as the {cmd:by()} variables
(if a {cmd:by()} option is specified).
It may also contain a weight variable, specified by the {cmd:weightvar()} suboption,
containing weights to specify a frequency distribution for the variable
with the same name as th input variable.
If a {cmd:weightvar()} option is not specified,
then all weights are assumed to be 1.
The generated variable will contain foreign ridits,
which are ridits with respect to the distribution specified
by the variable of the same name in the foreign frame,
and by the weight variable in the foreign frame (if specified).


{title:Methods and formulas}

{pstd}
Ridits were introduced by Bross (1958).
Given a variable {it:X},
the unfolded ridit for a value {it:x} is equal to the probability that {it:X<x}
plus half the probability that {it:X==x}.
The folded ridit for {it:x}, introduced by Brockett and Levene (1977),
is equal to the probability that {it:X<x}
minus the probability that {it:X>x}.
These ridits are classed as center ridits.
The unfolded left ridit is the probability that {it:X<x},
and the folded left ridit is the probability that {it:X<x}
minus the probability that {it:X>=x}.
The unfolded right ridit is the probability that {it:X<=x},
and the folded right ridit is the probability that {it:X<=x}
minus the probability that {it:X>x}.
Note that the center ridit is the mean of the left ridit and the right ridit,
whether unfolded or folded ridits are generated.
Note, also, that the unfolded right ridit
is also known as the sample cumulative distribution function.

{pstd}
Foreign ridits (computed by {cmd:fridit})
are defined in the same way as the native ridits generated by {cmd:wridit},
except that they are defined with respect to the distribution of a variable {it:Y},
possibly in another population,
instead of with respect to the distribution of {it:X}.
For instance, the unfolded ridit for a value {it:x} is equal to the probability that {it:Y<x}
plus half the probability that {it:Y==x}.
The distribution of the variable {it:Y} is specified in the foreign frame.


{title:Remarks}

{pstd}
Nicholas J. Cox introduced an {helpb egen} function {cmd:ridit()},
computing unweighted unfolded center ridits,
as part of the {helpb egenmore} package,
downloadable from {help ssc:SSC}.


{title:Examples}

{p 8 12 2}{cmd:. wridit mpg, gene(wrid1)}{p_end}

{p 8 12 2}{cmd:. wridit mpg [pwei=weight], gene(wrid2) by(foreign)}{p_end}

{pstd}
The following advanced example demonsttrates {cmd:fridit} in the {cmd:auto} data.
We first use the {help ssc:SSC} package {helpb xcontract}
to create a {help frame:data frame} {cmd:frankie},
with 1 observation per value of {cmd:mpg} present in the US car models,
and data on the frequencies and percents of these values in the US car models.
We then use {cmd:fridit} to computse foreign ridits of {cmd:mpg} for all car models,
with respect to the frequency distribution of {cmd:mpg} in the US car models,
specified by the weight variable {cmd:_freq} in the frame {cmd:frankie}.
These ridits are stored in  a variable {cmd:jenny}.
We then use {helpb xcontract} to list the values of {cmd:mpg},
and the corresponding ridit value stored in {cmd:jenny},
in the US and non-US car models.
Note that some of the foreign ridits of {cmd:mpg} values in the non-US car models
have value 1,
corresponding to values of {cmd:mpg} higher than any values inn the US car models.

{p 8 12 2}{cmd:. sysuse auto, clear}{p_end}
{p 8 12 2}{cmd:. desc}{p_end}
{p 8 12 2}{cmd:. xcontract mpg if foreign==0, frame(frankie, replace) list(, abbr(32))}{p_end}
{p 8 12 2}{cmd:. fridit mpg, ffr(frankie, weightvar(_freq)) gene(jenny)}{p_end}
{p 8 12 2}{cmd:. xcontract mpg jenny, by(foreign) list(, abbr(32))}{p_end}


{title:References}

{phang}
Brockett, P. L., and Levene, A.  1977.
On a characterization of ridits.
{it:The Annals of Statistics} 5(6): 1245-1248.

{phang}
Bross, I. D. J.  1958.
How to use ridit analysis.
{it:Biometrics} 14(1): 18-38.


{title:Author}

{pstd}
Roger Newson, King's College London, UK.{break}
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[D] egen}
{p_end}
{p 4 13 2}
On-line: help for {helpb egen}{break}
         help for {helpb egenmore}, {helpb xcontract} if installed
{p_end}
