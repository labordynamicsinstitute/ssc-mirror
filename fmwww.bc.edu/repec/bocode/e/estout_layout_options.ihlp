{p 4 8 2}
{cmd:varwidth(}{it:#}{cmd:)} specifies the number of characters used to display
the names (labels) of regressors and statistics (i.e. {cmd:varwidth}
specifies the width of the table's left stub). Long names (labels) are
abbreviated (depending on the {cmd:abbrev} option) and short or empty
cells are padded out with blanks to fit the width specified by the user.
{cmd:varwidth} defaults to 0, which means that the names are not
abbreviated and no white space is added. Specifying low values may cause
misalignment.

{p 4 8 2}
{cmd:modelwidth(}{it:#}{cmd:)} designates the number of characters used to display
the results columns. If a non-zero {cmd:modelwidth} is specified, model names
are abbreviated if necessary (depending on the {cmd:abbrev} option) and short
or empty results cells are padded out with blanks. In contrast,
{cmd:modelwidth} does not shorten or truncate the display of the results
themselves (coefficients, t-statistics, summary statistics, etc.) although it may
add blanks if needed. {cmd:modelwidth} defaults to 0, which means that the
model names are not abbreviated and no white space is added. Specifying low
values may cause misalignment.

{p 8 8 2}
The purpose of {cmd:modelwidth} is to be able to construct a fixed-format
table and thus make the raw table more readable. Be aware, however, that the
added blanks may cause problems with the conversion to a table in word
processors or spreadsheets.

{p 4 8 2}
{cmd:abbrev} specifies that long names and labels be abbreviated if
a {cmd:modelwidth()} and/or a {cmd:varwidth()} is specified.

{p 4 8 2}
{cmd:unstack} specifies that the individual equations from multiple-equation
models (e.g. {cmd:mlogit}, {cmd:reg3}, {cmd:heckman}) be placed in
separate columns. The default is to place the equations below one another in a
single column. Summary statistics will be reported for each equation if
{cmd:unstack} is specified and the estimation command is either {cmd:reg3},
{cmd:sureg}, or {cmd:mvreg} (see help {help reg3}, help {help sureg}, help {help mvreg}).

{p 4 8 2}
{cmd:begin(}<{it:string}>{cmd:)} specifies a string to be printed at the
beginning of every table row. The default is an empty string. It is possible to
use special functions such as {cmd:_tab} or {cmd:_skip} in
{cmd:begin()}. For more information on using such functions, see the
description of the functions in help {help file}.

{p 4 8 2}
{cmd:delimiter(}<{it:string}>{cmd:)} designates the delimiter used between the
table columns. The default is a tab character. See the {cmd:begin} option
above for further details.

{p 4 8 2}
{cmd:end(}<{it:string}>{cmd:)} specifies a string to be printed at the end of
every table row. The default is an empty string. See the {cmd:begin} option
above for further details.

{p 4 8 2}
{cmd:dmarker(}<{it:string}>{cmd:)} specifies the form of the decimal marker. The
standard decimal symbol (a period or a comma, depending on the input provided
to {cmd:set dp}; see help {help format}) is replaced by {it:string}.

{p 4 8 2}
{cmd:msign(}<{it:string}>{cmd:)} determines the form of the minus sign. The
standard minus sign ({cmd:-}) is replaced by {it:string}.

{p 4 8 2}
{cmd:lz} specifies that the leading zero of fixed format numbers in the
interval (-1,1) be printed. This is the default. Use {cmd:nolz} to advise
{cmd:estout} to omit the leading zeros (that is, to print numbers like
{cmd:0.021} or {cmd:-0.33} as {cmd:.021} and {cmd:-.33}).

{p 4 8 2}
{cmd:substitute(}{it:subst_list}{cmd:)} specifies that the substitutions
specified in {it:subst_list} be applied to the estimates table after it has
been created. Specify {it:subst_list} as a list of substitution pairs, that
is:

{p 12 12 2}
<{it:from}> <{it:to}> [<{it:from}> <{it:to}> ...]
