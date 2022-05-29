{smcl}
{* version 1.1.0  21mar2022  Gorkem Aksaray <gaksaray@ku.edu.tr>}
{viewerjumpto "Syntax" "frapply##syntax"}{...}
{viewerjumpto "Description" "frapply##description"}{...}
{viewerjumpto "Options" "frapply##options"}{...}
{viewerjumpto "Stored results" "frapply##results"}{...}
{viewerjumpto "Examples" "frapply##examples"}{...}
{viewerjumpto "Remarks" "frapply##remarks"}{...}
{viewerjumpto "Author" "frapply##author"}{...}
{vieweralsosee "gautils" "help gautils"}{...}
{cmd:help frapply}{right: {browse "https://github.com/gaksaray/stata-gautils/"}}
{hline}

{title:Title}

{phang}
{bf:frapply} {hline 2} Nondestructively apply command(s) to a frame


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:frapply} [{it:framename1}]
{ifin}
[{cmd:,}
{cmd:into(}{it:framename2 }[{cmd:, }{opt replace }{opt ch:ange}{cmd:}]{cmd:)}
{opt qui:etly}]
[: {it:commandlist}]

{pstd}
where the syntax of {it:commandlist} is 

{p 8 16 2}
{it:command} [ |> {it:command} [ |> {it:command} [...]]]

{pstd}
and {it:command} is any Stata command.

{pstd}
{cmd:frapply} is a flexible command.
It takes {it:framename1} (or current frame if not specified),
subsets it by {help if} and {help in},
applies daisy chained command(s) to it,
and puts the end result in either a new frame, an existing frame if {opt replace} is specified, or a temporary frame (discarded when the program concludes) if {opt into()} is not specified at all.

{pstd}
{it:framename1} (or current frame) is always preserved.

{pstd}
{it:{opt Note}}{bf::}
Specifying {it:framename1} inside {cmd:frapply} is functionally equivalent to using {help frame_prefix:frame prefix} as in {cmd:frame }{it:framename1}{cmd:: frapply}.
However, {cmd:frame:} prefix is not recommended to use with {cmd:frapply} not only because it is redundant but also because it disables the {opt change} option (see {help frapply##options:options}). 


{marker description}{...}
{title:Description}

{pstd}
{cmd:frapply} applies a command or a series of commands to the dataset in the specified (or current) frame and optionally puts the result into another frame.
Commands that are otherwise destructive (such as {help drop}, {help keep}, {help collapse}, {help contract} etc.) can be run serially while preserving the dataset.
This can be particularly useful in interactive and experimental settings where we want to quickly and iteratively summarize and/or transform the data without changing it.

{pstd}
{cmd:frapply} can also be a convenient drop-in replacement for the {help frames_prefix:frames prefix} and a substitute for {help frames} commands such as {help frame copy} and {help frame put}.
It can do everything those commands can do in a more flexible fashion.


{marker options}{...}
{title:Options}

{phang}
{opt replace} overwrites the {it:framename2}.

{phang}
{opt change} makes the {it:framename2} current frame.

{phang}
{opt quietly} silences the output of {cmd:frapply}. Use {help noisily} to display the results of any command in {it:commandlist}.


{marker examples}{...}
{title:Examples}

{pstd}
Running {cmd:frapply} on multiple datasets

{phang}{input:. frames reset}{p_end}
{phang}{input:. frame create auto1}{p_end}
{phang}{input:. frame create auto2}{p_end}
{phang}{input:. frame auto1: sysuse auto}{p_end}
{phang}{input:. frame auto2: sysuse auto2}{p_end}

{phang}{input:. frapply auto1, into(copy1, replace): collapse mpg, by(foreign)}{p_end}
{phang}{input:. cwf copy1}{text: // includes summary stats; auto1 is not changed}{p_end}

{phang}{input:. frapply auto2, into(copy2, replace): contract mpg foreign}{p_end}
{phang}{input:. cwf copy2}{text: // includes frequencies; auto2 is not changed}{p_end}

{pstd}
Applying serial commands interactively

{phang}{input:. sysuse auto, clear}{p_end}

{phang}{input:. frapply if price > 5000 & mpg > 15, into(subset)}{p_end}

{phang}{input:. frapply, into(subset, replace change): ///}{p_end}
{phang}{input:{space 6}keep if price > 5000 |>{space 12}///}{text: you may change these numbers}{p_end}
{phang}{input:{space 6}keep if mpg > 15{space 5}|>{space 12}///}{text: and run frapply again}{p_end}
{phang}{input:{space 6}collapse price mpg, by(foreign)}{text:{space 5}// to see the result change}{p_end}

{pstd}
Listing means by group

{phang}{input:. sysuse auto, clear}{p_end}
{phang}{input:. frapply: collapse price mpg, by(foreign) |> list}

{pstd}
Displaying predictive margins

{phang}{input:. sysuse auto, clear}{p_end}
{phang}{input:. frapply, qui: reg price mpg |> predict yhat |> collapse yhat |> noi l}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:frapply} uses |>-separator to daisy chain commands, somewhat similar to {browse "https://stat.ethz.ch/R-manual/R-devel/library/base/html/pipeOp.html":the pipe operator in R} (and in {browse "https://magrittr.tidyverse.org/":Tidyverse}).
This was changed from an earlier version of {cmd:frapply} in which the separator was ||.
This is in order to distinguish it from the ||-separator notation used in {help twoway}, which denotes serial superimposition rather than chaining.
The |> operator makes it clear that it acts as a forward pipe, and is also more familiar for folks coming from R.

{pstd}
One seeming limitation of using daisy-chained {it:commandlist} is that macros produced by a command may not be an input of a subsequent command.
For example, {cmd:summary |> di `r(mean)'} would summarize the dataset but not display {cmd:r(mean)}, as Stata would substitute the local macro before {cmd:frapply} starts to run.

{pstd}
To illustrate,

{phang}{input:. sysuse auto, clear}{p_end}
{phang}{input:. frapply, qui: sum price |> noi di r(mean)}{p_end}

{pstd}
displays the mean. However,

{phang}{input:. frapply, qui: sum price |> noi di `r(mean)'}{p_end}

{pstd}
doesn't display the mean, as the local macro {cmd:`r(mean)'} is substituted to nothing right before {cmd:frapply} runs.

{pstd}
This can be circumvented by using escape character "\" before any macro.
In the same example,

{phang}{input:. frapply, qui: sum price |> noi di \`r(mean)'}{p_end}

{pstd}
does display the mean.


{marker author}{...}
{title:Author}

{pstd}
Gorkem Aksaray, Koc University.{break}
Email: {browse "mailto:gaksaray@ku.edu.tr":gaksaray@ku.edu.tr}{break}
Personal Website: {browse "https://sites.google.com/site/gorkemak/":sites.google.com/site/gorkemak}{break}
GitHub: {browse "https://github.com/gaksaray/":github.com/gaksaray}{break}
